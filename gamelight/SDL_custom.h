typedef struct SDL_Rect
{
    int x, y;
    int w, h;
} SDL_Rect;

struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;

#include <stdint.h>
#define Uint8 uint8_t
#define Sint16 int16_t
#define Uint16 uint16_t
#define Uint32 uint32_t

typedef struct SDL_Color
{
    Uint8 r;
    Uint8 g;
    Uint8 b;
    Uint8 a;
} SDL_Color;

typedef struct SDL_RWops {} SDL_RWops;

typedef struct SDL_Texture {} SDL_Texture;

typedef struct SDL_Surface {} SDL_Surface;

#define SDL_VERSION_ATLEAST(X, Y, Z) \
    (false)

#define SDL_SWSURFACE 0
#define SDL_RendererFlip int