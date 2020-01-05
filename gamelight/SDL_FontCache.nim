#
#SDL_FontCache v0.10.0: A font cache for SDL and SDL_ttf
#by Jonathan Dearborn
#Dedicated to the memory of Florian Hufsky
#
#License:
#    The short:
#    Use it however you'd like, but keep the copyright and license notice
#    whenever these files or parts of them are distributed in uncompiled form.
#
#    The long:
#Copyright (c) 2019 Jonathan Dearborn
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#
{.compile: "SDL_FontCache/SDL_FontCache.c".}
const 
  TTF_STYLE_OUTLINE* = 16
# Differences between Target and SDL_gpu
import sdl2
import sdl2/ttf as sdl2_ttf
when defined(USE_SDL_GPU): 
  const 
    Rect* = gPU_Rect
    Target* = gPU_Target
    Image* = gPU_Image
    Log* = gPU_LogError
else: 
  type 
    Rect* = sdl2.Rect
    TargetPtr* = sdl2.RendererPtr
    ImagePtr* = sdl2.TexturePtr
    #Log* = sdl2.Log
# SDL_FontCache types
type 
  AlignEnum* {.size: sizeof(cint).} = enum 
    ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT
  FilterEnum* {.size: sizeof(cint).} = enum 
    FILTER_NEAREST, FILTER_LINEAR
  Scale* {.importc: "FC_Scale".} = object 
    x* {.importc: "x".}: cfloat
    y* {.importc: "y".}: cfloat

  Effect* {.importc: "FC_Effect".} = object 
    alignment* {.importc: "alignment".}: AlignEnum
    scale* {.importc: "scale".}: Scale
    color* {.importc: "color".}: sdl2.Color

# Opaque type
type 
  FontPtr* = pointer
  GlyphData* {.importc: "FC_GlyphData", 
               .} = object 
    rect* {.importc: "rect".}: Rect
    cacheLevel* {.importc: "cache_level".}: cint

# Object creation
proc makeRect*(x: cfloat; y: cfloat; w: cfloat; h: cfloat): Rect {.
    importc: "FC_MakeRect".}
proc makeScale*(x: cfloat; y: cfloat): Scale {.importc: "FC_MakeScale", 
    .}
proc makeColor*(r: uint8; g: uint8; b: uint8; a: uint8): sdl2.Color {.
    importc: "FC_MakeColor".}
proc makeEffect*(alignment: AlignEnum; scale: Scale; color: sdl2.Color): Effect {.
    importc: "FC_MakeEffect".}
proc makeGlyphData*(cacheLevel: cint; x: int16; y: int16; w: uint16; 
                    h: uint16): GlyphData {.importc: "FC_MakeGlyphData", 
    .}
# Font object
proc createFont*(): FontPtr {.importc: "FC_CreateFont", 
                               .}
when defined(USE_SDL_GPU): 
  proc loadFont*(font: FontPtr; filenameTtf: cstring; pointSize: uint32; 
                 color: sdl2.Color; style: cint): uint8 {.
      importc: "FC_LoadFont".}
  proc loadFontFromTTF*(font: FontPtr; ttf: sdl2_ttf.FontPtr; color: sdl2.Color): uint8 {.
      importc: "FC_LoadFontFromTTF".}
  proc loadFontRW*(font: FontPtr; fileRwopsTtf: ptr sdl2.RWops; 
                   ownRwops: uint8; pointSize: uint32; color: sdl2.Color; 
                   style: cint): uint8 {.importc: "FC_LoadFont_RW", 
      .}
else: 
  proc loadFont*(font: FontPtr; renderer: TargetPtr; 
                 filenameTtf: cstring; pointSize: uint32; color: sdl2.Color; 
                 style: cint): uint8 {.importc: "FC_LoadFont", 
      .}
  proc loadFontFromTTF*(font: FontPtr; renderer: TargetPtr; 
                        ttf: sdl2_ttf.FontPtr; color: sdl2.Color): uint8 {.
      importc: "FC_LoadFontFromTTF".}
  proc loadFontRW*(font: FontPtr; renderer: TargetPtr; 
                   fileRwopsTtf: ptr sdl2.RWops; ownRwops: uint8; 
                   pointSize: uint32; color: sdl2.Color; style: cint): uint8 {.
      importc: "FC_LoadFont_RW".}
