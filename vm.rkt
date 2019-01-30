#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [vm (-> program? string? vm?)]
  [vm? (-> any/c boolean?)]
  [vm-program (-> vm? program?)]
  [vm-input (-> vm? string?)]
  [vm-status (-> vm? status/c)]
  [vm-run (-> vm? #:steps natural? vm?)]
  [vm-step (-> vm? vm?)]
  [vm-threads (-> vm? (listof vm-thread?))]
  [vm-pict (->* (vm?) (#:hide-input? boolean?) pict?)]
  [vm-thread? (-> any/c boolean?)]
  [vm-thread-status (-> vm-thread? status/c)]
  [vm-thread-program-counter (-> vm-thread? natural?)]
  [vm-thread-character-counter (-> vm-thread? natural?)]
  [status/c flat-contract?]
  [example-input string?]))

(require file/convertible
         pict
         pict/conditional
         pict/convert
         racket/list
         racket/math
         regex-vm/program)

(module+ test
  (require (submod "..")
           rackunit))

;@------------------------------------------------------------------------------

(define status/c (or/c 'running 'success 'failure))

(struct vm-thread (status program-counter character-counter)
  #:omit-define-syntaxes
  #:constructor-name plain-vm-thread
  #:transparent)

(define (vm-thread #:status status
                   #:program-counter pc
                   #:character-counter ac)
  (plain-vm-thread status pc ac))

(define main-thread
  (vm-thread #:program-counter 0
             #:character-counter 0
             #:status 'running))

(define (running-vm-thread? v)
  (and (vm-thread? v)
       (equal? (vm-thread-status v) 'running)))

(define (completed-vm-thread? v)
  (or (successful-vm-thread? v)
      (failed-vm-thread? v)))

(define (successful-vm-thread? v)
  (and (vm-thread? v)
       (equal? (vm-thread-status v) 'success)))

(define (failed-vm-thread? v)
  (and (vm-thread? v)
       (equal? (vm-thread-status v) 'failure)))

(define (vm-thread-set-program-counter thd pc)
  (vm-thread #:status (vm-thread-status thd)
             #:program-counter pc
             #:character-counter (vm-thread-character-counter thd)))

(define (vm-thread-increment-both-counters thd)
  (vm-thread #:status (vm-thread-status thd)
             #:program-counter (add1 (vm-thread-program-counter thd))
             #:character-counter (add1 (vm-thread-character-counter thd))))

(define (vm-thread-set-failed thd)
  (vm-thread #:status 'failure
             #:program-counter (vm-thread-program-counter thd)
             #:character-counter (vm-thread-character-counter thd)))

(define (vm-thread-set-successful thd)
  (vm-thread #:status 'success
             #:program-counter (vm-thread-program-counter thd)
             #:character-counter (vm-thread-character-counter thd)))

(struct execution-step (updated-thread forked-thread))

(struct vm (program input threads)
  #:omit-define-syntaxes
  #:constructor-name plain-vm
  #:transparent

  #:property prop:pict-convertible
  (λ (this) (vm-pict this))

  #:property prop:convertible
  (λ (this request default)
    (convert (pict-convert this) request default)))

(define (vm program input #:threads [threads (list main-thread)])
  (plain-vm program input threads))

(define (vm-thread-count machine)
  (length (vm-threads machine)))

(define (vm-update-thread machine position thread-updater)
  (define updated-threads
    (list-update (vm-threads machine) position thread-updater))
  (vm (vm-program machine) (vm-input machine) #:threads updated-threads))

(define (vm-copy-thread machine position)
  (define threads (vm-threads machine))
  (define updated-threads (append threads (list (list-ref threads position))))
  (vm (vm-program machine) (vm-input machine) #:threads updated-threads))

(define (status->priority-ordering status)
  (case status [(success) 3] [(running) 2] [(failure) 1]))

(define (vm-status machine)
  (define thread-statuses (map vm-thread-status (vm-threads machine)))
  (argmax status->priority-ordering thread-statuses))

(define (vm-run machine #:steps [n 1])
  (if (zero? n)
      machine
      (vm-run (vm-step machine) #:steps (sub1 n))))

(define (vm-step machine)
  (for/fold ([machine machine])
            ([thread-num (in-range 0 (vm-thread-count machine))])
    (define action (vm-next-thread-action machine thread-num))
    (vm-perform-thread-action machine thread-num action)))

(define (vm-next-instruction machine thread-number)
  (define thread (list-ref (vm-threads machine) thread-number))
  (define instructions (program-instructions (vm-program machine)))
  (define instruction-position (vm-thread-program-counter thread))
  (and (< instruction-position (length instructions))
       (list-ref instructions instruction-position)))

(define (vm-next-character machine thread-number)
  (define thread (list-ref (vm-threads machine) thread-number))
  (define input (vm-input machine))
  (define input-position (vm-thread-character-counter thread))
  (and (< input-position (string-length input))
       (string-ref input input-position)))

(define (vm-has-more-characters? machine thread-number)
  (and (vm-next-character machine thread-number) #t))

(struct thread-action (function))

(struct copy-action ()
  #:constructor-name plain-copy-action
  #:omit-define-syntaxes)

(define copy-action (plain-copy-action))

(struct composite-action (components)
  #:constructor-name plain-composite-action
  #:omit-define-syntaxes)

(define (composite-action . actions)
  (plain-composite-action
   (append-map (λ (act)
                 (if (composite-action? act)
                     (composite-action-components act)
                     (list act)))
               actions)))

(define (vm-perform-thread-action machine thread-number action)
  (cond
    [(thread-action? action)
     (vm-update-thread machine thread-number (thread-action-function action))]
    [(copy-action? action) (vm-copy-thread machine thread-number)]
    [else
     (for/fold ([machine machine])
               ([component (composite-action-components action)])
       (vm-perform-thread-action machine thread-number component))]))

(define empty-action (composite-action))
(define fail-action (thread-action vm-thread-set-failed))
(define succeed-action (thread-action vm-thread-set-successful))
(define char-action (thread-action vm-thread-increment-both-counters))

(define (jump-action target)
  (thread-action (λ (thd) (vm-thread-set-program-counter thd target))))


(define (vm-next-thread-action machine thread-number)
  (define thread (list-ref (vm-threads machine) thread-number))
  (define instruction (vm-next-instruction machine thread-number))
  (cond
    [(completed-vm-thread? thread) empty-action]
    [(not instruction) fail-action]
    [(char-instruction? instruction)
     (define next-char-matches?
       (equal? (char-instruction-unwrap instruction)
               (vm-next-character machine thread-number)))
     (if next-char-matches? char-action fail-action)]
    [(match-instruction? instruction)
     (if (vm-has-more-characters? machine thread-number)
         fail-action
         succeed-action)]
    [(jmp-instruction? instruction)
     (jump-action (jmp-instruction-target instruction))]
    [(split-instruction? instruction)
     (define target (split-instruction-target instruction))
     (define fork-target (split-instruction-fork-target instruction))
     (composite-action (jump-action fork-target)
                       copy-action
                       (jump-action target))]))

(define thread-colors
  (list "Red"
        "Blue"
        "Green"
        "Yellow"
        "Cyan"
        "Purple"
        "Orange"
        "Pink"
        "LightGreen"
        "LightBlue"
        "DarkRed"
        "Tomato"
        "Maroon"
        "LightCoral"
        "LightPink"
        "DarkOrange"
        "Salmon"
        "YellowGreen"
        "SeaGreen"
        "Turquoise"
        "RoyalBlue"
        "SkyBlue"
        "MidnightBlue"
        "CadetBlue"
        "Indigo"
        "SlateBlue"
        "DimGray"
        "Black"))

(define (vm-text str) (text str empty 24))
(define (vm-input-text str) (text str empty 36))

(define (pict-pad pict
                  #:up [up 0]
                  #:down [down 0]
                  #:left [left 0]
                  #:right [right 0])
  (define w (+ (pict-width pict) left right))
  (define h (+ (pict-height pict) up down))
  (define base (blank w h))
  (pin-over base left up pict))

(define (pict-expand-right pict min-width)
  (if (< (pict-width pict) min-width)
      (pin-over (blank min-width (pict-height pict)) 0 0 pict)
      pict))

(define (pict-expand-down pict min-height)
  (if (< (pict-height pict) min-height)
      (pin-over (blank (pict-width pict) min-height) 0 0 pict)
      pict))

(define (vm-pict vm #:hide-input? [hide-input? #f])
  (define prog (vm-program vm))
  (define input-string (vm-input vm))
  (define threads (vm-threads vm))
  (define prog-pict
    (table 2
           (flatten
            (for/list ([instruction (in-list (program-instructions prog))]
                       [n (in-naturals)])
              (define index-pict (vm-text (number->string n)))
              (define instruction-pict
                (vm-text
                 (instruction->string instruction)))
              (define thread-picts
                (for/list ([thread (in-list threads)]
                           [color (in-list thread-colors)])
                  (pict-if #:combine cc-superimpose
                           (equal? (vm-thread-program-counter thread) n)
                           (disk 15 #:color color)
                           (blank 20))))
              (list (hc-append (pict-expand-right (apply hc-append thread-picts)
                                                  400)
                               index-pict)
                    instruction-pict)))
           lc-superimpose
           cc-superimpose
           40
           10))
  (define input-pict (vm-input-text input-string))
  (define thread-status-pict
    (table 3
           (flatten
            (for/list ([thread (in-list threads)]
                       [color (in-list thread-colors)])
              (define cc (vm-thread-character-counter thread))
              (list (disk 15 #:color color)
                    (pict-expand-right (vm-text
                                        (symbol->string
                                         (vm-thread-status thread)))
                                       150)
                    (vm-text (substring input-string 0 cc)))))
           lc-superimpose
           cc-superimpose
           20
           10))
  (define state-pict
    (ht-append 100
               (frame (pict-pad prog-pict
                                #:up 20
                                #:down 20
                                #:left 20
                                #:right 20)
                      #:line-width 2)
               (pict-expand-right (frame (pict-pad
                                          (pict-expand-right
                                           (pict-expand-down
                                            thread-status-pict
                                            500)
                                           400)
                                          #:up 20
                                          #:down 20
                                          #:left 20
                                          #:right 20)
                                         #:line-width 2)
                                  300)))
  (define content-pict
    (if hide-input? state-pict (vl-append 40 input-pict state-pict)))
  (pict-pad content-pict
            #:up 20
            #:down 20
            #:left 20
            #:right 20))

(define example-input "aaaabbb")
(define example-vm (vm example-program example-input))

(module+ test
  (test-case "trivial-match-program"
    (define trivial-match-program (program match-instruction))

    (test-case "no-input-left"
      (define machine (vm trivial-match-program ""))
      (check-equal? (vm-status machine) 'running)
      (check-equal? (vm-status (vm-step machine)) 'success))

    (test-case "some-input-left"
      (define machine (vm trivial-match-program "a"))
      (check-equal? (vm-status machine) 'running)
      (check-equal? (vm-status (vm-step machine)) 'failure)))
    
  (test-case "trivial-char-program"
    (define trivial-char-program
      (program (char-instruction #\a)
               match-instruction))

    (test-case "next-char-matches"
      (define machine (vm trivial-char-program "a"))
      (check-equal? (vm-status machine) 'running)
      (check-equal? (vm-status (vm-run machine #:steps 1)) 'running)
      (check-equal? (vm-status (vm-run machine #:steps 2)) 'success))

    (test-case "next-char-does-not-match"
      (define machine (vm trivial-char-program "b"))
      (check-equal? (vm-status machine) 'running)
      (check-equal? (vm-status (vm-run machine #:steps 1)) 'failure))

    (test-case "end-of-input"
      (define machine (vm trivial-char-program ""))
      (check-equal? (vm-status machine) 'running)
      (check-equal? (vm-status (vm-run machine #:steps 1)) 'failure)))

  (test-case "trivial-jmp-program"
    (define trivial-jmp-program
      (program (jmp-instruction 2)
               (char-instruction #\a)
               match-instruction))
    (define machine (vm trivial-jmp-program ""))
    (check-equal? (vm-status machine) 'running)
    (check-equal? (vm-status (vm-run machine #:steps 1)) 'running)
    (check-equal? (vm-status (vm-run machine #:steps 2)) 'success))

  (test-case "trivial-split-program"
    (define trivial-split-program
      (program (split-instruction 1 3)
               (char-instruction #\a)
               match-instruction
               (char-instruction #\b)
               match-instruction))
    (define machine (vm trivial-split-program ""))
    (check-equal? (vm-thread-count machine) 1)
    (define machine/split (vm-run machine #:steps 1))
    (check-equal? (vm-status machine/split) 'running)
    (check-equal? (vm-thread-count machine/split) 2)
    
    (test-case "first-branch-matches"
      (define machine (vm trivial-split-program "a"))
      (check-equal? (vm-status (vm-run machine #:steps 3)) 'success))
    
    (test-case "second-branch-matches"
      (define machine (vm trivial-split-program "b"))
      (check-equal? (vm-status (vm-run machine #:steps 3)) 'success))
    
    (test-case "neither-branch-matches"
      (define machine (vm trivial-split-program "z"))
      (check-equal? (vm-status (vm-run machine #:steps 2)) 'failure)))

  (test-case "even-number-of-as-program"
    (define even-number-of-as-program
      (program (split-instruction 1 4)
               (char-instruction #\a)
               (char-instruction #\a)
               (jmp-instruction 0)
               match-instruction))

    (test-case "even-as"
      (define machine (vm even-number-of-as-program "aaaa"))
      (check-equal? (vm-status (vm-run machine #:steps 100)) 'success))

    (test-case "odd-as"
      (define machine (vm even-number-of-as-program "aaaaa"))
      (check-equal? (vm-status (vm-run machine #:steps 100)) 'failure))

    (test-case "zero-as"
      (define machine (vm even-number-of-as-program ""))
      (check-equal? (vm-status (vm-run machine #:steps 100)) 'success))))
