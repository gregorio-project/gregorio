;; Gregorio mode for Emacs.
;; Copyright (C) 2013 John Jenkins
;;
;; URL: https://github.com/cajetanus/gregorio-mode.el
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;; 
;; This is a derived-major-mode for editing GABC files.
;; For information on Gregorio, please see:
;; http://home.gna.org/gregorio/
;; 
;; See https://github.com/cajetanus/gregorio-mode.el for updates, documentation
;; and more details.
;; 

;; Keyboard bindings. Change them here

(defvar gregorio-mode-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'gregorio-to-tex)
    (define-key map (kbd "C-c u") 'gregorio-transpose-region-up)
    (define-key map (kbd "C-c d") 'gregorio-transpose-region-down)
    (define-key map (kbd "C-M-f") 'gregorio-next-parens)
    (define-key map (kbd "C-M-b") 'gregorio-prev-parens)
    (define-key map (kbd "C-c f") 'gregorio-fill-parens)
    map)
  "Keymap used for gregorio-mode.")

;; Here are the faces for syntax coloring. To modify them you can:
;; 1) Change them here.
;; 2) Use M-x customize-group RET gregorio-faces RET
;; 3) Redefine them in your emacs init file.
;;    i.e. (set-face-foreground 'gregorio-comment "Green")

(defgroup gregorio-faces nil
  "Faces used by gregorio-mode."
  :group 'gregorio
  :group 'faces)

(defface gregorio-comment
  '((t (:inherit font-lock-comment-face)))
  "Face used for comments."
  :group 'gregorio-faces)
(defvar gregorio-comment-face 'gregorio-comment
  "Face name used for comments.")

(defface gregorio-keyword
  '((t (:inherit font-lock-constant-face)))
  "Face used for header attributes."
  :group 'gregorio-faces)
(defvar gregorio-keyword-face 'gregorio-keyword
  "Face name used for header attributes.")

(defface gregorio-title-fields
  '((t (:inherit font-lock-builtin-face)))
  "Face used for values of header attributes."
  :group 'gregorio-faces)
(defvar gregorio-title-fields-face 'gregorio-title-fields
  "Face name used for values of header attributes.")

(defface gregorio-notes
  '((t (:inherit font-lock-keyword-face)))
  "Face used for notes."
  :group 'gregorio-faces)
(defvar gregorio-notes-face 'gregorio-notes
  "Face name used for notes.")

(defface gregorio-modifiers
  '((t (:inherit font-lock-preprocessor-face)))
  "Face used for control characters."
  :group 'gregorio-faces)
(defvar gregorio-modifiers-face 'gregorio-modifiers
  "Face name used for control characters.")

(defface gregorio-html
  '((t (:inherit nobreak-space)))
  "Face used for html code."
  :group 'gregorio-faces)
(defvar gregorio-html-face 'gregorio-html
  "Face name used for html code.")

(defface gregorio-text
  '((t (:inherit bold)))
  "Face used for regular text."
  :group 'gregorio-faces)
(defvar gregorio-text-face 'gregorio-text
  "Face name used for regular text.")

(defface gregorio-accented
  '((t (:inherit bold)))
  "Face used for accented text."
  :group 'gregorio-faces)
(defvar gregorio-accented-face 'gregorio-accented
  "Face name used for accented text.")

(defcustom gregorio-keywords
      '("name"
	"gabc-copyright"
	"score-copyright"
	"office-part"
	"occasion"
	"meter"
	"commentary"
	"arranger"
	"gabc-version"
	"author"
	"date"
	"manuscript"
	"manuscript-reference"
	"manuscript-storage-place"
	"book"
	"transcriber"
	"transcription-date"
	"gregoriotex-font"
	"mode"
	"initial-style"
	"centering-scheme"
	"user-notes"
	"annotation"
	"style")
   "List of possible attribues for the header in gabc files. [meta-data]

You can add to the list if necessary with either one of the following options:
  1) M-x customize-group RET gregorio RET
  2) Adding to your emacs init:

       (font-lock-add-keywords 'gregorio-mode
         '((\"\\\\(NEWKEYWORD\\\\)\" (0 gregorio-keyword-face))))

  3) Edit this file."
  :group 'gregorio)

;;;; The rest of the file shouldn't need to be modified, but feel free to do so!

;; The various types of syntax coloring. Change the faces at the beginning of
;; the file.

(defvar gregorio-comments-regexp "^%.?+"
  "Regexp for comments which start with % on the beginning of the line.")

(defvar gregorio-keywords-regexp (regexp-opt gregorio-keywords)
  "Regexp for header attributes.")

(defvar gregorio-title-fields-regexp ":.+[^()];"
  "Regexp for the values of keywords.")

(defvar gregorio-notes-regexp "([^)]+)"
  "Regexp for the notes contained within ()'s.")

(defvar gregorio-text-regexp "\\ca\\|æ\\|œ"
  "Regexp for sepcial text so it can be read easier.")

(defvar gregorio-modifiers-regexp "{[^}]+}"
  "Regexp for control characters.")

(defvar gregorio-text-accented-regexp (regexp-opt '("á" "é" "í" "ó" "ú"))
  "Regexp for accented vowels.")

(defvar gregorio-html-text-regexp "<[^>]+>"
  "Regexp for html tags.")

;; set the faces.

(defvar gregorio-font-lock-keywords
  (list
   (list gregorio-comments-regexp '(0 gregorio-comment-face))
   (list gregorio-keywords-regexp '(0 gregorio-keyword-face))
   (list gregorio-title-fields-regexp '(0 gregorio-title-fields-face))
   (list gregorio-notes-regexp '(0 gregorio-notes-face))
   (list gregorio-modifiers-regexp '(0 gregorio-modifiers-face))
   (list gregorio-html-text-regexp '(0 gregorio-html-face))
   (list gregorio-text-regexp '(0 gregorio-text-face))
   (list gregorio-text-accented-regexp '(0 gregorio-accented-face))
   )
  "Expressions to highligh in gregorio mode.")

(defvar gregorio-mode-hook nil
  "Function(s) to call after starting up gregorio-mode.")

(defun gregorio-to-tex (&optional arg)
  "Convert buffer to tex, output to another buffer.

With a prefix argument, save buffer and execute gregorio on the buffer's file."
  (interactive "P")
  (if arg (progn
	    (save-buffer)
	    (shell-command
	     (concat "gregorio " buffer-file-name) nil "*Gregorio Error*"))
    (progn
      (setf new-tex (concat (file-name-base) ".tex"))
      (shell-command-on-region
       (point-min) (point-max)
       "gregorio -sS"
       new-tex
       nil 't)
      (switch-to-buffer-other-window new-tex)
      (tex-mode))))
;; new buffer is in tex-mode for syntax coloring and ready to save!

(defun gregorio-transpose-region-up (start end arg)
  "Transpose region upwards by one diatonic step.

With a numerical prefix argument, transpose by N diatonic steps.
i.e. C-u 2 \\[gregorio-transpose-region-up] Will transpose the region
upwards by two steps.

N.B. This function does not check to see if the resulting score
will be out of range for gregorio. i.e. a tone higher than 'm'."
  (interactive "r\np")
  (unless arg (setq arg '(1)))
  (save-restriction
    (narrow-to-region start end)
    (goto-char 1)
    (let ((case-fold-search nil))
      (while (search-forward-regexp "(\\([^)]+\\))" nil t)
	(replace-match
	 (concat "("
		 (replace-regexp-in-string "[a-mA-M]"
		    (lambda (char) (char-to-string
				    (+ (string-to-char char) arg)))
		    (match-string 1) t)
		 ")")
	 t)))))

(defun gregorio-transpose-region-down (start end arg)
  "Transpose region downwards by one diatonic step.

With a numerical prefix argument, transpose by N diatonic steps.
i.e. C-u 2 \\[gregorio-transpose-region-down] Will transpose the region
downwards by two steps.

N.B. This function does not check to see if the resulting score
will be out of range for gregorio. i.e. a tone lower than 'a'."
  (interactive "r\np")
  (unless arg (setq arg '(1)))
  (save-restriction
    (narrow-to-region start end)
    (goto-char 1)
    (let ((case-fold-search nil))
      (while (search-forward-regexp "(\\([^)]+\\))" nil t)
	(replace-match
	 (concat "("
		 (replace-regexp-in-string "[a-mA-M]"
		    (lambda (char) (char-to-string
				    (- (string-to-char char) arg)))
		    (match-string 1) t)
		 ")")
	 t)))))

(defun gregorio-fill-parens (start end note)
  "Fills empty parentheses with note.

Bound to C-c f by default"

  (interactive "r\nsNote to fill with: ")
  (save-restriction
    (narrow-to-region start end)
    (goto-char 1)
    (while (search-forward "()" nil t)
      (replace-match
       (concat "(" note ")")
       t))))

(defun gregorio-next-parens (&optional arg)
  "Move forward to the next punctum group.
With ARG, do it that many times. Negative arg -N means
move backward N punctum groups.

forward-sexp (C-M-f) is remaped to this function by default."

  (interactive "p")
  (or arg (setq arg 1))
  (goto-char (search-forward "(" nil nil arg)))

(defun gregorio-prev-parens (&optional arg)
  "Move backward to the previous punctum group.
With ARG, do it that many times. Negative arg -N means
move forward N punctum groups.

backward-sexp (C-M-b) is remaped to this function by default."

  (interactive "p")
  (or arg (setq arg 1))
  (goto-char (search-backward ")" nil nil arg)))

;; define the derived mode. Note we use tex-mode as basis.

(define-derived-mode gregorio-mode tex-mode
  "gregorio"
  "Major Mode for editing .gabc files.

This mode executes a hook `gregorio-mode-hook'.
The customization group is 'gregorio'.

Commands:
\\{gregorio-mode-keymap}"

  (set (make-local-variable 'font-lock-defaults)
       '(gregorio-font-lock-keywords))
  (use-local-map gregorio-mode-keymap)
  (run-hooks 'gregorio-mode-hook))

;; hooks for opening .gabc files, so this mode loads automatically.

(or (assoc "\\.gabc$" auto-mode-alist)
    (add-to-list 'auto-mode-alist '("\\.gabc\\'" . gregorio-mode)))

;; let's wrap it all up.

(provide 'gregorio-mode)
