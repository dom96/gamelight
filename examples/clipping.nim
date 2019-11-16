import sugar, os, options

import gamelight/[graphics, vec, geometry]

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")

  # temp.setClippingMask(some(clip))
  renderer.drawImage(getCurrentDir() / "CC_BY.svg", Point[int](x: 0, y: 0), 400, 200, TopLeft)
  renderer.drawImage(getCurrentDir() / "circle2.svg", Point[int](x: 0, y: 0), 200, 200, TopLeft)

proc onLoad() {.exportc.} =

  var renderer = newRenderer2D("canvas")

  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()