when not defined(USE_SDL_GPU): 
  # note: handle SDL event types SDL_RENDER_TARGETS_RESET(>= SDL 2.0.2) and SDL_RENDER_DEVICE_RESET(>= SDL 2.0.4)
  proc resetFontFromRendererReset*(font: FontPtr; renderer: TargetPtr; 
                                   evType: uint32) {.
      importc: "FC_ResetFontFromRendererReset", 
      .}
proc clearFont*(font: FontPtr) {.importc: "FC_ClearFont", 
                                  .}
proc freeFont*(font: FontPtr) {.importc: "FC_FreeFont", 
                                 .}
# Built-in loading strings
proc getStringASCII*(): cstring {.importc: "FC_GetStringASCII", 
                                  .}
proc getStringLatin1*(): cstring {.importc: "FC_GetStringLatin1", 
                                   .}
proc getStringASCII_Latin1*(): cstring {.importc: "FC_GetStringASCII_Latin1", 
    .}
# UTF-8 to SDL_FontCache codepoint conversion
#!
#Returns the uint32 codepoint (not UTF-32) parsed from the given UTF-8 string.
#\param c A pointer to a string of proper UTF-8 character values.
#\param advance_pointer If true, the source pointer will be incremented to skip the extra bytes from multibyte codepoints.
#
proc getCodepointFromUTF8*(c: cstringArray; advancePointer: uint8): uint32 {.
    importc: "FC_GetCodepointFromUTF8", 
    .}
#!
#Parses the given codepoint and stores the UTF-8 bytes in 'result'.  The result is NULL terminated.
#\param result A memory buffer for the UTF-8 values.  Must be at least 5 bytes long.
#\param codepoint The uint32 codepoint to parse (not UTF-32).
#
proc getUTF8FromCodepoint*(result: cstring; codepoint: uint32) {.
    importc: "FC_GetUTF8FromCodepoint", 
    .}
# UTF-8 string operations
#! Allocates a new string of 'size' bytes that is already NULL-terminated.  The NULL byte counts toward the size limit, as usual.  Returns NULL if size is 0. 
proc u8Alloc*(size: cuint): cstring {.importc: "U8_alloc", 
                                      .}
#! Deallocates the given string. 
proc u8Free*(string: cstring) {.importc: "U8_free", 
                                .}
#! Allocates a copy of the given string. 
proc u8Strdup*(string: cstring): cstring {.importc: "U8_strdup", 
    .}
#! Returns the number of UTF-8 characters in the given string. 
proc u8Strlen*(string: cstring): cint {.importc: "U8_strlen", 
    .}
#! Returns the number of bytes in the UTF-8 multibyte character pointed at by 'character'. 
proc u8Charsize*(character: cstring): cint {.importc: "U8_charsize", 
    .}
#! Copies the source multibyte character into the given buffer without overrunning it.  Returns 0 on failure. 
proc u8Charcpy*(buffer: cstring; source: cstring; bufferSize: cint): cint {.
    importc: "U8_charcpy".}
#! Returns a pointer to the next UTF-8 character. 
proc u8Next*(string: cstring): cstring {.importc: "U8_next", 
    .}
#! Inserts a UTF-8 string into 'string' at the given position.  Use a position of -1 to append.  Returns 0 when unable to insert the string. 
proc u8Strinsert*(string: cstring; position: cint; source: cstring; 
                  maxBytes: cint): cint {.importc: "U8_strinsert", 
    .}
#! Erases the UTF-8 character at the given position, moving the subsequent characters down. 
proc u8Strdel*(string: cstring; position: cint) {.importc: "U8_strdel", 
    .}
# Internal settings
#! Sets the string from which to load the initial glyphs.  Use this if you need upfront loading for any reason (such as lack of render-target support). 
proc setLoadingString*(font: FontPtr; string: cstring) {.
    importc: "FC_SetLoadingString".}
#! Returns the size of the internal buffer which is used for unpacking variadic text data.  This buffer is shared by all FC_Fonts. 
proc getBufferSize*(): cuint {.importc: "FC_GetBufferSize", 
                               .}
