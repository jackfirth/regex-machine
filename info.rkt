#lang info

(define empty-list (list))

(define pkg-name "regex-machine")

(define collection "regex-machine")

(define deps
  (list "base"
        "gui-lib"
        "pict-lib"
        "reprovide-lang"))

(define build-deps '("rackunit-lib"
                     "racket-doc"
                     "scribble-lib"))

(define scribblings
  (list (list "main.scrbl"
              empty-list
              (list "Teaching")
              "regex-machine")))
