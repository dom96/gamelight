import math
type
  Point*[T] = object
    x*, y*: T

proc getOrigin(): Point[int] = Point[int](x: 0, y: 0)

converter toPoint*[T: int | int8 | int16 | int32 | uint8 | uint16 | uint32](
  point: (T, T)
): Point[T] =
  Point[T](x: point[0], y: point[1])

converter toPoint*(point: (float, float)): Point[float] =
  Point[float](x: point[0], y: point[1])

proc `+`*[T](point: Point[T], point2: Point[T]): Point[T] =
  Point[T](x: point.x + point2.x, y: point.y + point2.y)

proc `-`*[T](point: Point[T], point2: Point[T]): Point[T] =
  Point[T](x: point.x - point2.x, y: point.y - point2.y)

template `+=`*(point: var Point, point2: Point): untyped =
  point = point + point2

template `-=`*(point: var Point, point2: Point): untyped =
  point = point - point2

proc `+`*[T](point: Point[T], scalar: T): Point[T] =
  (point.x + scalar, point.y + scalar)

proc `-`*[T](point: Point[T], scalar: T): Point[T] =
  (point.x - scalar, point.y - scalar)

template `+=`*[T](point: var Point[T], scalar: T): untyped =
  point = point + scalar

template `-=`*[T](point: var Point[T], scalar: T): untyped =
  point = point - scalar

proc `-`*(point: Point): Point =
  (-point.x, -point.y)

proc `/`*[T](point: Point[T], scalar: T): Point[T] =
  (T(point.x / scalar), T(point.y / scalar))

proc `div`*[T](point: Point[T], scalar: T): Point[T] =
  (T(point.x div scalar), T(point.y div scalar))

proc `*`*[T](point: Point[T], scalar: T): Point[T] =
  (T(point.x * scalar), T(point.y * scalar))

proc add*(point: var Point, value: Point) =
  point.x += value.x
  point.y += value.y

proc copy*(point: Point): Point =
  return Point(x: point.x, y: point.y)

proc distanceSquared*[T](point, point2: Point[T]): T =
  return (point2.x - point.x)^2 + (point2.y - point.y)^2

proc distanceSquared*[T](point: Point[float], point2: Point[T]): float =
  return (point2.x.float - point.x)^2 + (point2.y.float - point.y)^2

proc distanceSquared*[T](point: Point[T], point2: Point[float]): float {.inline.} =
  return distanceSquared(point2, point)

proc distance*[T](a, b: Point[T]): float = sqrt(distanceSquared(a,b))

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

proc toPointInt*[T](point: Point[T]): Point[int] =
  return Point[int](x: point.x.int, y: point.y.int)

proc toPointFloat*[T](point: Point[T]): Point[float] =
  return Point[float](x: point.x.float, y: point.y.float)

proc angle*(point: Point): float =
  let degrees = radToDeg(arctan2(point.y.float64, point.x.float64))
  # https://stackoverflow.com/a/25725005/492186
  return (degrees + 360) mod 360

proc normalize*(point: Point): Point =
  ## Returns a unit vector of ``point``.
  return point / sqrt(point.x^2 + point.y^2)

proc toDirVec*(angle: float): Point[float] =
  ## Returns a unit vector for the specified angle in degrees.
  return Point[float](
    x: math.cos(degToRad(angle)),
    y: math.sin(degToRad(angle))
  )

proc vec2*(x, y: int): Point[int] =
  Point[int](x: x, y: y)

proc vec2*(x, y: float): Point[float] =
  Point[float](x: x, y: y)

proc lerp*[T](start, finish: T, ratio: range[0.0 .. 1.0]): T =
  ## Linear interpolation between two points.
  let res = start + ratio.float*(finish - start)
  return res.T

proc lerp*[T](start, finish: Point[T], ratio: range[0.0 .. 1.0]): Point[T] =
  ## Linear interpolation between two points.
  let res = start + (finish - start)*ratio
  return vec2(res.x.T, res.y.T)