#! Changes the size of the internal buffer which is used for unpacking variadic text data.  This buffer is shared by all FC_Fonts. 
proc setBufferSize*(size: cuint) {.importc: "FC_SetBufferSize", 
                                   .}
#! Returns the width of a single horizontal tab in multiples of the width of a space (default: 4) 
proc getTabWidth*(): cuint {.importc: "FC_GetTabWidth", 
                             .}
#! Changes the width of a horizontal tab in multiples of the width of a space (default: 4) 
proc setTabWidth*(widthInSpaces: cuint) {.importc: "FC_SetTabWidth", 
    .}
proc setRenderCallback*(callback: proc (src: ImagePtr; srcrect: ptr Rect; 
    dest: TargetPtr; x: cfloat; y: cfloat; xscale: cfloat; yscale: cfloat): Rect) {.
    importc: "FC_SetRenderCallback".}
proc defaultRenderCallback*(src: ImagePtr; srcrect: ptr Rect; 
                            dest: TargetPtr; x: cfloat; y: cfloat; 
                            xscale: cfloat; yscale: cfloat): Rect {.
    importc: "FC_DefaultRenderCallback", 
    .}
# Custom caching
#! Returns the number of cache levels that are active. 
proc getNumCacheLevels*(font: FontPtr): cint {.
    importc: "FC_GetNumCacheLevels".}
#! Returns the cache source texture at the given cache level. 
proc getGlyphCacheLevel*(font: FontPtr; cacheLevel: cint): ImagePtr {.
    importc: "FC_GetGlyphCacheLevel".}
# TODO: Specify ownership of the texture (should be shareable)
#! Sets a cache source texture for rendering.  New cache levels must be sequential. 
proc setGlyphCacheLevel*(font: FontPtr; cacheLevel: cint; 
                         cacheTexture: ImagePtr): uint8 {.
    importc: "FC_SetGlyphCacheLevel".}
#! Copies the given surface to the given cache level as a texture.  New cache levels must be sequential. 
proc uploadGlyphCache*(font: FontPtr; cacheLevel: cint; 
                       dataSurface: ptr sdl2.Surface): uint8 {.
    importc: "FC_UploadGlyphCache".}
#! Returns the number of codepoints that are stored in the font's glyph data map. 
proc getNumCodepoints*(font: FontPtr): cuint {.
    importc: "FC_GetNumCodepoints".}
#! Copies the stored codepoints into the given array. 
proc getCodepoints*(font: FontPtr; result: ptr uint32) {.
    importc: "FC_GetCodepoints".}
#! Stores the glyph data for the given codepoint in 'result'.  Returns 0 if the codepoint was not found in the cache. 
proc getGlyphData*(font: FontPtr; result: ptr GlyphData; codepoint: uint32): uint8 {.
    importc: "FC_GetGlyphData".}
#! Sets the glyph data for the given codepoint.  Duplicates are not checked.  Returns a pointer to the stored data. 
proc setGlyphData*(font: FontPtr; codepoint: uint32; glyphData: GlyphData): ptr GlyphData {.
    importc: "FC_SetGlyphData".}
# Rendering
proc draw*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
           formattedText: cstring): Rect {.varargs, importc: "FC_Draw", 
    .}
proc drawAlign*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                align: AlignEnum; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawAlign".}
proc drawScale*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                scale: Scale; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawScale".}
proc drawColor*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                color: sdl2.Color; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawColor".}
proc drawEffect*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                 effect: Effect; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawEffect".}
proc drawBox*(font: FontPtr; dest: TargetPtr; box: Rect; 
              formattedText: cstring): Rect {.varargs, importc: "FC_DrawBox", 
    .}
