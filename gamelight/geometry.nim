import math
import vec

type
  Direction* = enum
    dirNorth, dirEast, dirSouth, dirWest

  LineSegment*[T] = tuple[start, finish: Point[T]]
  Rect*[T] = tuple[left, top, width, height: T]
  Circle*[T] = tuple[pos: Point[T], radius: T]

converter toLineSegment*(x: tuple[start, finish: (int, int)]): LineSegment[int] =
  return (x.start.toPoint, x.finish.toPoint)

converter toLineSegment*(x: tuple[start: (int, int),
                                  finish: Point[int]]): LineSegment[int] =
  return (x.start.toPoint, x.finish)

proc intersect*[T](line1, line2: LineSegment[T], point: var Point[T],
    epsilon = 0.001): bool =
  ## Based on algorithm described by Paul Bourke.
  ## http://paulbourke.net/geometry/pointlineplane/

  let (x1, y1) = (line1.start.x, line1.start.y)
  let (x2, y2) = (line1.finish.x, line1.finish.y)
  let (x3, y3) = (line2.start.x, line2.start.y)
  let (x4, y4) = (line2.finish.x, line2.finish.y)

  let denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
  let numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)
  let numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)

  if denom == 0:
    return false

  # Is the intersection along the segments?
  let mua = numera / denom
  let mub = numerb / denom

  if mua >= 0 and mua <= 1 and mub >= 0 and mub <= 1:
    point.x = T(x1.T + T(mua.T * (x2 - x1)))
    point.y = T(y1.T + T(mua.T * (y2 - y1)))
    return true

proc intersect*[T](line1, line2: LineSegment[T], epsilon = 0.001): bool =
  var foo: Point[T]
  return intersect(line1, line2, foo, epsilon)

proc intersect*[T](lines: openarray[LineSegment[T]], p: Point[T]): bool =
  # Based on https://en.wikipedia.org/wiki/Even%E2%80%93odd_rule
  template `{}`(lines: openarray[LineSegment[T]], i: int): Point[T] =
    if i mod 2 == 0:
      lines[i div 2].start
    else:
      lines[i div 2].finish

  let num = len(lines)*2
  var i = 0
  var j = num - 1
  result = false
  for i in 0 ..< num:
    let cond1 = ((lines{i}.y > p.y) != (lines{j}.y > p.y))
    let cond2 = (
      p.x <
        lines{i}.x + (lines{j}.x - lines{i}.x) *
        (p.y - lines{i}.y) / (lines{j}.y - lines{i}.y)
    )
    if cond1 and cond2:
      result = not result
    j = i

proc intersect*(rect: Rect, p: Point): bool =
  return p.x >= rect.left and p.x <= (rect.left + rect.width) and
      p.y >= rect.top and p.y <= (rect.top + rect.height)

proc intersect*(rect: Rect, c: Circle): bool =
  # https://stackoverflow.com/a/1879223/492186
  let closestX = clamp(c[0].x, rect.left, (rect.left + rect.width))
  let closestY = clamp(c[0].y, rect.top, (rect.top + rect.height))

  let distanceX = c[0].x - closestX
  let distanceY = c[0].y - closestY

  let distanceSquared = (distanceX * distanceX) + (distanceY * distanceY)
  return distanceSquared < (c[1] * c[1])

proc intersect*(rect: Rect, line: LineSegment): bool =
  # Check if line is inside rectangle.
  if rect.intersect(line.start) or rect.intersect(line.finish):
    return true

  # Check if `line` intersects any of the lines of the rectangle.
  let topLeft = (rect.left, rect.top)
  let top = (topLeft, topLeft + (rect.width, 0))
  let left = (topLeft, topLeft + (0, rect.height))
  let bottom = (left[1], top[1] + (0, rect.height))
  let right = (top[1], bottom[1])
  return top.intersect(line) or left.intersect(line) or
      bottom.intersect(line) or right.intersect(line)

