#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [char-instruction (-> char? char-instruction?)]
  [char-instruction? (-> any/c boolean?)]
  [char-instruction-unwrap (-> char-instruction? char?)]
  [match-instruction match-instruction?]
  [match-instruction? (-> any/c boolean?)]
  [jmp-instruction (-> natural? jmp-instruction?)]
  [jmp-instruction? (-> any/c boolean?)]
  [jmp-instruction-target (-> jmp-instruction? natural?)]
  [split-instruction (-> natural? natural? split-instruction?)]
  [split-instruction? (-> any/c boolean?)]
  [split-instruction-target (-> split-instruction? natural?)]
  [split-instruction-fork-target (-> split-instruction? natural?)]
  [instruction? (-> any/c boolean?)]
  [instruction->string (-> instruction? string?)]
  [program (-> instruction? instruction? ... program?)]
  [program? (-> any/c boolean?)]
  [program-instructions (-> program? (listof instruction?))]
  [example-program program?]))

(require racket/function
         racket/math
         racket/struct)

;@------------------------------------------------------------------------------

(struct char-instruction (unwrap) #:omit-define-syntaxes #:transparent)

(struct match-instruction ()
  #:omit-define-syntaxes #:constructor-name plain-match-instruction)

(define match-instruction (plain-match-instruction))

(struct jmp-instruction (target)
  #:omit-define-syntaxes
  #:transparent)

(struct split-instruction (target fork-target)
  #:omit-define-syntaxes
  #:transparent)

(define instruction?
  (disjoin char-instruction?
           match-instruction?
           jmp-instruction?
           split-instruction?))

(struct program (instructions)
  #:constructor-name plain-program
  #:omit-define-syntaxes
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (λ (this) 'program)
      (λ (this) (program-instructions this))))])

(define (program . instructions) (plain-program instructions))

(define example-program
  (program (split-instruction 1 3)
           (char-instruction #\a)
           (jmp-instruction 0)
           (char-instruction #\b)
           (split-instruction 5 7)
           (char-instruction #\b)
           (jmp-instruction 4)
           match-instruction))

(define (instruction->string instruction)
  (cond
    [(char-instruction? instruction)
     (format "CHAR ~a"
             (char-instruction-unwrap instruction))]
    [(split-instruction? instruction)
     (format "SPLIT ~a ~a"
             (split-instruction-target instruction)
             (split-instruction-fork-target instruction))]
    [(jmp-instruction? instruction)
     (format "JMP ~a" (jmp-instruction-target instruction))]
    [(match-instruction? instruction)
     "MATCH"]))
