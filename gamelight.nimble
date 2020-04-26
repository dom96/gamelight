# Package

version       = "0.1.0"
author        = "Dominik Picheta"
description   = "A set of simple modules for writing a JavaScript 2D game."
license       = "MIT"

# Dependencies

requires "nim >= 0.16.0"

requires "sdl2"
requires "chroma >= 0.1.0"
requires "typography >= 0.2.4"
requires "flippy >= 0.4.0"

task exampleem, "Builds examples for emscripten":
  exec "rm -r examples/emscripten"
  exec "nim c -d:emscripten examples/clipping.nim"
  exec "nim c -r examples/rename_all.nim clipping"