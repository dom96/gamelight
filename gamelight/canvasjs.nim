import dom

type
  CanvasRenderingContext* = ref object
    fillStyle* {.importc.}: cstring
    strokeStyle* {.importc.}: cstring
    width* {.importc.}: int
    height* {.importc.}: int

    shadowColor* {.importc.}: cstring
    shadowBlur* {.importc.}: int

    lineWidth* {.importc.}: int

    font* {.importc.}: cstring

  ContextAttributes* = ref object
    alpha* {.importc.}: bool
    # TODO: WebGL

{.push importcpp.}

proc getContext*(canvasElement: Element, contextType: cstring,
    contextAttributes = ContextAttributes(alpha: true)): CanvasRenderingContext

proc fillRect*(context: CanvasRenderingContext,
    x, y, width, height: int)


proc beginPath*(context: CanvasRenderingContext)

proc moveTo*(context: CanvasRenderingContext, x, y: int)

proc lineTo*(context: CanvasRenderingContext, x, y: int)

proc stroke*(context: CanvasRenderingContext)

proc fillText*(context: CanvasRenderingContext, text: cstring, x, y: int)

proc translate*(context: CanvasRenderingContext, x, y: int)

proc setTransform*(context: CanvasRenderingContext, a, b, c, d, e, f: int)

