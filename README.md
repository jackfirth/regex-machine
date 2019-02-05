# regex-machine [![CircleCI][circleci-badge]][circleci] [![Documentation][docs-badge]][docs]

This is an implementation of a virtual machine for Russ Cox's regular expression machine language.
This is *not* a parser for the language; instructions must be written in Racket as expressions like
this:

```
(program (char-instruction #\a)
         (char-instruction #\b)
         match-instruction)
```

## Installation

To use this code, you'll need to install the [Racket](http://racket-lang.org/) programming language.
This code is available as a Racket *package* named `regex-machine`, meaning that Racket can
automatically download and install this code without you having to do anything more than tell Racket
the name of the package. **You do not need to clone this Git repository or download a ZIP folder of
its code.** Racket will do that for you using the Racket *package manager*. There are two ways you
can do this:

1. Through DrRacket (recommended). Open up the DrRacket program (which is included with Racket out
of the box) and open the package manager menu. It's located in `File > Package Manager...`. Then,
type `regex-machine` in the `Package Source` text field and click `Install`. You should see the
package manager spit out some lines of text output starting with `raco setup`. If the install failed
for some reason, this output should include a section labeled `--- summary of errors ---`. If you
don't see that, the package should have been installed successfully.

2. Through the command line (not recommended). First make sure Racket's command line tools are in
your `$PATH` -- you should be able to run both of the commands `racket --version` and `raco help`
without errors. This is *not* automatically set up for you when you install Racket, and setting it
up correctly requires different steps depending on whether you're using a Windows, macOS, or Linux
computer. Instead of trying to figure it out I strongly recommend using DrRacket to install this
package. But assuming you really want to use the command line and have figured out how to get the
Racket tools working, you can install this package by running the command
`raco pkg install --auto regex-machine`.

You can check that the package installed successfully by opening DrRacket and running the code
`(require regex-machine)`, including the parentheses. This makes all of the functions defined in
this package available to you for use. See this package's [documentation][docs] for the details of
those functions.

## GUI

You can run the GUI by executing `(require (submod regex-machine/gui main))` in DrRacket. It's not
very configurable however.

[circleci]: https://circleci.com/gh/jackfirth/regex-machine
[circleci-badge]: https://circleci.com/gh/jackfirth/regex-machine.svg?style=svg
[docs]: http://docs.racket-lang.org/regex-machine/index.html
[docs-badge]: https://img.shields.io/badge/docs-published-blue.svg
