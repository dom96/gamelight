import sugar, options

import gamelight/[graphics, vec, geometry]

var start = none[Point[int]]()
var finish = none[Point[int]]()
var lastMousePos = Point[int](x: 0, y: 0)

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")
  renderer.fillRect(20, 20, 100, 100, "#1ff20f")

  renderer.strokeRect(40, 40, 100, 100, "#8a8a8a")
  renderer.fillRect(45, 45, 90, 90, "#8a8a8a")

  renderer.beginPath()
  renderer.moveTo(400, 50)
  renderer.lineTo(550, 80)
  # renderer.lineTo(450, 140)
  renderer.closePath()
  renderer.strokePath("#fdd96d", 10)

  if start.isSome():
    let a = start.get()
    let b = finish.get(lastMousePos)
    renderer.beginPath()
    renderer.moveTo(a.x, a.y)
    renderer.lineTo(b.x, b.y)
    renderer.strokePath("#fdd96d", 10)

proc onLoad() {.exportc.} =
  var renderer = newRenderer2D("canvas")
  renderer.onKeyDown =
    proc (event: KeyboardEvent) =
      echo(event)
  renderer.onMouseButtonDown =
    proc (event: MouseButtonEvent) =
      echo(event)
      if start.isSome() and finish.isSome():
        start = none[Point[int]]()
        finish = none[Point[int]]()
      elif start.isNone():
        start = some(Point[int](x: event.x, y: event.y))
      elif finish.isNone():
        finish = some(Point[int](x: event.x, y: event.y))
  renderer.onMouseMotion =
    proc (event: MouseMotionEvent) =
      echo(event)
      lastMousePos = Point[int](x: event.x, y: event.y)
  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()