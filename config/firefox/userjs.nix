/******
* name: ghacks user.js
* date: 15 February 2020
* version 73-beta
* authors: v52+ github | v51- www.ghacks.net
* url: https://github.com/ghacksuserjs/ghacks-user.js
* license: MIT: https://github.com/ghacksuserjs/ghacks-user.js/blob/master/LICENSE.txt

* releases: These are end-of-stable-life-cycle legacy archives.
            *Always* use the master branch user.js for a current up-to-date version.
       url: https://github.com/ghacksuserjs/ghacks-user.js/releases

* README:

  0. Consider using Tor Browser if it meets your needs or fits your threat model better
     * https://www.torproject.org/about/torusers.html.en
  1. READ the full README
     * https://github.com/ghacksuserjs/ghacks-user.js/blob/master/README.md
  2. READ this
     * https://github.com/ghacksuserjs/ghacks-user.js/wiki/1.3-Implementation
  3. If you skipped steps 1 and 2 above (shame on you), then here is the absolute minimum
     * Real time binary checks with Google services are disabled (0412)
     * You will still get prompts to update Firefox, but auto-installing them is disabled (0302a)
     * Some user data is erased on close (section 2800). Change this to suit your needs
     * EACH RELEASE check:
         - 4600s: reset prefs made redundant due to privacy.resistFingerprinting (RPF)
                  or enable them as an alternative to RFP (or some of them for ESR users)
         - 9999s: reset deprecated prefs in about:config or enable the relevant section for ESR
     * Site breakage WILL happen
         - There are often trade-offs and conflicts between Security vs Privacy vs Anti-Fingerprinting
           and these need to be balanced against Functionality & Convenience & Breakage
     * You will need to make changes, and to troubleshoot at times (choose wisely, there is always a trade-off).
       While not 100% definitive, search for "[SETUP". If required, add each pref to your overrides section at
       default values (or comment them out and reset them in about:config). Here are the main ones:
       [SETUP-SECURITY] it's one item, read it
            [SETUP-WEB] can cause some websites to break
         [SETUP-CHROME] changes how Firefox itself behaves (i.e. NOT directly website related)
           [SETUP-PERF] may impact performance
         [SETUP-HARDEN] maybe you should consider using the Tor Browser
     * [WARNING] tags are extra special and used sparingly, so heed them
  4. BACKUP your profile folder before implementing (and/or test in a new/cloned profile)
  5. KEEP UP TO DATE: https://github.com/ghacksuserjs/ghacks-user.js/wiki#small_orange_diamond-maintenance

* INDEX:

  0100: STARTUP
  0200: GEOLOCATION / LANGUAGE / LOCALE
  0300: QUIET FOX
  0400: BLOCKLISTS / SAFE BROWSING
  0500: SYSTEM ADD-ONS / EXPERIMENTS
  0600: BLOCK IMPLICIT OUTBOUND
  0700: HTTP* / TCP/IP / DNS / PROXY / SOCKS etc
  0800: LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS
  0900: PASSWORDS
  1000: CACHE / SESSION (RE)STORE / FAVICONS
  1200: HTTPS (SSL/TLS / OCSP / CERTS / HPKP / CIPHERS)
  1400: FONTS
  1600: HEADERS / REFERERS
  1700: CONTAINERS
  1800: PLUGINS
  2000: MEDIA / CAMERA / MIC
  2200: WINDOW MEDDLING & LEAKS / POPUPS
  2300: WEB WORKERS
  2400: DOM (DOCUMENT OBJECT MODEL) & JAVASCRIPT
  2500: HARDWARE FINGERPRINTING
  2600: MISCELLANEOUS
  2700: PERSISTENT STORAGE
  2800: SHUTDOWN
  4000: FPI (FIRST PARTY ISOLATION)
  4500: RFP (RESIST FINGERPRINTING)
  4600: RFP ALTERNATIVES
  4700: RFP ALTERNATIVES (NAVIGATOR / USER AGENT (UA) SPOOFING)
  5000: PERSONAL
  9999: DEPRECATED / REMOVED / LEGACY / RENAMED

******/

/* START: internal custom pref to test for syntax errors
 * [NOTE] In FF60+, not all syntax errors cause parsing to abort i.e. reaching the last debug
 * pref no longer necessarily means that all prefs have been applied. Check the console right
 * after startup for any warnings/error messages related to non-applied prefs
 * [1] https://blog.mozilla.org/nnethercote/2018/03/09/a-new-preferences-parser-for-firefox/ ***/

