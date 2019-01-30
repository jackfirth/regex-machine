1526
((3) 0 () 1 ((q lib "regex-vm/main.rkt")) () (h ! (equal) ((c def c (c (? . 0) q match-instruction?)) q (531 . 3)) ((c def c (c (? . 0) q jmp-instruction-target)) q (786 . 3)) ((c def c (c (? . 0) q char-instruction-unwrap)) q (447 . 3)) ((c def c (c (? . 0) q vm-input)) q (1442 . 3)) ((c def c (c (? . 0) q char-instruction?)) q (307 . 3)) ((c def c (c (? . 0) q jmp-instruction)) q (704 . 3)) ((c def c (c (? . 0) q split-instruction)) q (935 . 4)) ((c def c (c (? . 0) q vm-run)) q (1622 . 4)) ((c def c (c (? . 0) q example-program)) q (125 . 2)) ((c def c (c (? . 0) q vm-thread?)) q (1726 . 3)) ((c def c (c (? . 0) q vm-thread-character-counter)) q (1940 . 3)) ((c def c (c (? . 0) q vm-threads)) q (1782 . 3)) ((c def c (c (? . 0) q program)) q (54 . 3)) ((c def c (c (? . 0) q program?)) q (0 . 3)) ((c def c (c (? . 0) q char-instruction)) q (370 . 3)) ((c def c (c (? . 0) q jmp-instruction?)) q (642 . 3)) ((c def c (c (? . 0) q vm?)) q (1246 . 3)) ((c def c (c (? . 0) q split-instruction-fork-target)) q (1152 . 3)) ((c def c (c (? . 0) q program-instructions)) q (160 . 3)) ((c def c (c (? . 0) q split-instruction?)) q (871 . 3)) ((c def c (c (? . 0) q match-instruction)) q (595 . 2)) ((c def c (c (? . 0) q instruction?)) q (249 . 3)) ((c def c (c (? . 0) q vm)) q (1295 . 4)) ((c def c (c (? . 0) q vm-status)) q (1505 . 4)) ((c def c (c (? . 0) q vm-thread-program-counter)) q (1860 . 3)) ((c def c (c (? . 0) q split-instruction-target)) q (1063 . 3)) ((c def c (c (? . 0) q vm-program)) q (1376 . 3))))
procedure
(program? v) -> boolean?
  v : any/c
procedure
(program inst ...) -> program?
  inst : instruction?
value
example-program : program?
procedure
(program-instructions prog) -> (listof instruction?)
  prog : program?
procedure
(instruction? v) -> boolean?
  v : any/c
procedure
(char-instruction? v) -> boolean?
  v : any/c
procedure
(char-instruction char) -> char-instruction?
  char : char?
procedure
(char-instruction-unwrap inst) -> char?
  inst : char-instruction?
procedure
(match-instruction? v) -> boolean?
  v : any/c
value
match-instruction : match-instruction?
procedure
(jmp-instruction? v) -> boolean?
  v : any/c
procedure
(jmp-instruction target) -> jmp-instruction?
  target : natural?
procedure
(jmp-instruction-target inst) -> natural?
  inst : jmp-instruction?
procedure
(split-instruction? v) -> boolean?
  v : any/c
procedure
(split-instruction target fork-target) -> split-instruction?
  target : natural?
  fork-target : natural?
procedure
(split-instruction-target inst) -> natural?
  inst : split-instruction?
procedure
(split-instruction-fork-target inst) -> natural?
  inst : split-instruction?
procedure
(vm? v) -> boolean?
  v : any/c
procedure
(vm prog input) -> vm?
  prog : program?
  input : string?
procedure
(vm-program machine) -> program?
  machine : vm?
procedure
(vm-input machine) -> string?
  machine : vm?
procedure
(vm-status machine)
 -> (or/c 'not-finished 'matching-success 'matching-failure)
  machine : vm?
procedure
(vm-run machine #:steps num-steps) -> vm?
  machine : vm?
  num-steps : natural?
procedure
(vm-thread? v) -> boolean?
  v : any/c
procedure
(vm-threads machine) -> (listof vm-thread?)
  machine : vm?
procedure
(vm-thread-program-counter thd) -> natural?
  thd : vm-thread?
procedure
(vm-thread-character-counter thd) -> natural?
  thd : vm-thread?
