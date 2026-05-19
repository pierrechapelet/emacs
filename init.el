;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Personal config: atom-one-dark theme, completion stack (vertico/corfu/embark),
;; Python/C++/LaTeX/Org support, Dirvish file manager, Claude Code integration.

;;; Code:

;; Load personal identifiers (gitignored — copy personal.el.example if missing)
(load (expand-file-name "personal.el" user-emacs-directory) t)

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

(set-face-attribute 'default nil :height 130)

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
                                (shell  . t)
                                (R      . t)
                                (sql    . t)))

;; === GTD / Org ===
(use-package org
  :ensure nil
  :bind (("C-c c"   . org-capture)
         ("C-c a"   . org-agenda)
         ("C-c o h" . consult-org-heading))
  :config
  (setq org-directory "~/ORG/"
        org-agenda-files '("~/ORG/inbox.org"
                           "~/ORG/gtd.org"
                           "~/ORG/areas.org"
                           "~/ORG/tickler.org"
                           "~/ORG/projects.org"))

  (setq org-todo-keywords
        '((sequence "ACTIVE(a)" "HOLD(h@)" "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")))

  (setq org-todo-keyword-faces
        '(("TODO"      . (:foreground "orange"   :weight bold))
          ("NEXT"      . (:foreground "cyan"     :weight bold))
          ("WAITING"   . (:foreground "magenta"  :weight bold))
          ("ACTIVE"    . (:foreground "#00ff5f"  :weight bold))
          ("HOLD"      . (:foreground "yellow"   :weight bold))
          ("CANCELLED" . (:foreground "gray"     :weight bold))))

  (setq org-capture-templates
        '(("i" "Inbox" entry (file "~/ORG/inbox.org")
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
          ("t" "Tickler" entry (file "~/ORG/tickler.org")
           "* TODO %?\nSCHEDULED: %^t\n")
          ("p" "UNESCO Project" entry (file+headline "~/ORG/projects.org" "Projects")
           "* ACTIVE %?  :PROJECT:\n  :PROPERTIES:\n  :REGION:    \n  :COUNTRIES: \n  :TYPE:      Global/Regional/Country\n  :PARTNER:   \n  :END:\n  %U\n\n*** TODO [first next action]\n")
          ("n" "Reference Note" entry (file "~/ORG/reference.org")
           "* %?\n  %U\n  %a")))

  (setq org-refile-targets
        '(("~/ORG/gtd.org"       :maxlevel . 2)
          ("~/ORG/projects.org"  :maxlevel . 3)
          ("~/ORG/areas.org"     :maxlevel . 3)
          ("~/ORG/reference.org" :maxlevel . 2)
          ("~/ORG/someday.org"   :level    . 1)
          ("~/ORG/tickler.org"   :maxlevel . 2)))
  (setq org-refile-use-outline-path        'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)

  (setq org-tag-alist '(("@computer"    . ?c)
                        ("@phone"       . ?p)
                        ("@home"        . ?h)
                        ("@errands"     . ?e)
                        ("@office"      . ?o)
                        (:newline)
                        ("PROJECT"      . ?P)
                        (:newline)
                        ("Global"       . ?G)
                        ("Africa"       . ?A)
                        ("AsiaPacific"  . ?X)
                        ("Europe"       . ?E)
                        ("LatinAmerica" . ?L)
                        ("ArabStates"   . ?B)))

  ;; Stuck = PROJECT-tagged heading with no NEXT child
  (setq org-stuck-projects
        '("+PROJECT/-DONE-CANCELLED" ("NEXT") nil ""))

  (setq org-archive-location     "~/ORG/archive.org::* From %s"
        org-deadline-warning-days 21
        org-agenda-window-setup  'current-window
        org-log-done              'time
        org-log-into-drawer       t
        org-use-fast-todo-selection t)

  (setq org-agenda-custom-commands
        '(("g" "GTD Dashboard"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Actions")
                   (org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))
                   (org-super-agenda-groups
                    '((:name "UNESCO Projects" :file-path "projects\\.org")
                      (:name "Areas"           :file-path "areas\\.org")
                      (:name "Personal"        :file-path "gtd\\.org")
                      (:discard (:anything t))))))
            (todo "WAITING"
                  ((org-agenda-overriding-header "Waiting For")))
            (stuck ""
                   ((org-agenda-overriding-header "Stuck Projects")))
            (todo "TODO"
                  ((org-agenda-overriding-header "Inbox (unprocessed)")
                   (org-agenda-files '("~/ORG/inbox.org"))))))

          ("c" "By Context"
           ((tags-todo "@computer" ((org-agenda-overriding-header "@computer")))
            (tags-todo "@phone"    ((org-agenda-overriding-header "@phone")))
            (tags-todo "@home"     ((org-agenda-overriding-header "@home")))
            (tags-todo "@errands"  ((org-agenda-overriding-header "@errands")))
            (tags-todo "@office"   ((org-agenda-overriding-header "@office")))))

          ("r" "Weekly Review"
           ((agenda "" ((org-agenda-span 7)))
            (todo "HOLD"
                  ((org-agenda-overriding-header "On Hold — reassess or reactivate")))
            (agenda "" ((org-agenda-span 14)
                        (org-agenda-entry-types '(:deadline))
                        (org-agenda-overriding-header "Deadlines — next 14 days")))
            (stuck "")
            (todo "WAITING" ((org-agenda-overriding-header "Waiting For")))
            (todo "TODO"
                  ((org-agenda-overriding-header "Inbox to process")
                   (org-agenda-files '("~/ORG/inbox.org"))))))

          ("d" "Upcoming Deadlines"
           agenda ""
           ((org-agenda-span 30)
            (org-agenda-entry-types '(:deadline))
            (org-agenda-overriding-header "Deadlines — next 30 days")))

          ("H" "On Hold"
           todo "HOLD"
           ((org-agenda-overriding-header "Projects on Hold — reassess or reactivate")))

          ;; UNESCO project views (all scoped to projects.org)
          ("u" . "UNESCO Projects")
          ("us" "All Active Projects" todo "ACTIVE"
           ((org-agenda-files '("~/ORG/projects.org"))
            (org-agenda-overriding-header "UNESCO Projects by Region")
            (org-super-agenda-groups
             '((:name "Global"        :tag "Global")
               (:name "Africa"        :tag "Africa")
               (:name "Arab States"   :tag "ArabStates")
               (:name "Asia-Pacific"  :tag "AsiaPacific")
               (:name "Europe"        :tag "Europe")
               (:name "Latin America" :tag "LatinAmerica")
               (:name "Other"         :anything t)))))
          ("ug" "Global" tags "+Global+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("ua" "Africa" tags "+Africa+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("ub" "Arab States" tags "+ArabStates+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("ux" "Asia-Pacific" tags "+AsiaPacific+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("ue" "Europe" tags "+Europe+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("ul" "Latin America & Caribbean" tags "+LatinAmerica+PROJECT"
           ((org-agenda-files '("~/ORG/projects.org"))))
          ("uT" "All UNESCO Tasks" todo "TODO|NEXT|WAITING"
           ((org-agenda-files '("~/ORG/projects.org"))
            (org-agenda-overriding-header "UNESCO Tasks by Project")
            (org-super-agenda-groups
             '((:auto-parent t))))))))

(use-package org-super-agenda
  :after org
  :config (org-super-agenda-mode))

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

;; === Email (mu4e) ===
(use-package mu4e
  :ensure nil
  :load-path "/usr/local/share/emacs/site-lisp/mu/mu4e"
  :bind ("C-c m" . mu4e)
  :config
  (setq mu4e-maildir          "~/Maildir"
        mu4e-get-mail-command "mbsync -a"
        mu4e-update-interval  300
        mu4e-view-show-addresses    t
        mu4e-compose-dont-reply-to-self t
        mu4e-confirm-quit           nil
        message-kill-buffer-on-exit t
        mu4e-use-fancy-chars        t
        mu4e-attachment-dir        "~/Downloads")

  ;; SMTP via macOS Keychain
  (require 'smtpmail)
  (setq message-send-mail-function 'smtpmail-send-it
        auth-sources '(macos-keychain-internet macos-keychain-generic))

  (setq mu4e-contexts
        (list
         (make-mu4e-context
          :name "Gmail"
          :match-func (lambda (msg)
                        (when msg
                          (string-prefix-p "/gmail"
                            (mu4e-message-field msg :maildir))))
          :vars `((user-mail-address       . ,my/gmail-address)
                  (user-full-name          . ,my/full-name)
                  (mu4e-inbox-folder       . "/gmail/INBOX")
                  (mu4e-sent-folder        . "/gmail/[Gmail]/Sent Mail")
                  (mu4e-drafts-folder      . "/gmail/[Gmail]/Drafts")
                  (mu4e-trash-folder       . "/gmail/[Gmail]/Trash")
                  (mu4e-refile-folder      . "/gmail/INBOX")
                  (smtpmail-smtp-server    . "smtp.gmail.com")
                  (smtpmail-smtp-service   . 587)
                  (smtpmail-stream-type    . starttls)))
         (make-mu4e-context
          :name "Proton"
          :match-func (lambda (msg)
                        (when msg
                          (string-prefix-p "/proton"
                            (mu4e-message-field msg :maildir))))
          :vars `((user-mail-address       . ,my/proton-address)
                  (user-full-name          . ,my/full-name)
                  (mu4e-inbox-folder       . "/proton/INBOX")
                  (mu4e-sent-folder        . "/proton/Sent")
                  (mu4e-drafts-folder      . "/proton/Drafts")
                  (mu4e-trash-folder       . "/proton/Trash")
                  (mu4e-refile-folder      . "/proton/Archive")
                  (smtpmail-smtp-server    . "127.0.0.1")
                  (smtpmail-smtp-service   . 1025)
                  (smtpmail-stream-type    . ssl)))))

  (setq mu4e-context-policy         'pick-first
        mu4e-compose-context-policy 'ask-if-none))

(message (emacs-init-time))

(provide 'init)
;;; init.el ends here
