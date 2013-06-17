;; Gregorio mode for Emacs.
;; Copyright (C) 2013 John Jenkins
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

;; here are the faces for syntax coloring.
;; change them here. 

(setq
 comment-face      'font-lock-comment-face
 keyword-face      'font-lock-constant-face
 title-fields-face 'font-lock-builtin-face
 notes-face        'font-lock-keyword-face
 modifiers-face    'font-lock-preprocessor-face
 text-face         'bold
 accented-face     'bold
)

;; the keywords that are in the beginning of a gabc file. [meta-data]

(setq gregorio-keywords
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
	"style"
	))

;; you can add to the list if necessary, just include the quotes for each item.

;;;; The rest of the file shouldn't need to be modified, but feel free to do so!

;; The various types of syntax coloring. Change the faces at the beginning of the file.

;; comments start with % on the beginning of the line.
(setq gregorio-comments-regexp "^%.?+")
;; keywords list as regexp
(setq gregorio-keywords-regexp
      (regexp-opt gregorio-keywords))
;; fields in other face, just because we can 
(setq gregorio-title-fields-regexp ":.+;")
;; the notes are always in parens, treat them like keywords
(setq gregorio-notes-regexp "([^)]+)")
;; the text in a special face so we can read it easier
(setq gregorio-text-regexp "\\ca\\|æ\\|œ") 
;; sometimes control characters
(setq gregorio-modifiers-regexp "{[^}]+}")
;; accented characters. Can also put vowels in different face if wanted.
(setq gregorio-text-accented-regexp
      (regexp-opt '("á" "é" "í" "ó" "ú")))

;; set the faces. 

(setq gregorio-font-lock-keywords
      `((,gregorio-comments-regexp . comment-face)
	(,gregorio-keywords-regexp . keyword-face)
	(,gregorio-title-fields-regexp . title-fields-face)
	(,gregorio-notes-regexp . notes-face)
	(,gregorio-modifiers-regexp . modifiers-face)
	(,gregorio-text-regexp . text-face)
	(,gregorio-text-accented-regexp . accented-face)))

(defun gregorio-to-tex ()
  "convert buffer to tex, output to another buffer"
  (interactive)
  (setf new-tex (concat (file-name-base) ".tex"))
  (shell-command-on-region
   (point-min) (point-max)
   "gregorio -sS"
   new-tex
   nil 't)
   (switch-to-buffer-other-window new-tex)
   (tex-mode)) ;; new buffer is in tex-mode for syntax coloring and ready to save!

;; Keyboard bindings

(global-set-key [f1] 'gregorio-to-tex) ;; to-tex in another buffer.

;; define the derived mode. Note we use tex-mode as basis.

(define-derived-mode gregorio-mode tex-mode
  "gregorio"
  "Major Mode for editing .gabc files"
  
  (setq font-lock-defaults '((gregorio-font-lock-keywords)))
)

;; hooks for opening .gabc files, so this mode loads automatically.

(or (assoc "\\.gabc$" auto-mode-alist)
    (setq auto-mode-alist (cons '("\\.gabc$" . gregorio-mode) auto-mode-alist)))

;; let's wrap it all up.

(provide 'gregorio-mode)

