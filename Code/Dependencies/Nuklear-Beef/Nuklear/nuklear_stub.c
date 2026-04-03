/*
 * This c-file is needed so that the compiler can generate object-files.
 * Nuklear is a header-only library, so we need to define NK_IMPLEMENTATION
 * in exactly one compilation unit.
 */

/* Use standard fixed-size types from stdint.h */
#define NK_INCLUDE_FIXED_TYPES

/* Include default memory allocator (malloc/free from stdlib.h) */
#define NK_INCLUDE_DEFAULT_ALLOCATOR

/* Include file I/O functions (stdio.h) */
#define NK_INCLUDE_STANDARD_IO

/* Include varargs support (stdarg.h) */
#define NK_INCLUDE_STANDARD_VARARGS

/* Use standard bool type */
#define NK_INCLUDE_STANDARD_BOOL

/* Include vertex buffer output for GPU rendering backends */
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT

/* Include font baking (stb_truetype and stb_rect_pack) */
#define NK_INCLUDE_FONT_BAKING

/* Include default font (ProggyClean.ttf embedded) */
#define NK_INCLUDE_DEFAULT_FONT

/* Include command userdata for custom rendering */
#define NK_INCLUDE_COMMAND_USERDATA

/* The implementation */
#define NK_IMPLEMENTATION
#include "nuklear.h"
