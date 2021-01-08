# Scraper
What will be a simple web scraper in OCaml to try out using the language on a real world project

## Building

First you will need to make sure you have `ocaml`, `opam` and `dune` instealled. Then you will need to install the dependencies like so `opam install cohttp-lwt-unix` finally run `dune build main.exe` which will build in `_build/default/main.exe`

N.B. if building on OpenBSD you'll likely have to increase your stack size limit during dependency install as `parsexp` uses a large stack allocated array. This can by done by running `ulimit -s 32768` in the shell before you start