proc drawBoxAlign*(font: FontPtr; dest: TargetPtr; box: Rect; 
                   align: AlignEnum; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawBoxAlign".}
proc drawBoxScale*(font: FontPtr; dest: TargetPtr; box: Rect; scale: Scale; 
                   formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawBoxScale".}
proc drawBoxColor*(font: FontPtr; dest: TargetPtr; box: Rect; 
                   color: sdl2.Color; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawBoxColor".}
proc drawBoxEffect*(font: FontPtr; dest: TargetPtr; box: Rect; 
                    effect: Effect; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawBoxEffect".}
proc drawColumn*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                 width: uint16; formattedText: cstring): Rect {.varargs, 
    importc: "FC_DrawColumn".}
proc drawColumnAlign*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                      width: uint16; align: AlignEnum; formattedText: cstring): Rect {.
    varargs, importc: "FC_DrawColumnAlign", 
    .}
proc drawColumnScale*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                      width: uint16; scale: Scale; formattedText: cstring): Rect {.
    varargs, importc: "FC_DrawColumnScale", 
    .}
proc drawColumnColor*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                      width: uint16; color: sdl2.Color; formattedText: cstring): Rect {.
    varargs, importc: "FC_DrawColumnColor", 
    .}
proc drawColumnEffect*(font: FontPtr; dest: TargetPtr; x: cfloat; y: cfloat; 
                       width: uint16; effect: Effect; formattedText: cstring): Rect {.
    varargs, importc: "FC_DrawColumnEffect", 
    .}
# Getters
proc getFilterMode*(font: FontPtr): FilterEnum {.importc: "FC_GetFilterMode", 
    .}
proc getLineHeight*(font: FontPtr): uint16 {.importc: "FC_GetLineHeight", 
    .}
proc getHeight*(font: FontPtr; formattedText: cstring): uint16 {.varargs, 
    importc: "FC_GetHeight".}
proc getWidth*(font: FontPtr; formattedText: cstring): uint16 {.varargs, 
    importc: "FC_GetWidth".}
# Returns a 1-pixel wide box in front of the character in the given position (index)
proc getCharacterOffset*(font: FontPtr; positionIndex: uint16; 
                         columnWidth: cint; formattedText: cstring): Rect {.
    varargs, importc: "FC_GetCharacterOffset", 
    .}
proc getColumnHeight*(font: FontPtr; width: uint16; formattedText: cstring): uint16 {.
    varargs, importc: "FC_GetColumnHeight", 
    .}
proc getAscent*(font: FontPtr; formattedText: cstring): cint {.varargs, 
    importc: "FC_GetAscent".}
proc getDescent*(font: FontPtr; formattedText: cstring): cint {.varargs, 
    importc: "FC_GetDescent".}
proc getBaseline*(font: FontPtr): cint {.importc: "FC_GetBaseline", 
    .}
proc getSpacing*(font: FontPtr): cint {.importc: "FC_GetSpacing", 
    .}
proc getLineSpacing*(font: FontPtr): cint {.importc: "FC_GetLineSpacing", 
    .}
proc getMaxWidth*(font: FontPtr): uint16 {.importc: "FC_GetMaxWidth", 
    .}
proc getDefaultColor*(font: FontPtr): sdl2.Color {.
    importc: "FC_GetDefaultColor".}
proc getBounds*(font: FontPtr; x: cfloat; y: cfloat; align: AlignEnum; 
                scale: Scale; formattedText: cstring): Rect {.varargs, 
    importc: "FC_GetBounds".}
proc inRect*(x: cfloat; y: cfloat; inputRect: Rect): uint8 {.
    importc: "FC_InRect".}
# Given an offset (x,y) from the text draw position (the upper-left corner), returns the character position (UTF-8 index)
proc getPositionFromOffset*(font: FontPtr; x: cfloat; y: cfloat; 
                            columnWidth: cint; align: AlignEnum; 
                            formattedText: cstring): uint16 {.varargs, 
    importc: "FC_GetPositionFromOffset", 
    .}
# Returns the number of characters in the new wrapped text written into `result`.
proc getWrappedText*(font: FontPtr; result: cstring; maxResultSize: cint; 
                     width: uint16; formattedText: cstring): cint {.varargs, 
    importc: "FC_GetWrappedText".}
# Setters
proc setFilterMode*(font: FontPtr; filter: FilterEnum) {.
    importc: "FC_SetFilterMode".}
proc setSpacing*(font: FontPtr; letterSpacing: cint) {.
    importc: "FC_SetSpacing".}
proc setLineSpacing*(font: FontPtr; lineSpacing: cint) {.
    importc: "FC_SetLineSpacing".}
proc setDefaultColor*(font: FontPtr; color: sdl2.Color) {.
    importc: "FC_SetDefaultColor".}