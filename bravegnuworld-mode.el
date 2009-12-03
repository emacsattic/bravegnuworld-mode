;;; bravegnuworld.el --- "BraveGnuWorld Corrector Mode"

;; Copyright (C) 2000 Stefan Kamphausen

;; Author: Stefan Kamphausen <mail@skamphausen.de>
;; Version: 0.9.1
;; Keywords: html, brave gnu world
;;

;; Thsi program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; this program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the 
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; Brave Gnu World Mode provides just a function to start and end
;; annotations to Georg Greves Brave Gnu World colum. When saving the
;; file those annotations get converted to HTML Code (default: red
;; font)
;;
;; and that's it
;; To use it automagically insert the following code into any of your
;; (X)emacs startup files. Don't ask me if it works with Gnu Emacs,
;; too; sorry!

;; (autoload 'bravegnuworld-mode "bravegnuworld")
;; (setq auto-mode-alist
;;      (append
;;       '(("BraveGNUWorld.*\.html" .bravegnuworld-mode ))
;;       auto-mode-alist))

;;; Changes:
;; 
;; 0.9:     first published version
;;
;; 0.9.1:   bravegnuworld-annotation detects converted notes, too
;;          and deletes them

;;; Code:
(defcustom bravegnuworld-start-comment "{{"
  "This string is inserted when you start an annotation.
It should be a reasonable value that usually doesn't occur in HTML
documents. Thus setting this to `<h1>' would be quite stoopid ;)"
  :type 'string
  :group 'bravegnuworld)
(defcustom bravegnuworld-end-comment "}}"
  "This string is inserted when you end an open annotation.
It should be a reasonable value that usually doesn't occur in HTML
documents. Thus setting this to `<h1>' would be quite stoopid ;)"
  :type 'string
  :group 'bravegnuworld)
(defcustom bravegnuworld-start-comment-converted "<font color=\"red\">"
  "The starting tag to be inserted when saving the file. This should
be a HTML tag which makes it easy for Georg to find it."
  :type 'string
  :group 'bravegnuworld)
(defcustom bravegnuworld-end-comment-converted "</font>"
  "The closing tag to be inserted when saving the file. This should
be a HTML tag which makes it easy for Georg to find it"
  :type 'string
  :group 'bravegnuworld)

;(defun bravegnuworld-mode ()
;  "Mode for the test-readers of Georg C. Greves Brave Gnu World column
; that you can find at http://www.gnu.org/brave-gnu-world/. You may enter
;annotations with C-c C-c, delete annotations with C-c C-d and the
;remaining annotations get converted when saving the file, defaults to
;a red font."
;  (kill-all-local-variables')
;  (setq major-mode 'bravegnuworld-mode)
;  (setq mode-name "BGW")
;  (if (boundp 'mode-line-modified)
;      (setq mode-line-modified (default-value 'mode-line-modified))
;    (setq mode-line-format (default-value 'mode-line-format)))
;  (run-hooks 'text-mode-hook 'bravegnuworld-mode-hook))
(define-derived-mode bravegnuworld-mode html-mode "BGW"
  "Mode for the test-readers of Georg C. Greves Brave Gnu World column
 that you can find at http://www.gnu.org/brave-gnu-world/. You may enter
annotations with C-c C-c, delete annotations with C-c C-d and the
remaining annotations get converted when saving the file to a HTML tag
which defaults to a red font. When the point is in a converted
annotation that gets deleted.
Keybindings:
\\{bravegnuworld-mode-map}"
;;  (local-unset-key "C-cC-c")
  (define-key bravegnuworld-mode-map
	[(control ?c) (control ?c)] 'bravegnuworld-annotation)
  (define-key bravegnuworld-mode-map
	[(control ?c) (control ?d)] 'bravegnuworld-delete-annotation)

 ;; (append
  (add-hook 'local-write-file-hooks 
			'(lambda ()
			   (bravegnuworld-convert-to-tag)
			   ))
  (put 'bravegnuworld-mode 'font-lock-defaults '(html-font-lock-keywords nil t))
  (run-hooks 'bravegnuworld-mode-hook)
  )

(defun bravegnuworld-annotation ()
  "Start an annotation for Georg. This defun automagically detects the
following cases:
* not in an annotation:
      start a new one
* point in an open annotation:
      close this one
* point in a converted annotation
      delete it (mainly for Georg)."
  (interactive)
  (let ((pattern
		(concat bravegnuworld-start-comment "\\|"
				bravegnuworld-end-comment "\\|"
				bravegnuworld-start-comment-converted "\\|"
				bravegnuworld-end-comment-converted)))
	(save-excursion
	  (re-search-backward pattern nil t)
	  (setq action
			(cond ((looking-at bravegnuworld-start-comment)
			 "end")
			((looking-at bravegnuworld-start-comment-converted)
			 "deconv")
			(t "start"))))
	(cond ((string-match "end" action)
		   (insert bravegnuworld-end-comment))
		  ((string-match "deconv" action)
		   (bravegnuworld-delete-tagged-annotation))
		  ((string-match "start" action)
		   (insert bravegnuworld-start-comment))))
	)

(defun bravegnuworld-delete-annotation ()
  "Delete the next (not converted) annotation before the point."
  (interactive)
	(let
		((st (re-search-backward  bravegnuworld-start-comment nil t))
		 (en (re-search-forward  bravegnuworld-end-comment nil t)))
	(kill-region st en)
	(goto-char st))	
  )
(defun bravegnuworld-delete-tagged-annotation ()
  "Delete the already converted annotation the point is in.
This is mainly useful for The Georg Himself ;-)."
  (interactive)
	(let
		((st (re-search-backward  bravegnuworld-start-comment-converted nil t))
		 (en (re-search-forward  bravegnuworld-end-comment-converted nil t)))
	(kill-region st en)
	(goto-char st))
	)

(defun bravegnuworld-convert-to-tag ()
  "This function gets called when saving a BGW file. It converts the
strings given in `bravegnuworld-start-comment' and
`bravegnuworld-end-comment' to the strings given in
`bravegnuworld-start-comment-converted' and
`bravegnuworld-end-comment-converted' respectively."
  (interactive)
  (message "Converting BrveGNUWorld annotations to HTML tags")
  (beginning-of-buffer)
  (while (search-forward bravegnuworld-start-comment nil t)
    (replace-match bravegnuworld-start-comment-converted nil t))
  (beginning-of-buffer)
  (while (search-forward bravegnuworld-end-comment nil t)
    (replace-match bravegnuworld-end-comment-converted nil t))
  )