proc distanceSquared*[T](line: LineSegment[T], point: Point[T]): T {.deprecated: "This is currently broken, TODO".} =
  # http://stackoverflow.com/a/1501725/492186
  proc dist2(v, w: Point[T]): T = ((v.x - w.x) ^ 2) + ((v.y - w.y) ^ 2)

  let lsq = dist2(line.start, line.finish)
  if lsq == 0: return dist2(point, line.start)

  var t = ((point.x - line.start.x) * (line.finish.x - line.start.x) +
      (point.y - line.start.y) * (line.finish.y - line.start.y)) / lsq
  t = max(0, min(1, t))

  let x = T(line.start.x + t.T) * T(line.finish.x - line.start.x)
  let y = T(line.start.y + t.T) * T(line.finish.y - line.start.y)
  return dist2(point, (x, y))

proc distance*(line: LineSegment, point: Point): float =
  return sqrt(distanceSquared(line, point).float)

proc intersect*(line: LineSegment, point: Point): bool =
  let d1 = distance(line.start, point)
  let d2 = distance(line.finish, point)

  let lineLen = distance(line.start, line.finish)

  let buffer = 0.1
  return d1+d2 >= lineLen-buffer and d1+d2 <= lineLen+buffer

proc nearestEdge*(line: LineSegment, point: Point): Point =
  ## Returns `line.start` if it's nearest to `point`, `line.finish` otherwise.
  let start = distanceSquared(line.start, point)
  let finish = distanceSquared(line.finish, point)
  if start < finish:
    return line.start
  else:
    return line.finish

proc `+`*(line: LineSegment, point: Point): LineSegment =
  (start: line.start + point, finish: line.finish + point)

proc `-`*(line: LineSegment, point: Point): LineSegment =
  line + (-point)

proc parallelWith*(line: LineSegment, direction: Direction): bool =
  if line.start.x == line.finish.x:
    return direction in {dirNorth, dirSouth}
  if line.start.y == line.finish.y:
    return direction in {dirEast, dirWest}

  assert false, "We only support lines which are parallel to the x or y-axis."

proc toPoint*[T](direction: Direction): Point[T] =
  case direction
  of dirNorth: Point[T]((0.T, -1.T))
  of dirEast: Point[T]((1.T, 0.T))
  of dirSouth: Point[T]((0.T, 1.T))
  of dirWest: Point[T]((-1.T, 0.T))

proc angle*(direction: Direction): float =
  case direction
  of dirNorth: 3 / 2 * PI # 270
  of dirEast: 0
  of dirSouth: PI / 2 # 90
  of dirWest: PI # 180

proc intersect*(a, b: Circle): bool =
  # https://stackoverflow.com/a/1736741/492186
  return distanceSquared(a[0], b[0]) <= (a[1]+b[1])^2

proc intersect*(circle: Circle, p: Point): bool =
  # http://www.jeffreythompson.org/collision-detection/point-circle.php
  let distX = p.x - circle.pos.x
  let distY = p.y - circle.pos.y
  let distance = sqrt((distX*distX) + (distY*distY))

  return distance <= circle.radius

proc intersect*[T](
  line: LineSegment[T], c: Circle[T],
): bool =
  # Wow, a very nice guide: http://www.jeffreythompson.org/collision-detection/line-circle.php
  # Either end of the line inside the circle?
  let inside1 = intersect(c, line.start)
  let inside2 = intersect(c, line.finish)
  if inside1 or inside2: return true

  # get length of the line
  let lenX = line.start.x - line.finish.x
  let lenY = line.start.y - line.finish.y;
  let len = sqrt((lenX*lenX) + (lenY*lenY))

  # get dot product of the line and circle
  let dot = (
    ((c.pos.x-line.start.x)*(line.finish.x-line.start.x)) +
    ((c.pos.y-line.start.y)*(line.finish.y-line.start.y))
  ) / pow(len, 2)

  # find the closest point on the line
  let closestX = line.start.x + (dot * (line.finish.x-line.start.x))
  let closestY = line.start.y + (dot * (line.finish.y-line.start.y))

  # is this point actually on the line segment?
  # if so keep going, but if not, return false
  let onSegment = intersect(line, Point[float](x: closestX, y: closestY))
  if not onSegment: return false

  # get distance to closest point
  let distX = closestX - c.pos.x
  let distY = closestY - c.pos.y
  let distance = sqrt((distX*distX) + (distY*distY))

  return distance <= c.radius

