;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name    "foldu"
      user-mail-address "foldu@protonmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; lisp-2's sux
(cl-flet ((monospace (size)
                     (font-spec :family "Iosevka" :size size)))
  (setq doom-font (monospace 16))
  (setq doom-variable-pitch-font (font-spec :family "ETBembo" :size 16))
  (setq doom-big-font (monospace 19)))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; Turn on buffer previews
(setq +ivy-buffer-preview t)

;; Better syntax highlighting
(use-package! tree-sitter
  :config
  (require 'tree-sitter-langs)
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

;; Use nixpkgs-fmt for formatting nix files
(use-package! nixpkgs-fmt
  :commands nixpkgs-fmt nixpkgs-fmt-buffer)

(set-formatter! 'nixpkgs-fmt #'nixpkgs-fmt
  :modes '(nix-mode))

;; Increase the amount of data which Emacs reads from the process. Again the emacs
;; default is too low 4k considering that the some of the language server responses
;; are in 800k - 3M range.
(setq read-process-output-max (* 3 1024 1024))

;; Just learning elisp here. IGNORE ME
(setq fd/emacs-abbr
      ["Eighthundred Megabytes And Constantly Swapping"
       "Esc+Meta+Alt+Ctrl+Shift"
       "Eventually Munches All Computer Storage"
       "Eradication of Memory Accomplished with Complete Simplicity"
       "Generally Not Used Except by Middle Aged Computer Scientists"
       "Eating Memory And Cycle-Sucking"
       "Easily Maintained with the Assistance of Chemical Solutions"
       "Exceptionally Mediocre Algorithms for Computer Scientists"
       "Excavating Mayan Architecture Comes Simpler"
       "Eventually Makes All Cpus Seem slow"
       "EMACS Makers Are Crazy Sickos"])

(defun fd/vector-to-list (vec)
  "Convert the vector VEC to a list."
  (if (vectorp vec)
      ;; Python tier
      (append vec nil)
    (error "Expected a vector")))

(defun fd/emacs-set-name-to (name)
  "Set the Emacs window title to NAME."
  (setq frame-title-format (list (format "%%b - %s" name))))

(defun fd/emacs-set-name ()
  "Set Emacs window title name."
  (interactive)
  (let ((name (ivy-read "Set name: "
                        (fd/vector-to-list fd/emacs-abbr)
                        :require-match t)))
    (fd/emacs-set-name-to name)))

(defun fd/seq-random-pick (seq)
  "Picks a random element from SEQ. Return nil when seq lenght equals zero."
  (if (not (sequencep seq))
      (error "SEQ is not a sequence")
    (let ((len (seq-length seq)))
      (if (= len 0)
          nil
        (elt seq (random len))))))

(defun fd/emacs-random-name ()
  "Set the Emacs window name to something random from fd/emacs-abbr."
  (interactive)
  (fd/emacs-set-name-to (fd/seq-random-pick fd/emacs-abbr)))

;; Change default window title to random thing every 5 minutes
;; This is completely useless.
(setq fd/emacs-random-timer (run-at-time 0 (* 5 60) #'fd/emacs-random-name))

;; make which key pop up faster
(setq which-key-idle-delay 0.5)

;; show completion with less timeout
(after! company
  (setq company-idle-delay 0.5))

(setq fancy-splash-image "~/fancy_splash_image.png")

;; disable autocomplete for nix (hangs emacs)
(set-company-backend! 'nix-mode nil)

(setq lsp-julia-default-environment "~/.julia/environments/v1.5")

(defun dwim-compile ()
  "Just compile the current project"
  (interactive)
  (let ((current-project (project-current)))
    (if (not current-project)
        (error "Not in a project, I have no idea how to figure out what you mean")
      (let ((workdir (cdr current-project)))
        (cond ((file-exists-p (concat workdir "Makefile"))
               (compile "make -k"))
              ((file-exists-p (concat workdir "CMakeLists.txt"))
               (let ((build-dir (concat workdir "build")))
                 (unless (file-directory-p build-dir) (make-directory build-dir))
                 (let ((default-directory build-dir))
                   (when (directory-empty-p build-dir)
                     (shell-command "cmake -G Ninja .."))
                   (compile "ninja"))))
              ((file-exists-p (concat workdir "Cargo.toml"))
               (let ((default-directory workdir))
                 (compile "cargo b")))
              (t
               (error "I don't know how to compile this")))))))

(map!
 :leader
 :nv
 :desc "dwim compile"
 "cc"
 #'dwim-compile)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
