(defun debug-ignore (c h)
  (declare (ignore h))
  (print c)
  (abort))
(setf *debugger-hook* #'debug-ignore)
(load "~/quicklisp/setup.lisp")
(ql:quickload 'cl-fastcgi)

(defun simple-app (req)
  (let ((c (format nil "Content-Type: text/plain

Hello, I am a fcgi-program using Common-Lisp")))
    (cl-fastcgi:fcgx-puts req c)))

(defun main (argv)
  (cl-fastcgi:simple-server #'simple-app))
