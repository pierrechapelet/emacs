;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Personal config: doom-one-light theme, completion stack (vertico/corfu/embark),
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
;; (use-package atom-one-dark-theme
;;   :config (load-theme 'atom-one-dark t))
;; (load-theme 'modus-operandi-tinted t)
(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-one-light t)
  (doom-themes-org-config))

(set-face-attribute 'default nil :height 130)

;; Automatically switch between windowed (130) and fullscreen (160) font height.
;; Hooked on window-size-change-functions so it reacts to C-s-f (toggle-frame-fullscreen).
(defvar my/windowed-font-height 130)
(defvar my/fullscreen-font-height 160)

(defun my/apply-font-for-frame (&optional frame)
  (let* ((frame     (or frame (selected-frame)))
         (fullscreen (frame-parameter frame 'fullscreen))
         (height    (if (memq fullscreen '(fullscreen fullboth))
                        my/fullscreen-font-height
                      my/windowed-font-height)))
    (set-face-attribute 'default frame :height height)))

(add-hook 'window-size-change-functions #'my/apply-font-for-frame)

(setq inhibit-startup-message t
      column-number-mode t
      split-height-threshold nil       ; always split side-by-side
      split-width-threshold 0          ; always split side-by-side
      use-short-answers t
      make-backup-files nil            ; rely on git instead
      history-length 50                ; minibuffer / savehist depth
      global-auto-revert-non-file-buffers t
      completion-cycle-threshold 3)

(global-superword-mode t)       ; treat CamelCase/snake_case as single words
(delete-selection-mode t)
(electric-pair-mode t)          ; auto-close brackets and quotes
(tab-bar-mode 1)                ; named workspaces per project/context
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
      mac-right-option-modifier nil)

(when (eq system-type 'darwin)
  (setq dired-use-ls-dired nil)
  (setq tooltip-use-echo-area t))

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
;; vertico: minibuffer UI  |  corfu: inline popup  |  orderless: fuzzy matching
;; marginalia: annotations  |  embark: context actions  |  consult: enhanced commands
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
;; C-c o h: fuzzy heading search  |  C-c o c/r: country/region pickers  |  C-c o l: insert heading link
(require 'org-geo-data (expand-file-name "org-geo-data.el" user-emacs-directory))

(defun my/org-set-countries ()
  "Set :COUNTRIES: on current heading via multi-select from UN ISO list."
  (interactive)
  (let* ((current (org-entry-get nil "COUNTRIES"))
         (initial (when (and current (> (length current) 0))
                    (mapconcat #'identity (split-string current) ", ")))
         (selected (completing-read-multiple "Countries: " my/un-countries nil t initial))
         (value    (mapconcat #'identity selected " ")))
    (org-set-property "COUNTRIES" value)))

(defun my/org-set-region ()
  "Set :REGION: property and sync the geographic heading tag for agenda filtering."
  (interactive)
  (let* ((current  (or (org-entry-get nil "REGION") ""))
         (selected (completing-read "Region: " my/unesco-regions nil t current)))
    (org-set-property "REGION" selected)
    (dolist (r my/unesco-regions) (org-toggle-tag r 'off))
    (org-toggle-tag selected 'on)))

(defun my/org-property-picker-advice (orig property &optional value)
  (cond
   ((and (equal property "COUNTRIES") (null value)) (my/org-set-countries))
   ((and (equal property "REGION")    (null value)) (my/org-set-region))
   (t (funcall orig property value))))

(advice-add 'org-set-property :around #'my/org-property-picker-advice)

(defun my/consult-org-all-headings ()
  "Fuzzy search headings across all GTD/UNESCO org files (agenda + reference/someday/contacts)."
  (interactive)
  (let ((org-agenda-files
         (append (org-agenda-files)
                 (mapcar #'expand-file-name
                         '("~/ORG/reference.org"
                           "~/ORG/someday.org"
                           "~/ORG/contacts.org")))))
    (minibuffer-with-setup-hook
        (lambda ()
          ;; Neutralise org heading height scaling so candidates render at
          ;; base font size rather than 1.4×/1.25×/1.1× in the picker.
          (let ((cookies (list (face-remap-add-relative 'org-level-1 :height (/ 1.0 1.4))
                               (face-remap-add-relative 'org-level-2 :height (/ 1.0 1.25))
                               (face-remap-add-relative 'org-level-3 :height (/ 1.0 1.1)))))
            (add-hook 'minibuffer-exit-hook
                      (lambda () (mapc #'face-remap-remove-relative cookies))
                      nil t)))
      (consult-org-heading nil 'agenda))))

(defun my/org-insert-heading-link ()
  "Pick any org heading via the refile UI and insert an org link at point."
  (interactive)
  (let* ((orig-buf   (current-buffer))
         (orig-point (point))
         (loc        (org-refile-get-location "Insert link to"))
         (file       (nth 1 loc))
         (pos        (nth 3 loc))
         link desc)
    (with-current-buffer (find-file-noselect file 'nowarn)
      (org-with-wide-buffer
       (goto-char pos)
       (org-back-to-heading t)
       (setq link (org-store-link nil nil))
       (setq desc (plist-get org-store-link-plist :description))))
    (with-current-buffer orig-buf
      (goto-char orig-point)
      (org-insert-link nil link desc))))

(use-package org
  :ensure nil
  :bind (("C-c c"   . org-capture)
         ("C-c a"   . org-agenda)
         ("C-c o h" . my/consult-org-all-headings)
         ("C-c o c" . my/org-set-countries)
         ("C-c o r" . my/org-set-region)
         ("C-c o l" . my/org-insert-heading-link))
  :config
  (setq org-directory "~/ORG/"
        org-agenda-files '("~/ORG/inbox.org"
                           "~/ORG/gtd.org"
                           "~/ORG/areas.org"
                           "~/ORG/tickler.org"
                           "~/ORG/projects.org"
                           "~/ORG/opportunities.org"))

  ;; Three sequences cover the full GTD+CRM workflow:
  ;;   1. ACTIVE/HOLD  — projects (long-running, pause-able)
  ;;   2. TODO/NEXT/WAITING — standard task pipeline
  ;;   3. LEAD→NEGOTIATION — opportunity pipeline (mirrors a sales funnel)
  (setq org-todo-keywords
        '((sequence "ACTIVE(a)" "HOLD(h@)" "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence "LEAD(l)" "QUALIFIED(q)" "PROPOSAL(s)" "NEGOTIATION(n)" "|" "WON(w!)" "LOST(L@)")))

  (setq org-todo-keyword-faces
        '(("TODO"        . (:foreground "orange"   :weight bold))
          ("NEXT"        . (:foreground "cyan"     :weight bold))
          ("WAITING"     . (:foreground "magenta"  :weight bold))
          ("ACTIVE"      . (:foreground "#00ff5f"  :weight bold))
          ("HOLD"        . (:foreground "yellow"   :weight bold))
          ("CANCELLED"   . (:foreground "gray"     :weight bold))
          ("LEAD"        . (:foreground "#d4b483"  :weight bold))
          ("QUALIFIED"   . (:foreground "#5fafff"  :weight bold))
          ("PROPOSAL"    . (:foreground "#ff8c00"  :weight bold))
          ("NEGOTIATION" . (:foreground "#df80ff"  :weight bold))
          ("WON"         . (:foreground "#00d700"  :weight bold))
          ("LOST"        . (:foreground "gray"     :weight bold))))

  (setq org-capture-templates
        '(;; --- GTD ---
          ("i" "Inbox" entry (file "~/ORG/inbox.org")
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
          ("t" "Tickler" entry (file "~/ORG/tickler.org")
           "* TODO %?\nSCHEDULED: %^t\n")
          ;; --- UNESCO project management ---
          ("p" "UNESCO Project" entry (file+headline "~/ORG/projects.org" "Projects")
           "* ACTIVE %^{Project title}  :PROJECT:\n  :PROPERTIES:\n  :REGION:    \n  :COUNTRIES: \n  :TYPE:      Global/Regional/Country\n  :PARTNER:   \n  :END:\n  %U\n\n*** TODO [first next action]\n")
          ("n" "Reference Note" entry (file "~/ORG/reference.org")
           "* %?\n  %U\n  %a")
          ("o" "Opportunity" entry (file+headline "~/ORG/opportunities.org" "Pipeline")
           "* LEAD %^{Opportunity title}  :Opportunity:\n  :PROPERTIES:\n  :STAGE:    Lead\n  :REGION:   \n  :COUNTRIES: \n  :CONTACT:  \n  :VALUE:    \n  :CLOSE:    %^t\n  :SOURCE:   \n  :END:\n  %U\n\n*** TODO [next action]\n")
          ("m" "Meeting Note" entry (file+headline "~/ORG/meetings.org" "Meetings")
           "* %<%Y-%m-%d> %^{Meeting title}  :Meeting:\n  :PROPERTIES:\n  :ATTENDEES: %^{Attendees — names, comma-separated (e.g. Alice, Bob)}\n  :PROJECT:   \n  :REGION:    \n  :COUNTRIES: \n  :END:\n  %T\n\n** Notes\n   %?\n\n** Action Items\n"
           :empty-lines 1)
          ;; --- CRM ---
          ("C" "Contact" entry (file+headline "~/ORG/contacts.org" "Contacts")
           "* %^{Name — full name}\n  :PROPERTIES:\n  :EMAIL:    \n  :PHONE:    \n  :ORG:      \n  :ROLE:     \n  :REGION:   \n  :LAST_CONTACT: %U\n  :END:\n")))

  (setq org-refile-targets
        '(("~/ORG/gtd.org"            :maxlevel . 2)
          ("~/ORG/projects.org"       :maxlevel . 3)
          ("~/ORG/opportunities.org"  :maxlevel . 2)
          ("~/ORG/areas.org"          :maxlevel . 3)
          ("~/ORG/contacts.org"       :maxlevel . 2)
          ("~/ORG/reference.org"      :maxlevel . 2)
          ("~/ORG/someday.org"        :level    . 1)
          ("~/ORG/tickler.org"        :maxlevel . 2)
          ("~/ORG/meetings.org"       :maxlevel . 3)))
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
                        ("Opportunity"  . ?O)
                        ("Meeting"      . ?M)
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

  (setq org-archive-location      "~/ORG/archive.org::* From %s"
        org-deadline-warning-days 21
        org-agenda-window-setup   'current-window
        org-log-done              'time
        org-log-into-drawer       t
        org-use-fast-todo-selection t
        org-startup-indented      t
        org-return-follows-link   t)

  (setq org-agenda-custom-commands
        '(;; Daily driver: today's agenda + NEXT actions + WAITING + stuck + inbox
          ("g" "GTD Dashboard"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Actions")
                   (org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))
                   (org-super-agenda-groups
                    '((:name "UNESCO Projects" :file-path "projects\\.org")
                      (:name "Opportunities"   :file-path "opportunities\\.org")
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

          ;; Context dispatch: pick tasks by physical location tag
          ("c" "By Context"
           ((tags-todo "@computer" ((org-agenda-overriding-header "@computer")))
            (tags-todo "@phone"    ((org-agenda-overriding-header "@phone")))
            (tags-todo "@home"     ((org-agenda-overriding-header "@home")))
            (tags-todo "@errands"  ((org-agenda-overriding-header "@errands")))
            (tags-todo "@office"   ((org-agenda-overriding-header "@office")))))

          ;; Weekly review checklist: 7-day agenda, HOLD items, deadlines, stuck, inbox
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

          ;; 30-day deadline horizon
          ("d" "Upcoming Deadlines"
           agenda ""
           ((org-agenda-span 30)
            (org-agenda-entry-types '(:deadline))
            (org-agenda-overriding-header "Deadlines — next 30 days")))

          ;; All HOLD items — reassess or reactivate during weekly review
          ("H" "On Hold"
           todo "HOLD"
           ((org-agenda-overriding-header "Projects on Hold — reassess or reactivate")))

          ;; UNESCO project views: "us" all active, "u<region>" filtered by region, "uT" all tasks
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
             '((:auto-parent t)))))

          ;; Opportunity pipeline views: "op" full pipeline by stage, "ow" won, "oT" follow-up tasks
          ("o" . "Opportunities")
          ("op" "Full Pipeline" todo "LEAD|QUALIFIED|PROPOSAL|NEGOTIATION"
           ((org-agenda-files '("~/ORG/opportunities.org"))
            (org-agenda-overriding-header "Opportunity Pipeline")
            (org-super-agenda-groups
             '((:name "Lead"        :todo "LEAD")
               (:name "Qualified"   :todo "QUALIFIED")
               (:name "Proposal"    :todo "PROPOSAL")
               (:name "Negotiation" :todo "NEGOTIATION")
               (:name "Other"       :anything t)))))
          ("ow" "Won" todo "WON"
           ((org-agenda-files '("~/ORG/opportunities.org"))
            (org-agenda-overriding-header "Won Opportunities")))
          ("oT" "Follow-up Tasks" todo "TODO|NEXT|WAITING"
           ((org-agenda-files '("~/ORG/opportunities.org"))
            (org-agenda-overriding-header "Opportunity Follow-up Tasks")
            (org-super-agenda-groups '((:auto-parent t)))))

          ;; Meeting action items — refile TODO/NEXT to destination files after each meeting
          ("m" . "Meetings")
          ("mt" "Unprocessed Meeting Actions" todo "TODO|NEXT|WAITING"
           ((org-agenda-files '("~/ORG/meetings.org"))
            (org-agenda-overriding-header "Meeting Action Items — refile to destination files")
            (org-super-agenda-groups '((:auto-parent t))))))))

;; Org heading hierarchy — scaled for visual depth
(set-face-attribute 'org-level-1 nil :height 1.4  :weight 'bold)
(set-face-attribute 'org-level-2 nil :height 1.25 :weight 'bold)
(set-face-attribute 'org-level-3 nil :height 1.1  :weight 'semi-bold)
(set-face-attribute 'org-level-4 nil :height 1.0  :weight 'normal)

;; Groups agenda blocks by custom rules (used in GTD/UNESCO/pipeline views above)
(use-package org-super-agenda
  :after org
  :config (org-super-agenda-mode))

;; Links contacts.org to mu4e compose auto-complete
(use-package org-contacts
  :after org
  :custom (org-contacts-files '("~/ORG/contacts.org")))

;; Replaces asterisks/checkboxes/tags with styled Unicode glyphs
(use-package org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-star '("◉" "○" "◆" "◇" "▷")))

;; Reveals hidden markup (links, emphasis markers) only when cursor is inside
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autoentities t)
  (org-appear-autosubmarkers t))

;; Required for syntax-highlighted HTML export from org-mode src blocks
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

;; pylsp-ruff: fast formatter/linter  |  pylsp-mypy: type-checker  |  clangd for C++
(setq-default eglot-workspace-configuration
              '(:pylsp (:skip_token_initialization t
                        :plugins (:ruff       (:enabled t :formatEnabled t)
                                  :pylsp_mypy (:enabled t)))))

(add-to-list 'auto-mode-alist '("\\.cu\\'" . c++-mode))  ; CUDA files → clangd via c++-mode
(add-hook 'c++-mode-hook #'eglot-ensure)

;; pyvenv reads WORKON_HOME to discover virtualenvs.  On remote buffers via
;; TRAMP the var is unset, so pyvenv would fall back to the local home path.
;; This advice injects the correct remote prefix before every workon call.
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
;; ssh-controlmaster conflicts with TRAMP's own multiplexing; disabling it
;; prevents hangs on slow or multi-hop SSH connections.
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

;; Color-code files by type: directories → blue, symlinks → yellow, images → pink,
;; media → orange, documents → purple, source → green, data → teal, archives → red.
(use-package dired-rainbow
  :after dired
  :config
  (dired-rainbow-define-chmod directory      "#1e66f5" "d.*")
  (dired-rainbow-define       symlink        "#df8e1d" "l.*")
  (dired-rainbow-define       image          "#ea76cb" ("jpg" "jpeg" "png" "gif" "svg" "webp" "bmp" "tiff" "ico"))
  (dired-rainbow-define       media          "#fe640b" ("mp3" "mp4" "mkv" "avi" "mov" "flac" "ogg" "wav" "m4a"))
  (dired-rainbow-define       document       "#8839ef" ("pdf" "doc" "docx" "odt" "tex" "md" "rst" "org"))
  (dired-rainbow-define       sourcefile     "#40a02b" ("py" "el" "js" "ts" "go" "rs" "c" "cpp" "h" "hpp" "sh" "bash" "zsh"))
  (dired-rainbow-define       data           "#179299" ("csv" "json" "yaml" "yml" "toml" "xml" "sql" "db"))
  (dired-rainbow-define       archive        "#d20f39" ("zip" "tar" "gz" "bz2" "xz" "7z" "rar"))
  (dired-rainbow-define-chmod executable-unix "#04a5e5" "-.*x.*"))

;; === Icons ===
(use-package nerd-icons)

(use-package dirvish
  :init (dirvish-override-dired-mode 1)
  :custom
  (dirvish-mode-line-format '(:left (sort symlink) :right (omit yank index)))
  (dirvish-attributes        '(nerd-icons vc-state subtree-state collapse git-msg file-modes file-time file-size))
  (dirvish-side-attributes   '(nerd-icons vc-state collapse file-size))
  (dirvish-default-layout    '(1 0.11 0.55))
  (dirvish-layout-recipes    '((0 0 0.4) (1 0.11 0.55)))
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
   ("M-e" . dirvish-emerge-menu)
   ("\\"  . dirvish-layout-switch)))


;; doom-modeline: shows git branch, LSP status, time, and battery in a compact bar.
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
