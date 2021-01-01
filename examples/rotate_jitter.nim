import sugar, os, options

import gamelight/[graphics, vec, geometry]

var size = 1.0
var targetSize = 3.0

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")

  # temp.setClippingMask(some(clip))
  renderer.drawImage(
    getCurrentDir() / "dice.png",
    vec2(300, 200),
    int(200*size), int(150*size),
    Center,
    152
  )

  size += (targetSize - size) * 0.001 * elapsedTime
  if abs(targetSize - size) < 0.01:
    if targetSize == 3.0:
      targetSize = 1.0
    else:
      targetSize = 3.0

proc onLoad() {.exportc.} =

  var renderer = newRenderer2D("canvas")

  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()