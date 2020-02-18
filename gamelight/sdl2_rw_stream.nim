import streams

import sdl2, sdl2_utils

type
  SdlFileStream* = ref SdlFileStreamObj
  SdlFileStreamObj* = object of Stream
    ops: RWopsPtr

proc checkErrEx*(ret: ptr | SDL_Return | cint, file: string = "") =
  try:
    checkError(ret, file)
  except Exception:
    raise newException(IOError, getCurrentExceptionMsg())

const
  RW_SEEK_SET = 0
  RW_SEEK_CUR = 1
  RW_SEEK_END = 2
proc tell(ops: RWopsPtr): int64 {.raises: [Defect, IOError, OSError].} =
  result = seek(ops, 0, RW_SEEK_CUR)
  checkErrEx result.cint

proc fsClose(s: Stream) {.tags: [WriteIOEffect], gcsafe.} =
  if SdlFileStream(s).ops != nil:
    checkErrEx SdlFileStream(s).ops.close(SdlFileStream(s).ops)
    SdlFileStream(s).ops = nil
proc fsFlush(s: Stream) {.gcsafe.} = discard
proc fsAtEnd(s: Stream): bool {.tags: [], gcsafe, raises: [Defect, IOError, OSError].} =
  return SdlFileStream(s).ops.tell() == size(SdlFileStream(s).ops)
proc fsSetPosition(s: Stream, pos: int) {.tags: [], gcsafe.} =
  checkErrEx seek(SdlFileStream(s).ops, pos, RW_SEEK_SET).cint
proc fsGetPosition(s: Stream): int {.tags: [], gcsafe.} =
  SdlFileStream(s).ops.tell().int

proc fsReadData(s: Stream, buffer: pointer, bufLen: int): int {.tags: [ReadIOEffect], gcsafe.} =
  result = read(SdlFileStream(s).ops, buffer, bufLen, 1) * bufLen
  if result == 0:
    checkErrEx cint(-1)

proc fsReadDataStr(s: Stream, buffer: var string, slice: Slice[int]): int {.tags: [ReadIOEffect], gcsafe.} =
  return fsReadData(s, addr buffer[slice.a], slice.b + 1 - slice.a)

proc fsPeekData(s: Stream, buffer: pointer, bufLen: int): int {.tags: [ReadIOEffect], gcsafe.} =
  let pos = fsGetPosition(s)
  defer: fsSetPosition(s, pos)
  result = fsReadData(s, buffer, bufLen)

proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) {.tags: [WriteIOEffect], gcsafe, raises: [Defect, IOError, OSError].} =
  if write(SdlFileStream(s).ops, buffer, bufLen, 1) != bufLen:
    checkErrEx(cint(-1))

proc newSdlFileStream*(ops: RWopsPtr): owned SdlFileStream =
  new(result)
  result.ops = ops
  result.closeImpl = fsClose
  result.atEndImpl = fsAtEnd
  result.setPositionImpl = fsSetPosition
  result.getPositionImpl = fsGetPosition
  result.readDataStrImpl = fsReadDataStr
  result.readDataImpl = fsReadData
  result.readLineImpl = nil # There is a fallback that will be used.
  result.peekDataImpl = fsPeekData
  result.writeDataImpl = fsWriteData
  result.flushImpl = fsFlush

proc newSdlFileStream*(filename: string, mode: FileMode = fmRead): owned SdlFileStream =
  let ops = rwFromFile(
    filename,
    if mode == fmRead:
      "r"
    else:
      "w"  
  )
  checkError ops
  return newSdlFileStream(ops)