import sugar

import gamelight/[graphics, vec, geometry]

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")
  renderer.fillRect(20, 20, 100, 100, "#1ff20f")

  renderer.strokeRect(40, 40, 100, 100, "#8a8a8a")
  renderer.fillRect(45, 45, 90, 90, "#8a8a8a")

  renderer.beginPath()
  renderer.moveTo(400, 50)
  renderer.lineTo(550, 60)
  renderer.lineTo(450, 140)
  renderer.closePath()
  renderer.strokePath("#fdd96d", 30)
  quit(1)

proc onLoad() {.exportc.} =
  var renderer = newRenderer2D("canvas")
  renderer.onKeyDown =
    proc (event: KeyboardEvent) =
      echo(event)
  renderer.onMouseButtonDown =
    proc (event: MouseButtonEvent) =
      echo(event)
  renderer.onMouseMotion =
    proc (event: MouseMotionEvent) =
      echo(event)
  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()