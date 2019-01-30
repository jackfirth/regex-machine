#lang scribble/manual

@(require (for-label racket/base
                     racket/contract/base
                     racket/math
                     regex-vm)
          scribble/example)

@(define module-sharing-evaluator-factory
   (make-base-eval-factory (list 'racket/base 'regex-vm)))

@(define (make-evaluator)
   (define evaluator (module-sharing-evaluator-factory))
   (evaluator '(require regex-vm))
   evaluator)

@title{Regex Machine Language}
@defmodule[regex-vm]

@section{Programs and Instructions}

@defproc[(program? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a regex machine program.}

@defproc[(program [inst instruction?] ...) program?]{
 Constructs a regex machine program comprised of the given @racket[inst]s.

 @(examples
   #:eval (make-evaluator) #:once
   (program (char-instruction #\a)
            (char-instruction #\b)
            (split-instruction 3 5)
            (char-instruction #\x)
            match-instruction
            (char-instruction #\y)
            match-instruction))}

@defthing[example-program program?]{
 The example program. Used in documentation examples and in tests.

 @(examples
   #:eval (make-evaluator) #:once
   example-program)}

@defproc[(program-instructions [prog program?]) (listof instruction?)]{
 Returns the list of instructions in @racket[prog].

 @(examples
   #:eval (make-evaluator) #:once
   (program-instructions
    (program (char-instruction #\a)
             (char-instruction #\b)
             (char-instruction #\c)))
   (program-instructions example-program))}

@defproc[(instruction? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a regex machine instruction.}

@subsection{CHAR instructions}

@defproc[(char-instruction? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a @litchar{CHAR} instruction.
 Implies @racket[instruction?].}

@defproc[(char-instruction [char char?]) char-instruction?]{
 Constructs a @litchar{CHAR} instruction that instructs the machine to consume
 @racket[char] from the input.

 @(examples
   #:eval (make-evaluator) #:once
   (char-instruction #\b))}

@defproc[(char-instruction-unwrap [inst char-instruction?]) char?]{
 Returns the character that @racket[inst] instructs the machine to consume.

 @(examples
   #:eval (make-evaluator) #:once
   (char-instruction-unwrap (char-instruction #\z)))}

@subsection{MATCH instructions}

@defproc[(match-instruction? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is the @litchar{MATCH} instruction.
 Implies @racket[instruction?].}

@defthing[match-instruction match-instruction?]{
 The @litchar{MATCH} instruction, which instructs the machine to stop running
 the executing thread and mark that thread's execution successful if all input
 has been consumed. If any input has not been consumed, the thread's execution
 is considered failed.}

@subsection{JMP instructions}

@defproc[(jmp-instruction? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a @litchar{JMP} instruction.
 Implies @racket[instruction?].}

@defproc[(jmp-instruction [target natural?]) jmp-instruction?]{
 Constructs a @litchar{JMP} instruction, which instructs the executing thread to
 jump to the instruction at position @racket[target] in the program.

 @(examples
   #:eval (make-evaluator) #:once
   (jmp-instruction 4))}

@defproc[(jmp-instruction-target [inst jmp-instruction?]) natural?]{
 Returns the position that @racket[inst] instructs the executing thread to jump
 to.

 @(examples
   #:eval (make-evaluator) #:once
   (define example-jmp (jmp-instruction 42))
   (jmp-instruction-target example-jmp))}

@subsection{SPLIT instructions}

@defproc[(split-instruction? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a @litchar{SPLIT} instruction.
 Implies @racket[instruction?].}

@defproc[(split-instruction [target natural?] [fork-target natural?])
         split-instruction?]{
 Constructs a @litchar{SPLIT} instruction, which instructs the executing thread
 to jump to the instruction at position @racket[target] in the program, similar
 to a @litchar{JMP} instruction. However, unlike a @litchar{JMP} instruction,
 the @litchar{SPLIT} instruction also instructs the machine to @emph{spawn a new
  thread} that is @emph{forked} from the thread executing the @litchar{SPLIT},
 meaning the new thread is a copy of this thread with the same program position
 and the same consumed input. The forked thread then jumps to the @racket[
 fork-target] instruction.

 @(examples
   #:eval (make-evaluator) #:once
   (split-instruction 2 5))}

@deftogether[
 (@defproc[(split-instruction-target [inst split-instruction?]) natural?]
   @defproc[(split-instruction-fork-target [inst split-instruction?])
            natural?])]{
 Functions that return either the position that @racket[inst] instructs the
 executing thread to jump to, or the position that @racket[inst] instructs the
 forked thread to jump to, respectively.

 @(examples
   #:eval (make-evaluator) #:once
   (define example-split (split-instruction 42 17))
   (split-instruction-target example-split)
   (split-instruction-fork-target example-split))}

@section{Regex Virtual Machine}

@defproc[(vm? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a regex virtual machine.}

@defproc[(vm [prog program?] [input string?]) vm?]{
 Constructs a regex virtual machine that matches @racket[input] with @racket[
 prog].

 @(examples
   #:eval (make-evaluator) #:once
   (vm example-program "abx"))}

@defproc[(vm-program [machine vm?]) program?]{
 Returns the program that @racket[machine] is running.

 @(examples
   #:eval (make-evaluator) #:once
   (define example-vm (vm example-program "ab"))
   (vm-program example-vm))}

@defproc[(vm-input [machine vm?]) string?]{
 Returns the input string that @racket[machine] is trying to match with its
 program.

 @(examples
   #:eval (make-evaluator) #:once
   (define example-vm (vm example-program "ab"))
   (vm-input example-vm))}

@defproc[(vm-status [machine vm?])
         (or/c 'not-finished 'matching-success 'matching-failure)]{
 Returns the current status of @racket[machine]. A VM can have one of three
 statuses:

 @itemlist[
 @item{@emph{not finished} --- the VM has not finished running the program.}
 @item{@emph{matching success} -- the VM successfully matched the input string
   with the program.}
 @item{@emph{matching failure} --- the VM determined that the input string does
   not match the program.}]

 @(examples
   #:eval (make-evaluator) #:once
   (define multiple-as-then-one-b
     (program (split-instruction 1 3)
              (char-instruction #\a)
              (jmp-instruction 0)
              (char-instruction #\b)
              match-instruction))
   
   (define aab-vm
     (vm multiple-as-then-one-b "aab"))

   (vm-status aab-vm)
   (vm-status (vm-run aab-vm #:steps 2))
   (vm-status (vm-run aab-vm #:steps 10)))}

@defproc[(vm-run [machine vm?]
                 [#:steps num-steps natural?])
         vm?]{
 Advances @racket[machine] by a @racket[num-steps] execution steps and returns
 the updated machine. All threads in a regex machine run in parallel, so a
 single execution step of the machine updates multiple threads at once.

 Note that virtual machines are immutable, so this function returns a @emph{new}
 machine that is distinct from @racket[machine].

 @(examples
   #:eval (make-evaluator) #:once
   (define even-number-of-as
     (program (split-instruction 1 4)
              (char-instruction #\a)
              (char-instruction #\a)
              (jmp-instruction 0)
              match-instruction))

   (define aaaaaa-vm (vm even-number-of-as "aaaaaa"))
   aaaaaa-vm
   (vm-run aaaaaa-vm #:steps 1)
   (vm-run aaaaaa-vm #:steps 4)
   (vm-run aaaaaa-vm #:steps 20))}

@subsection{Regex VM Threads}

@defproc[(vm-thread? [v any/c]) boolean?]{
 A predicate that determines if @racket[v] is a @emph{thread of execution} in a
 regex virtual machine.}

@defproc[(vm-threads [machine vm?]) (listof vm-thread?)]{
 Returns a list of all threads that have ever been started by @racket[machine],
 including running threads, dead threads, and threads that successfully matched
 the input.

 @(examples
   #:eval (make-evaluator) #:once
   (define all-as-or-all-bs
     (program (split-instruction 1 4)
              (split-instruction 2 7)
              (char-instruction #\a)
              (jmp-instruction 1)
              (split-instruction 5 7)
              (char-instruction #\b)
              (jmp-instruction 4)
              match-instruction))
   (define aaaa-vm (vm all-as-or-all-bs "aaaa"))
   (vm-threads aaaa-vm)
   (vm-threads (vm-run aaaa-vm #:steps 1))
   (vm-threads (vm-run aaaa-vm #:steps 2)))}

@defproc[(vm-thread-program-counter [thd vm-thread?]) natural?]{
 Returns the @emph{program counter} of @racket[thd], which indicates what
 program instruction the thread is executing. @litchar{CHAR} and @litchar{MATCH}
 instructions increase this number by one, while @litchar{JMP} and
 @litchar{SPLIT} instructions set it to a new number.}

@defproc[(vm-thread-character-counter [thd vm-thread?]) natural?]{
 Returns the @emph{character counter} of @racket[thd], which is the total number
 of characters that @racket[thd] has accepted from the input string so far. Each
 @litchar{CHAR} instruction successfully executed by a thread increases this
 number by one.

 Note that threads must accept characters from the input string in left-to-right
 order and cannot skip characters, so the exact prefix accepted by the thread
 can be reconstructed given its character counter and the original input
 string.}
