import os, strutils, osproc, strformat

let bin = paramStr(1)

for file in walkDir("examples/emscripten"):
  let newName = file.path.replace("@", "_R_")
  if newName != file.path:
    echo "moving ", file, " to ", newName
    removeFile(newName)
    moveFile(file.path, newName)

# Prepend "C:\Users\Dominik\.nimble\pkgs\stb_image-2.5\stb_image\ to the read/write.c filenames (and quote this path)
let stb_path = r"C:\Users\Dominik\.nimble\pkgs\stb_image-2.5\stb_image\"
# Search and replace all `@` into `_R_`.
# Search and replace `clang` into `emcc` (and make sure no .exe suffixes exist)
# Change -o client into -o client.html
let compileSh = readFile(fmt"examples/emscripten/compile_{bin}.sh")
writeFile(fmt"examples/emscripten/compile_{bin}.sh", compileSh.multireplace({
  "@": "_R_", "clang.exe": "emcc", "clang": "emcc", fmt"-o {bin}": fmt"-o {bin}.html",
  "-o read.c.o read.c": "-o read.c.o \"$1read.c\"" % stb_path,
  "-o write.c.o write.c": "-o write.c.o \"$1write.c\"" % stb_path,
}))

copyFile("examples/circle2.svg", "examples/emscripten/circle2.svg")
copyFile("examples/CC_BY.svg", "examples/emscripten/CC_BY.svg")
setCurrentDir(getCurrentDir() / "examples/emscripten")
assert execCmd(fmt"sh compile_{bin}.sh") == QuitSuccess
