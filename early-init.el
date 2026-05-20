
;;; early-init.el --- Early initialization

;;; Commentary:
;; Runs before package.el and the GUI are initialized.  Two goals:
;;   1. Speed — defer GC during loading; restore a sane threshold after.
;;   2. No flicker — suppress UI chrome (toolbar, scrollbars) before the
;;      first frame is drawn so they are never painted then hidden.
;;

;;; Code:

;; Maximize GC threshold during startup to avoid collections mid-load,
;; then restore a sensible limit (16 MB) once Emacs is ready.
(setq gc-cons-threshold most-positive-fixnum
	gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
	    (lambda ()
	      (setq gc-cons-threshold 16777216
		    gc-cons-percentage 0.1)))

;; Also suppress GC while the minibuffer is active — completions generate
;; a lot of short-lived objects and a collection here causes noticeable lag.
(defun doom-defer-garbage-collection-h ()
  "Set GC threshold to max while minibuffer is active."
  (setq gc-cons-threshold most-positive-fixnum))

(defun doom-restore-garbage-collection-h ()
  "Restore normal GC threshold 1 s after minibuffer exits."
  (run-at-time
   1 nil (lambda () (setq gc-cons-threshold 16777216))))

(add-hook 'minibuffer-setup-hook #'doom-defer-garbage-collection-h)
(add-hook 'minibuffer-exit-hook #'doom-restore-garbage-collection-h)

;; package.el is initialized explicitly in init.el; skip the duplicate call here.
(setq package-enable-at-startup nil)

;; Prevent an extra resize event (and redraw) when fonts or frame parameters
;; change during init — Emacs would otherwise resize to fit the new metrics.
(setq frame-inhibit-implied-resize t)

;; Set frame appearance before the first frame is drawn to avoid flicker.
(push '(tool-bar-lines . 0) default-frame-alist)       ; no toolbar
(push '(vertical-scroll-bars) default-frame-alist)     ; no scrollbar
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist)) ; macOS: titlebar blends with theme
(push '(width . 0.5) default-frame-alist)              ; start at 50% screen width
(push '(height . 0.5) default-frame-alist)             ; start at 50% screen height

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; early-init.el ends here
