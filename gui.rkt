#lang racket

(require pict
         racket/gui
         regex-machine)

(define (step-visualizer f init-string from-string to-pict)
  (define state (box #f))
  (define (set-state! new-state)
    (set-box! state new-state)
    (send pict-canvas min-width
          (exact-ceiling (pict-width new-state)))
    (send pict-canvas min-height
          (exact-ceiling (pict-height new-state)))
    (send pict-canvas refresh))
  (define frame
    (new frame%
         [label "Stepper"]
         [alignment '(center center)]
         [width 400]
         [spacing 20]))
  (define controls-pane
    (new horizontal-pane% [parent frame]))
  (define input-field
    (new text-field%
         [parent controls-pane]
         [label "Input"]
         [init-value init-string]))
  (define reset-button
    (new button%
         [parent controls-pane]
         [label "Reset"]
         [callback (λ (unused-button unused-event)
                     (set-state! (from-string (send input-field get-value))))]))
  (define next-button
    (new button%
         [parent controls-pane]
         [label "Step"]
         [callback (λ (unused-button unused-event)
                     (set-state! (f (unbox state))))]))
  (define pict-canvas
    (new canvas%
         [parent frame]
         [paint-callback (λ (unused-canvas dc)
                           (draw-pict (to-pict (unbox state)) dc 0 0))]))
  (set-state! (from-string init-string))
  (send frame show #t))

(define char-instruction-demo-program
  (program (char-instruction #\a)
           (char-instruction #\b)
           (char-instruction #\c)
           match-instruction))

(define jmp-instruction-demo-program
  (program (char-instruction #\a)
           (jmp-instruction 4)
           (char-instruction #\b)
           (char-instruction #\c)
           match-instruction))

(module+ main
  (step-visualizer vm-step
                   "aaabc"
                   (λ (input-string)
                     (vm example-program
                         input-string))
                   (λ (machine)
                     (and machine (vm-pict machine #:hide-input? #t)))))
