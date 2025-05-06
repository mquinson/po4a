;;; Emacs per-directory local variables.
;;; Copyright © 2025 gemmaro <gemmaro.dev@gmail.com>
;;;
;;; This program is free software; you can redistribute it and/or modify it
;;; under the terms of GPL v2.0 or later (see COPYING).

;; Per-directory local variables for GNU Emacs 23 and later.
((nil
  . (;; For use with 'bug-reference-prog-mode'.

     ;; 1. bug reference region
     ;; 2. issue number
     ;; 3. issue kind
     ;;    - GitHub
     (eval . (setq-local bug-reference-bug-regexp
                         (rx (group
                              (or
                               (seq word-boundary (group-n 3 "GitHub") "'s #"
                                    (group-n 2 (+ digit)))
                               (seq word-boundary (group-n 3 "Debian") "'s #"
                                    (group-n 2 (+ digit))))))))

     (eval . (setq-local bug-reference-url-format
                         (lambda ()
                           (let ((num (match-string 2))
                                 (kind (match-string 3)))
                             (cond
                              ((string= kind "GitHub")
                               (concat "https://github.com/mquinson/po4a/pull/" num))
                              ((string= kind "Debian")
                               (concat
                                "https://bugs.debian.org/cgi-bin/bugreport.cgi?bug="
                                num))))))))))
