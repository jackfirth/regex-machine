#lang info

(define empty-list (list))

(define pkg-name "regex-vm")

(define collection "regex-vm")

(define deps
  (list "base"
        "gui-lib"
        "pict-lib"
        "reprovide-lang"))

(define build-deps '("racket-doc"
                     "scribble-lib"))

(define scribblings
  (list (list "main.scrbl"
              empty-list
              (list "Teaching")
              "regex-vm")))
