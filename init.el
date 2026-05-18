;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Personal config: atom-one-dark theme, completion stack (vertico/corfu/embark),
;; Python/C++/LaTeX/Org support, Dirvish file manager, Claude Code integration.

;;; Code:

;; === Package bootstrap ===
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; use-package is built-in since Emacs 29; ensure all MELPA packages by default
(require 'use-package)
(setq use-package-always-ensure t)

;; Separate custom.el (auto-managed by Emacs, not tracked in git)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)

;; === Appearance & global settings ===
(use-package atom-one-dark-theme
  :config (load-theme 'atom-one-dark t))

(setq inhibit-startup-message t
      column-number-mode t
      split-height-threshold nil
      split-width-threshold 0
      use-short-answers t
      make-backup-files nil
      history-length 50
      global-auto-revert-non-file-buffers t
      completion-cycle-threshold 3)

(global-superword-mode t)
(delete-selection-mode t)
(electric-pair-mode t)
(tab-bar-mode 1)
(display-time-mode 1)
(display-battery-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(global-auto-revert-mode 1)

(setq initial-scratch-message
      (concat ";; " (replace-regexp-in-string "\n" "\n;; "
              (shell-command-to-string "fortune"))
              "\n\n"))

;; === macOS keys ===
(setq mac-option-modifier       'meta
      mac-command-modifier      'super
      mac-right-option-modifier 'meta)

(when (eq system-type 'darwin)
  (setq dired-use-ls-dired nil))

(windmove-default-keybindings 'meta)

(defun comment-or-uncomment-region-or-line ()
  "Comment or uncomment the region, or the current line if no active region."
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (line-beginning-position)))
        (end (if (region-active-p) (region-end)       (line-end-position))))
    (comment-or-uncomment-region beg end)))

(global-set-key (kbd "s-Z")          #'undo-redo)
(global-set-key (kbd "s-/")          #'comment-or-uncomment-region-or-line)
(global-set-key (kbd "C-s-f")        #'toggle-frame-fullscreen)
(global-set-key (kbd "M-s-<left>")   #'shrink-window-horizontally)
(global-set-key (kbd "M-s-<right>")  #'enlarge-window-horizontally)
(global-set-key (kbd "M-s-<up>")     #'shrink-window)
(global-set-key (kbd "M-s-<down>")   #'enlarge-window)

;; === Completion ===
(use-package vertico
  :demand t
  :bind (:map minibuffer-local-map
              ("<tab>"    . vertico-insert)
              ("<backtab>" . vertico-previous))
  :custom (vertico-cycle t)
  :config
  (vertico-mode t)
  (vertico-reverse-mode t)
  (set-face-attribute 'vertico-current nil
                      :weight 'bold :inverse-video nil
                      :foreground "#ffbf00" :background "grey20")
  (set-face-attribute 'completions-common-part nil
                      :weight 'bold :foreground "#d70000")
  (set-face-attribute 'minibuffer-prompt nil
                      :foreground "#ffbf00"))

(use-package marginalia
  :custom (marginalia-align 'right)
  :config
  (marginalia-mode t)
  (set-face-attribute 'marginalia-documentation nil
                      :inherit nil :slant 'italic :foreground "grey43")
  (set-face-attribute 'marginalia-key nil :foreground "#00ff5f"))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package corfu
  :custom (corfu-auto t)
  :bind (:map corfu-map ("RET" . nil))
  :init (global-corfu-mode))

(use-package corfu-popupinfo
  :ensure nil  ; bundled with corfu
  :after corfu
  :init (corfu-popupinfo-mode)
  :custom (corfu-popupinfo-delay '(1.0 . 0.1)))

(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings))
  :init (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil (window-parameters (mode-line-format . none)))))

(use-package embark-consult)

;; === Writing & Org ===
(defun human-text-on ()
  "Enable visual line mode and line numbers for prose buffers."
  (turn-on-visual-line-mode)
  (display-line-numbers-mode))

(add-hook 'text-mode-hook #'human-text-on)
(add-hook 'org-mode-hook  #'human-text-on)

(setq org-image-actual-width      500
      org-support-shift-select    t
      org-latex-src-block-backend 'listings
      org-src-fontify-natively    t
      browse-url-browser-function 'xwidget-webkit-browse-url)

(setq org-file-apps
      '((auto-mode . emacs)
        ("\\.x?html?\\'" . (lambda (file link)
                             (xwidget-webkit-browse-url (concat "file://" link))))
        ("\\.mp4\\'" . "vlc \"%s\"")))

(org-babel-do-load-languages 'org-babel-load-languages
                              '((python . t)
                                (shell  . t)))

(use-package htmlize)

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :custom (markdown-command "multimarkdown"))

(use-package xwwp
  :custom (xwwp-search-prefix "https://duckduckgo.com/?q="))

;; === LaTeX ===
(use-package pdf-tools
  :config
  (pdf-loader-install)
  (add-hook 'pdf-view-mode-hook #'pdf-view-dark-minor-mode))

(use-package tex
  :ensure auctex
  :hook ((LaTeX-mode . turn-on-reftex)
         (LaTeX-mode . flyspell-mode))
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-source-correlate-start-server t)
  (TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-mode t)
  (reftex-plug-into-AUCTeX t)
  (reftex-bibliography-commands '("bibliography" "nobibliography" "addbibresource"))
  :config
  (setq-default TeX-master nil)
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (global-set-key (kbd "C-c C-g") #'pdf-sync-forward-search)
              (define-key LaTeX-mode-map (kbd "$") #'self-insert-command))))

;; === Programming ===
(add-hook 'prog-mode-hook       #'display-line-numbers-mode)
(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

(setq-default eglot-workspace-configuration
              '(:pylsp (:skip_token_initialization t
                        :plugins (:ruff       (:enabled t :formatEnabled t)
                                  :pylsp_mypy (:enabled t)))))

(add-to-list 'auto-mode-alist '("\\.cu\\'" . c++-mode))
(add-hook 'c++-mode-hook #'eglot-ensure)

(use-package pyvenv
  :config
  (pyvenv-mode 1)
  (defun tramp-conda-setup ()
    "Set WORKON_HOME for both local and remote pyvenv sessions."
    (when default-directory
      (setenv "WORKON_HOME"
              (if (file-remote-p default-directory)
                  (concat (file-remote-p default-directory) "~/.virtualenvs")
                "~/.virtualenvs"))))
  (advice-add #'pyvenv-workon-home :before #'tramp-conda-setup))

(use-package jupyter)

(use-package processing-mode
  :custom
  (processing-location "/usr/local/bin/processing-java")
  (processing-application-dir "/Applications/Processing.app")
  (processing-sketchbook-dir "~/Documents/Processing"))

;; === TRAMP ===
(setq tramp-use-ssh-controlmaster-options nil
      tramp-verbose 6)
;; Adjust or remove this path if not using Stanford AFS
(setq exec-path (append exec-path '("/afs/.ir/users/b/i/bidiptas/bin")))

;; === File management ===
(use-package dired
  :ensure nil  ; built-in
  :config
  (when (and (eq system-type 'darwin) (executable-find "gls"))
    (setq insert-directory-program "gls"))
  (setq dired-listing-switches "-l --almost-all --human-readable --group-directories-first --no-group")
  (put 'dired-find-alternate-file 'disabled nil))

(use-package dired-rainbow
  :after dired
  :config
  (dired-rainbow-define-chmod directory      "#6cb2eb" "d.*")
  (dired-rainbow-define       symlink        "#f6d860" "l.*")
  (dired-rainbow-define       image          "#b5bd68" ("jpg" "jpeg" "png" "gif" "svg" "webp" "bmp" "tiff" "ico"))
  (dired-rainbow-define       media          "#de935f" ("mp3" "mp4" "mkv" "avi" "mov" "flac" "ogg" "wav" "m4a"))
  (dired-rainbow-define       document       "#cc99cc" ("pdf" "doc" "docx" "odt" "tex" "md" "rst" "org"))
  (dired-rainbow-define       sourcefile     "#f6993f" ("py" "el" "js" "ts" "go" "rs" "c" "cpp" "h" "hpp" "sh" "bash" "zsh"))
  (dired-rainbow-define       data           "#8abeb7" ("csv" "json" "yaml" "yml" "toml" "xml" "sql" "db"))
  (dired-rainbow-define       archive        "#cc6666" ("zip" "tar" "gz" "bz2" "xz" "7z" "rar"))
  (dired-rainbow-define-chmod executable-unix "#a3be8c" "-.*x.*"))

(use-package dirvish
  :init (dirvish-override-dired-mode)
  :custom
  (dirvish-mode-line-format '(:left (sort symlink) :right (omit yank index)))
  (dirvish-attributes        '(vc-state subtree-state collapse git-msg file-time file-size))
  (dirvish-side-attributes   '(vc-state collapse file-size))
  (dirvish-large-directory-threshold 20000)
  (dired-mouse-drag-files t)
  (mouse-drag-and-drop-region-cross-program t)
  (mouse-1-click-follows-link nil)
  :config
  (dirvish-peek-mode)
  (dirvish-side-follow-mode)
  (define-key dirvish-mode-map (kbd "<mouse-1>") #'dirvish-subtree-toggle-or-open)
  (define-key dirvish-mode-map (kbd "<mouse-2>") #'dired-mouse-find-file-other-window)
  (define-key dirvish-mode-map (kbd "<mouse-3>") #'dired-mouse-find-file)
  (define-key dirvish-mode-map (kbd "P")
    (lambda () (interactive)
      (start-process "mpv" nil "mpv" (dired-get-file-for-visit))))
  :bind
  (("C-c f" . dirvish)
   ("C-c s" . dirvish-side)
   ("C-c F" . dirvish-fd)
   :map dirvish-mode-map
   (";"   . dired-up-directory)
   ("^"   . dired-up-directory)
   ("?"   . dirvish-dispatch)
   ("a"   . dirvish-setup-menu)
   ("f"   . dirvish-file-info-menu)
   ("o"   . dirvish-quick-access)
   ("s"   . dirvish-quicksort)
   ("r"   . dirvish-history-jump)
   ("l"   . dirvish-ls-switches-menu)
   ("v"   . dirvish-vc-menu)
   ("*"   . dirvish-mark-menu)
   ("y"   . dirvish-yank-menu)
   ("N"   . dirvish-narrow)
   ("H"   . dirvish-history-last)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ("M-e" . dirvish-emerge-menu)))

;; === Icons ===
(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-icon t)
  (doom-modeline-time t)
  (doom-modeline-battery t)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-vcs-max-length 15)
  (doom-modeline-checker-simple-format nil))

;; === Git ===
(use-package magit)

;; === Terminal & shell ===
;; inheritenv propagates buffer-local env vars (e.g. WORKON_HOME) into vterm
(use-package inheritenv)

(use-package vterm :defer t)

;; Ensure Emacs inherits $PATH from the shell (needed for claude, conda, etc.)
(use-package exec-path-from-shell
  :config (exec-path-from-shell-initialize))

;; === Claude Code ===
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config (claude-code-ide-emacs-tools-setup))

(setq claude-code-ide-terminal-backend 'vterm)

(message (emacs-init-time))

(provide 'init)
;;; init.el ends here
