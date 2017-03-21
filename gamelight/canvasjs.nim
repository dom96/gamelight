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

  ImageData* = ref object
    data*: seq[byte]
    width*, height*: int


proc getPixelRatio*(): float =
  # Based on: http://stackoverflow.com/a/15666143/492186
  {.emit: """
    var ctx = document.createElement("canvas").getContext("2d"),
        dpr = window.devicePixelRatio || 1,
        bsr = ctx.webkitBackingStorePixelRatio ||
                ctx.mozBackingStorePixelRatio ||
                ctx.msBackingStorePixelRatio ||
                ctx.oBackingStorePixelRatio ||
                ctx.backingStorePixelRatio || 1;

    `result` = dpr / bsr;
  """.}

{.push importcpp.}

proc getContext*(canvasElement: Element, contextType: cstring,
    contextAttributes = ContextAttributes(alpha: false)): CanvasRenderingContext

proc fillRect*(context: CanvasRenderingContext,
    x, y, width, height: int | float)

proc strokeRect*(context: CanvasRenderingContext,
    x, y, width, height: int | float)

proc beginPath*(context: CanvasRenderingContext)

proc moveTo*(context: CanvasRenderingContext, x, y: int)

proc lineTo*(context: CanvasRenderingContext, x, y: int)

proc stroke*(context: CanvasRenderingContext)

proc fillText*(context: CanvasRenderingContext, text: cstring, x, y: int | float)

proc translate*(context: CanvasRenderingContext, x, y: int)

proc setTransform*(context: CanvasRenderingContext, a, b, c, d, e, f: int | float)

proc createImageData*(context: CanvasRenderingContext, width, height: int): ImageData

proc putImageData*(context: CanvasRenderingContext, image: ImageData, dx, dy: int)