/* 0000: disable about:config warning
 * FF71-72: chrome://global/content/config.xul
 * FF73+: chrome://global/content/config.xhtml ***/
{
  "general.warnOnAboutConfig" = false;
  # XUL/XHTML version
  "browser.aboutConfig.showWarning" = false;
  # HTML version [FF71+]

  /*** [SECTION 0100]: STARTUP ***/

  /* 0101: disable default browser check
   * [SETTING] General>Startup>Always check if Firefox is your default browser ***/
  "browser.shell.checkDefaultBrowser" = false;
  /* 0102: set START page (0=blank, 1=home, 2=last visited page, 3=resume previous session)
   * [NOTE] Session Restore is not used in PB mode (0110) and is cleared with history (2803, 2804)
   * [SETTING] General>Startup>Restore previous session ***/
  "browser.startup.page" = 3;
  /* 0103: set HOME+NEWWINDOW page
   * about:home=Activity Stream (default, see 0105), custom URL, about:blank
   * [SETTING] Home>New Windows and Tabs>Homepage and new windows ***/
  "browser.startup.homepage" = "about:blank";
  /* 0104: set NEWTAB page
   * true=Activity Stream (default, see 0105), false=blank page
   * [SETTING] Home>New Windows and Tabs>New tabs ***/
  "browser.newtabpage.enabled" = false;
  "browser.newtab.preload" = false;
  /* 0105: disable Activity Stream stuff (AS)
   * AS is the default homepage/newtab in FF57+, based on metadata and browsing behavior.
   *    **NOT LISTING ALL OF THESE: USE THE PREFERENCES UI**
   * [SETTING] Home>Firefox Home Content>...  to show/hide what you want ***/
  /* 0105a: disable Activity Stream telemetry ***/
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  /* 0105b: disable Activity Stream Snippets
   * Runs code received from a server (aka Remote Code Execution) and sends information back to a metrics server
   * [1] https://abouthome-snippets-service.readthedocs.io/ ***/
  "browser.newtabpage.activity-stream.feeds.snippets" = false;
  "browser.newtabpage.activity-stream.asrouter.providers.snippets" = "";
  /* 0105c: disable Activity Stream Top Stories, Pocket-based and/or sponsored content ***/
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
  "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
  # [FF66+]
  /* 0105d: disable Activity Stream recent Highlights in the Library [FF57+] ***/
  # "browser.library.activity-stream.enabled" = false;
  /* 0110: start Firefox in PB (Private Browsing) mode
   * [NOTE] In this mode *all* windows are "private windows" and the PB mode icon is not displayed
   * [WARNING] The P in PB mode is misleading: it means no "persistent" disk storage such as history,
   * caches, searches, cookies, localStorage, IndexedDB etc (which you can achieve in normal mode).
   * In fact, PB mode limits or removes the ability to control some of these, and you need to quit
   * Firefox to clear them. PB is best used as a one off window (File>New Private Window) to provide
   * a temporary self-contained new session. Close all Private Windows to clear the PB mode session.
   * [SETTING] Privacy & Security>History>Custom Settings>Always use private browsing mode
   * [1] https://wiki.mozilla.org/Private_Browsing
   * [2] https://spreadprivacy.com/is-private-browsing-really-private/ ***/
  # "browser.privatebrowsing.autostart" = true;

  /*** [SECTION 0200]: GEOLOCATION / LANGUAGE / LOCALE ***/

  /** GEOLOCATION ***/
  /* 0201: disable Location-Aware Browsing
   * [NOTE] Best left at default "true", fingerprintable, is already behind a prompt (see 0202)
   * [1] https://www.mozilla.org/firefox/geolocation/ ***/
  # "geo.enabled" = false;
  /* 0202: set a default permission for Location (see 0201) [FF58+]
   * 0=always ask (default), 1=allow, 2=block
   * [NOTE] Best left at default "always ask", fingerprintable via Permissions API
   * [SETTING] to add site exceptions: Page Info>Permissions>Access Your Location
   * [SETTING] to manage site exceptions: Options>Privacy & Security>Permissions>Location>Settings ***/
  # "permissions.default.geo" = 2;
  /* 0203: use Mozilla geolocation service instead of Google when geolocation is enabled
   * Optionally enable logging to the console (defaults to false) ***/
  "geo.wifi.uri" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
  # "geo.wifi.logging.enabled" = true; // [HIDDEN PREF]
  /* 0204: disable using the OS's geolocation service ***/
  "geo.provider.ms-windows-location" = false;
  # [WINDOWS]
  "geo.provider.use_corelocation" = false;
  # [MAC]
  "geo.provider.use_gpsd" = false;
  # [LINUX]
  /* 0205: disable GeoIP-based search results
   * [NOTE] May not be hidden if Firefox has changed your settings due to your locale
   * [1] https://trac.torproject.org/projects/tor/ticket/16254
   * [2] https://support.mozilla.org/en-US/kb/how-stop-firefox-making-automatic-connections#w_geolocation-for-default-search-engine ***/
  "browser.search.region" = "US";
  # [HIDDEN PREF]
  "browser.search.geoip.url" = "";
  /* 0206: disable geographically specific results/search engines e.g. "browser.search.*.US"
   * i.e. ignore all of Mozilla's various search engines in multiple locales ***/
  "browser.search.geoSpecificDefaults" = false;
  "browser.search.geoSpecificDefaults.url" = "";

  /** LANGUAGE / LOCALE ***/
  /* 0210: set preferred language for displaying web pages
   * [TEST] https://addons.mozilla.org/about ***/
  "intl.accept_languages" = "en-US = en";
  /* 0211: enforce US English locale regardless of the system locale
   * [1] https://bugzilla.mozilla.org/867501 ***/
  "javascript.use_us_english_locale" = true;
  # [HIDDEN PREF]
  /* 0212: enforce fallback text encoding to match en-US
   * When the content or server doesn't declare a charset the browser will
   * fallback to the "Current locale" based on your application language
   * [SETTING] General>Language and Appearance>Fonts and Colors>Advanced>Text Encoding for Legacy Content
   * [TEST] https://hsivonen.com/test/moz/check-charset.htm
   * [1] https://trac.torproject.org/projects/tor/ticket/20025 ***/
  "intl.charset.fallback.override" = "windows-1252";

  /*** [SECTION 0300]: QUIET FOX
       Starting in user.js v67, we only disable the auto-INSTALL of Firefox. You still get prompts
       to update, in one click. We have NEVER disabled auto-CHECKING, and highly discourage that.
       Previously we also disabled auto-INSTALLING of extensions (302b).

       There are many legitimate reasons to turn off auto-INSTALLS, including hijacked or monetized
       extensions, time constraints, legacy issues, dev/testing, and fear of breakage/bugs. It is
       still important to do updates for security reasons, please do so manually if you make changes.
  ***/

  /* 0301b: disable auto-CHECKING for extension and theme updates ***/
  # "extensions.update.enabled" = false;
  /* 0302a: disable auto-INSTALLING Firefox updates [NON-WINDOWS FF65+]
   * [NOTE] In FF65+ on Windows this SETTING (below) is now stored in a file and the pref was removed
   * [SETTING] General>Firefox Updates>Check for updates but let you choose to install them ***/
  "app.update.auto" = false;
  /* 0302b: disable auto-INSTALLING extension and theme updates (after the check in 0301b)
   * [SETTING] about:addons>Extensions>[cog-wheel-icon]>Update Add-ons Automatically (toggle) ***/
  # "extensions.update.autoUpdateDefault" = false;
  /* 0306: disable extension metadata
   * used when installing/updating an extension, and in daily background update checks:
   * when false, extension detail tabs will have no description ***/
  # "extensions.getAddons.cache.enabled" = false;
  /* 0308: disable search engine updates (e.g. OpenSearch)
   * [NOTE] This does not affect Mozilla's built-in or Web Extension search engines
   * [SETTING] General>Firefox Updates>Automatically update search engines ***/
  "browser.search.update" = false;
  /* 0309: disable sending Flash crash reports ***/
  "dom.ipc.plugins.flash.subprocess.crashreporter.enabled" = false;
  /* 0310: disable sending the URL of the website where a plugin crashed ***/
  "dom.ipc.plugins.reportCrashURL" = false;
  /* 0320: disable about:addons' Recommendations pane (uses Google Analytics) ***/
  "extensions.getAddons.showPane" = false;
  # [HIDDEN PREF]
  /* 0321: disable recommendations in about:addons' Extensions and Themes panes [FF68+] ***/
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  /* 0330: disable telemetry
   * the pref (.unified) affects the behaviour of the pref (.enabled)
   * IF unified=false then .enabled controls the telemetry module
   * IF unified=true then .enabled ONLY controls whether to record extended data
   * so make sure to have both set as false
   * [NOTE] FF58+ 'toolkit.telemetry.enabled' is now LOCKED to reflect prerelease
   * or release builds (true and false respectively), see [2]
   * [1] https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/internals/preferences.html
   * [2] https://medium.com/georg-fritzsche/data-preference-changes-in-firefox-58-2d5df9c428b5 ***/
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.enabled" = false;
  # see [NOTE] above FF58+
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  # [FF55+]
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  # [FF55+]
  "toolkit.telemetry.updatePing.enabled" = false;
  # [FF56+]
  "toolkit.telemetry.bhrPing.enabled" = false;
  # [FF57+] Background Hang Reporter
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  # [FF57+]
  /* 0331: disable Telemetry Coverage
   * [1] https://blog.mozilla.org/data/2018/08/20/effectively-measuring-search-in-firefox/ ***/
  "toolkit.telemetry.coverage.opt-out" = true;
  # [HIDDEN PREF]
  "toolkit.coverage.opt-out" = true;
  # [FF64+] [HIDDEN PREF]
  "toolkit.coverage.endpoint.base" = "";
  /* 0340: disable Health Reports
   * [SETTING] Privacy & Security>Firefox Data Collection & Use>Allow Firefox to send technical... data ***/
  "datareporting.healthreport.uploadEnabled" = false;
  /* 0341: disable new data submission, master kill switch [FF41+]
   * If disabled, no policy is shown or upload takes place, ever
   * [1] https://bugzilla.mozilla.org/1195552 ***/
  "datareporting.policy.dataSubmissionEnabled" = false;
  /* 0342: disable Studies (see 0503)
   * [SETTING] Privacy & Security>Firefox Data Collection & Use>Allow Firefox to install and run studies ***/
  "app.shield.optoutstudies.enabled" = false;
  /* 0343: disable personalized Extension Recommendations in about:addons and AMO [FF65+]
   * [NOTE] This pref has no effect when Health Reports (0340) are disabled
   * [SETTING] Privacy & Security>Firefox Data Collection & Use>Allow Firefox to make personalized extension recommendations
   * [1] https://support.mozilla.org/kb/personalized-extension-recommendations ***/
  "browser.discovery.enabled" = false;
  /* 0350: disable Crash Reports ***/
  "breakpad.reportURL" = "";
  "browser.tabs.crashReporting.sendReport" = false;
  # [FF44+]
  "browser.crashReports.unsubmittedCheck.enabled" = false;
  # [FF51+]
  /* 0351: disable backlogged Crash Reports
   * [SETTING] Privacy & Security>Firefox Data Collection & Use>Allow Firefox to send backlogged crash reports  ***/
  "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
  # [FF58+]
  /* 0390: disable Captive Portal detection
   * [1] https://www.eff.org/deeplinks/2017/08/how-captive-portals-interfere-wireless-security-and-privacy
   * [2] https://wiki.mozilla.org/Necko/CaptivePortal ***/
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;
  # [FF52+]
  /* 0391: disable Network Connectivity checks [FF65+]
   * [1] https://bugzilla.mozilla.org/1460537 ***/
  "network.connectivity-service.enabled" = false;

  /*** [SECTION 0400]: BLOCKLISTS / SAFE BROWSING (SB) ***/

  /** BLOCKLISTS ***/
  /* 0401: enforce Firefox blocklist, but sanitize blocklist url
   * [NOTE] It includes updates for "revoked certificates"
   * [1] https://blog.mozilla.org/security/2015/03/03/revoking-intermediate-certificates-introducing-onecrl/
   * [2] https://trac.torproject.org/projects/tor/ticket/16931 ***/
  "extensions.blocklist.enabled" = true;
  # [DEFAULT: true]
  "extensions.blocklist.url" = "https://blocklists.settings.services.mozilla.com/v1/blocklist/3/%APP_ID%/%APP_VERSION%/";

  /** SAFE BROWSING (SB)
      Safe Browsing has taken many steps to preserve privacy. *IF* required, a full url is never
      sent to Google, only a PART-hash of the prefix, and this is hidden with noise of other real
      PART-hashes. Google also swear it is anonymized and only used to flag malicious sites.
      Firefox also takes measures such as striping out identifying parameters and since SBv4 (FF57+)
      doesn't even use cookies. (#Turn on browser.safebrowsing.debug to monitor this activity)

      #Required reading [#] https://feeding.cloud.geek.nz/posts/how-safe-browsing-works-in-firefox/
      [1] https://wiki.mozilla.org/Security/Safe_Browsing
      [2] https://support.mozilla.org/en-US/kb/how-does-phishing-and-malware-protection-work
  ***/
  /* 0410: disable SB (Safe Browsing)
   * [WARNING] Do this at your own risk! These are the master switches.
   * [SETTING] Privacy & Security>Security>... "Block dangerous and deceptive content" ***/
  # "browser.safebrowsing.malware.enabled" = false;
  # "browser.safebrowsing.phishing.enabled" = false;
  /* 0411: disable SB checks for downloads (both local lookups + remote)
   * This is the master switch for the safebrowsing.downloads* prefs (0412, 0413)
   * [SETTING] Privacy & Security>Security>... "Block dangerous downloads" ***/
  # "browser.safebrowsing.downloads.enabled" = false;
  /* 0412: disable SB checks for downloads (remote)
   * To verify the safety of certain executable files, Firefox may submit some information about the
   * file, including the name, origin, size and a cryptographic hash of the contents, to the Google
   * Safe Browsing service which helps Firefox determine whether or not the file should be blocked
   * [SETUP-SECURITY] If you do not understand this, or you want this protection, then override it ***/
  "browser.safebrowsing.downloads.remote.enabled" = false;
  "browser.safebrowsing.downloads.remote.url" = "";
  /* 0413: disable SB checks for unwanted software
   * [SETTING] Privacy & Security>Security>... "Warn you about unwanted and uncommon software" ***/
  # "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
  # "browser.safebrowsing.downloads.remote.block_uncommon" = false;
  /* 0419: disable 'ignore this warning' on SB warnings
   * If clicked, it bypasses the block for that session. This is a means for admins to enforce SB
   * [TEST] see github wiki APPENDIX A: Test Sites: Section 5
   * [1] https://bugzilla.mozilla.org/1226490 ***/
  # "browser.safebrowsing.allowOverride" = false;

  /*** [SECTION 0500]: SYSTEM ADD-ONS / EXPERIMENTS
       System Add-ons are a method for shipping extensions, considered to be
       built-in features to Firefox, that are hidden from the about:addons UI.
       To view your System Add-ons go to about:support, they are listed under "Firefox Features"

       Some System Add-ons have no on-off prefs. Instead you can manually remove them. Note that app
       updates will restore them. They may also be updated and possibly restored automatically (see 0505)
       * Portable: "...\App\Firefox64\browser\features\" (or "App\Firefox\etc" for 32bit)
       * Windows: "...\Program Files\Mozilla\browser\features" (or "Program Files (X86)\etc" for 32bit)
       * Mac: "...\Applications\Firefox\Contents\Resources\browser\features\"
              [NOTE] On Mac you can right-click on the application and select "Show Package Contents"
       * Linux: "/usr/lib/firefox/browser/features" (or similar)

       [1] https://firefox-source-docs.mozilla.org/toolkit/mozapps/extensions/addon-manager/SystemAddons.html
       [2] https://dxr.mozilla.org/mozilla-central/source/browser/extensions
  ***/

  /* 0503: disable Normandy/Shield [FF60+]
   * Shield is an telemetry system (including Heartbeat) that can also push and test "recipes"
   * [1] https://wiki.mozilla.org/Firefox/Shield
   * [2] https://github.com/mozilla/normandy ***/
  "app.normandy.enabled" = false;
  "app.normandy.api_url" = "";
  /* 0505: disable System Add-on updates ***/
  "extensions.systemAddon.update.enabled" = false;
  # [FF62+]
  "extensions.systemAddon.update.url" = "";
  # [FF44+]
  /* 0506: disable PingCentre telemetry (used in several System Add-ons) [FF57+]
   * Currently blocked by 'datareporting.healthreport.uploadEnabled' (see 0340) ***/
  "browser.ping-centre.telemetry" = false;
  /* 0515: disable Screenshots
   * alternatively in FF60+, disable uploading to the Screenshots server
   * [1] https://github.com/mozilla-services/screenshots
   * [2] https://www.ghacks.net/2017/05/28/firefox-screenshots-integrated-in-firefox-nightly/ ***/
  # "extensions.screenshots.disabled" = true; // [FF55+]
  # "extensions.screenshots.upload-disabled" = true;
  # [FF60+]
  /* 0517: disable Form Autofill
   * [NOTE] Stored data is NOT secure (uses a JSON file)
   * [NOTE] Heuristics controls Form Autofill on forms without @autocomplete attributes
   * [SETTING] Privacy & Security>Forms and Autofill>Autofill addresses (FF74+)
   * [1] https://wiki.mozilla.org/Firefox/Features/Form_Autofill
   * [2] https://www.ghacks.net/2017/05/24/firefoxs-new-form-autofill-is-awesome/ ***/
  #"extensions.formautofill.addresses.enabled" = false;
  # [FF55+]
  #"extensions.formautofill.available" = "off";
  # [FF56+]
  #"extensions.formautofill.creditCards.enabled" = false;
  # [FF56+]
  #"extensions.formautofill.heuristics.enabled" = false;
  # [FF55+]
  /* 0518: disable Web Compatibility Reporter [FF56+]
   * Web Compatibility Reporter adds a "Report Site Issue" button to send data to Mozilla ***/
  "extensions.webcompat-reporter.enabled" = false;

  /*** [SECTION 0600]: BLOCK IMPLICIT OUTBOUND [not explicitly asked for - e.g. clicked on] ***/

  /* 0601: disable link prefetching
   * [1] https://developer.mozilla.org/docs/Web/HTTP/Link_prefetching_FAQ ***/
  "network.prefetch-next" = false;
  /* 0602: disable DNS prefetching
   * [1] https://www.ghacks.net/2013/04/27/firefox-prefetching-what-you-need-to-know/
   * [2] https://developer.mozilla.org/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control ***/
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  # [HIDDEN PREF ESR] [DEFAULT: true FF70+]
  /* 0603: disable predictor / prefetching ***/
  "network.predictor.enabled" = false;
  "network.predictor.enable-prefetch" = false;
  # [FF48+]
  /* 0605: disable link-mouseover opening connection to linked server
   * [1] https://news.slashdot.org/story/15/08/14/2321202/how-to-quash-firefoxs-silent-requests
   * [2] https://www.ghacks.net/2015/08/16/block-firefox-from-connecting-to-sites-when-you-hover-over-links/ ***/
  "network.http.speculative-parallel-limit" = 0;
  /* 0606: disable "Hyperlink Auditing" (click tracking) and enforce same host in case
   * [1] https://www.bleepingcomputer.com/news/software/major-browsers-to-prevent-disabling-of-click-tracking-privacy-risk/ ***/
  "browser.send_pings" = false;
  # [DEFAULT: false]
  "browser.send_pings.require_same_host" = true;

  /*** [SECTION 0700]: HTTP* / TCP/IP / DNS / PROXY / SOCKS etc ***/

  /* 0701: disable IPv6
   * IPv6 can be abused, especially regarding MAC addresses. They also do not play nice
   * with VPNs. That's even assuming your ISP and/or router and/or website can handle it.
   * Firefox telemetry (April 2019) shows only 5% of all connections are IPv6.
   * [NOTE] This is just an application level fallback. Disabling IPv6 is best done at an
   * OS/network level, and/or configured properly in VPN setups. If you are not masking your IP,
   * then this won't make much difference. If you are masking your IP, then it can only help.
   * [TEST] https://ipleak.org/
   * [1] https://github.com/ghacksuserjs/ghacks-user.js/issues/437#issuecomment-403740626
   * [2] https://www.internetsociety.org/tag/ipv6-security/ (see Myths 2,4,5,6) ***/
  "network.dns.disableIPv6" = true;
  /* 0702: disable HTTP2
   * HTTP2 raises concerns with "multiplexing" and "server push", does nothing to
   * enhance privacy, and opens up a number of server-side fingerprinting opportunities.
   * [WARNING] Disabling this made sense in the past, and doesn't break anything, but HTTP2 is
   * at 40% (December 2019) and growing [5]. Don't be that one person using HTTP1.1 on HTTP2 sites
   * [1] https://http2.github.io/faq/
   * [2] https://blog.scottlogic.com/2014/11/07/http-2-a-quick-look.html
   * [3] https://http2.github.io/http2-spec/#rfc.section.10.8
   * [4] https://queue.acm.org/detail.cfm?id=2716278
   * [5] https://w3techs.com/technologies/details/ce-http2/all/all ***/
  # "network.http.spdy.enabled" = false;
  # "network.http.spdy.enabled.deps" = false;
  # "network.http.spdy.enabled.http2" = false;
  # "network.http.spdy.websockets" = false;
  # [FF65+]
  /* 0703: disable HTTP Alternative Services [FF37+]
   * [SETUP-PERF] Relax this if you have FPI enabled (see 4000) *AND* you understand the
   * consequences. FPI isolates these, but it was designed with the Tor protocol in mind,
   * and the Tor Browser has extra protection, including enhanced sanitizing per Identity.
   * [1] https://tools.ietf.org/html/rfc7838#section-9
   * [2] https://www.mnot.net/blog/2016/03/09/alt-svc ***/
  "network.http.altsvc.enabled" = false;
  "network.http.altsvc.oe" = false;
  /* 0704: enforce the proxy server to do any DNS lookups when using SOCKS
   * e.g. in Tor, this stops your local DNS server from knowing your Tor destination
   * as a remote Tor node will handle the DNS request
   * [1] https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO/WebBrowsers ***/
  "network.proxy.socks_remote_dns" = true;
  /* 0708: disable FTP [FF60+]
   * [1] https://www.ghacks.net/2018/02/20/firefox-60-with-new-preference-to-disable-ftp/ ***/
  # "network.ftp.enabled" = false;
  /* 0709: disable using UNC (Uniform Naming Convention) paths [FF61+]
   * [SETUP-CHROME] Can break extensions for profiles on network shares
   * [1] https://trac.torproject.org/projects/tor/ticket/26424 ***/
  "network.file.disable_unc_paths" = true;
  # [HIDDEN PREF]
  /* 0710: disable GIO as a potential proxy bypass vector
   * Gvfs/GIO has a set of supported protocols like obex, network, archive, computer, dav, cdda,
   * gphoto2, trash, etc. By default only smb and sftp protocols are accepted so far (as of FF64)
   * [1] https://bugzilla.mozilla.org/1433507
   * [2] https://trac.torproject.org/23044
   * [3] https://en.wikipedia.org/wiki/GVfs
   * [4] https://en.wikipedia.org/wiki/GIO_(software) ***/
  "network.gio.supported-protocols" = "";
  # [HIDDEN PREF]

  /*** [SECTION 0800]: LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS
       Change items 0850 and above to suit for privacy vs convenience and functionality. Consider
       your environment (no unwanted eyeballs), your device (restricted access), your device's
       unattended state (locked, encrypted, forensic hardened). Likewise, you may want to check
       the items cleared on shutdown in section 2800.
       [NOTE] The urlbar is also commonly referred to as the location bar and address bar
       #Required reading [#] https://xkcd.com/538/
  ***/

  /* 0801: disable location bar using search
   * Don't leak URL typos to a search engine, give an error message instead.
   * Examples: "secretplace,com", "secretplace/com", "secretplace com", "secret place.com"
   * [NOTE] Search buttons in the dropdown work, but hitting 'enter' in the location bar will fail
   * [TIP] You can add keywords to search engines in options (e.g. 'd' for DuckDuckGo) and
   * the dropdown will now auto-select it and you can then hit 'enter' and it will work
   * [SETUP-CHROME] If you don't, or rarely, type URLs, or you use a default search
   * engine that respects privacy, then you probably don't need this ***/
  #"keyword.enabled" = false;
  /* 0802: disable location bar domain guessing
   * domain guessing intercepts DNS "hostname not found errors" and resends a
   * request (e.g. by adding www or .com). This is inconsistent use (e.g. FQDNs), does not work
   * via Proxy Servers (different error), is a flawed use of DNS (TLDs: why treat .com
   * as the 411 for DNS errors?), privacy issues (why connect to sites you didn't
   * intend to), can leak sensitive data (e.g. query strings: e.g. Princeton attack),
   * and is a security risk (e.g. common typos & malicious sites set up to exploit this) ***/
  "browser.fixup.alternate.enabled" = false;
  /* 0803: display all parts of the url in the location bar ***/
  "browser.urlbar.trimURLs" = false;
  /* 0805: disable coloring of visited links - CSS history leak
   * [NOTE] This has NEVER been fully "resolved": in Mozilla/docs it is stated it's
   * only in 'certain circumstances', also see latest comments in [2]
   * [TEST] https://earthlng.github.io/testpages/visited_links.html (see github wiki APPENDIX A on how to use)
   * [1] https://dbaron.org/mozilla/visited-privacy
   * [2] https://bugzilla.mozilla.org/147777
   * [3] https://developer.mozilla.org/docs/Web/CSS/Privacy_and_the_:visited_selector ***/
  #"layout.css.visited_links_enabled" = false;
  /* 0807: disable live search suggestions
  /* [NOTE] Both must be true for the location bar to work
   * [SETUP-CHROME] Change these if you trust and use a privacy respecting search engine
   * [SETTING] Search>Provide search suggestions | Show search suggestions in address bar results ***/
  "browser.search.suggest.enabled" = false;
  "browser.urlbar.suggest.searches" = false;
  /* 0809: disable location bar suggesting "preloaded" top websites [FF54+]
   * [1] https://bugzilla.mozilla.org/1211726 ***/
  "browser.urlbar.usepreloadedtopurls.enabled" = false;
  /* 0810: disable location bar making speculative connections [FF56+]
   * [1] https://bugzilla.mozilla.org/1348275 ***/
  "browser.urlbar.speculativeConnect.enabled" = false;
  /* 0850a: disable location bar suggestion types
   * If all three suggestion types are false, search engine keywords are disabled
   * [SETTING] Privacy & Security>Address Bar>When using the address bar, suggest ***/
  # "browser.urlbar.suggest.history" = false;
  # "browser.urlbar.suggest.bookmark" = false;
  # "browser.urlbar.suggest.openpage" = false;
  /* 0850c: disable location bar dropdown
   * This value controls the total number of entries to appear in the location bar dropdown
   * [NOTE] Items (bookmarks/history/openpages) with a high "frecency"/"bonus" will always
   * be displayed (no we do not know how these are calculated or what the threshold is),
   * and this does not affect the search by search engine suggestion (see 0807)
   * [NOTE] This setting is only useful if you want to enable search engine keywords
   * (i.e. at least one of 0850a suggestion types must be true) but you want to *limit* suggestions shown ***/
  # "browser.urlbar.maxRichResults" = 0;
  /* 0850d: disable location bar autofill
   * [1] https://support.mozilla.org/en-US/kb/address-bar-autocomplete-firefox#w_url-autocomplete ***/
  # "browser.urlbar.autoFill" = false;
  /* 0850e: disable location bar one-off searches [FF51+]
   * [1] https://www.ghacks.net/2016/08/09/firefox-one-off-searches-address-bar/ ***/
  # "browser.urlbar.oneOffSearches" = false;
  /* 0860: disable search and form history
   * [SETUP-WEB] Be aware thet autocomplete form data can be read by third parties, see [1] [2]
   * [NOTE] We also clear formdata on exit (see 2803)
   * [SETTING] Privacy & Security>History>Custom Settings>Remember search and form history
   * [1] https://blog.mindedsecurity.com/2011/10/autocompleteagain.html
   * [2] https://bugzilla.mozilla.org/381681 ***/
  #"browser.formfill.enable" = false;
  /* 0862: disable browsing and download history
   * [NOTE] We also clear history and downloads on exiting Firefox (see 2803)
   * [SETTING] Privacy & Security>History>Custom Settings>Remember browsing and download history ***/
  # "places.history.enabled" = false;
  /* 0870: disable Windows jumplist [WINDOWS] ***/
  "browser.taskbar.lists.enabled" = false;
  "browser.taskbar.lists.frequent.enabled" = false;
  "browser.taskbar.lists.recent.enabled" = false;
  "browser.taskbar.lists.tasks.enabled" = false;
  /* 0871: disable Windows taskbar preview [WINDOWS] ***/
  "browser.taskbar.previews.enable" = false;

  /*** [SECTION 0900]: PASSWORDS ***/

  /* 0901: disable saving passwords
   * [NOTE] This does not clear any passwords already saved
   * [SETTING] Privacy & Security>Logins and Passwords>Ask to save logins and passwords for websites ***/
  # "signon.rememberSignons" = false;
  /* 0902: use a master password
   * There are no preferences for this. It is all handled internally.
   * [SETTING] Privacy & Security>Logins and Passwords>Use a master password
   * [1] https://support.mozilla.org/kb/use-master-password-protect-stored-logins ***/
  /* 0903: set how often Firefox should ask for the master password
   * 0=the first time (default), 1=every time it's needed, 2=every n minutes (see 0904) ***/
  "security.ask_for_password" = 2;
  /* 0904: set how often in minutes Firefox should ask for the master password (see 0903)
   * in minutes, default is 30 ***/
  "security.password_lifetime" = 5;
  /* 0905: disable auto-filling username & password form fields
   * can leak in cross-site forms *and* be spoofed
   * [NOTE] Username & password is still available when you enter the field
   * [SETTING] Privacy & Security>Logins and Passwords>Autofill logins and passwords ***/
  #"signon.autofillForms" = false;
  /* 0909: disable formless login capture for Password Manager [FF51+] ***/
  #"signon.formlessCapture.enabled" = false;
  /* 0912: limit (or disable) HTTP authentication credentials dialogs triggered by sub-resources [FF41+]
   * hardens against potential credentials phishing
   * 0=don't allow sub-resources to open HTTP authentication credentials dialogs
   * 1=don't allow cross-origin sub-resources to open HTTP authentication credentials dialogs
   * 2=allow sub-resources to open HTTP authentication credentials dialogs (default)
   * [1] https://www.fxsitecompat.com/en-CA/docs/2015/http-auth-dialog-can-no-longer-be-triggered-by-cross-origin-resources/ ***/
  "network.auth.subresource-http-auth-allow" = 1;

  /*** [SECTION 1000]: CACHE / SESSION (RE)STORE / FAVICONS
       Cache tracking/fingerprinting techniques [1][2][3] require a cache. Disabling disk (1001)
       *and* memory (1003) caches is one solution; but that's extreme and fingerprintable. A hardened
       Temporary Containers configuration can effectively do the same thing, by isolating every tab [4].

       We consider avoiding disk cache (1001) so cache is session/memory only (like Private Browsing
       mode), and isolating cache to first party (4001) is sufficient and a good balance between
       risk and performance. ETAGs can also be neutralized by modifying response headers [5], and
       you can clear the cache manually or on a regular basis with an extension.

       [1] https://en.wikipedia.org/wiki/HTTP_ETag#Tracking_using_ETags
       [2] https://robertheaton.com/2014/01/20/cookieless-user-tracking-for-douchebags/
       [3] https://www.grepular.com/Preventing_Web_Tracking_via_the_Browser_Cache
       [4] https://medium.com/@stoically/enhance-your-privacy-in-firefox-with-temporary-containers-33925cd6cd21
       [5] https://github.com/ghacksuserjs/ghacks-user.js/wiki/4.2.4-Header-Editor
  ***/

  /** CACHE ***/
  /* 1001: disable disk cache
   * [SETUP-PERF] If you think disk cache may help (heavy tab user, high-res video),
   * or you use a hardened Temporary Containers, then feel free to override this
   * [NOTE] We also clear cache on exiting Firefox (see 2803) ***/
  #"browser.cache.disk.enable" = false;
  /* 1003: disable memory cache
  /* capacity: -1=determine dynamically (default), 0=none, n=memory capacity in kilobytes ***/
  # "browser.cache.memory.enable" = false;
  # "browser.cache.memory.capacity" = 0;
  # [HIDDEN PREF ESR]
  /* 1006: disable permissions manager from writing to disk [RESTART]
   * [NOTE] This means any permission changes are session only
   * [1] https://bugzilla.mozilla.org/967812 ***/
  # "permissions.memory_only" = true;
  # [HIDDEN PREF]

  /** SESSIONS & SESSION RESTORE ***/
  /* 1020: exclude "Undo Closed Tabs" in Session Restore ***/
  # "browser.sessionstore.max_tabs_undo" = 0;
  /* 1021: disable storing extra session data [SETUP-CHROME]
   * extra session data contains contents of forms, scrollbar positions, cookies and POST data
   * define on which sites to save extra session data:
   * 0=everywhere, 1=unencrypted sites, 2=nowhere ***/
  #"browser.sessionstore.privacy_level" = 2;
  /* 1022: disable resuming session from crash ***/
  # "browser.sessionstore.resume_from_crash" = false;
  /* 1023: set the minimum interval between session save operations
   * Increasing this can help on older machines and some websites, as well as reducing writes, see [1]
   * Default is 15000 (15 secs). Try 30000 (30 secs), 60000 (1 min) etc
   * [SETUP-CHROME] This can also affect entries in the "Recently Closed Tabs" feature:
   * i.e. the longer the interval the more chance a quick tab open/close won't be captured.
   * This longer interval *may* affect history but we cannot replicate any history not recorded
   * [1] https://bugzilla.mozilla.org/1304389 ***/
  #"browser.sessionstore.interval" = 30000;
  /* 1024: disable automatic Firefox start and session restore after reboot [FF62+] [WINDOWS]
   * [1] https://bugzilla.mozilla.org/603903 ***/
  "toolkit.winRegisterApplicationRestart" = false;

  /** FAVICONS ***/
  /* 1030: disable favicons in shortcuts
   * URL shortcuts use a cached randomly named .ico file which is stored in your
   * profile/shortcutCache directory. The .ico remains after the shortcut is deleted.
   * If set to false then the shortcuts use a generic Firefox icon ***/
  #"browser.shell.shortcutFavicons" = false;
  /* 1031: disable favicons in history and bookmarks
   * Stored as data blobs in favicons.sqlite, these don't reveal anything that your
   * actual history (and bookmarks) already do. Your history is more detailed, so
   * control that instead; e.g. disable history, clear history on close, use PB mode
   * [NOTE] favicons.sqlite is sanitized on Firefox close, not in-session ***/
  # "browser.chrome.site_icons" = false;
  /* 1032: disable favicons in web notifications ***/
  # "alerts.showFavicons" = false;
  # [DEFAULT: false]

  /*** [SECTION 1200]: HTTPS (SSL/TLS / OCSP / CERTS / HPKP / CIPHERS)
     Your cipher and other settings can be used in server side fingerprinting
     [TEST] https://www.ssllabs.com/ssltest/viewMyClient.html
     [1] https://www.securityartwork.es/2017/02/02/tls-client-fingerprinting-with-bro/
  ***/

  /** SSL (Secure Sockets Layer) / TLS (Transport Layer Security) ***/
  /* 1201: require safe negotiation
   * Blocks connections to servers that don't support RFC 5746 [2] as they're potentially
   * vulnerable to a MiTM attack [3]. A server *without* RFC 5746 can be safe from the attack
   * if it disables renegotiations but the problem is that the browser can't know that.
   * Setting this pref to true is the only way for the browser to ensure there will be
   * no unsafe renegotiations on the channel between the browser and the server.
   * [1] https://wiki.mozilla.org/Security:Renegotiation
   * [2] https://tools.ietf.org/html/rfc5746
   * [3] https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-3555 ***/
  "security.ssl.require_safe_negotiation" = true;
  /* 1202: control TLS versions with min and max
   * 1=TLS 1.0, 2=TLS 1.1, 3=TLS 1.2, 4=TLS 1.3
   * [WARNING] Leave these at default, otherwise you alter your TLS fingerprint.
   * Firefox telemetry (April 2019) shows only 0.5% of TLS web traffic uses 1.0 or 1.1
   * [1] https://www.ssllabs.com/ssl-pulse/ ***/
  # "security.tls.version.min" = 3;
  # "security.tls.version.max" = 4;
  /* 1203: disable SSL session tracking [FF36+]
   * SSL Session IDs are unique, last up to 24hrs in Firefox, and can be used for tracking
   * [SETUP-PERF] Relax this if you have FPI enabled (see 4000) *AND* you understand the
   * consequences. FPI isolates these, but it was designed with the Tor protocol in mind,
   * and the Tor Browser has extra protection, including enhanced sanitizing per Identity.
   * [1] https://tools.ietf.org/html/rfc5077
   * [2] https://bugzilla.mozilla.org/967977
   * [3] https://arxiv.org/abs/1810.07304 ***/
  #"security.ssl.disable_session_identifiers" = true;
  # [HIDDEN PREF]
  /* 1204: disable SSL Error Reporting
   * [1] https://firefox-source-docs.mozilla.org/browser/base/sslerrorreport/preferences.html ***/
  "security.ssl.errorReporting.automatic" = false;
  "security.ssl.errorReporting.enabled" = false;
  "security.ssl.errorReporting.url" = "";
  /* 1205: disable TLS1.3 0-RTT (round-trip time) [FF51+]
   * [1] https://github.com/tlswg/tls13-spec/issues/1001
   * [2] https://blog.cloudflare.com/tls-1-3-overview-and-q-and-a/ ***/
  "security.tls.enable_0rtt_data" = false;

  /** OCSP (Online Certificate Status Protocol)
      #Required reading [#] https://scotthelme.co.uk/revocation-is-broken/ ***/
  /* 1210: enable OCSP Stapling
   * [1] https://blog.mozilla.org/security/2013/07/29/ocsp-stapling-in-firefox/ ***/
  #"security.ssl.enable_ocsp_stapling" = true;
  /* 1211: control when to use OCSP fetching (to confirm current validity of certificates)
   * 0=disabled, 1=enabled (default), 2=enabled for EV certificates only
   * OCSP (non-stapled) leaks information about the sites you visit to the CA (cert authority)
   * It's a trade-off between security (checking) and privacy (leaking info to the CA)
   * [NOTE] This pref only controls OCSP fetching and does not affect OCSP stapling
   * [1] https://en.wikipedia.org/wiki/Ocsp ***/
  #"security.OCSP.enabled" = 1;
  /* 1212: set OCSP fetch failures (non-stapled, see 1211) to hard-fail [SETUP-WEB]
   * When a CA cannot be reached to validate a cert, Firefox just continues the connection (=soft-fail)
   * Setting this pref to true tells Firefox to instead terminate the connection (=hard-fail)
   * It is pointless to soft-fail when an OCSP fetch fails: you cannot confirm a cert is still valid (it
   * could have been revoked) and/or you could be under attack (e.g. malicious blocking of OCSP servers)
   * [1] https://blog.mozilla.org/security/2013/07/29/ocsp-stapling-in-firefox/
   * [2] https://www.imperialviolet.org/2014/04/19/revchecking.html ***/
  #"security.OCSP.require" = true;

  /** CERTS / HPKP (HTTP Public Key Pinning) ***/
  /* 1220: disable or limit SHA-1 certificates
   * 0=all SHA1 certs are allowed
   * 1=all SHA1 certs are blocked
   * 2=deprecated option that now maps to 1
   * 3=only allowed for locally-added roots (e.g. anti-virus)
   * 4=only allowed for locally-added roots or for certs in 2015 and earlier
   * [SETUP-CHROME] When disabled, some man-in-the-middle devices (e.g. security scanners and
   * antivirus products, may fail to connect to HTTPS sites. SHA-1 is *almost* obsolete.
   * [1] https://blog.mozilla.org/security/2016/10/18/phasing-out-sha-1-on-the-public-web/ ***/
  "security.pki.sha1_enforcement_level" = 1;
  /* 1221: disable Windows 8.1's Microsoft Family Safety cert [FF50+] [WINDOWS]
   * 0=disable detecting Family Safety mode and importing the root
   * 1=only attempt to detect Family Safety mode (don't import the root)
   * 2=detect Family Safety mode and import the root
   * [1] https://trac.torproject.org/projects/tor/ticket/21686 ***/
  "security.family_safety.mode" = 0;
  /* 1222: disable intermediate certificate caching (fingerprinting attack vector) [FF41+] [RESTART]
   * [NOTE] This affects login/cert/key dbs. The effect is all credentials are session-only.
   * Saved logins and passwords are not available. Reset the pref and restart to return them.
   * [1] https://shiftordie.de/blog/2017/02/21/fingerprinting-firefox-users-with-cached-intermediate-ca-certificates-fiprinca/ ***/
  # "security.nocertdb" = true; // [HIDDEN PREF]
  /* 1223: enforce strict pinning
   * PKP (Public Key Pinning) 0=disabled 1=allow user MiTM (such as your antivirus), 2=strict
   * [SETUP-WEB] If you rely on an AV (antivirus) to protect your web browsing
   * by inspecting ALL your web traffic, then leave at current default=1
   * [1] https://trac.torproject.org/projects/tor/ticket/16206 ***/
  "security.cert_pinning.enforcement_level" = 2;

  /** MIXED CONTENT ***/
  /* 1240: disable insecure active content on https pages
   * [1] https://trac.torproject.org/projects/tor/ticket/21323 ***/
  #"security.mixed_content.block_active_content" = true;
  # [DEFAULT: true]
  /* 1241: disable insecure passive content (such as images) on https pages [SETUP-WEB] ***/
  #"security.mixed_content.block_display_content" = true;
  /* 1243: block unencrypted requests from Flash on encrypted pages to mitigate MitM attacks [FF59+]
   * [1] https://bugzilla.mozilla.org/1190623 ***/
  #"security.mixed_content.block_object_subrequest" = true;

  /** CIPHERS [WARNING: do not meddle with your cipher suite: see the section 1200 intro] ***/
  /* 1261: disable 3DES (effective key size < 128)
   * [1] https://en.wikipedia.org/wiki/3des#Security
   * [2] https://en.wikipedia.org/wiki/Meet-in-the-middle_attack
   * [3] https://www-archive.mozilla.org/projects/security/pki/nss/ssl/fips-ssl-ciphersuites.html ***/
  # "security.ssl3.rsa_des_ede3_sha" = false;
  /* 1262: disable 128 bits ***/
  # "security.ssl3.ecdhe_ecdsa_aes_128_sha" = false;
  # "security.ssl3.ecdhe_rsa_aes_128_sha" = false;
  /* 1263: disable DHE (Diffie-Hellman Key Exchange)
   * [1] https://www.eff.org/deeplinks/2015/10/how-to-protect-yourself-from-nsa-attacks-1024-bit-DH ***/
  # "security.ssl3.dhe_rsa_aes_128_sha" = false;
  # "security.ssl3.dhe_rsa_aes_256_sha" = false;
  /* 1264: disable the remaining non-modern cipher suites as of FF52 ***/
  # "security.ssl3.rsa_aes_128_sha" = false;
  # "security.ssl3.rsa_aes_256_sha" = false;

  /** UI (User Interface) ***/
  /* 1270: display warning on the padlock for "broken security" (if 1201 is false)
   * Bug: warning padlock not indicated for subresources on a secure page! [2]
   * [1] https://wiki.mozilla.org/Security:Renegotiation
   * [2] https://bugzilla.mozilla.org/1353705 ***/
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  /* 1271: control "Add Security Exception" dialog on SSL warnings
   * 0=do neither 1=pre-populate url 2=pre-populate url + pre-fetch cert (default)
   * [1] https://github.com/pyllyukko/user.js/issues/210 ***/
  "browser.ssl_override_behavior" = 1;
  /* 1272: display advanced information on Insecure Connection warning pages
   * only works when it's possible to add an exception
   * i.e. it doesn't work for HSTS discrepancies (https://subdomain.preloaded-hsts.badssl.com/)
   * [TEST] https://expired.badssl.com/ ***/
  "browser.xul.error_pages.expert_bad_cert" = true;
  /* 1273: display "insecure" icon and "Not Secure" text on HTTP sites ***/
  "security.insecure_connection_icon.enabled" = true;
  # [FF59+] [DEFAULT: true FF70+]
  "security.insecure_connection_text.enabled" = true;
  # [FF60+]

  /*** [SECTION 1400]: FONTS ***/

  /* 1401: disable websites choosing fonts (0=block, 1=allow)
   * This can limit most (but not all) JS font enumeration which is a high entropy fingerprinting vector
   * [SETUP-WEB] Disabling fonts can uglify the web a fair bit.
   * [SETTING] General>Language and Appearance>Fonts & Colors>Advanced>Allow pages to choose... ***/
  #"browser.display.use_document_fonts" = 0;
  /* 1403: disable icon fonts (glyphs) and local fallback rendering
   * [1] https://bugzilla.mozilla.org/789788
   * [2] https://trac.torproject.org/projects/tor/ticket/8455 ***/
  # "gfx.downloadable_fonts.enabled" = false; // [FF41+]
  # "gfx.downloadable_fonts.fallback_delay" = -1;
  /* 1404: disable rendering of SVG OpenType fonts
   * [1] https://wiki.mozilla.org/SVGOpenTypeFonts - iSECPartnersReport recommends to disable this ***/
  #"gfx.font_rendering.opentype_svg.enabled" = false;
  /* 1408: disable graphite
   * Graphite has had many critical security issues in the past, see [1]
   * [1] https://www.mozilla.org/security/advisories/mfsa2017-15/#CVE-2017-7778
   * [2] https://en.wikipedia.org/wiki/Graphite_(SIL) ***/
  #"gfx.font_rendering.graphite.enabled" = false;
  /* 1409: limit system font exposure to a whitelist [FF52+] [RESTART]
   * If the whitelist is empty, then whitelisting is considered disabled and all fonts are allowed.
   * [WARNING] Creating your own probably highly-unique whitelist will raise your entropy.
   * Eventually privacy.resistFingerprinting (see 4500) will cover this
   * [1] https://bugzilla.mozilla.org/1121643 ***/
  # "font.system.whitelist" = ""; // [HIDDEN PREF]

  /*** [SECTION 1600]: HEADERS / REFERERS
       Only *cross domain* referers need controlling: leave 1601, 1602, 1605 and 1606 alone
       ---
              harden it a bit: set XOriginPolicy (1603) to 1 (as per the settings below)
         harden it a bit more: set XOriginPolicy (1603) to 2 (and optionally 1604 to 1 or 2), expect breakage
       ---
       If you want any REAL control over referers and breakage, then use an extension. Either:
                uMatrix: limited by scope, all requests are spoofed or not-spoofed
         Smart Referrer: granular with source<->destination, whitelists
       ---
                      full URI: https://example.com:8888/foo/bar.html?id=1234
         scheme+host+port+path: https://example.com:8888/foo/bar.html
              scheme+host+port: https://example.com:8888
       ---
       #Required reading [#] https://feeding.cloud.geek.nz/posts/tweaking-referrer-for-privacy-in-firefox/
  ***/

  /* 1601: ALL: control when images/links send a referer
   * 0=never, 1=send only when links are clicked, 2=for links and images (default) ***/
  # "network.http.sendRefererHeader" = 2; // [DEFAULT: 2]
  /* 1602: ALL: control the amount of information to send
   * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
  # "network.http.referer.trimmingPolicy" = 0;
  # [DEFAULT: 0]
  /* 1603: CROSS ORIGIN: control when to send a referer
   * 0=always (default), 1=only if base domains match, 2=only if hosts match
   * [SETUP-WEB] Known to cause issues with older modems/routers and some sites e.g vimeo, icloud ***/
  "network.http.referer.XOriginPolicy" = 1;
  /* 1604: CROSS ORIGIN: control the amount of information to send [FF52+]
   * 0=send full URI (default), 1=scheme+host+port+path, 2=scheme+host+port ***/
  "network.http.referer.XOriginTrimmingPolicy" = 0;
  # [DEFAULT: 0]
  /* 1605: ALL: disable spoofing a referer
   * [WARNING] Do not set this to true, as spoofing effectively disables the anti-CSRF
   * (Cross-Site Request Forgery) protections that some sites may rely on ***/
  # "network.http.referer.spoofSource" = false;
  # [DEFAULT: false]
  /* 1606: ALL: set the default Referrer Policy [FF59+]
   * 0=no-referer, 1=same-origin, 2=strict-origin-when-cross-origin, 3=no-referrer-when-downgrade
   * [NOTE] This is only a default, it can be overridden by a site-controlled Referrer Policy
   * [1] https://www.w3.org/TR/referrer-policy/
   * [2] https://developer.mozilla.org/docs/Web/HTTP/Headers/Referrer-Policy
   * [3] https://blog.mozilla.org/security/2018/01/31/preventing-data-leaks-by-stripping-path-information-in-http-referrers/ ***/
  # "network.http.referer.defaultPolicy" = 3;
  # [DEFAULT: 3]
  # "network.http.referer.defaultPolicy.pbmode" = 2;
  # [DEFAULT: 2]
  /* 1607: TOR: hide (not spoof) referrer when leaving a .onion domain [FF54+]
   * [NOTE] Firefox cannot access .onion sites by default. We recommend you use
   * the Tor Browser which is specifically designed for hidden services
   * [1] https://bugzilla.mozilla.org/1305144 ***/
  "network.http.referer.hideOnionSource" = true;
  /* 1610: ALL: enable the DNT (Do Not Track) HTTP header
   * [NOTE] DNT is enforced with Enhanced Tracking Protection regardless of this pref
   * [SETTING] Privacy & Security>Enhanced Tracking Protection>Send websites a "Do Not Track" signal... ***/
  "privacy.donottrackheader.enabled" = true;

  /*** [SECTION 1700]: CONTAINERS
       If you want to *really* leverage containers, we highly recommend Temporary Containers [2].
       Read the article by the extension author [3], and check out the github wiki/repo [4].
       [1] https://wiki.mozilla.org/Security/Contextual_Identity_Project/Containers
       [2] https://addons.mozilla.org/firefox/addon/temporary-containers/
       [3] https://medium.com/@stoically/enhance-your-privacy-in-firefox-with-temporary-containers-33925cd6cd21
       [4] https://github.com/stoically/temporary-containers/wiki
  ***/

  /* 1701: enable Container Tabs setting in preferences (see 1702) [FF50+]
   * [1] https://bugzilla.mozilla.org/1279029 ***/
  "privacy.userContext.ui.enabled" = true;
  /* 1702: enable Container Tabs [FF50+]
   * [SETTING] General>Tabs>Enable Container Tabs ***/
  "privacy.userContext.enabled" = true;
  /* 1704: set behaviour on "+ Tab" button to display container menu [FF53+] [SETUP-CHROME]
   * 0=no menu (default), 1=show when clicked, 2=show on long press
   * [1] https://bugzilla.mozilla.org/1328756 ***/
  "privacy.userContext.longPressBehavior" = 2;

  /*** [SECTION 1800]: PLUGINS ***/

  /* 1803: disable Flash plugin
   * 0=deactivated, 1=ask, 2=enabled
   * ESR52.x is the last branch to *fully* support NPAPI, FF52+ stable only supports Flash
   * [NOTE] You can still override individual sites via site permissions
   * [1] https://www.ghacks.net/2013/07/09/how-to-make-sure-that-a-firefox-plugin-never-activates-again/ ***/
  "plugin.state.flash" = 0;
  /* 1820: disable GMP (Gecko Media Plugins)
   * [1] https://wiki.mozilla.org/GeckoMediaPlugins ***/
  # "media.gmp-provider.enabled" = false;
  /* 1825: disable widevine CDM (Content Decryption Module)
   * [SETUP-WEB] if you *need* CDM, e.g. Netflix, Amazon Prime, Hulu, whatever ***/
  "media.gmp-widevinecdm.visible" = false;
  "media.gmp-widevinecdm.enabled" = false;
  /* 1830: disable all DRM content (EME: Encryption Media Extension)
   * [SETUP-WEB] if you *need* EME, e.g. Netflix, Amazon Prime, Hulu, whatever
   * [SETTING] General>DRM Content>Play DRM-controlled content
   * [1] https://www.eff.org/deeplinks/2017/10/drms-dead-canary-how-we-just-lost-web-what-we-learned-it-and-what-we-need-do-next ***/
  "media.eme.enabled" = false;

  /*** [SECTION 2000]: MEDIA / CAMERA / MIC ***/

  /* 2001: disable WebRTC (Web Real-Time Communication)
   * [SETUP-WEB] WebRTC can leak your IP address from behind your VPN, but if this is not
   * in your threat model, and you want Real-Time Communication, this is the pref for you
   * [1] https://www.privacytools.io/#webrtc ***/
  "media.peerconnection.enabled" = false;
  /* 2002: limit WebRTC IP leaks if using WebRTC
   * In FF70+ these settings match Mode 4 (Mode 3 in older versions) (see [3])
   * [TEST] https://browserleaks.com/webrtc
   * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1189041,1297416,1452713
   * [2] https://wiki.mozilla.org/Media/WebRTC/Privacy
   * [3] https://tools.ietf.org/html/draft-ietf-rtcweb-ip-handling-12#section-5.2 ***/
  "media.peerconnection.ice.default_address_only" = true;
  "media.peerconnection.ice.no_host" = true;
  # [FF51+]
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
  # [FF70+]
  /* 2010: disable WebGL (Web Graphics Library)
   * [SETUP-WEB] When disabled, may break some websites. When enabled, provides high entropy,
   * especially with readPixels(). Some of the other entropy is lessened with RFP (see 4501)
   * [1] https://www.contextis.com/resources/blog/webgl-new-dimension-browser-exploitation/
   * [2] https://security.stackexchange.com/questions/13799/is-webgl-a-security-concern ***/
  #"webgl.disabled" = true;
  #"webgl.enable-webgl2" = false;
  /* 2012: limit WebGL ***/
  #"webgl.min_capability_mode" = true;
  #"webgl.disable-extensions" = true;
  #"webgl.disable-fail-if-major-performance-caveat" = true;
  /* 2022: disable screensharing ***/
  "media.getusermedia.screensharing.enabled" = false;
  "media.getusermedia.browser.enabled" = false;
  "media.getusermedia.audiocapture.enabled" = false;
  /* 2024: set a default permission for Camera/Microphone [FF58+]
   * 0=always ask (default), 1=allow, 2=block
   * [SETTING] to add site exceptions: Page Info>Permissions>Use the Camera/Microphone
   * [SETTING] to manage site exceptions: Options>Privacy & Security>Permissions>Camera/Microphone>Settings ***/
  # "permissions.default.camera" = 2;
  # "permissions.default.microphone" = 2;
  /* 2030: disable autoplay of HTML5 media [FF63+]
   * 0=Allow all, 1=Block non-muted media (default in FF67+), 2=Prompt (removed in FF66), 5=Block all (FF69+)
   * [NOTE] You can set exceptions under site permissions
   * [SETTING] Privacy & Security>Permissions>Autoplay>Settings>Default for all websites ***/
  # "media.autoplay.default" = 5;
  /* 2031: disable autoplay of HTML5 media if you interacted with the site [FF66+] ***/
  "media.autoplay.enabled.user-gestures-needed" = false;

  /*** [SECTION 2200]: WINDOW MEDDLING & LEAKS / POPUPS ***/

  /* 2201: prevent websites from disabling new window features ***/
  "dom.disable_window_open_feature.close" = true;
  "dom.disable_window_open_feature.location" = true;
  # [DEFAULT: true]
  "dom.disable_window_open_feature.menubar" = true;
  "dom.disable_window_open_feature.minimizable" = true;
  "dom.disable_window_open_feature.personalbar" = true;
  # bookmarks toolbar
  "dom.disable_window_open_feature.resizable" = true;
  # [DEFAULT: true]
  "dom.disable_window_open_feature.status" = true;
  # [DEFAULT: true]
  "dom.disable_window_open_feature.titlebar" = true;
  "dom.disable_window_open_feature.toolbar" = true;
  /* 2202: prevent scripts from moving and resizing open windows ***/
  "dom.disable_window_move_resize" = true;
  /* 2203: open links targeting new windows in a new tab instead
   * This stops malicious window sizes and some screen resolution leaks.
   * You can still right-click a link and open in a new window.
   * [TEST] https://ghacksuserjs.github.io/TorZillaPrint/TorZillaPrint.html#screen
   * [1] https://trac.torproject.org/projects/tor/ticket/9881 ***/
  "browser.link.open_newwindow" = 3;
  "browser.link.open_newwindow.restriction" = 0;
  /* 2204: disable Fullscreen API (requires user interaction) to prevent screen-resolution leaks
   * [NOTE] You can still manually toggle the browser's fullscreen state (F11),
   * but this pref will disable embedded video/game fullscreen controls, e.g. youtube
   * [TEST] https://ghacksuserjs.github.io/TorZillaPrint/TorZillaPrint.html#screen ***/
  # "full-screen-api.enabled" = false;
  /* 2210: block popup windows
   * [SETTING] Privacy & Security>Permissions>Block pop-up windows ***/
  "dom.disable_open_during_load" = true;
  /* 2212: limit events that can cause a popup [SETUP-WEB]
   * default is "change click dblclick auxclick mouseup pointerup notificationclick reset submit touchend contextmenu" ***/
  "dom.popup_allowed_events" = "click dblclick";

  /*** [SECTION 2300]: WEB WORKERS
       A worker is a JS "background task" running in a global context, i.e. it is different from
       the current window. Workers can spawn new workers (must be the same origin & scheme),
       including service and shared workers. Shared workers can be utilized by multiple scripts and
       communicate between browsing contexts (windows/tabs/iframes) and can even control your cache.

       [NOTE] uMatrix 1.2.0+ allows a per-scope control for workers (2301-deprecated) and service workers (2302)
                #Required reading [#] https://github.com/gorhill/uMatrix/releases/tag/1.2.0

       [1]    Web Workers: https://developer.mozilla.org/docs/Web/API/Web_Workers_API
       [2]         Worker: https://developer.mozilla.org/docs/Web/API/Worker
       [3] Service Worker: https://developer.mozilla.org/docs/Web/API/Service_Worker_API
       [4]   SharedWorker: https://developer.mozilla.org/docs/Web/API/SharedWorker
       [5]   ChromeWorker: https://developer.mozilla.org/docs/Web/API/ChromeWorker
       [6]  Notifications: https://support.mozilla.org/questions/1165867#answer-981820
  ***/

  /* 2302: disable service workers [FF32, FF44-compat]
   * Service workers essentially act as proxy servers that sit between web apps, and the
   * browser and network, are event driven, and can control the web page/site it is associated
   * with, intercepting and modifying navigation and resource requests, and caching resources.
   * [NOTE] Service worker APIs are hidden (in Firefox) and cannot be used when in PB mode.
   * [NOTE] Service workers only run over HTTPS. Service workers have no DOM access.
   * [SETUP-WEB] Disabling service workers will break some sites. This pref is required true for
   * service worker notifications (2304), push notifications (disabled, 2305) and service worker
   * cache (2740). If you enable this pref, then check those settings as well ***/
  #"dom.serviceWorkers.enabled" = false;
  /* 2304: disable Web Notifications
   * [NOTE] Web Notifications can also use service workers (2302) and are behind a prompt (2306)
   * [1] https://developer.mozilla.org/docs/Web/API/Notifications_API ***/
  # "dom.webnotifications.enabled" = false; // [FF22+]
  # "dom.webnotifications.serviceworker.enabled" = false;
  # [FF44+]
  /* 2305: disable Push Notifications [FF44+]
   * Push is an API that allows websites to send you (subscribed) messages even when the site
   * isn't loaded, by pushing messages to your userAgentID through Mozilla's Push Server.
   * [NOTE] Push requires service workers (2302) to subscribe to and display, and is behind
   * a prompt (2306). Disabling service workers alone doesn't stop Firefox polling the
   * Mozilla Push Server. To remove all subscriptions, reset your userAgentID (in about:config
   * or on start), and you will get a new one within a few seconds.
   * [1] https://support.mozilla.org/en-US/kb/push-notifications-firefox
   * [2] https://developer.mozilla.org/en-US/docs/Web/API/Push_API ***/
  #"dom.push.enabled" = false;
  # "dom.push.userAgentID" = "";
  /* 2306: set a default permission for Notifications (both 2304 and 2305) [FF58+]
   * 0=always ask (default), 1=allow, 2=block
   * [NOTE] Best left at default "always ask", fingerprintable via Permissions API
   * [SETTING] to add site exceptions: Page Info>Permissions>Receive Notifications
   * [SETTING] to manage site exceptions: Options>Privacy & Security>Permissions>Notifications>Settings ***/
  # "permissions.default.desktop-notification" = 2;

  /*** [SECTION 2400]: DOM (DOCUMENT OBJECT MODEL) & JAVASCRIPT ***/

  /* 2401: disable website control over browser right-click context menu
   * [NOTE] Shift-Right-Click will always bring up the browser right-click context menu ***/
  # "dom.event.contextmenu.enabled" = false;
  /* 2402: disable website access to clipboard events/content
   * [SETUP-WEB] This will break some sites functionality such as pasting into facebook, wordpress
   * This applies to onCut/onCopy/onPaste events - i.e. it requires interaction with the website
   * [WARNING] If both 'middlemouse.paste' and 'general.autoScroll' are true (at least one
   * is default false) then enabling this pref can leak clipboard content, see [2]
   * [1] https://www.ghacks.net/2014/01/08/block-websites-reading-modifying-clipboard-contents-firefox/
   * [2] https://bugzilla.mozilla.org/1528289 */
  #"dom.event.clipboardevents.enabled" = false;
  /* 2404: disable clipboard commands (cut/copy) from "non-privileged" content [FF41+]
   * this disables document.execCommand("cut"/"copy") to protect your clipboard
   * [1] https://bugzilla.mozilla.org/1170911 ***/
  #"dom.allow_cut_copy" = false;
  /* 2405: disable "Confirm you want to leave" dialog on page close
   * Does not prevent JS leaks of the page close event.
   * [1] https://developer.mozilla.org/docs/Web/Events/beforeunload
   * [2] https://support.mozilla.org/questions/1043508 ***/
  #"dom.disable_beforeunload" = true;
  /* 2414: disable shaking the screen ***/
  #"dom.vibrator.enabled" = false;
  /* 2420: disable asm.js [FF22+] [SETUP-PERF]
   * [1] http://asmjs.org/
   * [2] https://www.mozilla.org/security/advisories/mfsa2015-29/
   * [3] https://www.mozilla.org/security/advisories/mfsa2015-50/
   * [4] https://www.mozilla.org/security/advisories/mfsa2017-01/#CVE-2017-5375
   * [5] https://www.mozilla.org/security/advisories/mfsa2017-05/#CVE-2017-5400
   * [6] https://rh0dev.github.io/blog/2017/the-return-of-the-jit/ ***/
  #"javascript.options.asmjs" = false;
  /* 2421: disable Ion and baseline JIT to help harden JS against exploits
   * [WARNING] If false, causes the odd site issue and there is also a performance loss
   * [1] https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-0817 ***/
  # "javascript.options.ion" = false;
  # "javascript.options.baselinejit" = false;
  /* 2422: disable WebAssembly [FF52+] [SETUP-PERF]
   * [NOTE] In FF71+ this no longer affects extensions (1576254)
   * [1] https://developer.mozilla.org/docs/WebAssembly ***/
  #"javascript.options.wasm" = false;
  /* 2426: disable Intersection Observer API [FF55+]
   * [1] https://developer.mozilla.org/docs/Web/API/Intersection_Observer_API
   * [2] https://w3c.github.io/IntersectionObserver/
   * [3] https://bugzilla.mozilla.org/1243846 ***/
  # "dom.IntersectionObserver.enabled" = false;
  /* 2429: enable (limited but sufficient) window.opener protection [FF65+]
   * Makes rel=noopener implicit for target=_blank in anchor and area elements when no rel attribute is set ***/
  "dom.targetBlankNoOpener.enabled" = true;

  /*** [SECTION 2500]: HARDWARE FINGERPRINTING ***/

  /* 2502: disable Battery Status API
   * Initially a Linux issue (high precision readout) that was fixed.
   * However, it is still another metric for fingerprinting, used to raise entropy.
   * e.g. do you have a battery or not, current charging status, charge level, times remaining etc
   * [NOTE] From FF52+ Battery Status API is only available in chrome/privileged code. see [1]
   * [1] https://bugzilla.mozilla.org/1313580 ***/
  "dom.battery.enabled" = false;
  /* 2505: disable media device enumeration [FF29+]
   * [NOTE] media.peerconnection.enabled should also be set to false (see 2001)
   * [1] https://wiki.mozilla.org/Media/getUserMedia
   * [2] https://developer.mozilla.org/docs/Web/API/MediaDevices/enumerateDevices ***/
  "media.navigator.enabled" = false;
  /* 2508: disable hardware acceleration to reduce graphics fingerprinting [SETUP-HARDEN]
   * [WARNING] Affects text rendering (fonts will look different), impacts video performance,
   * and parts of Quantum that utilize the GPU will also be affected as they are rolled out
   * [SETTING] General>Performance>Custom>Use hardware acceleration when available
   * [1] https://wiki.mozilla.org/Platform/GFX/HardwareAcceleration ***/
  # "gfx.direct2d.disabled" = true; // [WINDOWS]
  # "layers.acceleration.disabled" = true;
  /* 2510: disable Web Audio API [FF51+]
   * [1] https://bugzilla.mozilla.org/1288359 ***/
  "dom.webaudio.enabled" = false;
  /* 2517: disable Media Capabilities API [FF63+]
   * [WARNING] This *may* affect media performance if disabled, no one is sure
   * [1] https://github.com/WICG/media-capabilities
   * [2] https://wicg.github.io/media-capabilities/#security-privacy-considerations ***/
  # "media.media-capabilities.enabled" = false;
  /* 2520: disable virtual reality devices
   * Optional protection depending on your connected devices
   * [1] https://developer.mozilla.org/docs/Web/API/WebVR_API ***/
  # "dom.vr.enabled" = false;
  /* 2521: set a default permission for Virtual Reality (see 2520) [FF73+]
   * 0=always ask (default), 1=allow, 2=block
   * [SETTING] to add site exceptions: Page Info>Permissions>Access Virtual Reality Devices
   * [SETTING] to manage site exceptions: Options>Privacy & Security>Permissions>Virtual Reality>Settings ***/
  # "permissions.default.xr" = 0;

  /*** [SECTION 2600]: MISCELLANEOUS ***/

  /* 2601: prevent accessibility services from accessing your browser [RESTART]
   * [SETTING] Privacy & Security>Permissions>Prevent accessibility services from accessing your browser
   * [1] https://support.mozilla.org/kb/accessibility-services ***/
  "accessibility.force_disabled" = 1;
  /* 2602: disable sending additional analytics to web servers
   * [1] https://developer.mozilla.org/docs/Web/API/Navigator/sendBeacon ***/
  "beacon.enabled" = false;
  /* 2603: remove temp files opened with an external application
   * [1] https://bugzilla.mozilla.org/302433 ***/
  "browser.helperApps.deleteTempFileOnExit" = true;
  /* 2604: disable page thumbnail collection
   * look in profile/thumbnails directory - you may want to clean that out ***/
  #"browser.pagethumbnails.capturing_disabled" = true;
  # [HIDDEN PREF]
  /* 2605: block web content in file processes [FF55+]
   * [SETUP-WEB] You may want to disable this for corporate or developer environments
   * [1] https://bugzilla.mozilla.org/1343184 ***/
  #"browser.tabs.remote.allowLinkedWebInFileUriProcess" = false;
  /* 2606: disable UITour backend so there is no chance that a remote page can use it ***/
  "browser.uitour.enabled" = false;
  "browser.uitour.url" = "";
  /* 2607: disable various developer tools in browser context
   * [SETTING] Devtools>Advanced Settings>Enable browser chrome and add-on debugging toolboxes
   * [1] https://github.com/pyllyukko/user.js/issues/179#issuecomment-246468676 ***/
  #"devtools.chrome.enabled" = false;
  /* 2608: disable remote debugging
   * [1] https://trac.torproject.org/projects/tor/ticket/16222 ***/
  #"devtools.debugger.remote-enabled" = false;
  /* 2609: disable MathML (Mathematical Markup Language) [FF51+] [SETUP-HARDEN]
   * [TEST] https://ghacksuserjs.github.io/TorZillaPrint/TorZillaPrint.html#misc
   * [1] https://bugzilla.mozilla.org/1173199 ***/
  # "mathml.disabled" = true;
  /* 2610: disable in-content SVG (Scalable Vector Graphics) [FF53+]
   * [NOTE] In FF70+ and ESR68.1.0+ this no longer affects extensions (1564208)
   * [WARNING] Expect breakage incl. youtube player controls. Best left for a "hardened" profile.
   * [1] https://bugzilla.mozilla.org/1216893 ***/
  # "svg.disabled" = true;
  /* 2611: disable middle mouse click opening links from clipboard
   * [1] https://trac.torproject.org/projects/tor/ticket/10089 ***/
  "middlemouse.contentLoadURL" = false;
  /* 2614: limit HTTP redirects (this does not control redirects with HTML meta tags or JS)
   * [NOTE] A low setting of 5 or under will probably break some sites (e.g. gmail logins)
   * To control HTML Meta tag and JS redirects, use an extension. Default is 20 ***/
  "network.http.redirection-limit" = 10;
  /* 2615: disable websites overriding Firefox's keyboard shortcuts [FF58+]
   * 0 (default) or 1=allow, 2=block
   * [SETTING] to add site exceptions: Page Info>Permissions>Override Keyboard Shortcuts ***/
  # "permissions.default.shortcuts" = 2;
  /* 2616: remove special permissions for certain mozilla domains [FF35+]
   * [1] resource://app/defaults/permissions ***/
  "permissions.manager.defaultsUrl" = "";
  /* 2617: remove webchannel whitelist ***/
  "webchannel.allowObject.urlWhitelist" = "";
  /* 2619: enforce Punycode for Internationalized Domain Names to eliminate possible spoofing
   * Firefox has *some* protections, but it is better to be safe than sorry
   * [SETUP-WEB] Might be undesirable for non-latin alphabet users since legitimate IDN's are also punycoded
   * [TEST] https://www.xn--80ak6aa92e.com/ (www.apple.com)
   * [1] https://wiki.mozilla.org/IDN_Display_Algorithm
   * [2] https://en.wikipedia.org/wiki/IDN_homograph_attack
   * [3] CVE-2017-5383: https://www.mozilla.org/security/advisories/mfsa2017-02/
   * [4] https://www.xudongz.com/blog/2017/idn-phishing/ ***/
  "network.IDN_show_punycode" = true;
  /* 2620: enforce Firefox's built-in PDF reader [SETUP-CHROME]
   * This setting controls if the option "Display in Firefox" is available in the setting below
   *   and by effect controls whether PDFs are handled in-browser or externally ("Ask" or "Open With")
   * PROS: pdfjs is lightweight, open source, and as secure/vetted as any pdf reader out there (more than most)
   *   Exploits are rare (1 serious case in 4 yrs), treated seriously and patched quickly.
   *   It doesn't break "state separation" of browser content (by not sharing with OS, independent apps).
   *   It maintains disk avoidance and application data isolation. It's convenient. You can still save to disk.
   * CONS: You may prefer a different pdf reader for security reasons
   * CAVEAT: JS can still force a pdf to open in-browser by bundling its own code (rare)
   * [SETTING] General>Applications>Portable Document Format (PDF) ***/
  "pdfjs.disabled" = false;
  # [DEFAULT: false]
  /* 2621: disable links launching Windows Store on Windows 8/8.1/10 [WINDOWS]
   * [1] https://www.ghacks.net/2016/03/25/block-firefox-chrome-windows-store/ ***/
  "network.protocol-handler.external.ms-windows-store" = false;

  /** DOWNLOADS ***/
  /* 2650: discourage downloading to desktop
   * 0=desktop, 1=downloads (default), 2=last used
   * [SETTING] To set your default "downloads": General>Downloads>Save files to ***/
  "browser.download.folderList" = 2;
  /* 2651: enforce user interaction for security by always asking where to download
   * [SETUP-CHROME] On Android this blocks longtapping and saving images
   * [SETTING] General>Downloads>Always ask you where to save files ***/
  #"browser.download.useDownloadDir" = false;
  /* 2652: disable adding downloads to the system's "recent documents" list ***/
  #"browser.download.manager.addToRecentDocs" = false;
  /* 2653: disable hiding mime types (Options>General>Applications) not associated with a plugin ***/
  "browser.download.hide_plugins_without_extensions" = false;
  /* 2654: disable "open with" in download dialog [FF50+] [SETUP-HARDEN]
   * This is very useful to enable when the browser is sandboxed (e.g. via AppArmor)
   * in such a way that it is forbidden to run external applications.
   * [WARNING] This may interfere with some users' workflow or methods
   * [1] https://bugzilla.mozilla.org/1281959 ***/
  # "browser.download.forbid_open_with" = true;

  /** EXTENSIONS ***/
  /* 2660: lock down allowed extension directories
   * [SETUP-CHROME] This will break extensions, language packs, themes and any other
   * XPI files which are installed outside of profile and application directories
   * [1] https://mike.kaply.com/2012/02/21/understanding-add-on-scopes/
   * [1] archived: https://archive.is/DYjAM ***/
  #"extensions.enabledScopes" = 5;
  # [HIDDEN PREF]
  #"extensions.autoDisableScopes" = 15;
  # [DEFAULT: 15]
  /* 2662: disable webextension restrictions on certain mozilla domains (also see 4503) [FF60+]
   * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1384330,1406795,1415644,1453988 ***/
  # "extensions.webextensions.restrictedDomains" = "";

  /** SECURITY ***/
  /* 2680: enforce CSP (Content Security Policy)
   * [WARNING] CSP is a very important and widespread security feature. Don't disable it!
   * [1] https://developer.mozilla.org/docs/Web/HTTP/CSP ***/
  "security.csp.enable" = true;
  # [DEFAULT: true]
  /* 2684: enforce a security delay on some confirmation dialogs such as install, open/save
   * [1] https://www.squarefree.com/2004/07/01/race-conditions-in-security-dialogs/ ***/
  "security.dialog_enable_delay" = 700;

  /*** [SECTION 2700]: PERSISTENT STORAGE
       Data SET by websites including
              cookies : profile\cookies.sqlite
         localStorage : profile\webappsstore.sqlite
            indexedDB : profile\storage\default
             appCache : profile\OfflineCache
       serviceWorkers :

       [NOTE] indexedDB and serviceWorkers are not available in Private Browsing Mode
       [NOTE] Blocking cookies also blocks websites access to: localStorage (incl. sessionStorage),
       indexedDB, sharedWorker, and serviceWorker (and therefore service worker cache and notifications)
       If you set a site exception for cookies (either "Allow" or "Allow for Session") then they become
       accessible to websites except shared/service workers where the cookie setting *must* be "Allow"
  ***/

  /* 2701: disable 3rd-party cookies and site-data [SETUP-WEB]
   * 0=Accept cookies and site data, 1=(Block) All third-party cookies, 2=(Block) All cookies,
   * 3=(Block) Cookies from unvisited websites, 4=(Block) Cross-site and social media trackers (FF63+) (default FF69+)
   * [NOTE] You can set exceptions under site permissions or use an extension
   * [NOTE] Enforcing category to custom ensures ETP related prefs are always honored
   * [SETTING] Privacy & Security>Enhanced Tracking Protection>Custom>Cookies ***/
  "network.cookie.cookieBehavior" = 1;
  "browser.contentblocking.category" = "custom";
  /* 2702: set third-party cookies (i.e ALL) (if enabled, see 2701) to session-only
     and (FF58+) set third-party non-secure (i.e HTTP) cookies to session-only
     [NOTE] .sessionOnly overrides .nonsecureSessionOnly except when .sessionOnly=false and
     .nonsecureSessionOnly=true. This allows you to keep HTTPS cookies, but session-only HTTP ones
   * [1] https://feeding.cloud.geek.nz/posts/tweaking-cookies-for-privacy-in-firefox/ ***/
  "network.cookie.thirdparty.sessionOnly" = true;
  "network.cookie.thirdparty.nonsecureSessionOnly" = true;
  # [FF58+]
  /* 2703: delete cookies and site data on close
   * 0=keep until they expire (default), 2=keep until you close Firefox
   * [NOTE] The setting below is disabled (but not changed) if you block all cookies (2701 = 2)
   * [SETTING] Privacy & Security>Cookies and Site Data>Delete cookies and site data when Firefox is closed ***/
  # "network.cookie.lifetimePolicy" = 2;
  /* 2710: disable DOM (Document Object Model) Storage
   * [WARNING] This will break a LOT of sites' functionality AND extensions!
   * You are better off using an extension for more granular control ***/
  # "dom.storage.enabled" = false;
  /* 2730: disable offline cache ***/
  #"browser.cache.offline.enable" = false;
  /* 2740: disable service worker cache and cache storage
   * [NOTE] We clear service worker cache on exiting Firefox (see 2803)
   * [1] https://w3c.github.io/ServiceWorker/#privacy ***/
  # "dom.caches.enabled" = false;
  /* 2750: disable Storage API [FF51+]
   * The API gives sites the ability to find out how much space they can use, how much
   * they are already using, and even control whether or not they need to be alerted
   * before the user agent disposes of site data in order to make room for other things.
   * [1] https://developer.mozilla.org/docs/Web/API/StorageManager
   * [2] https://developer.mozilla.org/docs/Web/API/Storage_API
   * [3] https://blog.mozilla.org/l10n/2017/03/07/firefox-l10n-report-aurora-54/ ***/
  # "dom.storageManager.enabled" = false;
  /* 2755: disable Storage Access API [FF65+]
   * [1] https://developer.mozilla.org/en-US/docs/Web/API/Storage_Access_API ***/
  # "dom.storage_access.enabled" = false;

  /*** [SECTION 2800]: SHUTDOWN
       You should set the values to what suits you best.
       - "Offline Website Data" includes appCache (2730), localStorage (2710),
         service worker cache (2740), and QuotaManager (IndexedDB (2720), asm-cache)
       - In both 2803 + 2804, the 'download' and 'history' prefs are combined in the
         Firefox interface as "Browsing & Download History" and their values will be synced
  ***/

  /* 2802: enable Firefox to clear items on shutdown (see 2803)
   * [SETTING] Privacy & Security>History>Custom Settings>Clear history when Firefox closes ***/
  #"privacy.sanitize.sanitizeOnShutdown" = true;
  /* 2803: set what items to clear on shutdown (if 2802 is true) [SETUP-CHROME]
   * [NOTE] If 'history' is true, downloads will also be cleared regardless of the value
   * but if 'history' is false, downloads can still be cleared independently
   * However, this may not always be the case. The interface combines and syncs these
   * prefs when set from there, and the sanitize code may change at any time
   * [SETTING] Privacy & Security>History>Custom Settings>Clear history when Firefox closes>Settings ***/
  #"privacy.clearOnShutdown.cache" = true;
  #"privacy.clearOnShutdown.cookies" = true;
  #"privacy.clearOnShutdown.downloads" = true;
  # see note above
  #"privacy.clearOnShutdown.formdata" = true;
  # Form & Search History
  #"privacy.clearOnShutdown.history" = true;
  # Browsing & Download History
  #"privacy.clearOnShutdown.offlineApps" = true;
  # Offline Website Data
  #"privacy.clearOnShutdown.sessions" = true;
  # Active Logins
  #"privacy.clearOnShutdown.siteSettings" = false;
  # Site Preferences
  /* 2804: reset default items to clear with Ctrl-Shift-Del (to match 2803) [SETUP-CHROME]
   * This dialog can also be accessed from the menu History>Clear Recent History
   * Firefox remembers your last choices. This will reset them when you start Firefox.
   * [NOTE] Regardless of what you set privacy.cpd.downloads to, as soon as the dialog
   * for "Clear Recent History" is opened, it is synced to the same as 'history' ***/
  #"privacy.cpd.cache" = true;
  #"privacy.cpd.cookies" = true;
  # "privacy.cpd.downloads" = true; // not used, see note above
  #"privacy.cpd.formdata" = true;
  # Form & Search History
  #"privacy.cpd.history" = true;
  # Browsing & Download History
  #"privacy.cpd.offlineApps" = true;
  # Offline Website Data
  #"privacy.cpd.passwords" = false;
  # this is not listed
  #"privacy.cpd.sessions" = true;
  # Active Logins
  #"privacy.cpd.siteSettings" = false;
  # Site Preferences
  /* 2805: clear Session Restore data when sanitizing on shutdown or manually [FF34+]
   * [NOTE] Not needed if Session Restore is not used (see 0102) or is already cleared with history (see 2803)
   * [NOTE] privacy.clearOnShutdown.openWindows prevents resuming from crashes (see 1022)
   * [NOTE] privacy.cpd.openWindows has a bug that causes an additional window to open ***/
  # "privacy.clearOnShutdown.openWindows" = true;
  # "privacy.cpd.openWindows" = true;
  /* 2806: reset default 'Time range to clear' for 'Clear Recent History' (see 2804)
   * Firefox remembers your last choice. This will reset the value when you start Firefox.
   * 0=everything, 1=last hour, 2=last two hours, 3=last four hours,
   * 4=today, 5=last five minutes, 6=last twenty-four hours
   * [NOTE] The values 5 + 6 are not listed in the dropdown, which will display a
   * blank value if they are used, but they do work as advertised ***/
  #"privacy.sanitize.timeSpan" = 0;

  /*** [SECTION 4000]: FPI (FIRST PARTY ISOLATION)
   ** 1278037 - isolate indexedDB (FF51+)
   ** 1277803 - isolate favicons (FF52+)
   ** 1264562 - isolate OCSP cache (FF52+)
   ** 1268726 - isolate Shared Workers (FF52+)
   ** 1316283 - isolate SSL session cache (FF52+)
   ** 1317927 - isolate media cache (FF53+)
   ** 1323644 - isolate HSTS and HPKP (FF54+)
   ** 1334690 - isolate HTTP Alternative Services (FF54+)
   ** 1334693 - isolate SPDY/HTTP2 (FF55+)
   ** 1337893 - isolate DNS cache (FF55+)
   ** 1344170 - isolate blob: URI (FF55+)
   ** 1300671 - isolate data:, about: URLs (FF55+)
   ** 1473247 - isolate IP addresses (FF63+)
   ** 1492607 - isolate postMessage with targetOrigin "*" (requires 4002) (FF65+)
   ** 1542309 - isolate top-level domain URLs when host is in the public suffix list (FF68+)
   ** 1506693 - isolate pdfjs range-based requests (FF68+)
   ** 1330467 - isolate site permissions (FF69+)
   ** 1534339 - isolate IPv6 (FF73+)
  ***/

  /* 4001: enable First Party Isolation [FF51+]
   * [SETUP-WEB] May break cross-domain logins and site functionality until perfected
   * [1] https://bugzilla.mozilla.org/1260931 ***/
  #"privacy.firstparty.isolate" = true;
  /* 4002: enforce FPI restriction for window.opener [FF54+]
   * [NOTE] Setting this to false may reduce the breakage in 4001
   * FF65+ blocks postMessage with targetOrigin "*" if originAttributes don't match. But
   * to reduce breakage it ignores the 1st-party domain (FPD) originAttribute. (see [2],[3])
   * The 2nd pref removes that limitation and will only allow communication if FPDs also match.
   * [1] https://bugzilla.mozilla.org/1319773#c22
   * [2] https://bugzilla.mozilla.org/1492607
   * [3] https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage ***/
  # "privacy.firstparty.isolate.restrict_opener_access" = true; // [DEFAULT: true]
  # "privacy.firstparty.isolate.block_post_message" = true;
  # [HIDDEN PREF ESR]

  /*** [SECTION 4500]: RFP (RESIST FINGERPRINTING)
     This master switch will be used for a wide range of items, many of which will
     **override** existing prefs from FF55+, often providing a **better** solution

     IMPORTANT: As existing prefs become redundant, and some of them WILL interfere
     with how RFP works, they will be moved to section 4600 and made inactive

   ** 418986 - limit window.screen & CSS media queries leaking identifiable info (FF41+)
        [NOTE] Info only: To set a size, open a XUL (chrome) page (such as about:config) which is at
        100% zoom, hit Shift+F4 to open the scratchpad, type window.resizeTo(1366,768), hit Ctrl+R to run.
        Test your window size, do some math, resize to allow for all the non inner window elements
        [TEST] https://ghacksuserjs.github.io/TorZillaPrint/TorZillaPrint.html#screen
   ** 1281949 - spoof screen orientation (FF50+)
   ** 1281963 - hide the contents of navigator.plugins and navigator.mimeTypes (FF50+)
        FF53: Fixes GetSupportedNames in nsMimeTypeArray and nsPluginArray (1324044)
   ** 1330890 - spoof timezone as UTC 0 (FF55+)
        FF58: Date.toLocaleFormat deprecated (818634)
        FF60: Date.toLocaleDateString and Intl.DateTimeFormat fixed (1409973)
   ** 1360039 - spoof navigator.hardwareConcurrency as 2 (see 4601) (FF55+)
        This spoof *shouldn't* affect core chrome/Firefox performance
   ** 1217238 - reduce precision of time exposed by javascript (FF55+)
   ** 1369303 - spoof/disable performance API (see 2410-deprecated, 4602, 4603) (FF56+)
   ** 1333651 & 1383495 & 1396468 - spoof Navigator API (see section 4700) (FF56+)
        FF56: The version number will be rounded down to the nearest multiple of 10
        FF57: The version number will match current ESR (1393283, 1418672, 1418162, 1511763)
        FF59: The OS will be reported as Windows, OSX, Android, or Linux (to reduce breakage) (1404608)
        FF66: The OS in HTTP Headers will be reduced to Windows or Android (1509829)
        FF68: Reported OS versions updated to Windows 10, OS 10.14, and Adnroid 8.1 (1511434)
   ** 1369319 - disable device sensor API (see 4604) (FF56+)
   ** 1369357 - disable site specific zoom (see 4605) (FF56+)
   ** 1337161 - hide gamepads from content (see 4606) (FF56+)
   ** 1372072 - spoof network information API as "unknown" when dom.netinfo.enabled = true (see 4607) (FF56+)
   ** 1333641 - reduce fingerprinting in WebSpeech API (see 4608) (FF56+)
   ** 1372069 & 1403813 & 1441295 - block geolocation requests (same as denying a site permission) (see 0201, 0202) (FF56-62)
   ** 1369309 - spoof media statistics (see 4610) (FF57+)
   ** 1382499 - reduce screen co-ordinate fingerprinting in Touch API (see 4611) (FF57+)
   ** 1217290 & 1409677 - enable fingerprinting resistance for WebGL (see 2010-12) (FF57+)
   ** 1382545 - reduce fingerprinting in Animation API (FF57+)
   ** 1354633 - limit MediaError.message to a whitelist (FF57+)
   ** 1382533 - enable fingerprinting resistance for Presentation API (FF57+)
        This blocks exposure of local IP Addresses via mDNS (Multicast DNS)
   **  967895 - enable site permission prompt before allowing canvas data extraction (FF58+)
        FF59: Added to site permissions panel (1413780) Only prompt when triggered by user input (1376865)
   ** 1372073 - spoof/block fingerprinting in MediaDevices API (FF59+)
        Spoof: enumerate devices reports one "Internal Camera" and one "Internal Microphone" if
               media.navigator.enabled is true (see 2505 which we chose to keep disabled)
        Block: suppresses the ondevicechange event (see 4612)
   ** 1039069 - warn when language prefs are set to non en-US (see 0210, 0211) (FF59+)
   ** 1222285 & 1433592 - spoof keyboard events and suppress keyboard modifier events (FF59+)
        Spoofing mimics the content language of the document. Currently it only supports en-US.
        Modifier events suppressed are SHIFT and both ALT keys. Chrome is not affected.
        FF60: Fix keydown/keyup events (1438795)
   ** 1337157 - disable WebGL debug renderer info (see 4613) (FF60+)
   ** 1459089 - disable OS locale in HTTP Accept-Language headers (ANDROID) (FF62+)
   ** 1479239 - return "no-preference" with prefers-reduced-motion (FF63+)
   ** 1363508 - spoof/suppress Pointer Events (see 4614) (FF64+)
        FF65: pointerEvent.pointerid (1492766)
   ** 1485266 - disable exposure of system colors to CSS or canvas (see 4615) (FF67+)
   ** 1407366 - enable inner window letterboxing (see 4504) (FF67+)
   ** 1494034 - return "light" with prefers-color-scheme (see 4616) (FF67+)
        [1] https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme
   ** 1564422 - spoof audioContext outputLatency (FF70+)
   ** 1595823 - spoof audioContext sampleRate (FF72+)
   ** 1607316 - spoof pointer as coarse and hover as none (ANDROID) (FF74+)
  ***/

  /* 4501: enable privacy.resistFingerprinting [FF41+]
   * This pref is the master switch for all other privacy.resist* prefs unless stated
   * [SETUP-WEB] RFP can cause the odd website to break in strange ways, and has a few side affects,
   * but is largely robust nowadays. Give it a try. Your choice. Also see 4504 (letterboxing).
   * [1] https://bugzilla.mozilla.org/418986 ***/
  "privacy.resistFingerprinting" = true;
  /* 4502: set new window sizes to round to hundreds [FF55+] [SETUP-CHROME]
   * Width will round down to multiples of 200s and height to 100s, to fit your screen.
   * The override values are a starting point to round from if you want some control
   * [1] https://bugzilla.mozilla.org/1330882
   * [2] https://hardware.metrics.mozilla.com/ ***/
  # "privacy.window.maxInnerWidth" = 1000;
  # "privacy.window.maxInnerHeight" = 1000;
  /* 4503: disable mozAddonManager Web API [FF57+]
   * [NOTE] As a side-effect in FF57-59 this allowed extensions to work on AMO. In FF60+ you also need
   * to sanitize or clear extensions.webextensions.restrictedDomains (see 2662) to keep that side-effect
   * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1384330,1406795,1415644,1453988 ***/
  "privacy.resistFingerprinting.block_mozAddonManager" = true;
  /* 4504: enable RFP letterboxing [FF67+]
   * Dynamically resizes the inner window (FF67; 200w x100h: FF68+; stepped ranges) by applying letterboxing,
   * using dimensions which waste the least content area, If you use the dimension pref, then it will only apply
   * those resolutions. The format is "width1xheight1, width2xheight2, ..." (e.g. "800x600, 1000x1000, 1600x900")
   * [SETUP-WEB] This does NOT require RFP (see 4501) **for now**, so if you're not using 4501, or you are but you're
   * not taking anti-fingerprinting seriously and a little visual change upsets you, then feel free to flip this pref
   * [WARNING] The dimension pref is only meant for testing, and we recommend you DO NOT USE it
   * [1] https://bugzilla.mozilla.org/1407366 ***/
  #"privacy.resistFingerprinting.letterboxing" = true;
  # [HIDDEN PREF]
  # "privacy.resistFingerprinting.letterboxing.dimensions" = "";
  # [HIDDEN PREF]
  /* 4510: disable showing about:blank as soon as possible during startup [FF60+]
   * When default true (FF62+) this no longer masks the RFP chrome resizing activity
   * [1] https://bugzilla.mozilla.org/1448423 ***/
  "browser.startup.blankWindow" = false;

  /*** [SECTION 4600]: RFP ALTERNATIVES
     * non-RFP users:
         Enable the whole section (see the SETUP tag below)
     * RFP users:
         Make sure these are reset in about:config. They are redundant. In fact, some
         even cause RFP to not behave as you would expect and alter your fingerprint
     * ESR RFP users:
         Reset those *up to and including* your version. Add those *after* your version
         as active prefs in your overrides. This is assuming that the patch wasn't also
         backported to Firefox ESR. Backporting RFP patches to ESR is rare.
  ***/

  /* [SETUP-non-RFP] Non-RFP users replace the * with a slash on this line to enable these
  # FF55+
  # 4601: [2514] spoof (or limit?) number of CPU cores [FF48+]
# [NOTE] *may* affect core chrome/Firefox performance, will affect content.
# [1] https://bugzilla.mozilla.org/1008453
# [2] https://trac.torproject.org/projects/tor/ticket/21675
# [3] https://trac.torproject.org/projects/tor/ticket/22127
# [4] https://html.spec.whatwg.org/multipage/workers.html#navigator.hardwareconcurrency
# "dom.maxHardwareConcurrency" = 2;
  # * * * /
  # FF56+
  # 4602: [2411] disable resource/navigation timing
  "dom.enable_resource_timing" = false;
  # 4603: [2412] disable timing attacks
# [1] https://wiki.mozilla.org/Security/Reviews/Firefox/NavigationTimingAPI
  "dom.enable_performance" = false;
  # 4604: [2512] disable device sensor API
# Optional protection depending on your device
# [1] https://trac.torproject.org/projects/tor/ticket/15758
# [2] https://blog.lukaszolejnik.com/stealing-sensitive-browser-data-with-the-w3c-ambient-light-sensor-api/
# [3] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1357733,1292751
# "device.sensors.enabled" = false;
  # 4605: [2515] disable site specific zoom
# Zoom levels affect screen res and are highly fingerprintable. This does not stop you using
# zoom, it will just not use/remember any site specific settings. Zoom levels on new tabs
# and new windows are reset to default and only the current tab retains the current zoom
  "browser.zoom.siteSpecific" = false;
  # 4606: [2501] disable gamepad API - USB device ID enumeration
# Optional protection depending on your connected devices
# [1] https://trac.torproject.org/projects/tor/ticket/13023
# "dom.gamepad.enabled" = false;
  # 4607: [2503] disable giving away network info [FF31+]
# e.g. bluetooth, cellular, ethernet, wifi, wimax, other, mixed, unknown, none
# [1] https://developer.mozilla.org/docs/Web/API/Network_Information_API
# [2] https://wicg.github.io/netinfo/
# [3] https://bugzilla.mozilla.org/960426
  "dom.netinfo.enabled" = false; // [DEFAULT: true on Android]
  # 4608: [2021] disable the SpeechSynthesis (Text-to-Speech) part of the Web Speech API
# [1] https://developer.mozilla.org/docs/Web/API/Web_Speech_API
# [2] https://developer.mozilla.org/docs/Web/API/SpeechSynthesis
# [3] https://wiki.mozilla.org/HTML5_Speech_API
  "media.webspeech.synth.enabled" = false;
  # * * * /
  # FF57+
  # 4610: [2506] disable video statistics - JS performance fingerprinting [FF25+]
# [1] https://trac.torproject.org/projects/tor/ticket/15757
# [2] https://bugzilla.mozilla.org/654550
  "media.video_stats.enabled" = false;
  # 4611: [2509] disable touch events
# fingerprinting attack vector - leaks screen res & actual screen coordinates
# 0=disabled, 1=enabled, 2=autodetect
# Optional protection depending on your device
# [1] https://developer.mozilla.org/docs/Web/API/Touch_events
# [2] https://trac.torproject.org/projects/tor/ticket/10286
# "dom.w3c_touch_events.enabled" = 0;
  # * * * /
  # FF59+
  # 4612: [2511] disable MediaDevices change detection [FF51+]
# [1] https://developer.mozilla.org/docs/Web/Events/devicechange
# [2] https://developer.mozilla.org/docs/Web/API/MediaDevices/ondevicechange
  "media.ondevicechange.enabled" = false;
  # * * * /
  # FF60+
  # 4613: [2011] disable WebGL debug info being available to websites
# [1] https://bugzilla.mozilla.org/1171228
# [2] https://developer.mozilla.org/docs/Web/API/WEBGL_debug_renderer_info
  "webgl.enable-debug-renderer-info" = false;
  # * * * /
  # FF65+
  # 4614: [2516] disable PointerEvents
# [1] https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent
  "dom.w3c_pointer_events.enabled" = false;
  # * * * /
  # FF67+
  # 4615: [2618] disable exposure of system colors to CSS or canvas [FF44+]
# [NOTE] See second listed bug: may cause black on black for elements with undefined colors
# [SETUP-CHROME] Might affect CSS in themes and extensions
# [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=232227,1330876
  "ui.use_standins_for_native_colors" = true;
  # 4616: enforce prefers-color-scheme as light [FF67+]
# 0=light, 1=dark : This overrides your OS value
  "ui.systemUsesDarkTheme" = 0; // [HIDDEN PREF]
  # * * * /
  # ***/

  /*** [SECTION 4700]: RFP ALTERNATIVES (NAVIGATOR / USER AGENT (UA) SPOOFING)
       This is FYI ONLY. These prefs are INSUFFICIENT(a) on their own, you need
       to use RFP (4500) or an extension, in which case they become POINTLESS.
       (a) Many of the components that make up your UA can be derived by other means.
           And when those values differ, you provide more bits and raise entropy.
           Examples of leaks include navigator objects, date locale/formats, iframes,
           headers, tcp/ip attributes, feature detection, and **many** more.
       ALL values below intentionally left blank - use RFP, or get a vetted, tested
           extension and mimic RFP values to *lower* entropy, or randomize to *raise* it
  ***/

  /* 4701: navigator.userAgent ***/
  # "general.useragent.override" = ""; // [HIDDEN PREF]
  /* 4702: navigator.buildID
   * Revealed build time down to the second. In FF64+ it now returns a fixed timestamp
   * [1] https://bugzilla.mozilla.org/583181
   * [2] https://www.fxsitecompat.com/en-CA/docs/2018/navigator-buildid-now-returns-a-fixed-timestamp/ ***/
  # "general.buildID.override" = "";
  # [HIDDEN PREF]
  /* 4703: navigator.appName ***/
  # "general.appname.override" = "";
  # [HIDDEN PREF]
  /* 4704: navigator.appVersion ***/
  # "general.appversion.override" = "";
  # [HIDDEN PREF]
  /* 4705: navigator.platform ***/
  # "general.platform.override" = "";
  # [HIDDEN PREF]
  /* 4706: navigator.oscpu ***/
  # "general.oscpu.override" = "";
  # [HIDDEN PREF]

  /*** [SECTION 5000]: PERSONAL
       Non-project related but useful. If any of these interest you, add them to your overrides ***/

  /* WELCOME & WHAT's NEW NOTICES ***/
  # "browser.startup.homepage_override.mstone" = "ignore"; // master switch
  # "startup.homepage_welcome_url" = "";
  # "startup.homepage_welcome_url.additional" = "";
  # "startup.homepage_override_url" = ""; // What's New page after updates
  /* WARNINGS ***/
  # "browser.tabs.warnOnClose" = false;
  # "browser.tabs.warnOnCloseOtherTabs" = false;
  # "browser.tabs.warnOnOpen" = false;
  # "full-screen-api.warning.delay" = 0;
  # "full-screen-api.warning.timeout" = 0;
  /* APPEARANCE ***/
  # "browser.download.autohideButton" = false; // [FF57+]
  # "toolkit.cosmeticAnimations.enabled" = false;
  # [FF55+]
  # "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  # [FF68+] allow userChrome/userContent
  /* CONTENT BEHAVIOR ***/
  # "accessibility.typeaheadfind" = true;
  # enable "Find As You Type"
  # "clipboard.autocopy" = false;
  # disable autocopy default [LINUX]
  # "layout.spellcheckDefault" = 2;
  # 0=none, 1-multi-line, 2 = multi-line & single-line
  /* UX BEHAVIOR ***/
  # "browser.backspace_action" = 2;
  # 0=previous page, 1 = scroll up, 2=do nothing
  # "browser.tabs.closeWindowWithLastTab" = false;
  # "browser.tabs.loadBookmarksInTabs" = true; // open bookmarks in a new tab [FF57+]
  # "browser.urlbar.decodeURLsOnCopy" = true;
  # see bugzilla 1320061 [FF53+]
  # "general.autoScroll" = false;
  # middle-click enabling auto-scrolling [DEFAULT: false on Linux]
  # "ui.key.menuAccessKey" = 0;
  # disable alt key toggling the menu bar [RESTART]
  # "view_source.tab" = false;
  # view "page/selection source" in a new window [FF68+, FF59 and under]
  /* UX FEATURES: disable and hide the icons and menus ***/
  # "browser.messaging-system.whatsNewPanel.enabled" = false;
  # What's New [FF69+]
  # "extensions.pocket.enabled" = false;
  # Pocket Account [FF46+]
  # "identity.fxaccounts.enabled" = false;
  # Firefox Accounts & Sync [FF60+] [RESTART]
  # "reader.parse-on-load.enabled" = false;
  # Reader View
  /* OTHER ***/
  # "browser.bookmarks.max_backups" = 2;
  # "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false; // disable CFR [FF67+]
  # [SETTING] General>Browsing>Recommend extensions as you browse
  # "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  # disable CFR [FF67+]
  # [SETTING] General>Browsing>Recommend features as you browse
  # "network.manage-offline-status" = false;
  # see bugzilla 620472
  # "xpinstall.signatures.required" = false);
  # enforced extension signing (Nightly/ESR

  /*** [SECTION 9999]: DEPRECATED / REMOVED / LEGACY / RENAMED
       Documentation denoted as [-]. Items deprecated in FF68 or earlier have been archived at [1],
       which also provides a link-clickable, viewer-friendly version of the deprecated bugzilla tickets
       [1] https://github.com/ghacksuserjs/ghacks-user.js/issues/123
  ***/

  /* ESR68.x still uses all the following prefs
  # [NOTE] replace the * with a slash in the line above to re-enable them
  # FF69
  # 1405: disable WOFF2 (Web Open Font Format) [FF35+]
# [-] https://bugzilla.mozilla.org/1556991
# "gfx.downloadable_fonts.woff2.enabled" = false;
  # 1802: enforce click-to-play for plugins
# [-] https://bugzilla.mozilla.org/1519434
  "plugins.click_to_play" = true; // [DEFAULT: true FF25+]
  # 2033: disable autoplay for muted videos [FF63+] - replaced by 'media.autoplay.default' options (2030)
# [-] https://bugzilla.mozilla.org/1562331
# "media.autoplay.allow-muted" = false;
  # * * * /
  # FF71
  # 2608: disable WebIDE and ADB extension download
# [1] https://trac.torproject.org/projects/tor/ticket/16222
# [-] https://bugzilla.mozilla.org/1539462
  "devtools.webide.enabled" = false; // [DEFAULT: false FF70+]
  "devtools.webide.autoinstallADBExtension" = false; // [FF64+]
  # 2731: enforce websites to ask to store data for offline use
# [1] https://support.mozilla.org/questions/1098540
# [2] https://bugzilla.mozilla.org/959985
# [-] https://bugzilla.mozilla.org/1574480
  "offline-apps.allow_by_default" = false;
  # * * * /
  # FF72
  # 0105a: disable Activity Stream telemetry
# [-] https://bugzilla.mozilla.org/1597697
  "browser.newtabpage.activity-stream.telemetry.ping.endpoint" = "";
  # 0330: disable Hybdrid Content telemetry
# [-] https://bugzilla.mozilla.org/1520491
  "toolkit.telemetry.hybridContent.enabled" = false; // [FF59+]
  # 2720: enforce IndexedDB (IDB) as enabled
# IDB is required for extensions and Firefox internals (even before FF63 in [1])
# To control *website* IDB data, control allowing cookies and service workers, or use
# Temporary Containers. To mitigate *website* IDB, FPI helps (4001), and/or sanitize
# on close (Offline Website Data, see 2800) or on-demand (Ctrl-Shift-Del), or automatically
# via an extension. Note that IDB currently cannot be sanitized by host.
# [1] https://blog.mozilla.org/addons/2018/08/03/new-backend-for-storage-local-api/
# [-] https://bugzilla.mozilla.org/1488583
  "dom.indexedDB.enabled" = true; // [DEFAULT: true]
  # * * * /
  # ***/

  /* END: internal custom pref to test for syntax errors ***/


  # disable smooth scrolling
  "general.smoothScroll" = false;
  # enable middle mouse autoscrolling
  "general.autoScroll" = true;
  # enable userChrome
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
}
