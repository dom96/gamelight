import math
type
  Point*[T] = object
    x*, y*: T

proc getOrigin(): Point[int] = Point[int](x: 0, y: 0)

converter toPoint*(point: (int, int)): Point[int] =
  Point[int](x: point[0], y: point[1])

converter toPoint*(point: (float, float)): Point[float] =
  Point[float](x: point[0], y: point[1])

proc `+`*(point: Point, point2: Point): Point =
  (point.x + point2.x, point.y + point2.y)

proc `-`*(point: Point, point2: Point): Point =
  (point.x - point2.x, point.y - point2.y)

proc `+`*[T](point: Point[T], scalar: T): Point[T] =
  (point.x + scalar, point.y + scalar)

proc `-`*[T](point: Point[T], scalar: T): Point[T] =
  (point.x - scalar, point.y - scalar)

proc `-`*(point: Point): Point =
  (-point.x, -point.y)

proc `/`*[T](point: Point[T], scalar: T): Point[T] =
  (T(point.x / scalar), T(point.y / scalar))

proc `*`*[T](point: Point[T], scalar: T): Point[T] =
  (T(point.x * scalar), T(point.y * scalar))

proc add*(point: var Point, value: Point) =
  point.x += value.x
  point.y += value.y

proc copy*(point: Point): Point =
  return Point(x: point.x, y: point.y)

proc distanceSquared*[T](point, point2: Point[T]): T =
  return (point2.x - point.x)^2 + (point2.y - point.y)^2

proc isOrigin*(point: Point): bool =
  return point.x == 0 and point.y == 0

proc rotate*[T](point: Point[T], radians: float,
                origin: Point[T] = getOrigin()): Point[T] =
  let ca = cos(radians)
  let sa = sin(radians)

  let xTrans = (point.x - origin.x)
  let yTrans = (point.y - origin.y)

  result = Point[T](
    x: ((xTrans * ca) - (yTrans * sa)) + origin.x,
    y: ((xTrans * sa) + (yTrans * ca)) + origin.y
  )

proc midpoint*(point, point2: Point): Point =
  return ((point.x + point2.x) div 2, (point.y + point2.y) div 2)

proc abs*(point: Point): Point =
  return (point.x.abs, point.y.abs)

converter toPointF*(point: Point[int]): Point[float] =
  return Point[float](x: point.x.float, y: point.y.float)

proc angle*(point: Point): float =
  let degrees = radToDeg(arctan2(point.y.float64, point.x.float64))
  # https://stackoverflow.com/a/25725005/492186
  return (degrees + 360) mod 360