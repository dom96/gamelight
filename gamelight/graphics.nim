import future
import dom
import canvasjs, vec

type
  Renderer2D* = ref object
    canvas: EmbedElement
    context: CanvasRenderingContext

proc resizeCanvas(canvas: EmbedElement) =
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight

proc newRenderer2D*(id: string): Renderer2D =
  ## This proc assumes that the document has been loaded.
  var canvas = document.getElementById(id).EmbedElement
  var context = canvas.getContext("2d")

  result = Renderer2D(canvas: canvas, context: context)

  var capturedResult = result
  window.addEventListener("resize", (ev: Event) => (resizeCanvas(capturedResult.canvas)))

  resizeCanvas(canvas)

proc strokeLine*(renderer: Renderer2D, start, finish: Point, width = 1,
    style = "#000000", shadowBlur = 0, shadowColor = "#000000") =
  renderer.context.beginPath()
  renderer.context.moveTo(start.x, start.y)
  renderer.context.lineTo(finish.x, finish.y)
  renderer.context.lineWidth = width
  renderer.context.strokeStyle = style
  renderer.context.shadowBlur = shadowBlur
  renderer.context.shadowColor = shadowColor
  renderer.context.stroke()

  renderer.context.shadowBlur = 0

proc strokeLines*(renderer: Renderer2D, points: seq[Point], width = 1,
    style = "#000000", shadowBlur = 0, shadowColor = "#000000") =
  if points.len == 0: return
  renderer.context.beginPath()

  renderer.context.moveTo(points[0].x, points[0].y)

  for i in 1 .. <points.len:
    renderer.context.lineTo(points[i].x, points[i].y)

  renderer.context.lineWidth = width
  renderer.context.strokeStyle = style
  renderer.context.shadowBlur = shadowBlur
  renderer.context.shadowColor = shadowColor
  renderer.context.stroke()

  renderer.context.shadowBlur = 0

proc fillRect*(renderer: Renderer2D, x, y, width, height: int,
    style = "#000000") =
  renderer.context.fillStyle = style
  renderer.context.fillRect(x, y, width, height)

proc fillText*(renderer: Renderer2D, text: string, pos: Point,
    style = "#000000", font = "12px Helvetica") =
  renderer.context.fillStyle = style
  renderer.context.font = font
  renderer.context.fillText(text, pos.x, pos.y)

proc setTranslation*(renderer: Renderer2D, pos: Point) =
  renderer.context.setTransform(1, 0, 0, 1, pos.x, pos.y)

proc getWidth*(renderer: Renderer2D): int =
  renderer.canvas.width

proc getHeight*(renderer: Renderer2D): int =
  renderer.canvas.height
