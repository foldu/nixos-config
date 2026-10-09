// A thin Electron window over the `dsh web` user service. The service owns the
// harness process; this app only displays the URL it serves. Because `dsh web`
// mints its authentication token per process, the service publishes that URL in
// $XDG_RUNTIME_DIR/dsh-web/url (see the dsh-web unit in
// home/common/graphical/dsh-desktop.nix) and this app waits for it, so a window
// opened before the server is up attaches on its own.
const { app, BrowserWindow, nativeTheme, shell } = require("electron");
const fs = require("node:fs/promises");
const path = require("node:path");

/** Where the dsh-web unit parks its URL (RuntimeDirectory=dsh-web). */
const urlFile = path.join(
  process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid()}`,
  "dsh-web",
  "url",
);

/** The service publishes the URL within a second of starting; poll cheaply. */
const pollMilliseconds = 1000;

const startingPage = path.join(__dirname, "starting.html");

/** The URL on display, or null while the window shows the waiting page. */
let shown = null;
/** Whether the waiting page is loaded, so polling does not reload it. */
let waiting = false;
let window = null;

/** The service's current URL, or null when it is not serving. */
async function serviceUrl() {
  try {
    const text = await fs.readFile(urlFile, "utf8");
    // A restart rewrites the file; the last line is the current token.
    return text.trim().split("\n").at(-1) || null;
  } catch {
    return null; // nothing published yet, or the service is down
  }
}

async function showWaiting() {
  if (waiting || window === null || window.isDestroyed()) return;
  waiting = true;
  await window.loadFile(startingPage).catch(() => {});
}

/**
 * Hold the window against whatever the service is serving: wait until it
 * publishes a URL, load that URL the first time it is seen, and drop back to
 * the waiting page when a load fails (a restart, or a port not yet bound) so
 * the next poll re-attaches.
 */
async function attach() {
  for (;;) {
    if (window === null || window.isDestroyed()) return;
    const url = await serviceUrl();
    if (url === null) {
      shown = null;
      await showWaiting();
    } else if (url !== shown) {
      waiting = false;
      try {
        await window.loadURL(url);
        shown = url;
      } catch {
        shown = null;
        await showWaiting();
      }
    }
    await new Promise((resolve) => setTimeout(resolve, pollMilliseconds));
  }
}

// A second launch is a request to surface the window that already exists.
if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on("second-instance", () => {
    if (window === null) return;
    if (window.isMinimized()) window.restore();
    window.focus();
  });

  app.whenReady().then(() => {
    window = new BrowserWindow({
      width: 1280,
      height: 860,
      title: "DeepSeek Harness",
      // dsh's own light and dark base colours, picked by the desktop's
      // preference, so the first paint does not flash the other theme.
      backgroundColor: nativeTheme.shouldUseDarkColors ? "#151517" : "#ffffff",
      autoHideMenuBar: true,
      webPreferences: {
        // The page is dsh's own GUI: no preload, no node, no shared context.
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: true,
      },
    });

    // Links out of the GUI belong in the user's browser, not in this window.
    window.webContents.setWindowOpenHandler(({ url }) => {
      shell.openExternal(url);
      return { action: "deny" };
    });

    // A failed main-frame load means the service went away; let the loop
    // re-attach. ERR_ABORTED (-3) is an ordinary redirect or superseded
    // navigation, and the waiting page is local, so neither counts.
    window.webContents.on("did-fail-load", (_event, code, _description, failedUrl, isMainFrame) => {
      if (!isMainFrame || code === -3 || failedUrl.startsWith("file://")) return;
      shown = null;
    });

    window.on("closed", () => {
      window = null;
    });

    attach();
  });

  app.on("window-all-closed", () => app.quit());
}
