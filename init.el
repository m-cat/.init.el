;;; init.el --- Emacs configuration file. -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2017-2019 Marcin Swieczkowski
;;
;;; Commentary:
;;
;; Requires Emacs 26 or higher.
;;
;; Making changes / testing:
;;
;; - Use M-x free-keys to find unused keybindings.
;; - Use M-x bug-hunter-init-file to locate errors.
;; - Use M-x esup to profile startup time,
;;   M-x profiler-start and profiler-report to profile runtime.
;; - Use restart-emacs to restart after making changes.

;;; Code:

;; Show more error info.
;; (setq debug-on-error t)

;; First things first, increase GC threshold to speed up startup.
;; Reset the GC threshold after initialization, and GC whenever we tab out.
(setq gc-cons-threshold (* 64 1000 1000))
(add-hook 'after-init-hook #'(lambda ()
                               (setq gc-cons-threshold (* 32 1000 1000))))
(add-hook 'focus-out-hook 'garbage-collect)
(run-with-idle-timer 5 t 'garbage-collect)

;;; User-Defined Variables

(defvar user-text-directory "~/Text/")
(defvar user-scratchpad-path (concat user-text-directory "scratchpad.txt"))
;; Symlink in my home directory.
(defvar user-org-directory (concat user-text-directory "org/"))

(defvar user-ideas-org (concat user-org-directory "ideas.org"))
(defvar user-notes-org (concat user-org-directory "notes.org"))
(defvar user-physical-org (concat user-org-directory "physical.org"))
(defvar user-projects-org (concat user-org-directory "notes.org"))
(defvar user-todo-org (concat user-org-directory "todo.org"))
(defvar user-work-org (concat user-org-directory "work.org"))

(defvar highlight-delay .03)
(defvar info-delay .25)

;; Open .emacs init.
(defun open-init-file ()
  "Open the init file."
  (interactive)
  (find-file user-init-file))

(global-set-key (kbd "C-c i") 'open-init-file)

;; Open scratchpad.txt.
(defun open-scratchpad-file ()
  "Open scratchpad file."
  (interactive)
  (find-file user-scratchpad-path))

(global-set-key (kbd "C-c s") 'open-scratchpad-file)

;;; Package settings

(require 'package)
;; Prefer the newest version of a package.
(setq load-prefer-newer t)
;; Only enable packages found in this file (not all installed packages).
(setq package-enable-at-startup nil)
;; Add package sources.
(unless (assoc-default "melpa" package-archives)
  (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t))

;; Run auto-load functions specified by package authors.
(package-initialize)

;; Require use-package.
(when (not (package-installed-p 'use-package))
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
;; Always install missing packages.
(setq use-package-always-ensure t)

;; Keep directories clean.
;; Should be one of the first things loaded.
(use-package no-littering
  :config
  (require 'recentf)

  (defvar recentf-exclude)
  (add-to-list 'recentf-exclude no-littering-var-directory)
  (add-to-list 'recentf-exclude no-littering-etc-directory)
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  )

;; Inherit environment variables from Shell.
(when (memq window-system '(mac ns x))
  (use-package exec-path-from-shell
    :config
    (exec-path-from-shell-initialize)
    ))

;; Enable restarting Emacs from within Emacs.
(use-package restart-emacs
  :defer t)

;; Find bugs in Emacs configuration.
(use-package bug-hunter
  :defer t)

;;; Helm

(use-package helm
  :bind (
         ("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-h C-a" . helm-apropos)
         ("M-i" . helm-semantic-or-imenu)

         :map helm-map

         ;; Rebind tab to run persistent action.
         ("<tab>" . helm-execute-persistent-action)
         ;; Alternate TAB key that works in terminal.
         ("C-i" . helm-execute-persistent-action)
         ("C-z" . helm-select-action) ;; List actions using C-z.
         ("M-x" . helm-select-action)

         :map minibuffer-local-isearch-map

         ;; No reason, and annoying, to bring up `helm-minibuffer-history' here.
         ("C-r" . isearch-reverse-exit-minibuffer)

         :map minibuffer-local-map

         ;; See above.
         ("C-r" . isearch-reverse-exit-minibuffer)
         )
  :init
  (require 'helm-config)
  :config
  (helm-mode t)

  ;; Set better keys to select helm candidates.
  (dotimes (i 10)
    (let ((key (format "s-%d" i))
          (fn (lambda () (interactive) (helm-execute-selection-action-at-nth i))))
      (define-key helm-map (kbd key) fn)
      ))

  (defvar helm-buffers-fuzzy-matching)
  (defvar helm-recentf-fuzzy-match)
  (defvar helm-apropos-fuzzy-match)
  (defvar helm-semantic-fuzzy-match)
  (defvar helm-imenu-fuzzy-match)
  (setq helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-apropos-fuzzy-match t
        helm-semantic-fuzzy-match t
        helm-imenu-fuzzy-match t)

  (defvar helm-ff-search-library-in-sexp)
  (defvar helm-ff-file-name-history-use-recentf)
  (setq
   ;; Open helm buffer inside current window?
   helm-split-window-inside-p t
   ;; Move to end or beginning of source when reaching top/bottom of source.
   helm-move-to-line-cycle-in-source t
   ;; Search for library in `use-package' and `declare-function' sexp.
   helm-ff-search-library-in-sexp t
   ;; Scroll 8 lines other window using M-<next>/M-<prior>.
   helm-scroll-amount 8
   helm-ff-file-name-history-use-recentf t
   helm-display-header-line nil
   helm-follow-mode-persistent t
   ;; How long to wait before executing helm-follow persistent action.
   helm-follow-input-idle-delay highlight-delay
   ;; Allow using the mouse to select candidates!
   helm-allow-mouse t
   )

  (defvar helm-buffers-column-separator)
  (setq helm-buffers-column-separator "  ")

  (defvar helm-mini-default-sources)
  (setq helm-mini-default-sources '(helm-source-buffers-list
                                    helm-source-recentf
                                    helm-source-files-in-current-dir
                                    ))

  ;;; helm packages.

  ;; Better mode help.
  (use-package helm-describe-modes
    :bind ("C-h m" . helm-describe-modes))

  ;; helm-swoop.
  (use-package helm-swoop
    ;; To prevent bug where `helm-swoop-from-isearch' doesn't work the first time.
    :demand t
    :bind (
           ("C-;" . helm-swoop-without-pre-input)
           ("C-:" . helm-multi-swoop-all)

           :map helm-swoop-map

           ;; Move up and down like isearch
           ("C-r" . helm-previous-line)
           ("C-s" . helm-next-line)

           ;; From helm-swoop to helm-multi-swoop-all.
           ("C-;" . helm-multi-swoop-all-from-helm-swoop)

           :map helm-multi-swoop-map

           ("C-r" . helm-previous-line)
           ("C-s" . helm-next-line)

           :map isearch-mode-map

           ;; When doing isearch, hand the word over to helm-swoop.
           ("C-;" . helm-swoop-from-isearch)
           )
    :config
    (setq
     ;; Show syntax highlighting in results.
     helm-swoop-speed-or-color t
     ;; Fix line number face issue.
     helm-swoop-use-line-number-face t
     ;; Split the window vertically.
     helm-swoop-split-with-multiple-windows t
     helm-swoop-split-direction 'split-window-vertically
     )
    )
  )

;;; Load customizations

(setq custom-file (concat user-emacs-directory "customize.el"))
(load custom-file t)

;;; Quality of life changes

;; Replace yes/no prompts with y/n.
(fset 'yes-or-no-p 'y-or-n-p)

;; Track recently-opened files.
(use-package recentf
  :config
  (setq recentf-max-saved-items 5000)
  (recentf-mode t)
  )

;; Enable commands that are disabled by default.
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'scroll-left 'disabled nil)
(put 'scroll-right 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)

;; Enable show-trailing-whitespace.
(defun enable-trailing-whitespace ()
  "Turn on trailing whitespace."
  (setq show-trailing-whitespace t)
  )
(add-hook 'prog-mode-hook 'enable-trailing-whitespace)
(add-hook 'conf-mode-hook 'enable-trailing-whitespace)
(add-hook 'text-mode-hook 'enable-trailing-whitespace)

(setq-default
 indent-tabs-mode nil
 tab-width 4
 ;; HTML tab width.
 sgml-basic-offset 2
 js-indent-level 2
 fill-column 80
 ;; Highlight end of buffer?
 indicate-empty-lines t
 )

(defvar apropos-do-all)
(defvar ediff-window-setup-function)
(defvar c-default-style)
(setq
 ;; Tries to preserve last open window point when multiple buffers are open for
 ;; the same file.
 switch-to-buffer-preserve-window-point t
 select-enable-clipboard t
 select-enable-primary t
 save-interprogram-paste-before-kill t
 ;; TODO: What does this do?
 apropos-do-all t
 kill-ring-max 1000
 ;; Ensure that files end with a newline.
 require-final-newline t
 ;; Add newline at end of buffer with C-n.
 next-line-add-newlines t
 ;; Flash the frame on every error?
 visible-bell nil
 ring-bell-function 'ignore
 ;; TODO: What does this do?
 ediff-window-setup-function 'ediff-setup-windows-plain
 window-combination-resize nil
 ;; Display keystrokes immediately.
 echo-keystrokes 0.01
 ;; Disable startup screen.
 inhibit-startup-message t
 ;; Change the initial *scratch* buffer.
 initial-scratch-message ""
 ;; Focus new help windows when opened.
 help-window-select t
 ;; Always confirm before closing Emacs?
 confirm-kill-emacs nil
 ;; Send deleted files to trash.
 delete-by-moving-to-trash t
 ;; Delay for displaying function/variable information.
 eldoc-idle-delay info-delay
 ;; Fix flickering in Emacs 26 on OSX.
 recenter-redisplay nil
 ;; Follow symlinks without asking?
 vc-follow-symlinks t

 ;; Inhibit backups?
 backup-inhibited t
 ;; Make backup files when creating a file?
 make-backup-files nil
 ;; Silently delete old backup versions.
 delete-old-versions t
 ;; Auto save?
 auto-save-default nil
 ;; Create interlock files?
 create-lockfiles nil

 ;; Where should we open new buffers by default?
 display-buffer-base-action '(display-buffer-below-selected)
 ;; Specify custom behavior for misbehaving buffers.
 display-buffer-alist
 '(("\\*Help\\*"
    (display-buffer-reuse-window
     display-buffer-below-selected))
   ("\\*Ibuffer\\*"
    (display-buffer-same-window))
   )
 ;; Open files in existing frames.
 pop-up-frames nil
 pop-up-windows t
 ;; Tab will always just try to indent.
 tab-always-indent 't
 ;; Resize the minibuffer when needed.
 resize-mini-windows t
 ;; Enable recursive editing of minibuffer?
 enable-recursive-minibuffers t
 ;; Move point to beginning or end of buffer when scrolling.
 scroll-error-top-bottom t
 mouse-wheel-scroll-amount '(5 ((shift) . 1) ((control)))

 ;; Set a larger minimum window width. Smaller than this is hard to read.
 window-min-width 30
 window-min-height 10

 ;; Language-specific settings?
 c-default-style "stroustrup"
 )

;; Change window name to be more descriptive.
(setq frame-title-format
      '((:eval (when (and (buffer-modified-p) buffer-file-name) "*"))
        "Emacs - "
        (buffer-file-name
         "%f" (dired-directory dired-directory "%b"))
        ))

;; Set c-style comments to be "//" by default (these are just better, sorry).
(add-hook 'c-mode-common-hook
          (lambda ()
            ;; Preferred comment style
            (setq comment-start "// "
                  comment-end "")))

;; Turn on utf-8 by default
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; Setup selected file endings to open in certain modes.
(add-to-list 'auto-mode-alist '("\\.over\\'" . json-mode))

;; Set some built-in modes.

;; Use compressed files like normal files.
(auto-compression-mode t)

;; Display the column number.
(column-number-mode t)

;; Replace selected text when typing or pasting.
(delete-selection-mode t)

;; Display line numbers (better than linum).
(defvar display-line-numbers-grow-only)
;; Don't shrink the line numbers.
(setq display-line-numbers-grow-only t)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'conf-mode-hook 'display-line-numbers-mode)
;; NOTE: Don't add `text-mode-hook', to prevent line numbers in org-mode.
;; Add `yaml-mode-hook' manually (it derives from `text-mode-hook').
(add-hook 'yaml-mode-hook 'display-line-numbers-mode)
(add-hook 'markdown-mode-hook 'display-line-numbers-mode)

;; Auto revert files that changed on disk.
(global-auto-revert-mode t)

;; Disable eldoc mode, causes huge slowdown in Rust files.
(global-eldoc-mode -1)

;; Highlight current line.
(defvar global-hl-line-sticky-flag)
;; Keep line highlight across windows?
(setq global-hl-line-sticky-flag t)
(global-hl-line-mode t)

;; Save minibuffer history across Emacs sessions.
(savehist-mode t)

;; Show matching parentheses.
(defvar show-paren-delay)
(setq show-paren-delay highlight-delay)
(show-paren-mode t)

;; Turn on subword-mode everywhere.
(global-subword-mode t)

;; Set up gpg.
;; For full instructions, see https://emacs.stackexchange.com/a/12213.

;; Don't bring up key recipient dialogue.
(require 'epa-file)
(setq epa-file-select-keys nil)
(setq epa-file-encrypt-to '("scatman@bu.edu"))

;; Fix EasyPG error.
;; From https://colinxy.github.io/software-installation/2016/09/24/emacs25-easypg-issue.html.
(defvar epa-pinentry-mode)
(setq epa-pinentry-mode 'loopback)

;; Kill inactive GPG buffers.

;; Adapted from https://stackoverflow.com/a/15854362/6085242.
(defun kill-gpg-buffers ()
  "Kill GPG buffers."
  (interactive)
  (let ((buffers-killed 0))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (string-match ".*\.gpg$" (buffer-name buffer))
          (message "Auto killing .gpg buffer '%s'" (buffer-name buffer))
          (when (buffer-modified-p buffer)
            (save-buffer))
          (kill-buffer buffer)
          (setq buffers-killed (+ buffers-killed 1)))))
    (unless (zerop buffers-killed)
      ;; Kill gpg-agent.
      (shell-command "gpgconf --kill gpg-agent")
      (message "%s .gpg buffers have been autosaved and killed" buffers-killed))))

(run-with-idle-timer 75 t 'kill-gpg-buffers)

;; Mouse settings

(setq
 ;; Make the mouse wheel not accelerate.
 mouse-wheel-progressive-speed nil
 mouse-yank-at-point t
 )

;;; My Functions and Shortcuts/Keybindings

;; Set s-s to save all buffers (default is only current buffer).
(global-set-key (kbd "s-s") 'save-all)

;; Set up keys using super. s-a, s-x, s-c, and s-v correspond to
;; select-all, save, cut, copy, and paste, which I've left for
;; consistency/utility on Macs.
(global-set-key (kbd "s-j") 'helm-mini)
(global-set-key (kbd "s-p") 'previous-buffer)
(global-set-key (kbd "s-n") 'next-buffer)
(global-set-key (kbd "s-k") 'kill-this-buffer)

(global-set-key (kbd "s-y") 'helm-show-kill-ring)
(global-set-key (kbd "s-h") 'helm-mark-ring)

;; Disable annoying popup on OSX.
(global-set-key (kbd "s-t") nil)

(defun other-window-reverse ()
  "Go to other window in reverse."
  (interactive)
  (other-window -1)
  )

(global-set-key (kbd "M-o") 'other-window)
(global-set-key (kbd "M-O") 'other-window-reverse)

;; Actions to perform when saving.
;; (add-hook 'before-save-hook 'whitespace-cleanup)
;; (add-hook 'before-save-hook 'ispell-comments-and-strings)

;; Save the buffer and revert it (reload from disk).
(defun save-revert-buffer ()
  "Save the buffer and then revert it."
  (interactive)
  (save-buffer)
  (revert-buffer))
(global-set-key (kbd "s-r") 'save-revert-buffer)

(defun save-all ()
  "Save all file-visiting buffers without prompting."
  (interactive)
  ;; Do not prompt for confirmation.
  (save-some-buffers t)
  )
(global-set-key (kbd "C-x s") 'save-all)

;; Automatically save all file-visiting buffers when Emacs loses focus.
(add-hook 'focus-out-hook 'save-all)
;; Run `save-all' when idle for a while.
;; Shouldn't run too quickly as it is a bit distracting.
(run-with-idle-timer 60 t 'save-all)

(defun goto-line-show ()
  "Show line numbers temporarily, while prompting for the line number input."
  (interactive)
  (let ((line-numbers display-line-numbers))
    (unwind-protect
        (progn
          (setq-local display-line-numbers t)
          (call-interactively #'goto-line)
          (end-of-line))
      (setq-local display-line-numbers line-numbers))))

(global-set-key (kbd "s-l") 'goto-line-show)

;; Commands to split window and move focus to other window.
(defun split-window-below-focus ()
  "Split window horizontally and move focus to other window."
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))
(defun split-window-right-focus ()
  "Split window vertically and move focus to other window."
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))
(defun delete-window-balance ()
  "Delete window and rebalance the remaining ones."
  (interactive)
  (delete-window)
  (balance-windows)
  )
(global-set-key (kbd "C-0") 'delete-window-balance)
(global-set-key (kbd "C-1") 'delete-other-windows)
(global-set-key (kbd "C-2") 'split-window-below-focus)
(global-set-key (kbd "C-3") 'split-window-right-focus)

(global-set-key (kbd "M-SPC") 'cycle-spacing)

;; Code folding.
(require 'hideshow)
(add-hook 'prog-mode-hook 'hs-minor-mode)
(define-key hs-minor-mode-map (kbd "C-z") 'hs-toggle-hiding)

(autoload 'zap-up-to-char "misc"
  "Kill up to, but not including ARGth occurrence of CHAR." t)
(global-set-key (kbd "M-z") 'zap-up-to-char)

(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Zoom in/out.
(global-set-key (kbd "M-+") 'text-scale-increase)
(global-set-key (kbd "M--") 'text-scale-decrease)

(defun indent-buffer ()
  "Indent the whole buffer."
  (interactive)
  (indent-region (point-min) (point-max))
  )
(global-set-key (kbd "C-c n") 'indent-buffer)
;; (add-hook 'before-save-hook 'indent-buffer)

(defun region-history-other (begin end)
  "Display the source controlled history of region from BEGIN to END in \
another window."
  (interactive "r")
  (vc-region-history begin end)
  (other-window 1)
  )
(global-set-key (kbd "C-c h") 'region-history-other)

(defun delete-current-buffer-file ()
  "Remove file connected to current buffer and kill buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        )
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

(global-set-key (kbd "C-c k") 'delete-current-buffer-file)

(defun rename-current-buffer-file ()
  "Rename the current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(global-set-key (kbd "C-c r") 'rename-current-buffer-file)

;; Select from point onwards instead of the entire line.
;; + Behaves like C-k.
;; + Can choose whether to keep indentation (run either C-a or M-m beforehand).
;; + Being able to select from point onwards comes in handy much of the time.
(defun select-line ()
  "Select the rest of the current line."
  (interactive)
  (push-mark (line-end-position) nil t)
  )

;; Replace default C-l, it's useless.
(global-set-key (kbd "C-l") 'select-line)

;; Select entire line or lines.
;; + Will entirely select any line that's even partially within the region.
;; + Behaves like C-S-k.
(defun select-lines ()
  "Select the entire current line or region.
If called on a region, will entirely select all lines included in
the region."
  (interactive)
  (cond ((region-active-p)
         (select-lines-region (region-beginning) (region-end)))
        (t
         (select-lines-region (point) (point))
         )))
(defun select-lines-region (beg end)
  "Entirely select all lines in the region from BEG to END."
  (goto-char end)
  (end-of-line)
  (push-mark)
  (activate-mark)
  (goto-char beg)
  (beginning-of-line)
  )

(global-set-key (kbd "C-S-l") 'select-lines)

;; Improved kill-whole-line which doesn't change cursor position.
;; Can be called on multiple lines.
;; Will entirely kill any line that's even partially within the region.
(defun annihilate-lines ()
  "Annihilate the current line or region by killing it entirely.
Will delete the resulting empty line and restore cursor position.
If called on a region, will annihilate every line included in the
region."
  (interactive)
  (cond ((region-active-p)
         (annihilate-lines-region (region-beginning) (region-end)))
        (t
         (annihilate-lines-region (point) (point))
         )))
(defun annihilate-lines-region (beg end)
  "Annihilate the region from BEG to END."
  (let ((col (current-column)))
    (goto-char beg)
    (setq beg (line-beginning-position))
    (goto-char end)
    (setq end (line-end-position))
    (kill-region beg end)
    (kill-append "\n" t)
    ;; Are there more lines after this?
    (if (/= (line-end-position) (point-max))
        (delete-char 1))
    ;; Restore column position
    (move-to-column col)
    ))

(global-set-key (kbd "C-S-k") 'annihilate-lines)

;; Drag up/down single line or lines in region.
(use-package drag-stuff
  :bind (("C-S-n" . drag-stuff-down)
         ("C-S-p" . drag-stuff-up)))

;; Join the following line onto the current line.
;; Use this to quickly consolidate multiple lines into one.
(defun join-next-line ()
  "Join the next line onto the current line, preserving the cursor position.
This command can be used to rapidly consolidate multiple lines
into one."
  (interactive)
  (let ((col (current-column)))
    (join-line -1)
    (move-to-column col)))

(global-set-key (kbd "C-j") 'join-next-line)

(defun open-line-below ()
  "Open a new line below while keeping proper indentation."
  (interactive)
  (end-of-line)
  (newline-and-indent))
(defun open-line-above ()
  "Open a new line above while keeping proper indentation."
  (interactive)
  (beginning-of-line)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))
(global-set-key (kbd "<C-return>") 'open-line-below)
(global-set-key (kbd "<S-return>") 'open-line-above)

(defun open-line-indent ()
  "Like the regular `open-line', but indent the next line."
  (interactive)
  (call-interactively #'open-line)
  (save-excursion
    (forward-line)
    (indent-according-to-mode)
    ))
(global-set-key (kbd "C-o") 'open-line-indent)

(defun clear-line ()
  "Clear the line, but don't delete it."
  (interactive)
  (beginning-of-line)
  (kill-line)
  (indent-according-to-mode)
  )

(defun window-fraction-height (fraction)
  "Get specified FRACTION of the height of the current window."
  (max 1 (/ (1- (window-height (selected-window))) fraction)))

(defun scroll-up-third ()
  "Scrolls up by a third of the current window height."
  (interactive)
  (scroll-up (window-fraction-height 3)))

(defun scroll-down-third ()
  "Scrolls down by a third of the current window height."
  (interactive)
  (scroll-down (window-fraction-height 3)))

(defun scroll-other-window-up-third ()
  "Scrolls other window up by a third of the current window height."
  (interactive)
  (scroll-other-window (window-fraction-height 3)))

(defun scroll-other-window-down-third ()
  "Scrolls other window down by a third of the current window height."
  (interactive)
  (scroll-other-window-down (window-fraction-height 3)))

;; Enable these commands in isearch.
(put 'scroll-up-third 'isearch-scroll t)
(put 'scroll-down-third 'isearch-scroll t)
(put 'scroll-other-window-up-third 'isearch-scroll t)
(put 'scroll-other-window-down-third 'isearch-scroll t)

(global-set-key (kbd "C-v") 'scroll-up-third)
(global-set-key (kbd "M-v") 'scroll-down-third)
(global-set-key (kbd "C-S-v") 'scroll-other-window-up-third)
(global-set-key (kbd "M-V") 'scroll-other-window-down-third)

;; Globally bind these keys so they work in every mode.
(bind-keys*
 )

;; Align region by string.
;; TODO: Enable history in read-string to allow for default values
;;       (i.e. last input).
(defun align-to-string (beg end)
  "Align region from BEG to END along input string."
  (interactive "r")
  (let ((char (read-string "string: ")))
    (align-regexp beg end (concat "\\(\\s-*\\)" char))))
(global-set-key (kbd "M-=") 'align-to-string)

;; Show ASCII table.
;; Obtained from http://www.chrislott.org/geek/emacs/dotemacs.html.
(defun ascii-table ()
  "Print the ascii table. Based on a defun by Alex Schroeder <asc@bsiag.com>."
  (interactive)
  (switch-to-buffer "*ASCII*")
  (erase-buffer)
  (insert (format "ASCII characters up to number %d.\n" 254))
  (let ((i 0))
    (while (< i 254)
      (setq i (+ i 1))
      (insert (format "%4d %c\n" i i))))
  (goto-char (point-min)))

;;; Visual settings

;; Set transparency.
(set-frame-parameter (selected-frame) 'alpha '(100))
;; (set-frame-parameter (selected-frame) 'alpha '(98))

;; Turn on blinking/flashing cursor.
(blink-cursor-mode t)
;; Blink forever!
(setq blink-cursor-blinks 0)
(when (display-graphic-p)
  (setq-default cursor-type 'box))
;; Stretch cursor to be as wide as the character at point.
(setq x-stretch-cursor 1)

;; Disable scroll bars and the tool bar.
(when (fboundp 'menu-bar-mode) (menu-bar-mode 0))
(when (fboundp 'tool-bar-mode) (tool-bar-mode 0))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode 0))
(when (fboundp 'horizontal-scroll-bar-mode) (horizontal-scroll-bar-mode 0))

;; Allow resizing by pixels.
(setq frame-resize-pixelwise t)

(toggle-frame-maximized) ;; Maximize!

;; Enable popup tooltips, use emacs tooltip implementation.
(tooltip-mode nil)
(defvar x-gtk-use-system-tooltips)
(setq x-gtk-use-system-tooltips nil)

;; Load Themes
;; (add-to-list 'custom-theme-load-path (concat user-emacs-directory "themes"))

(defadvice load-theme (before clear-previous-themes activate)
  "Clear existing theme settings instead of layering them."
  (mapc #'disable-theme custom-enabled-themes))

;; Nimbus is my personal theme, available on Melpa.
(use-package nimbus-theme
  :load-path "~/repos/github.com/m-cat/nimbus-theme"
  :config
  (nimbus-theme)
  )

;; Set font only if we're not in the terminal.
(when (display-graphic-p)
  ;; Function for checking font existence.
  (defun font-exists-p (font)
    "Check if FONT exists."
    (if (null (x-list-fonts font)) nil t))
  (declare-function font-exists-p "init.el")

  ;; Set font.
  (cond
   ((font-exists-p "Iosevka")
    (set-face-attribute
     ;; 'default nil :font "Iosevka:weight=Regular" :height 140)
     'default nil :font "Iosevka:weight=Light" :height 140)
    (setq-default line-spacing 0)
    )
   ((font-exists-p "Hack")
    (set-face-attribute
     'default nil :font "Hack:weight=Regular" :height 140)
    (setq-default line-spacing 1)
    )
   )
  )

;;; Built-in mode settings

(use-package isearch
  :ensure nil
  :config
  (setq
   ;; Can scroll using C-v and M-v.
   isearch-allow-scroll t
   ;; Highlight more matches after a delay.
   isearch-lazy-highlight t
   lazy-highlight-initial-delay info-delay
   )

  ;; Display last searched string in minibuffer prompt.
  (add-hook 'isearch-mode-hook
            (lambda () (interactive)
              (setq isearch-message
                    (format "%s[%s] "
                            isearch-message
                            (if search-ring
                                (propertize (car search-ring)
                                            'face '(:inherit font-lock-string-face))
                              ""))
                    )
              (isearch-search-and-update)))
  )

(use-package diff-mode
  :ensure nil
  :bind (
         :map diff-mode-map
         ("M-o" . nil)
         )
  )

(use-package dired
  :ensure nil
  :bind (
         :map dired-mode-map
         ("f" . helm-find-files)
         )
  :hook (dired-mode . dired-hide-details-mode)

  :config
  (setq-default
   ;; Always do recursive copies.
   dired-recursive-copies 'always
   ;; Make sizes human-readable by default and put dotfiles and capital-letters
   ;; first.
   dired-listing-switches "-alhv"
   ;; Try suggesting dired targets.
   dired-dwim-target t
   ;; Update buffer when visiting.
   dired-auto-revert-buffer t
   ;; Don't confirm various actions.
   dired-no-confirm t
   )

  ;; Expanded dired.
  ;; Enables jumping to the current directory in dired (default: C-x C-j).
  (use-package dired-x
    :ensure nil
    ;; Prevent certain files from showing up.
    ;; Use C-x M-o to show omitted files.
    :hook (dired-mode . dired-omit-mode)
    :bind ("s-d" . dired-jump)
    :config
    (setq dired-omit-files
          (concat dired-omit-files
                  "\\|\\.bk$\\|^\\.DS_Store$"))
    )

  ;; More dired colors.
  (use-package diredfl
    :config (diredfl-global-mode))

  ;; Allow changing file permissions in WDired.
  ;; NOTE: WDired can be entered with C-x C-q and changes saved with C-c C-c.
  ;; (defvar wdired-allow-to-change-permissions)
  (use-package wdired
    :ensure nil
    :config (setq wdired-allow-to-change-permissions t))
  )

;; ibuffer settings

(use-package ibuffer
  :ensure nil
  :bind (
         :map ibuffer-mode-map
         ;; Unbind ibuffer-visit-buffer-1-window.
         ("M-o" . nil)
         )
  :config

  ;; (define-key ibuffer-mode-map (kbd "M-o") nil)

  (setq
   ;; Don't show filter groups if there are no buffers in that group.
   ibuffer-show-empty-filter-groups nil
   ;; Don't ask for confirmation to delete marked buffers.
   ibuffer-expert t
   )

  ;; Use human-readable Size column.
  (define-ibuffer-column size-h
    (:name "Size" :inline t)
    (let ((bs (buffer-size)))
      (cond ((> bs 1e6) (format "%7.1fm" (/ bs 1e6)))
            ((> bs 1e3) (format "%7.1fk" (/ bs 1e3)))
            (t          (format "%7d" bs)))))

  (setf ibuffer-formats
        '((mark modified read-only vc-status-mini " "
                (name 24 24 :left :elide)
                " "
                (size-h 8 -1 :right)
                " "
                (mode 16 16 :left :elide)
                " "
                (vc-status 12 16 :left)
                " "
                filename-and-process)))

  (use-package ibuffer-vc
    :config
    (add-hook 'ibuffer-hook
              (lambda ()
                (ibuffer-vc-set-filter-groups-by-vc-root)
                (unless (eq ibuffer-sorting-mode 'alphabetic)
                  (ibuffer-do-sort-by-alphabetic))))
    )
  )

;; Ediff settings

(use-package ediff
  :ensure nil
  :config
  (setq ediff-split-window-function 'split-window-horizontally)
  )

;; ERC settings

(use-package erc
  :ensure nil
  :hook (erc-mode . erc-settings)
  :config

  ;; Set up modules.

  (use-package erc-join
    :ensure nil
    :config
    (setq erc-autojoin-channels-alist
          '(
            ("freenode.net"
             "#emacs"
             "#org-mode"
             "#emacsconf"
             "#bash"
             )
            ))
    )

  (use-package erc-notify
    :ensure nil
    :config
    ;; Notify in minibuffer when private messaged.
    (setq erc-echo-notices-in-minibuffer-flag t)
    )

  ;; Match keywords, highlight pals, ignore fools.
  (use-package erc-match
    :ensure nil
    :config
    (setq erc-keywords '()
          erc-pals  '()
          erc-fools '()
          )
    )

  ;; Settings

  (defun erc-settings ()
    "Set erc settings."
    ;; Move prompt one line at a time when point goes off the screen
    ;; (was centering the point before).
    (setq-local scroll-conservatively 999)
    )

  (setq
   erc-nick "bytedude"
   ;; How to open new channel buffers?
   erc-join-buffer 'window-noselect
   )

  ;; Show ERC activity in mode-line.
  (erc-track-mode)
  )

;; Eshell settings

(use-package eshell
  :ensure nil
  ;; :after projectile
  :bind (
         ("s-w" . projectile-run-eshell)
         ("s-e" . eshell-new)
         )
  ;; Save all buffers before running a command.
  :hook (eshell-pre-command . save-all)

  :config

  (setq
   ;; Stop output from always going to the bottom.
   eshell-scroll-show-maximum-output nil
   eshell-scroll-to-bottom-on-output nil
   ;; Always insert at the bottom.
   eshell-scroll-to-bottom-on-input t
   )

  ;; Set keys up in this hook. This doesn't work in :bind.
  (add-hook 'eshell-first-time-mode-hook
            #'(lambda ()
                (define-key eshell-mode-map (kbd "M-m") 'eshell-bol)
                (define-key eshell-mode-map (kbd "C-a") 'beginning-of-line)
                ;; Allow M-s .
                (define-key eshell-mode-map (kbd "M-s") nil)

                ;; Use helm to list eshell history.
                (define-key eshell-mode-map (kbd "M-i") 'helm-eshell-history)
                (define-key eshell-mode-map (kbd "M-{") 'eshell-previous-prompt)
                (define-key eshell-mode-map (kbd "M-}") 'eshell-next-prompt)
                ))

  (use-package em-hist
    :ensure nil
    :config
    (setq
     eshell-hist-ignoredups t
     ;; Set the history file.
     eshell-history-file-name "~/.bash_history"
     ;; Use HISTSIZE as the history size.
     eshell-history-size nil
     )
    )

  ;; Open a new eshell buffer.
  (defun eshell-new ()
    "Open a new eshell buffer."
    (interactive)
    (eshell t))

  ;; Load eshell packages.

  (use-package eshell-syntax-highlighting
    :config
    ;; Enable in all Eshell buffers.
    (eshell-syntax-highlighting-global-mode 1))

  ;; Add up to eshell.
  ;; Jump to a directory higher up in the directory hierarchy.
  (use-package eshell-up
    :config (setq eshell-up-print-parent-dir nil))

  ;; Add z to eshell.
  ;; Jumps to most recently visited directories.
  (use-package eshell-z)
  )

;;; Load packages

;; Stop execution here for terminal.

;; We typically only want to open `emacs' in the terminal for quick editing.
(when (not (display-graphic-p))
  (with-current-buffer " *load*"
    (goto-char (point-max)))
  )

;; Start loading packages.

;; Display number of matches when searching.
(use-package anzu
  :config
  (setq anzu-cons-mode-line-p nil)
  (global-anzu-mode))

;; Avy mode (jump to a char/word using a decision tree).
(use-package avy
  :bind (("C-," . avy-goto-line-end)
         ("C-." . avy-goto-char)
         )
  :init
  ;; Jump to the end of a line using avy's decision tree.
  (defun avy-goto-line-end ()
    "Jump to a line using avy and go to the end of the line."
    (interactive)
    (avy-goto-line)
    (end-of-line)
    )
  :config
  ;; Use more characters (and better ones) in the decision tree.
  ;; QWERTY keys.
  (setq avy-keys '(?a ?s ?d ?f ?j ?k ?l
                      ?w ?e ?r ?u ?i ?o))

  ;; Set the background to gray to highlight the decision tree?
  (setq avy-background nil)
  )

;; REMOVED
;; ;; Imagemagick wrapper.
;; (use-package blimp
;;   :hook (image-mode . blimp-mode)
;;   )

;; Move buffers around.
(use-package buffer-move
  :bind (
         ("<s-up>"    . buf-move-up)
         ("<s-down>"  . buf-move-down)
         ("<s-left>"  . buf-move-left)
         ("<s-right>" . buf-move-right)
         ))

;; Copy selected region to be pasted into Slack/Github/etc.
(use-package copy-as-format
  :defer t)

;; Display available keybindings in Dired mode (? creates popup).
(use-package discover
  :defer 2)

;; Show example usage when examining elisp functions.
(use-package elisp-demos
  :config
  (advice-add 'describe-function-1 :after #'elisp-demos-advice-describe-function-1))

;; Better comment command.
(use-package evil-nerd-commenter
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

;; Expand-region.
(use-package expand-region
  :bind ("C-=" . er/expand-region)
  :config
  ;; Fix region not highlighting.
  (setq
   shift-select-mode nil
   expand-region-fast-keys-enabled nil
   )
  )

;; Workspaces.
(use-package eyebrowse
  ;; To prevent mode-line display errors.
  :demand t

  :bind (("s-," . eyebrowse-prev-window-config)
         ("s-." . eyebrowse-next-window-config)
         ("s-0" . eyebrowse-switch-to-window-config-0)
         ("s-1" . eyebrowse-switch-to-window-config-1)
         ("s-2" . eyebrowse-switch-to-window-config-2)
         ("s-3" . eyebrowse-switch-to-window-config-3)
         ("s-4" . eyebrowse-switch-to-window-config-4)
         ("s-5" . eyebrowse-switch-to-window-config-5)
         ("s-6" . eyebrowse-switch-to-window-config-6)
         ("s-7" . eyebrowse-switch-to-window-config-7)
         ("s-8" . eyebrowse-switch-to-window-config-8)
         ("s-9" . eyebrowse-switch-to-window-config-9)
         ("s-/" . eyebrowse-close-window-config)
         ("s--" . eyebrowse-rename-window-config)
         )

  :config

  (eyebrowse-mode t)

  (setq
   eyebrowse-wrap-around t
   eyebrowse-switch-back-and-forth nil
   eyebrowse-new-workspace t
   eyebrowse-close-window-config-prompt t

   eyebrowse-mode-line-separator " "
   eyebrowse-mode-line-left-delimiter "["
   eyebrowse-mode-line-right-delimiter "]"
   )

  (set-face-attribute 'eyebrowse-mode-line-active nil :underline t :bold t)

  ;;; Show workspaces in title bar.

  ;; Only recalculate the workspaces string when it actually changes.
  (defvar eyebrowse-workspaces)
  (defun eyebrowse-current-workspace ()
    "Get the current workspace number."
    (eyebrowse--get 'current-slot))
  (defun eyebrowse-workspaces-string ()
    "Get the current workspaces as a string."
    (let ((workspaces (substring-no-properties (eyebrowse-mode-line-indicator))))
      (setq eyebrowse-workspaces workspaces)))
  (defun eyebrowse-workspaces-string-rename (_arg1 _arg2)
    "Advice for `eyebrowse-rename-window-config'."
    (eyebrowse-workspaces-string))
  (eyebrowse-workspaces-string)
  (add-hook 'eyebrowse-post-window-switch-hook 'eyebrowse-workspaces-string)
  (advice-add 'eyebrowse-close-window-config :after #'eyebrowse-workspaces-string)
  (advice-add 'eyebrowse-rename-window-config :after #'eyebrowse-workspaces-string-rename)

  ;; Append to title list.
  (add-to-list 'frame-title-format
               '(:eval (when (not (string-empty-p eyebrowse-workspaces))
                         (format " - %s - %s" eyebrowse-workspaces (eyebrowse-current-workspace))))
               t
               )
  )

;; Fix the capitalization commands.
(use-package fix-word
  :bind (("M-u" . fix-word-upcase)
         ("M-l" . fix-word-downcase)
         ("M-c" . fix-word-capitalize)
         )
  )

;; Fontify symbols representing faces with that face.
(use-package fontify-face
  :defer t
  :hook (emacs-lisp-mode . fontify-face-mode)
  )

;; Show unused keys.
(use-package free-keys
  :defer t)

;; Highlight more elisp syntax.
(use-package highlight-quoted
  :hook (emacs-lisp-mode . highlight-quoted-mode))

;; Highlight keywords such as TODO, FIXME, NOTE, etc.
;; NOTE: Face values defined in `hl-todo-keyword-faces'.
(use-package hl-todo
  :config
  (global-hl-todo-mode)

  (add-to-list 'hl-todo-keyword-faces '("REMOVED" . "#cc9393"))
  )

;; A package for choosing a color by updating text sample.
;; See https://www.emacswiki.org/emacs/MakeColor.
(use-package make-color
  :defer t)

;; Multiple cursors.
(use-package multiple-cursors
  :bind (
         ("C-{" . mc/mark-previous-like-this)
         ("C-}" . mc/mark-next-like-this)

         ;; Add cursors with the mouse!
         ("C-S-<mouse-1>" . mc/add-cursor-on-click)

         :map mc/keymap

         ;; Reclaim RET.
         ("<return>" . nil)
         )
  :config
  (setq mc/always-run-for-all t)
  )

;; Highlight color strings with the corresponding color.
(use-package rainbow-mode
  :defer t
  )

;; Open current directory.
(use-package reveal-in-folder
  :bind ("C-c f" . reveal-in-folder)
  )

;; Automatically save place in each file.
(use-package saveplace
  :config
  (save-place-mode t)
  )

;; TODO: Included in Emacs 27, remove.
(use-package so-long
  :config (global-so-long-mode 1))

;; Actually a really nice mode-line package.
;; Requires little configuration.
(use-package spaceline
  :config
  (require 'spaceline-config)

  ;; Don't display minor modes (too messy).
  (defvar spaceline-minor-modes-p)
  (setq spaceline-minor-modes-p nil)
  ;; Don't display eyebrowse workspace numbers (displayed in title bar instead).
  (defvar spaceline-workspace-number-p)
  (setq spaceline-workspace-number-p nil)
  ;; Don't display line ending type.
  (defvar spaceline-buffer-encoding-abbrev-p)
  (setq spaceline-buffer-encoding-abbrev-p nil)

  ;; Change the modeline display when the buffer has been modified or is read-only.
  (setq spaceline-highlight-face-func 'spaceline-highlight-face-modified)

  (spaceline-spacemacs-theme)
  (spaceline-helm-mode)
  )

;; Open current directory in an external terminal emulator.
(use-package terminal-here
  :bind ("C-c t" . terminal-here-launch)
  )

;; A more lightweight alternative to undo-tree.
(use-package undo-propose
  :bind ("C-_" . undo-propose))

;; Use a sensible mechanism for making buffer names unique.
(use-package uniquify
  :ensure nil
  :config
  (setq uniquify-buffer-name-style 'forward
        uniquify-min-dir-content 1
        uniquify-strip-common-suffix nil
        )
  )

;; Highlight some recent changes such as undos.
(use-package volatile-highlights
  :config (volatile-highlights-mode))

;; Display available keys.
(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-sort-order 'which-key-key-order-alpha)
  (setq which-key-sort-uppercase-first nil))

;; Highlight the parts of lines that exceed certain column numbers.
(use-package whitespace
  :config
  (setq whitespace-style '(face
                           empty lines-tail tabs trailing))

  (defun c-whitespace-mode ()
    "Set whitespace column for c-like modes and turn on `whitespace-mode'."
    (setq whitespace-line-column 80
          fill-column 80)
    (whitespace-mode)
    )
  (add-hook 'c-mode-common-hook 'c-whitespace-mode)
  (add-hook 'nim-mode-hook 'c-whitespace-mode)

  (defun 100-whitespace-mode ()
    "Set whitespace column at 100 and turn on `whitespace-mode'."
    (setq whitespace-line-column 100
          fill-column 100
          )
    (whitespace-mode)
    )
  (add-hook 'rust-mode-hook '100-whitespace-mode)
  (add-hook 'python-mode-hook '100-whitespace-mode)
  )

;; Undo/redo window configurations.
(use-package winner
  :bind (
         ("C-c C-," . winner-undo)
         ("C-c C-." . winner-redo)
         )
  :config (winner-mode t))

;; Switch windows more easily.
(use-package winum
  :init
  ;; Prevent winum from inserting its own number in the mode-line
  ;; (spaceline already does so).
  (setq winum-auto-setup-mode-line nil)

  ;; This has to be in :init for some reason.
  (setq winum-keymap
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "M-1") 'winum-select-window-1)
          (define-key map (kbd "M-2") 'winum-select-window-2)
          (define-key map (kbd "M-3") 'winum-select-window-3)
          (define-key map (kbd "M-4") 'winum-select-window-4)
          (define-key map (kbd "M-5") 'winum-select-window-5)
          (define-key map (kbd "M-6") 'winum-select-window-6)
          (define-key map (kbd "M-7") 'winum-select-window-7)
          (define-key map (kbd "M-8") 'winum-select-window-8)
          (define-key map (kbd "M-9") 'winum-select-window-9)
          (define-key map (kbd "M-0") 'winum-select-window-0)
          map))

  :config
  (winum-mode)
  )

;; REMOVED: not maintained.
;; ;; Wrap regions with pairs.
;; (use-package wrap-region
;;   :config
;;   (wrap-region-add-wrappers
;;    '(
;;      ("`" "`")
;;      ("*" "*")
;;      ))

;;   ;; Keep the region active after adding a pair.
;;   (setq wrap-region-keep-mark t)

;;   (wrap-region-global-mode t)
;;   )

;; Automatically clean up extraneous whitespace.
(use-package ws-butler
  :hook ((prog-mode . ws-butler-mode)
         (text-mode . ws-butler-mode)
         ))

;;; Git packages

;; Generate links to Github for current code location.
(use-package git-link
  :defer t)

;; Browse historic versions of a file.
(use-package git-timemachine
  :defer t)

(use-package gitignore-mode
  :defer t)

;; Git client in Emacs.
(use-package magit
  :bind (("C-x g" . magit-status)
         ("s-g" . magit-status))

  :init
  (setq
   ;; Show fine differences for all displayed diff hunks.
   magit-diff-refine-hunk `all
   ;; How to display new magit buffers?
   magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
   ;; Don't ask before saving repository buffers.
   magit-save-repository-buffers 'dontask
   ;; Stop magit from stupidly messing up my window configuration when quitting buffers.
   magit-bury-buffer-function 'quit-window
   )
  )

;;; Project packages

;; Company mode for auto-completion.
(use-package company
  :bind (
         ("M-/" . company-complete)

         :map company-active-map

         ("C-h" . nil)
         ("C-s" . company-isearch-forward)
         ("C-r" . company-isearch-backward)

         ;; ;; Prevent SPC from ever triggering a completion.
         ;; ("SPC" . nil)

         ;; Make TAB always complete the current selection.
         ;; <tab> is for windowed Emacs and TAB is for terminal Emacs.
         ("<tab>" . company-complete-selection)
         ("TAB" . company-complete-selection)

         ;; Do not complete with RET; should start a new line.
         ("<return>" . nil)
         ("RET" . nil)
         )
  :hook (prog-mode . company-mode)
  :init
  ;; Trigger completion immediately.
  (setq company-idle-delay nil)
  (setq company-minimum-prefix-length 1)
  ;; Align tooltips to right border.
  (setq company-tooltip-align-annotations t)
  ;; Number the candidates? (Use C-M-1, C-M-2 etc to select completions.)
  (setq company-show-numbers t)

  :config
  (defun company-isearch-backward ()
    "Abort company and search backward."
    (interactive)
    (company-abort)
    (isearch-backward)
    )
  (defun company-isearch-forward ()
    "Abort company and search forward."
    (interactive)
    (company-abort)
    (isearch-forward)
    )

  ;; Rebind the M-digit keys to prevent conflict with winum.
  (dotimes (i 10)
    (define-key company-active-map (kbd (format "M-%d" i)) nil)
    (define-key company-active-map (read-kbd-macro (format "s-%d" i)) 'company-complete-number))

  ;; Allow typing normally.
  (setq company-require-match nil)

  ;; Add commands that should abort completion.
  (add-to-list 'company-continue-commands 'rust-format-buffer t)
  (add-to-list 'company-continue-commands 'indent-buffer t)
  )

;; Show markers in margin indicating changes.
(use-package diff-hl
  :bind (
         ("C-?" . diff-hl-revert-hunk)
         ("M-[" . diff-hl-previous-hunk)
         ("M-]" . diff-hl-next-hunk)
         )
  :hook ((prog-mode . enable-diff-hl)
         (text-mode . enable-diff-hl)
         (conf-mode . enable-diff-hl)
         )
  :init
  (defun enable-diff-hl ()
    ;; Make the fringe wide enough to display correctly.
    (setq-local left-fringe-width 16)
    (turn-on-diff-hl-mode))

  :config

  ;; Show diffs in margin when running in terminal.
  (unless (window-system) (diff-hl-margin-mode))

  ;; Refresh diffs after a Magit commit.
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  ;; See diffs in Dired.
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)
  )

;; EditorConfig helps maintain consistent coding styles for multiple developers
;; working on the same project across various editors and IDEs.
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; On-the-fly syntax checker.
(use-package flycheck
  :hook ((prog-mode . flycheck-mode)
         (text-mode . flycheck-mode)
         (conf-mode . flycheck-mode)
         )
  :commands flycheck-mode
  :bind ("C-!" . flycheck-list-errors)
  :config
  (setq flycheck-check-syntax-automatically '(mode-enabled save))
  ;; (setq flycheck-check-syntax-automatically nil)

  ;; Set shorter delay for displaying errors at point.
  (setq flycheck-display-errors-delay (* 1 info-delay))
  (setq sentence-end-double-space nil) ;; Stupid check.

  ;; Disable checkers.
  (setq-default flycheck-disabled-checkers '(proselint rust rust-cargo rust-clippy))
  ;; (setq-default flycheck-disabled-checkers '(rust)) ;; Doesn't work.

  ;; (flycheck-add-next-checker 'rust-cargo 'rust-clippy)
  )

;; Elisp package lints.
(use-package flycheck-package
  :hook (flycheck-mode . flycheck-package-setup))

;; ag/rg with helm.
(use-package helm-ag
  :demand t
  :bind ("s-o" . helm-ag-pop-stack)
  )

;; Helm interface for projectile.
(use-package helm-projectile
  :after (helm-ag projectile)
  :bind (
         ("s-;" . helm-projectile)
         ("s-i" . helm-projectile-ag-inexact)
         ("s-u" . helm-projectile-ag-exact)
         )

  :config
  (defun helm-projectile-ag-inexact ()
    "Run helm-projectile-ag, case-insensitive and without word
boundaries."
    (interactive)
    (save-all)
    (setq helm-ag-base-command
          "ag --hidden --nocolor --nogroup --ignore-case")
    (setq helm-ag-insert-at-point nil)
    (helm-projectile-ag)
    )
  (defun helm-projectile-ag-exact ()
    "Run helm-projectile-ag, case-sensitive and with word
boundaries."
    (interactive)
    (save-all)
    (setq helm-ag-base-command
          "ag --hidden --nocolor --nogroup --word-regexp --case-sensitive")
    (setq helm-ag-insert-at-point 'symbol)
    (helm-projectile-ag)
    )

  ;; Don't use projectile buffers as a source.
  (setq helm-projectile-sources-list '(helm-source-projectile-files-list
                                       helm-source-projectile-projects
                                       ))

  (helm-projectile-on)
  )

;; Project manager.
(use-package projectile
  :defer 1
  :hook (prog-mode . projectile-mode)
  :config
  (setq projectile-completion-system 'helm)
  )

;; Jump to definitions using dumb-jump as a fallback.
(use-package smart-jump
  :config
  (smart-jump-setup-default-registers)
  (setq dumb-jump-selector 'helm)
  )

;;; Language packages

;; C#

(use-package csharp-mode
  :defer t)

;; Docker

(use-package dockerfile-mode
  :defer t)

;; Fish

(use-package fish-mode
  :defer t)

;; Go / Golang

(use-package go-mode
  :defer t
  :bind (:map go-mode-map ("C-c n" . gofmt))
  :config
  (setq
   gofmt-args '("-s")
   gofmt-command "gofmt"

   ;; gofmt-args nil
   ;; gofmt-command "goimports"
   )

  (use-package godoctor)
  (use-package go-errcheck)
  )

;; Groovy

(use-package groovy-mode
  :defer t)

;; Javascript

(use-package js2-mode
  :mode "\\.js\\'"
  :bind (
         :map js2-mode-map
         ("M-," . smart-jump-back)
         ("M-." . smart-jump-go)
         )
  :config
  (setq js2-basic-offset 2)
  )

;; Typescript
(use-package tide
  :ensure t
  :after (typescript-mode company flycheck)
  :hook ((typescript-mode . tide-setup)
         (typescript-mode . tide-hl-identifier-mode)
         ;; (before-save . tide-format-before-save)
         )
  :config
  (setq typescript-indent-level 2)
  )

;; JSON

(use-package json-mode
  :defer t
  :config
  (setq json-reformat:indent-width 2)
  )

;; Lua

(use-package lua-mode
  :mode "\\.lua\\'"
  :config
  (setq lua-indent-level 4)
  )

;; Markdown

;; Markdown previews.
(use-package grip-mode
  :commands grip-mode)

(use-package markdown-mode
  :mode "\\.md\\'"
  )

(use-package markdown-toc
  :after markdown-mode
  :defer t)

;; Nim

(use-package nim-mode
  :bind (:map nim-mode-map ("RET" . newline-and-indent))
  :defer t
  )

;; Python

(add-hook 'python-mode-hook
          (lambda ()
            (setq flycheck-python-pylint-executable "/usr/local/bin/pylint")
            (setq flycheck-python-flake8-executable "/usr/local/bin/flake8")
            ))

;; Rust

(use-package racer
  :bind (
         :map racer-mode-map
         ("M-," . smart-jump-back)
         ("M-." . smart-jump-go)
         )
  :hook (rust-mode . racer-mode)
  :config
  ;; Don't insert argument placeholders when completing a function.
  (setq racer-complete-insert-argument-placeholders nil)
  )

(use-package rust-mode
  :bind (:map rust-mode-map ("C-c n" . rust-format-buffer))
  :config
  (setq rust-format-on-save nil)
  )

;; TOML

(use-package toml-mode
  :mode "\\.toml\\'"
  )

;; YAML

(use-package yaml-mode
  :mode "\\.yml\\'")

;;; Org Mode

(use-package org
  :ensure nil
  :bind (
         ("C-c l" . org-store-link)
         ;; ("C-c c" . org-note-capture)
         ;; ("C-c v" . org-task-capture)

         ("s-'" . org-refile-goto)
         ("s-\"" . org-refile)
         ;; Jump to last refile or capture.
         ("C-c j" . org-refile-goto-last-stored)

         :map org-mode-map

         ("<s-return>" . org-meta-return-end)
         ("C-S-n" . org-metadown)
         ("C-S-p" . org-metaup)
         ("C-<" . org-shiftmetaleft)
         ("C->" . org-shiftmetaright)
         ("M-m" . org-beginning-of-line)
         ("C-^" . org-up-element)
         ("C-j" . join-next-line)

         ("<mouse-3>" . mouse-org-cycle)
         )
  :mode ("\\.org$" . org-mode)
  :hook (
         (org-mode . org-mode-hook-fun)

         ;; Word-wrap.
         (org-mode . visual-line-mode)
         ;; Indented entries.
         (org-mode . org-indent-mode)
         )

  :init

  (defun org-mode-hook-fun ()
    "Initialize `org-mode'."

    ;; Unbind keys stolen by org-mode.
    (local-unset-key (kbd "C-,"))

    ;; Fix tags alignment getting messed up (still not sure of the cause).
    (add-hook 'before-save-hook 'org-align-all-tags nil t)
    )

  ;; Don't align tags.
  ;; Keep this in :init so that no org-files are opened without these settings.
  ;; NOTE: Doesn't seem to fix tag alignment getting messed up.
  (setq org-tags-column 0
        org-auto-align-tags nil)

  :config

  ;;; Settings

  (setq
   ;; Default org directory.
   org-directory user-org-directory
   ;; Set location of agenda files.
   org-agenda-files (list
                     user-todo-org
                     user-work-org
                     )

   ;; Try to keep cursor before ellipses.
   org-special-ctrl-a/e t
   ;; Smart editing of invisible region around ellipses.
   org-catch-invisible-edits 'smart

   ;; All subtasks must be Done before marking a task as Done.
   org-enforce-todo-dependencies t
   ;; Log time a task was set to Done.
   org-log-done (quote time)
   ;; Don't log the time a task was rescheduled or redeadlined.
   org-log-reschedule nil
   org-log-redeadline nil

   ;; Prefer rescheduling to future dates and times.
   org-read-date-prefer-future 'time

   ;; M-RET should not split the heading if point is not at the end of a line.
   ;; (setq org-M-RET-may-split-line nil)

   ;; Should ‘org-insert-heading’ leave a blank line before new heading/item?
   org-blank-before-new-entry '((heading . nil) (plain-list-item . nil))

   ;; Custom to-do states.
   org-todo-keywords
   '((sequence "TODO(t)" "TODAY(y)" "WAITING(w)" "|" "DONE(d)")
     (sequence "|" "CANCELED(x)"))

   ;; org-refile settings

   ;; Refile notes to the top of the list.
   org-reverse-note-order t
   ;; Use headline paths (level1/level2/...)
   org-refile-use-outline-path t
   ;; Go down in steps when completing a path.
   org-outline-path-complete-in-steps nil
   org-refile-targets
   '(
     (org-agenda-files . (:maxlevel . 99))

     (user-notes-org . (:maxlevel . 99))
     (user-work-org . (:maxlevel . 99))
     (user-ideas-org . (:maxlevel . 99))
     (user-projects-org . (:maxlevel . 99))
     )
   ;; Jump to headings with completion.
   org-goto-interface 'outline-path-interface
   org-goto-max-level 99
   ;; Always show full context, no matter how we get to a certain heading (e.g.
   ;; `isearch', `org-goto', whatever). The default behavior of hiding headings
   ;; is asinine.
   org-show-context-detail '((default . tree))
   )

  ;; ;; org-capture template.
  ;; (defvar org-capture-templates
  ;;   '(("t" "My TODO task format." entry
  ;;      (file+headline "todo.org" "General")
  ;;      "* %?\nSCHEDULED: %t")
  ;;     ("n" "My note format." entry
  ;;      (file "notes.org")
  ;;      "* %?")))

  ;; Shortcuts/Keybindings

  (defun org-refile-goto ()
    "Use org-refile to conveniently choose and go to a heading."
    (interactive)
    (let ((current-prefix-arg '(4))) (call-interactively 'org-refile))
    )

  ;; ;; org-capture with template as default behavior.
  ;; (defun org-task-capture ()
  ;;   "Capture a task with my todo template."
  ;;   (interactive)
  ;;   (org-capture nil "t"))
  ;; (defun org-note-capture ()
  ;;   "Capture a note with my note template."
  ;;   (interactive)
  ;;   (org-capture nil "n"))

  (defun org-meta-return-end ()
    "Go to end of visual line before calling org-meta-return."
    (interactive)
    (end-of-visual-line)
    (org-meta-return))

  (defun mouse-org-cycle (@click)
    (interactive "e")
    (let ((p1 (posn-point (event-start @click))))
      (goto-char p1)
      (call-interactively 'org-cycle)
      )
    )

  ;;; org packages

  ;; Markdown export.
  (use-package ox-gfm)

  ;; REMOVED Package cl is deprecated.
  ;; ;; Export org to Reveal.js.
  ;; (use-package ox-reveal)
  )

(use-package org-agenda
  :ensure nil
  :hook (org-agenda-mode . visual-line-mode)
  :bind (
         ("C-c a" . org-agenda-list)

         :map org-agenda-mode-map

         ("s-\"" . org-agenda-refile)
         ("M" . org-agenda-bulk-mark-all)
         )

  :config

  ;; Set default span of agenda view.
  (setq org-agenda-span 'week)

  ;; Show scheduled items in order from most to least recent.
  (setq org-agenda-sorting-strategy
        '((agenda habit-down time-up scheduled-down priority-down category-keep)
          (todo   priority-down category-keep)
          (tags   priority-down category-keep)
          (search category-keep)))

  ;; Customize columns (remove filename/category, mostly redundant).
  (setq org-agenda-prefix-format '((agenda . " %i %?-12t% s")
                                   (todo . " %i %-12:c")
                                   (tags . " %i %-12:c")
                                   (search . " %i %-12:c")))

  (setq
   ;; Stop org-agenda from messing up my windows!!
   org-agenda-window-setup 'current-window
   ;; Start org-agenda from the current day.
   org-agenda-start-on-weekday nil
   ;; Don't align tags in the org-agenda (sometimes it messes up the display).
   org-agenda-tags-column 0)

  (defun org-agenda-refresh ()
    "Refresh all `org-agenda' buffers."
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-maybe-redo)
          ))))

  ;; Refresh org-agenda after changing an item status.
  ;; (add-hook 'org-trigger-hook 'org-agenda-refresh)
  ;; Refresh org-agenda after rescheduling a task.
  (defadvice org-schedule (after refresh-agenda activate)
    "Refresh `org-agenda'."
    (org-agenda-refresh))

  ;; Refresh org-agenda after an org-capture.
  (add-hook 'org-capture-after-finalize-hook 'org-agenda-refresh)
  ;; ;; Refresh org-agenda on a timer (refreshes the agenda on a new day).
  ;; (run-with-idle-timer 5 t 'org-agenda-refresh)

  ;; Try to fix the annoying tendency of this function to scroll the point to some
  ;; random place and mess up my view of the agenda.
  ;; NOTE: This is a copy-paste of the original `org-agenda-redo` function,
  ;; with one line commented out.
  (defun org-agenda-redo (&optional all)
    "Rebuild possibly ALL agenda view(s) in the current buffer."
    (interactive "P")
    (let* ((p (or (and (looking-at "\\'") (1- (point))) (point)))
           (cpa (unless (eq all t) current-prefix-arg))
           (org-agenda-doing-sticky-redo org-agenda-sticky)
           (org-agenda-sticky nil)
           (org-agenda-buffer-name (or org-agenda-this-buffer-name
                                       org-agenda-buffer-name))
           (org-agenda-keep-modes t)
           (tag-filter org-agenda-tag-filter)
           (tag-preset (get 'org-agenda-tag-filter :preset-filter))
           (top-hl-filter org-agenda-top-headline-filter)
           (cat-filter org-agenda-category-filter)
           (cat-preset (get 'org-agenda-category-filter :preset-filter))
           (re-filter org-agenda-regexp-filter)
           (re-preset (get 'org-agenda-regexp-filter :preset-filter))
           (effort-filter org-agenda-effort-filter)
           (effort-preset (get 'org-agenda-effort-filter :preset-filter))
           (cols org-agenda-columns-active)
           (line (org-current-line))
           ;; (window-line (- line (org-current-line (window-start))))
           (lprops (get 'org-agenda-redo-command 'org-lprops))
           (redo-cmd (get-text-property p 'org-redo-cmd))
           (last-args (get-text-property p 'org-last-args))
           (org-agenda-overriding-cmd (get-text-property p 'org-series-cmd))
           (org-agenda-overriding-cmd-arguments
            (unless (eq all t)
              (cond ((listp last-args)
                     (cons (or cpa (car last-args)) (cdr last-args)))
                    ((stringp last-args)
                     last-args))))
           (series-redo-cmd (get-text-property p 'org-series-redo-cmd)))
      (put 'org-agenda-tag-filter :preset-filter nil)
      (put 'org-agenda-category-filter :preset-filter nil)
      (put 'org-agenda-regexp-filter :preset-filter nil)
      (put 'org-agenda-effort-filter :preset-filter nil)
      (and cols (org-columns-quit))
      (message "Rebuilding agenda buffer...")
      (if series-redo-cmd
          (eval series-redo-cmd)
        (org-let lprops redo-cmd))
      (setq org-agenda-undo-list nil
            org-agenda-pending-undo-list nil
            org-agenda-tag-filter tag-filter
            org-agenda-category-filter cat-filter
            org-agenda-regexp-filter re-filter
            org-agenda-effort-filter effort-filter
            org-agenda-top-headline-filter top-hl-filter)
      (message "Rebuilding agenda buffer...done")
      (put 'org-agenda-tag-filter :preset-filter tag-preset)
      (put 'org-agenda-category-filter :preset-filter cat-preset)
      (put 'org-agenda-regexp-filter :preset-filter re-preset)
      (put 'org-agenda-effort-filter :preset-filter effort-preset)
      (let ((tag (or tag-filter tag-preset))
            (cat (or cat-filter cat-preset))
            (effort (or effort-filter effort-preset))
            (re (or re-filter re-preset)))
        (when tag (org-agenda-filter-apply tag 'tag t))
        (when cat (org-agenda-filter-apply cat 'category))
        (when effort (org-agenda-filter-apply effort 'effort))
        (when re  (org-agenda-filter-apply re 'regexp)))
      (and top-hl-filter (org-agenda-filter-top-headline-apply top-hl-filter))
      (and cols (called-interactively-p 'any) (org-agenda-columns))
      (org-goto-line line)
      ;; Commenting out the following line stops the random scrolling.
      ;; (recenter window-line)
      ))
  )

;; Recurring org-mode tasks.
(use-package org-recur
  ;; :load-path "~/projects/org-recur/"
  :after org
  :bind (
         :map org-recur-mode-map

         ("C-c d" . org-recur-finish)
         ("C-c 0" . org-recur-schedule-today)
         ("C-c 1" . org-recur-schedule-1)
         ("C-c 2" . org-recur-schedule-2)

         :map org-recur-agenda-mode-map

         ;; Rebind the 'd' key in org-agenda (default: `org-agenda-day-view').
         ("d" . org-recur-finish)
         ("0" . org-recur-schedule-today)
         ("1" . org-recur-schedule-1)
         ("2" . org-recur-schedule-2)
         ("C-c d" . org-recur-finish)
         ("C-c 0" . org-recur-schedule-today)
         ("C-c 1" . org-recur-schedule-1)
         ("C-c 2" . org-recur-schedule-2)
         )
  :hook ((org-mode . org-recur-mode)
         (org-agenda-mode . org-recur-agenda-mode))
  :demand t
  :config
  (defun org-recur-schedule-1 ()
    (interactive)
    (org-recur-schedule-date "|+1|"))
  (defun org-recur-schedule-2 ()
    (interactive)
    (org-recur-schedule-date "|+2|"))

  (setq org-recur-finish-done t
        org-recur-finish-archive t)
  )

;; Display groups in org-agenda to make things a bit more organized.
(use-package org-super-agenda
  :after org-agenda
  :config
  (org-super-agenda-mode)

  (setq
   org-super-agenda-header-separator ""
   org-super-agenda-unmatched-name "Other"
   org-super-agenda-groups
   '(
     ;; Each group has an implicit OR operator between its selectors.
     (:name "Today"  ; Optionally specify section name
            :time-grid t  ; Items that appear on the time grid.
            :todo "TODAY"   ; Items that have this todo keyword.
            )
     (:name "Work"
            :category "work"
            :tag "work"
            )
     (:name "High Priority"
            :priority "A"
            :order 1
            )
     (:name "Physical"
            :category "physical"
            :tag "physical"
            :order 2
            )
     (:name "Shopping List"
            :category "shopping"
            :tag "shopping"
            :order 3
            )
     (:name "Cleaning"
            :category "cleaning"
            :tag "cleaning"
            :order 4
            )
     (:name "Hygiene"
            :category "hygiene"
            :tag "hygiene"
            :order 5
            )
     (:name "Health"
            :category "health"
            :tag "health"
            :order 6
            )
     (:name "Financial"
            :category "financial"
            :tag "financial"
            :order 7
            )
     (:name "Self-improvement"
            :category "self-improvement"
            :tag "self-improvement"
            :order 8
            )
     (:name "Blog"
            :category "blog"
            :tag "blog"
            :order 9
            )

     ;; After the last group, the agenda will display items that didn't
     ;; match any of these groups, with the default order position of 99

     (:name "Tech"
            :category "tech"
            :tag "tech"
            :order 180
            )
     (:name "To Read"
            :category "read"
            :tag "read"
            :order 181
            )
     (:name "To Watch"
            :category "watch"
            :tag "watch"
            :order 182
            )
     (:todo "WAITING" :order 190)
     ;; (:name "Low priority"
     ;;        :priority "C"
     ;;        :order 200)
     )))

;;; Final

;; Start server.

(server-start)

;; Misc

;; Open stuff on startup.
(defun emacs-welcome()
  "Display Emacs welcome screen."
  (interactive)

  ;; Set up org files and agenda.

  (find-file user-notes-org)
  (split-window-right-focus)
  (find-file user-todo-org)
  (split-window-right-focus)
  (org-agenda-list)

  ;; Name eyebrowse slots.

  (eyebrowse-rename-window-config 1 "org")
  )

(emacs-welcome)

(message "init.el finished loading successfully!")

(provide 'init)
;;; init.el ends here