proc area*(a: Circle): float =
  math.PI * pow(a.radius, 2)

proc toCircleInt*(a: Circle): Circle[int] =
  (pos: a.pos.toPointInt(), radius: a.radius.int)

when isMainModule:
  # Test cases shamelessly stolen from https://martin-thoma.com/how-to-check-if-two-line-segments-intersect/

  block:
    let a = ((0, 0), (7, 7))
    let b = ((3, 4), (4, 5))
    assert(not intersect(a, b))

  block:
    let a = ((-4, 4), (-2, 1))
    let b = ((-2, 3), (0, 0))
    assert(not intersect(a, b))

  block:
    let a = ((0, -2), (0, 2))
    let b = ((-2, 0), (2, 0))
    assert(intersect(a, b))

  block:
    let a = ((5, 5), (0, 0))
    let b = ((1, 1), (8, 2))
    assert(intersect(a, b))

  # TODO: Tests to ensure that correct intersection point is returned.

  # Rectangle intersections
  block:
    let a = (left: 0, top: 0, width: 100, height: 50)
    assert(intersect(a, (50, 25)))
    assert(not intersect(a, (101, 25)))

  # Rectangle x line segment intersections
  block:
    let a = (left: 0, top: 0, width: 100, height: 50)
    assert(intersect(a, ((-5, 25), (125, 25))))
    assert(not intersect(a, ((125, 25), (160, 25))))

  # Test cases found "in the wild".
  block:
    let line1 = ((x: 960, y: 200), (x: 960, y: 270))
    let line2 = ((x: 960, y: 368), (x: 960, y: 388))
    assert(not intersect(line1, line2))

  block:
    let line1 = (start: vec2(400.41, 366.39), finish: vec2(415.63, 341.43))
    let circle1 = (pos: vec2(405.00, 360.00), radius: 6.0)
    assert line1.intersect(circle1)

  # Distance test cases
  # TODO: This is broken, fix it.
  # block:
  #   let line = ((0, 0), (100, 0))
  #   assert(distanceSquared(line, (50, 25)) == 25^2)

  # ParallelWith test cases
  block:
    let line1 = ((0, 0), (100, 0))
    assert(line1.parallelWith(dirEast))
    assert(line1.parallelWith(dirWest))
    assert(not line1.parallelWith(dirNorth))
    assert(not line1.parallelWith(dirSouth))
    let line2 = ((0, 0), (0, 100))
    assert(not line2.parallelWith(dirEast))
    assert(not line2.parallelWith(dirWest))
    assert(line2.parallelWith(dirNorth))
    assert(line2.parallelWith(dirSouth))

  # Circle-circle intersect tests
  block:
    let c1 = (Point[int](x: 5, y: 5), 10)
    let c2 = (Point[int](x: 20, y: 5), 20)
    doAssert intersect(c1, c2)
    let c3 = (Point[int](x: 200, y: 5), 20)
    doAssert(not intersect(c1, c3))
    doAssert(not intersect(c2, c3))

  block:
    let r1 = (left: 36, top: 37, width: 3, height: 3)
    let p = Point[int](x: 39, y: 39)
    doAssert r1.intersect(p)
    # doAssert(not r1.inside(p)) ??

  # Circle-rect intersect tests
  block:
    let a = (left: 0, top: 0, width: 100, height: 50)
    let c1 = (Point[int](x: 5, y: 5), 10)
    let c2 = (Point[int](x: 115, y: 5), 10)
    assert(intersect(a, c1))
    assert(not intersect(a, c2))

  echo("Tests passed!")