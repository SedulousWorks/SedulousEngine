using System;
namespace Nuklear_Beef;

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

/*
# Nuklear
![](https://cloud.githubusercontent.com/assets/8057201/11761525/ae06f0ca-a0c6-11e5-819d-5610b25f6ef4.gif)

## Contents
1. About section
2. Highlights section
3. Features section
4. Usage section
	1. Flags section
	2. Constants section
	3. Dependencies section
5. Example section
6. API section
	1. Context section
	2. Input section
	3. Drawing section
	4. Window section
	5. Layouting section
	6. Groups section
	7. Tree section
	8. Properties section
7. License section
8. Changelog section
9. Gallery section
10. Credits section

## About
This is a minimal state immediate mode graphical user interface toolkit
written in ANSI C and licensed under public domain. It was designed as a simple
embeddable user interface for application and does not have any dependencies,
a default renderbackend or OS window and input handling but instead provides a very modular
library approach by using simple input state for input and draw
commands describing primitive shapes as output. So instead of providing a
layered library that tries to abstract over a number of platform and
render backends it only focuses on the actual UI.

## Highlights
- Graphical user interface toolkit
- Single header library
- Written in C89 (a.k.a. ANSI C or ISO C90)
- Small codebase (~18kLOC)
- Focus on portability, efficiency and simplicity
- No dependencies (not even the standard library if not wanted)
- Fully skinnable and customizable
- Low memory footprint with total memory control if needed or wanted
- UTF-8 support
- No global or hidden state
- Customizable library modules (you can compile and use only what you need)
- Optional font baker and vertex buffer output
- [Code available on github](https://github.com/Immediate-Mode-UI/Nuklear/)

## Features
- Absolutely no platform dependent code
- Memory management control ranging from/to
	- Ease of use by allocating everything from standard library
	- Control every byte of memory inside the library
- Font handling control ranging from/to
	- Use your own font implementation for everything
	- Use this libraries internal font baking and handling API
- Drawing output control ranging from/to
	- Simple shapes for more high level APIs which already have drawing capabilities
	- Hardware accessible anti-aliased vertex buffer output
- Customizable colors and properties ranging from/to
	- Simple changes to color by filling a simple color table
	- Complete control with ability to use skinning to decorate widgets
- Bendable UI library with widget ranging from/to
	- Basic widgets like buttons, checkboxes, slider, ...
	- Advanced widget like abstract comboboxes, contextual menus,...
- Compile time configuration to only compile what you need
	- Subset which can be used if you do not want to link or use the standard library
- Can be easily modified to only update on user input instead of frame updates

## Usage
This library is self contained in one single header file and can be used either
in header only mode or in implementation mode. The header only mode is used
by default when included and allows including this header in other headers
and does not contain the actual implementation. <br /><br />

The implementation mode requires to define  the preprocessor macro
NK_IMPLEMENTATION in *one* .c/.cpp file before #including this file, e.g.:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~C
	#define NK_IMPLEMENTATION
	#include "nuklear.h"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Also optionally define the symbols listed in the section "OPTIONAL DEFINES"
below in header and implementation mode if you want to use additional functionality
or need more control over the library.

!!! WARNING
	Every time nuklear is included define the same compiler flags. This very important not doing so could lead to compiler errors or even worse stack corruptions.

### Flags
Flag                            | Description
--------------------------------|------------------------------------------
NK_PRIVATE                      | If defined declares all functions as static, so they can only be accessed inside the file that contains the implementation
NK_INCLUDE_FIXED_TYPES          | If defined it will include header `<stdint.h>` for fixed sized types otherwise nuklear tries to select the correct type. If that fails it will throw a compiler error and you have to select the correct types yourself.
NK_INCLUDE_DEFAULT_ALLOCATOR    | If defined it will include header `<stdlib.h>` and provide additional functions to use this library without caring for memory allocation control and therefore ease memory management.
NK_INCLUDE_STANDARD_IO          | If defined it will include header `<stdio.h>` and provide additional functions depending on file loading.
NK_INCLUDE_STANDARD_VARARGS     | If defined it will include header <stdarg.h> and provide additional functions depending on file loading.
NK_INCLUDE_STANDARD_BOOL        | If defined it will include header `<stdbool.h>` for nk_bool otherwise nuklear defines nk_bool as int.
NK_INCLUDE_VERTEX_BUFFER_OUTPUT | Defining this adds a vertex draw command list backend to this library, which allows you to convert queue commands into vertex draw commands. This is mainly if you need a hardware accessible format for OpenGL, DirectX, Vulkan, Metal,...
NK_INCLUDE_FONT_BAKING          | Defining this adds `stb_truetype` and `stb_rect_pack` implementation to this library and provides font baking and rendering. If you already have font handling or do not want to use this font handler you don't have to define it.
NK_INCLUDE_DEFAULT_FONT         | Defining this adds the default font: ProggyClean.ttf into this library which can be loaded into a font atlas and allows using this library without having a truetype font
NK_INCLUDE_COMMAND_USERDATA     | Defining this adds a userdata pointer into each command. Can be useful for example if you want to provide custom shaders depending on the used widget. Can be combined with the style structures.
NK_BUTTON_TRIGGER_ON_RELEASE    | Different platforms require button clicks occurring either on buttons being pressed (up to down) or released (down to up). By default this library will react on buttons being pressed, but if you define this it will only trigger if a button is released.
NK_ZERO_COMMAND_MEMORY          | Defining this will zero out memory for each drawing command added to a drawing queue (inside nk_command_buffer_push). Zeroing command memory is very useful for fast checking (using memcmp) if command buffers are equal and avoid drawing frames when nothing on screen has changed since previous frame.
NK_UINT_DRAW_INDEX              | Defining this will set the size of vertex index elements when using NK_VERTEX_BUFFER_OUTPUT to 32bit instead of the default of 16bit
NK_KEYSTATE_BASED_INPUT         | Define this if your backend uses key state for each frame rather than key press/release events
NK_IS_WORD_BOUNDARY(c)          | Define this to a function macro that takes a single nk_rune (nk_uint) and returns true if it's a word separator. If not defined, uses the default definition (see nk_is_word_boundary())

!!! WARNING
	The following flags will pull in the standard C library:
	- NK_INCLUDE_DEFAULT_ALLOCATOR
	- NK_INCLUDE_STANDARD_IO
	- NK_INCLUDE_STANDARD_VARARGS

!!! WARNING
	The following flags if defined need to be defined for both header and implementation:
	- NK_INCLUDE_FIXED_TYPES
	- NK_INCLUDE_DEFAULT_ALLOCATOR
	- NK_INCLUDE_STANDARD_VARARGS
	- NK_INCLUDE_STANDARD_BOOL
	- NK_INCLUDE_VERTEX_BUFFER_OUTPUT
	- NK_INCLUDE_FONT_BAKING
	- NK_INCLUDE_DEFAULT_FONT
	- NK_INCLUDE_STANDARD_VARARGS
	- NK_INCLUDE_COMMAND_USERDATA
	- NK_UINT_DRAW_INDEX

### Constants
Define                          | Description
--------------------------------|---------------------------------------
NK_BUFFER_DEFAULT_INITIAL_SIZE  | Initial buffer size allocated by all buffers while using the default allocator functions included by defining NK_INCLUDE_DEFAULT_ALLOCATOR. If you don't want to allocate the default 4k memory then redefine it.
NK_MAX_NUMBER_BUFFER            | Maximum buffer size for the conversion buffer between float and string Under normal circumstances this should be more than sufficient.
NK_INPUT_MAX                    | Defines the max number of bytes which can be added as text input in one frame. Under normal circumstances this should be more than sufficient.

!!! WARNING
	The following constants if defined need to be defined for both header and implementation:
	- NK_MAX_NUMBER_BUFFER
	- NK_BUFFER_DEFAULT_INITIAL_SIZE
	- NK_INPUT_MAX

### Dependencies
Function    | Description
------------|---------------------------------------------------------------
NK_ASSERT   | If you don't define this, nuklear will use <assert.h> with assert().
NK_MEMSET   | You can define this to 'memset' or your own memset implementation replacement. If not nuklear will use its own version.
NK_MEMCPY   | You can define this to 'memcpy' or your own memcpy implementation replacement. If not nuklear will use its own version.
NK_INV_SQRT | You can define this to your own inverse sqrt implementation replacement. If not nuklear will use its own slow and not highly accurate version.
NK_SIN      | You can define this to 'sinf' or your own sine implementation replacement. If not nuklear will use its own approximation implementation.
NK_COS      | You can define this to 'cosf' or your own cosine implementation replacement. If not nuklear will use its own approximation implementation.
NK_STRTOD   | You can define this to `strtod` or your own string to double conversion implementation replacement. If not defined nuklear will use its own imprecise and possibly unsafe version (does not handle nan or infinity!).
NK_DTOA     | You can define this to `dtoa` or your own double to string conversion implementation replacement. If not defined nuklear will use its own imprecise and possibly unsafe version (does not handle nan or infinity!).
NK_VSNPRINTF| If you define `NK_INCLUDE_STANDARD_VARARGS` as well as `NK_INCLUDE_STANDARD_IO` and want to be safe define this to `vsnprintf` on compilers supporting later versions of C or C++. By default nuklear will check for your stdlib version in C as well as compiler version in C++. if `vsnprintf` is available it will define it to `vsnprintf` directly. If not defined and if you have older versions of C or C++ it will be defined to `vsprintf` which is unsafe.

!!! WARNING
	The following dependencies will pull in the standard C library if not redefined:
	- NK_ASSERT

!!! WARNING
	The following dependencies if defined need to be defined for both header and implementation:
	- NK_ASSERT

!!! WARNING
	The following dependencies if defined need to be defined only for the implementation part:
	- NK_MEMSET
	- NK_MEMCPY
	- NK_SQRT
	- NK_SIN
	- NK_COS
	- NK_STRTOD
	- NK_DTOA
	- NK_VSNPRINTF

## Example

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~c
// init gui state
enum {EASY, HARD};
static int op = EASY;
static float value = 0.6f;
static int i =  20;
struct nk_context ctx;

nk_init_fixed(&ctx, calloc(1, MAX_MEMORY), MAX_MEMORY, &font);
if (nk_begin(&ctx, "Show", nk_rect(50, 50, 220, 220),
	NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_CLOSABLE)) {
	// fixed widget pixel width
	nk_layout_row_static(&ctx, 30, 80, 1);
	if (nk_button_label(&ctx, "button")) {
		// event handling
	}

	// fixed widget window ratio width
	nk_layout_row_dynamic(&ctx, 30, 2);
	if (nk_option_label(&ctx, "easy", op == EASY)) op = EASY;
	if (nk_option_label(&ctx, "hard", op == HARD)) op = HARD;

	// custom widget pixel width
	nk_layout_row_begin(&ctx, NK_STATIC, 30, 2);
	{
		nk_layout_row_push(&ctx, 50);
		nk_label(&ctx, "Volume:", NK_TEXT_LEFT);
		nk_layout_row_push(&ctx, 110);
		nk_slider_float(&ctx, 0, &value, 1.0f, 0.1f);
	}
	nk_layout_row_end(&ctx);
}
nk_end(&ctx);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

![](https://cloud.githubusercontent.com/assets/8057201/10187981/584ecd68-675c-11e5-897c-822ef534a876.png)

## API

*/

/** \file nuklear.h
 * \brief main API and documentation file
 *
 * \details
 */
/*
 * ==============================================================
 *
 *                          CONSTANTS
 *
 * ===============================================================
 */

static
{
	public const float NK_UNDEFINED = (-1.0f);
	public const uint32 NK_UTF_INVALID  = 0xFFFD; /**< internal invalid utf8 rune */
	public const uint32 NK_UTF_SIZE = 4; /**< describes the number of bytes a glyph consists of*/
	public const uint32 NK_INPUT_MAX = 16;
	public const uint32 NK_MAX_NUMBER_BUFFER = 64;
	public const float NK_SCROLLBAR_HIDING_TIMEOUT = 4.0f;
}
	/*
	 * ==============================================================
	 *
	 *                          HELPER
	 *
	 * ===============================================================
	 */

	/*#ifndef [CLink] public static extern
	  #ifdef NK_PRIVATE
		#if (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199409L))
		  #define [CLink] public static extern static inline
		#elif defined(__cplusplus)
		  #define [CLink] public static extern static inline
		#else
		  #define [CLink] public static extern static
		#endif
	  #else
		#define [CLink] public static extern extern
	  #endif
#endif
#ifndef NK_LIB
	  #ifdef NK_SINGLE_FILE
		#define NK_LIB static
	  #else
		#define NK_LIB extern
	  #endif
#endif

#define NK_INTERN static
#define NK_STORAGE static
#define NK_GLOBAL static

#define NK_FLAG(x) (1 << (x))
#define NK_STRINGIFY(x) #x
#define NK_MACRO_STRINGIFY(x) NK_STRINGIFY(x)
#define NK_STRING_JOIN_IMMEDIATE(arg1, arg2) arg1 ## arg2
#define NK_STRING_JOIN_DELAY(arg1, arg2) NK_STRING_JOIN_IMMEDIATE(arg1, arg2)
#define NK_STRING_JOIN(arg1, arg2) NK_STRING_JOIN_DELAY(arg1, arg2)

#ifdef _MSC_VER
	  #define NK_UNIQUE_NAME(name) NK_STRING_JOIN(name,__COUNTER__)
#else
	  #define NK_UNIQUE_NAME(name) NK_STRING_JOIN(name,__LINE__)
#endif

#ifndef NK_STATIC_ASSERT
	  #define NK_STATIC_ASSERT(exp) typedef char8 NK_UNIQUE_NAME(_dummy_array)[(exp)?1:-1]
#endif

#ifndef NK_FILE_LINE
#ifdef _MSC_VER
	  #define NK_FILE_LINE __FILE__ ":" NK_MACRO_STRINGIFY(__COUNTER__)
#else
	  #define NK_FILE_LINE __FILE__ ":" NK_MACRO_STRINGIFY(__LINE__)
#endif
#endif*/

static
{
	public static mixin NK_FLAG(var x)
	{
		(1 << (x))
	}
}

static
{
	public static T NK_MIN<T>(T a, T b) where bool : operator T < T => ((a) < (b) ? (a) : (b));
	public static T NK_MAX<T>(T a, T b) where bool : operator T < T => ((a) < (b) ? (b) : (a));
	public static T NK_CLAMP<T>(T i, T v, T x) where bool : operator T < T => (NK_MAX(NK_MIN(v, x), i));
}

	/*
	 * ===============================================================
	 *
	 *                          BASIC
	 *
	 * ===============================================================
	 */
typealias NK_INT8 = int8;
typealias  NK_UINT8 = uint8;
typealias  NK_INT16 = int16;
typealias  NK_UINT16 = uint16;
typealias  NK_INT32 = int32;
typealias  NK_UINT32 = uint32;
typealias  NK_SIZE_TYPE = uint;
typealias  NK_POINTER_TYPE = uint;

typealias NK_BOOL = bool;
	//typealias NK_BOOL =int32;

typealias nk_char = NK_INT8;
typealias nk_uchar = NK_UINT8;
typealias nk_byte = NK_UINT8;
typealias nk_short = NK_INT16;
typealias nk_ushort = NK_UINT16;
typealias nk_int = NK_INT32;
typealias nk_uint = NK_UINT32;
typealias nk_size = NK_SIZE_TYPE;
typealias nk_ptr = NK_POINTER_TYPE;
typealias nk_bool = NK_BOOL;

typealias nk_hash = nk_uint;
typealias nk_flags = nk_uint;
typealias nk_rune = nk_uint;

	/* Make sure correct type size:
	 * This will fire with a negative subscript error if the type sizes
	 * are set incorrectly by the compiler, and compile out if not */
static
{
	[Comptime]
	public static void AssertPrimitiveSizes()
	{
		Compiler.Assert(sizeof(nk_short) == 2);
		Compiler.Assert(sizeof(nk_ushort) == 2);
		Compiler.Assert(sizeof(nk_uint) == 4);
		Compiler.Assert(sizeof(nk_int) == 4);
		Compiler.Assert(sizeof(nk_byte) == 1);
		Compiler.Assert(sizeof(nk_flags) >= 4);
		Compiler.Assert(sizeof(nk_rune) >= 4);
		Compiler.Assert(sizeof(nk_size) >= sizeof(void*));
		Compiler.Assert(sizeof(nk_ptr) >= sizeof(void*));
#if NK_INCLUDE_STANDARD_BOOL
		Compiler.Assert(sizeof(nk_bool) == sizeof(bool));
#else
		Compiler.Assert(sizeof(nk_bool) >= 2);
#endif
	}

}

/* ============================================================================
 *
 *                                  API
 *
 * =========================================================================== */
//struct nk_buffer;
//struct nk_allocator;
//struct nk_command_buffer;
//struct nk_draw_command;
//struct nk_convert_config;
//struct nk_style_item;
//struct nk_text_edit;
//struct nk_draw_list;
//struct nk_user_font;
//struct nk_panel;
//struct nk_context;
//struct nk_draw_vertex_layout_element;
//struct nk_style_button;
//struct nk_style_toggle;
//struct nk_style_selectable;
//struct nk_style_slide;
//struct nk_style_progress;
//struct nk_style_scrollbar;
//struct nk_style_edit;
//struct nk_style_property;
//struct nk_style_chart;
//struct nk_style_combo;
//struct nk_style_tab;
//struct nk_style_window_header;
//struct nk_style_window;

static
{
	public const int32 nk_false = 0;
	public const int32 nk_true = 1;
}

[CRepr] struct nk_color { public nk_byte r, g, b, a; }
[CRepr] struct nk_colorf { public float r, g, b, a; }
[CRepr] struct nk_vec2 { public float x, y; }
[CRepr] struct nk_vec2i { public int16 x, y; }
[CRepr] struct nk_rect { public float x, y, w, h; }
[CRepr] struct nk_recti { public int16 x, y, w, h; }
typealias nk_glyph = char8[NK_UTF_SIZE];
[CRepr, Union] struct nk_handle { public void* ptr; public int32 id; }
[CRepr] struct nk_image { public nk_handle handle; public nk_ushort w, h; public nk_ushort[4] region; }
[CRepr] struct nk_nine_slice { public nk_image img; public nk_ushort l, t, r, b; }
[CRepr] struct nk_cursor { public nk_image img; public nk_vec2 size, offset; }
[CRepr] struct nk_scroll { public nk_uint x, y; }

enum nk_heading  : int32       { NK_UP, NK_RIGHT, NK_DOWN, NK_LEFT }
enum nk_button_behavior : int32 { NK_BUTTON_DEFAULT, NK_BUTTON_REPEATER }
enum nk_modify   : int32       { NK_FIXED = nk_false, NK_MODIFIABLE = nk_true }
enum nk_orientation   : int32  { NK_VERTICAL, NK_HORIZONTAL }
enum nk_collapse_states : int32 { NK_MINIMIZED = nk_false, NK_MAXIMIZED = nk_true }
enum nk_show_states  : int32   { NK_HIDDEN = nk_false, NK_SHOWN = nk_true }
enum nk_chart_type   : int32   { NK_CHART_LINES, NK_CHART_COLUMN, NK_CHART_MAX }
enum nk_chart_event  : int32   { NK_CHART_HOVERING = 0x01, NK_CHART_CLICKED = 0x02 }
enum nk_color_format : int32   { NK_RGB, NK_RGBA }
enum nk_popup_type   : int32   { NK_POPUP_STATIC, NK_POPUP_DYNAMIC }
enum nk_layout_format : int32  { NK_DYNAMIC, NK_STATIC }
enum nk_tree_type    : int32   { NK_TREE_NODE, NK_TREE_TAB }

typealias nk_plugin_alloc = function void*(nk_handle, void* old, nk_size);
typealias  nk_plugin_free = function void(nk_handle, void* old);
typealias  nk_plugin_filter = function nk_bool(nk_text_edit*, nk_rune unicode);
typealias  nk_plugin_paste = function void(nk_handle, nk_text_edit*);
typealias  nk_plugin_copy = function void(nk_handle, char8*, int32 len);

[CRepr] struct nk_allocator
{
	public nk_handle userdata;
	public nk_plugin_alloc alloc;
	public nk_plugin_free free;
}
enum nk_symbol_type : int32
{
	NK_SYMBOL_NONE,
	NK_SYMBOL_X,
	NK_SYMBOL_UNDERSCORE,
	NK_SYMBOL_CIRCLE_SOLID,
	NK_SYMBOL_CIRCLE_OUTLINE,
	NK_SYMBOL_RECT_SOLID,
	NK_SYMBOL_RECT_OUTLINE,
	NK_SYMBOL_TRIANGLE_UP,
	NK_SYMBOL_TRIANGLE_DOWN,
	NK_SYMBOL_TRIANGLE_LEFT,
	NK_SYMBOL_TRIANGLE_RIGHT,
	NK_SYMBOL_PLUS,
	NK_SYMBOL_MINUS,
	NK_SYMBOL_TRIANGLE_UP_OUTLINE,
	NK_SYMBOL_TRIANGLE_DOWN_OUTLINE,
	NK_SYMBOL_TRIANGLE_LEFT_OUTLINE,
	NK_SYMBOL_TRIANGLE_RIGHT_OUTLINE,
	NK_SYMBOL_MAX
}
/* =============================================================================
 *
 *                                  CONTEXT
 *
 * =============================================================================*/
/**
 * \page Context
 * Contexts are the main entry point and the majestro of nuklear and contain all required state.
 * They are used for window, memory, input, style, stack, commands and time management and need
 * to be passed into all nuklear GUI specific functions.
 *
 * # Usage
 * To use a context it first has to be initialized which can be achieved by calling
 * one of either `nk_init_default`, `nk_init_fixed`, `nk_init`, `nk_init_custom`.
 * Each takes in a font handle and a specific way of handling memory. Memory control
 * hereby ranges from standard library to just specifying a fixed sized block of memory
 * which nuklear has to manage itself from.
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     // [...]
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 *
 * # Reference
 * Function            | Description
 * --------------------|-------------------------------------------------------
 * \ref nk_init_default | Initializes context with standard library memory allocation (malloc,free)
 * \ref nk_init_fixed   | Initializes context from single fixed size memory block
 * \ref nk_init         | Initializes context with memory allocator callbacks for alloc and free
 * \ref nk_init_custom  | Initializes context from two buffers. One for draw commands the other for window/panel/table allocations
 * \ref nk_clear        | Called at the end of the frame to reset and prepare the context for the next frame
 * \ref nk_free         | Shutdown and free all memory allocated inside the context
 * \ref nk_set_user_data| Utility function to pass user data to draw command
 */

//#if NK_INCLUDE_DEFAULT_ALLOCATOR
static
{
/**
 * # nk_init_default
 * Initializes a `nk_context` struct with a default standard library allocator.
 * Should be used if you don't want to be bothered with memory management in nuklear.
 *
 * ```c
 * nk_bool nk_init_default(nk_context *ctx,  nk_user_font *font);
 * ```
 *
 * Parameter   | Description
 * ------------|---------------------------------------------------------------
 * \param[in] ctx     | Must point to an either stack or heap allocated `nk_context` struct
 * \param[in] font    | Must point to a previously initialized font handle for more info look at font documentation
 *
 * \returns either `false(0)` on failure or `true(1)` on success.
 */

	[CLink] public static extern nk_bool nk_init_default(nk_context*, nk_user_font*);

//#endif
/**
 * # nk_init_fixed
 * Initializes a `nk_context` struct from single fixed size memory block
 * Should be used if you want complete control over nuklear's memory management.
 * Especially recommended for system with little memory or systems with virtual memory.
 * For the later case you can just allocate for example 16MB of virtual memory
 * and only the required amount of memory will actually be committed.
 *
 * ```c
 * nk_bool nk_init_fixed(nk_context *ctx, void *memory, nk_size size,  nk_user_font *font);
 * ```
 *
 * !!! Warning
 *     make sure the passed memory block is aligned correctly for `nk_draw_commands`.
 *
 * Parameter   | Description
 * ------------|--------------------------------------------------------------
 * \param[in] ctx     | Must point to an either stack or heap allocated `nk_context` struct
 * \param[in] memory  | Must point to a previously allocated memory block
 * \param[in] size    | Must contain the total size of memory
 * \param[in] font    | Must point to a previously initialized font handle for more info look at font documentation
 *
 * \returns either `false(0)` on failure or `true(1)` on success.
 */
	[CLink] public static extern nk_bool nk_init_fixed(nk_context*, void* memory, nk_size size,  nk_user_font*);

/**
 * # nk_init
 * Initializes a `nk_context` struct with memory allocation callbacks for nuklear to allocate
 * memory from. Used internally for `nk_init_default` and provides a kitchen sink allocation
 * interface to nuklear. Can be useful for cases like monitoring memory consumption.
 *
 * ```c
 * nk_bool nk_init(nk_context *ctx,  nk_allocator *alloc,  nk_user_font *font);
 * ```
 *
 * Parameter   | Description
 * ------------|---------------------------------------------------------------
 * \param[in] ctx     | Must point to an either stack or heap allocated `nk_context` struct
 * \param[in] alloc   | Must point to a previously allocated memory allocator
 * \param[in] font    | Must point to a previously initialized font handle for more info look at font documentation
 *
 * \returns either `false(0)` on failure or `true(1)` on success.
 */
	[CLink] public static extern nk_bool nk_init(nk_context*,  nk_allocator*,  nk_user_font*);

/**
 * \brief Initializes a `nk_context` struct from two different either fixed or growing buffers.
 *
 * \details
 * The first buffer is for allocating draw commands while the second buffer is
 * used for allocating windows, panels and state tables.
 *
 * ```c
 * nk_bool nk_init_custom(nk_context *ctx, struct nk_buffer *cmds, struct nk_buffer *pool,  nk_user_font *font);
 * ```
 *
 * \param[in] ctx    Must point to an either stack or heap allocated `nk_context` struct
 * \param[in] cmds   Must point to a previously initialized memory buffer either fixed or dynamic to store draw commands into
 * \param[in] pool   Must point to a previously initialized memory buffer either fixed or dynamic to store windows, panels and tables
 * \param[in] font   Must point to a previously initialized font handle for more info look at font documentation
 *
 * \returns either `false(0)` on failure or `true(1)` on success.
 */
	[CLink] public static extern nk_bool nk_init_custom(nk_context*,  nk_buffer* cmds,  nk_buffer* pool,  nk_user_font*);

/**
 * \brief Resets the context state at the end of the frame.
 *
 * \details
 * This includes mostly garbage collector tasks like removing windows or table
 * not called and therefore used anymore.
 *
 * ```c
 * void nk_clear(nk_context *ctx);
 * ```
 *
 * \param[in] ctx  Must point to a previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_clear(nk_context*);

/**
 * \brief Frees all memory allocated by nuklear; Not needed if context was initialized with `nk_init_fixed`.
 *
 * \details
 * ```c
 * void nk_free(nk_context *ctx);
 * ```
 *
 * \param[in] ctx  Must point to a previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_free(nk_context*);

#if NK_INCLUDE_COMMAND_USERDATA
/**
 * \brief Sets the currently passed userdata passed down into each draw command.
 *
 * \details
 * ```c
 * void nk_set_user_data(nk_context *ctx, nk_handle data);
 * ```
 *
 * \param[in] ctx Must point to a previously initialized `nk_context` struct
 * \param[in] data  Handle with either pointer or index to be passed into every draw commands
 */
	[CLink] public static extern void nk_set_user_data(nk_context*, nk_handle handle);
#endif
}
/* =============================================================================
 *
 *                                  INPUT
 *
 * =============================================================================*/
/**
 * \page Input
 *
 * The input API is responsible for holding the current input state composed of
 * mouse, key and text input states.
 * It is worth noting that no direct OS or window handling is done in nuklear.
 * Instead all input state has to be provided by platform specific code. This on one hand
 * expects more work from the user and complicates usage but on the other hand
 * provides simple abstraction over a big number of platforms, libraries and other
 * already provided functionality.
 *
 * ```c
 * nk_input_begin(&ctx);
 * while (GetEvent(&evt)) {
 *     if (evt.type == MOUSE_MOVE)
 *         nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
 *     else if (evt.type == [...]) {
 *         // [...]
 *     }
 * } nk_input_end(&ctx);
 * ```
 *
 * # Usage
 * Input state needs to be provided to nuklear by first calling `nk_input_begin`
 * which resets internal state like delta mouse position and button transitions.
 * After `nk_input_begin` all current input state needs to be provided. This includes
 * mouse motion, button and key pressed and released, text input and scrolling.
 * Both event- or state-based input handling are supported by this API
 * and should work without problems. Finally after all input state has been
 * mirrored `nk_input_end` needs to be called to finish input process.
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     Event evt;
 *     nk_input_begin(&ctx);
 *     while (GetEvent(&evt)) {
 *         if (evt.type == MOUSE_MOVE)
 *             nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
 *         else if (evt.type == [...]) {
 *             // [...]
 *         }
 *     }
 *     nk_input_end(&ctx);
 *     // [...]
 *     nk_clear(&ctx);
 * } nk_free(&ctx);
 * ```
 *
 * # Reference
 * Function            | Description
 * --------------------|-------------------------------------------------------
 * \ref nk_input_begin  | Begins the input mirroring process. Needs to be called before all other `nk_input_xxx` calls
 * \ref nk_input_motion | Mirrors mouse cursor position
 * \ref nk_input_key    | Mirrors key state with either pressed or released
 * \ref nk_input_button | Mirrors mouse button state with either pressed or released
 * \ref nk_input_scroll | Mirrors mouse scroll values
 * \ref nk_input_char   | Adds a single ASCII text character into an internal text buffer
 * \ref nk_input_glyph  | Adds a single multi-byte UTF-8 character into an internal text buffer
 * \ref nk_input_unicode| Adds a single unicode rune into an internal text buffer
 * \ref nk_input_end    | Ends the input mirroring process by calculating state changes. Don't call any `nk_input_xxx` function referenced above after this call
 */

enum nk_keys : int32
{
	NK_KEY_NONE,
	NK_KEY_SHIFT,
	NK_KEY_CTRL,
	NK_KEY_DEL,
	NK_KEY_ENTER,
	NK_KEY_TAB,
	NK_KEY_BACKSPACE,
	NK_KEY_COPY,
	NK_KEY_CUT,
	NK_KEY_PASTE,
	NK_KEY_UP,
	NK_KEY_DOWN,
	NK_KEY_LEFT,
	NK_KEY_RIGHT,
	/* Shortcuts: text field */
	NK_KEY_TEXT_INSERT_MODE,
	NK_KEY_TEXT_REPLACE_MODE,
	NK_KEY_TEXT_RESET_MODE,
	NK_KEY_TEXT_LINE_START,
	NK_KEY_TEXT_LINE_END,
	NK_KEY_TEXT_START,
	NK_KEY_TEXT_END,
	NK_KEY_TEXT_UNDO,
	NK_KEY_TEXT_REDO,
	NK_KEY_TEXT_SELECT_ALL,
	NK_KEY_TEXT_WORD_LEFT,
	NK_KEY_TEXT_WORD_RIGHT,
	/* Shortcuts: scrollbar */
	NK_KEY_SCROLL_START,
	NK_KEY_SCROLL_END,
	NK_KEY_SCROLL_DOWN,
	NK_KEY_SCROLL_UP,
	NK_KEY_MAX
}
enum nk_buttons : int32
{
	NK_BUTTON_LEFT,
	NK_BUTTON_MIDDLE,
	NK_BUTTON_RIGHT,
	NK_BUTTON_DOUBLE,
	NK_BUTTON_MAX
}

static
{
/**
 * \brief Begins the input mirroring process by resetting text, scroll
 * mouse, previous mouse position and movement as well as key state transitions.
 *
 * \details
 * ```c
 * void nk_input_begin(nk_context*);
 * ```
 *
 * \param[in] ctx Must point to a previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_input_begin(nk_context*);

/**
 * \brief Mirrors current mouse position to nuklear
 *
 * \details
 * ```c
 * void nk_input_motion(nk_context *ctx, int x, int y);
 * ```
 *
 * \param[in] ctx   Must point to a previously initialized `nk_context` struct
 * \param[in] x     Must hold an integer describing the current mouse cursor x-position
 * \param[in] y     Must hold an integer describing the current mouse cursor y-position
 */
	[CLink] public static extern void nk_input_motion(nk_context*, int32 x, int32 y);

/**
 * \brief Mirrors the state of a specific key to nuklear
 *
 * \details
 * ```c
 * void nk_input_key(nk_context*, enum nk_keys key, nk_bool down);
 * ```
 *
 * \param[in] ctx      Must point to a previously initialized `nk_context` struct
 * \param[in] key      Must be any value specified in enum `nk_keys` that needs to be mirrored
 * \param[in] down     Must be 0 for key is up and 1 for key is down
 */
	[CLink] public static extern void nk_input_key(nk_context*,  nk_keys, nk_bool down);

/**
 * \brief Mirrors the state of a specific mouse button to nuklear
 *
 * \details
 * ```c
 * void nk_input_button(nk_context *ctx, enum nk_buttons btn, int x, int y, nk_bool down);
 * ```
 *
 * \param[in] ctx     Must point to a previously initialized `nk_context` struct
 * \param[in] btn     Must be any value specified in enum `nk_buttons` that needs to be mirrored
 * \param[in] x       Must contain an integer describing mouse cursor x-position on click up/down
 * \param[in] y       Must contain an integer describing mouse cursor y-position on click up/down
 * \param[in] down    Must be 0 for key is up and 1 for key is down
 */
	[CLink] public static extern void nk_input_button(nk_context*,  nk_buttons, int32 x, int32 y, nk_bool down);

/**
 * \brief Copies the last mouse scroll value to nuklear.
 *
 * \details
 * Is generally a scroll value. So does not have to come from mouse and could
 * also originate from balls, tracks, linear guide rails, or other programs.
 *
 * ```c
 * void nk_input_scroll(nk_context *ctx, struct nk_vec2 val);
 * ```
 *
 * \param[in] ctx     | Must point to a previously initialized `nk_context` struct
 * \param[in] val     | vector with both X- as well as Y-scroll value
 */
	[CLink] public static extern void nk_input_scroll(nk_context*,  nk_vec2 val);

/**
 * \brief Copies a single ASCII character into an internal text buffer
 *
 * \details
 * This is basically a helper function to quickly push ASCII characters into
 * nuklear.
 *
 * \note
 *     Stores up to NK_INPUT_MAX bytes between `nk_input_begin` and `nk_input_end`.
 *
 * ```c
 * void nk_input_char(nk_context *ctx, char8 c);
 * ```
 *
 * \param[in] ctx     | Must point to a previously initialized `nk_context` struct
 * \param[in] c       | Must be a single ASCII character preferable one that can be printed
 */
	[CLink] public static extern void nk_input_char(nk_context*, char8);

/**
 * \brief Converts an encoded unicode rune into UTF-8 and copies the result into an
 * internal text buffer.
 *
 * \note
 *     Stores up to NK_INPUT_MAX bytes between `nk_input_begin` and `nk_input_end`.
 *
 * ```c
 * void nk_input_glyph(nk_context *ctx, const nk_glyph g);
 * ```
 *
 * \param[in] ctx     | Must point to a previously initialized `nk_context` struct
 * \param[in] g       | UTF-32 unicode codepoint
 */
	[CLink] public static extern void nk_input_glyph(nk_context*,  nk_glyph);

/**
 * \brief Converts a unicode rune into UTF-8 and copies the result
 * into an internal text buffer.
 *
 * \details
 * \note
 *     Stores up to NK_INPUT_MAX bytes between `nk_input_begin` and `nk_input_end`.
 *
 * ```c
 * void nk_input_unicode(nk_context*, nk_rune rune);
 * ```
 *
 * \param[in] ctx     | Must point to a previously initialized `nk_context` struct
 * \param[in] rune    | UTF-32 unicode codepoint
 */
	[CLink] public static extern void nk_input_unicode(nk_context*, nk_rune);

/**
 * \brief End the input mirroring process by resetting mouse grabbing
 * state to ensure the mouse cursor is not grabbed indefinitely.
 *
 * \details
 * ```c
 * void nk_input_end(nk_context *ctx);
 * ```
 *
 * \param[in] ctx     | Must point to a previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_input_end(nk_context*);
}
/* =============================================================================
 *
 *                                  DRAWING
 *
 * =============================================================================*/
/**
 * \page Drawing
 * This library was designed to be render backend agnostic so it does
 * not draw anything to screen directly. Instead all drawn shapes, widgets
 * are made of, are buffered into memory and make up a command queue.
 * Each frame therefore fills the command buffer with draw commands
 * that then need to be executed by the user and his own render backend.
 * After that the command buffer needs to be cleared and a new frame can be
 * started. It is probably important to note that the command buffer is the main
 * drawing API and the optional vertex buffer API only takes this format and
 * converts it into a hardware accessible format.
 *
 * # Usage
 * To draw all draw commands accumulated over a frame you need your own render
 * backend able to draw a number of 2D primitives. This includes at least
 * filled and stroked rectangles, circles, text, lines, triangles and scissors.
 * As soon as this criterion is met you can iterate over each draw command
 * and execute each draw command in a interpreter like fashion:
 *
 * ```c
 *  nk_command *cmd = 0;
 * nk_foreach(cmd, &ctx) {
 *     switch (cmd->type) {
 *     case NK_COMMAND_LINE:
 *         your_draw_line_function(...)
 *         break;
 *     case NK_COMMAND_RECT
 *         your_draw_rect_function(...)
 *         break;
 *     case //...:
 *         //[...]
 *     }
 * }
 * ```
 *
 * In program flow context draw commands need to be executed after input has been
 * gathered and the complete UI with windows and their contained widgets have
 * been executed and before calling `nk_clear` which frees all previously
 * allocated draw commands.
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     Event evt;
 *     nk_input_begin(&ctx);
 *     while (GetEvent(&evt)) {
 *         if (evt.type == MOUSE_MOVE)
 *             nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
 *         else if (evt.type == [...]) {
 *             [...]
 *         }
 *     }
 *     nk_input_end(&ctx);
 *     //
 *     // [...]
 *     //
 *      nk_command *cmd = 0;
 *     nk_foreach(cmd, &ctx) {
 *     switch (cmd->type) {
 *     case NK_COMMAND_LINE:
 *         your_draw_line_function(...)
 *         break;
 *     case NK_COMMAND_RECT
 *         your_draw_rect_function(...)
 *         break;
 *     case ...:
 *         // [...]
 *     }
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 *
 * You probably noticed that you have to draw all of the UI each frame which is
 * quite wasteful. While the actual UI updating loop is quite fast rendering
 * without actually needing it is not. So there are multiple things you could do.
 *
 * First is only update on input. This of course is only an option if your
 * application only depends on the UI and does not require any outside calculations.
 * If you actually only update on input make sure to update the UI two times each
 * frame and call `nk_clear` directly after the first pass and only draw in
 * the second pass. In addition it is recommended to also add additional timers
 * to make sure the UI is not drawn more than a fixed number of frames per second.
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     // [...wait for input ]
 *     // [...do two UI passes ...]
 *     do_ui(...)
 *     nk_clear(&ctx);
 *     do_ui(...)
 *     //
 *     // draw
 *      nk_command *cmd = 0;
 *     nk_foreach(cmd, &ctx) {
 *     switch (cmd->type) {
 *     case NK_COMMAND_LINE:
 *         your_draw_line_function(...)
 *         break;
 *     case NK_COMMAND_RECT
 *         your_draw_rect_function(...)
 *         break;
 *     case ...:
 *         //[...]
 *     }
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 *
 * The second probably more applicable trick is to only draw if anything changed.
 * It is not really useful for applications with continuous draw loop but
 * quite useful for desktop applications. To actually get nuklear to only
 * draw on changes you first have to define `NK_ZERO_COMMAND_MEMORY` and
 * allocate a memory buffer that will store each unique drawing output.
 * After each frame you compare the draw command memory inside the library
 * with your allocated buffer by memcmp. If memcmp detects differences
 * you have to copy the command buffer into the allocated buffer
 * and then draw like usual (this example uses fixed memory but you could
 * use dynamically allocated memory).
 *
 * ```c
 * //[... other defines ...]
 * #define NK_ZERO_COMMAND_MEMORY
 * #include "nuklear.h"
 * //
 * // setup context
 * struct nk_context ctx;
 * void *last = calloc(1,64*1024);
 * void *buf = calloc(1,64*1024);
 * nk_init_fixed(&ctx, buf, 64*1024);
 * //
 * // loop
 * while (1) {
 *     // [...input...]
 *     // [...ui...]
 *     void *cmds = nk_buffer_memory(&ctx.memory);
 *     if (memcmp(cmds, last, ctx.memory.allocated)) {
 *         memcpy(last,cmds,ctx.memory.allocated);
 *          nk_command *cmd = 0;
 *         nk_foreach(cmd, &ctx) {
 *             switch (cmd->type) {
 *             case NK_COMMAND_LINE:
 *                 your_draw_line_function(...)
 *                 break;
 *             case NK_COMMAND_RECT
 *                 your_draw_rect_function(...)
 *                 break;
 *             case ...:
 *                 // [...]
 *             }
 *         }
 *     }
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 *
 * Finally while using draw commands makes sense for higher abstracted platforms like
 * X11 and Win32 or drawing libraries it is often desirable to use graphics
 * hardware directly. Therefore it is possible to just define
 * `NK_INCLUDE_VERTEX_BUFFER_OUTPUT` which includes optional vertex output.
 * To access the vertex output you first have to convert all draw commands into
 * vertexes by calling `nk_convert` which takes in your preferred vertex format.
 * After successfully converting all draw commands just iterate over and execute all
 * vertex draw commands:
 *
 * ```c
 * // fill configuration
 * struct your_vertex
 * {
 *     float pos[2]; // important to keep it to 2 floats
 *     float uv[2];
 *     uint8 col[4];
 * };
 * struct nk_convert_config cfg = {};
 * static  nk_draw_vertex_layout_element vertex_layout[] = {
 *     {NK_VERTEX_POSITION, NK_FORMAT_FLOAT, NK_OFFSETOF(struct your_vertex, pos)},
 *     {NK_VERTEX_TEXCOORD, NK_FORMAT_FLOAT, NK_OFFSETOF(struct your_vertex, uv)},
 *     {NK_VERTEX_COLOR, NK_FORMAT_R8G8B8A8, NK_OFFSETOF(struct your_vertex, col)},
 *     {NK_VERTEX_LAYOUT_END}
 * };
 * cfg.shape_AA = NK_ANTI_ALIASING_ON;
 * cfg.line_AA = NK_ANTI_ALIASING_ON;
 * cfg.vertex_layout = vertex_layout;
 * cfg.vertex_size = sizeof(struct your_vertex);
 * cfg.vertex_alignment = NK_ALIGNOF(struct your_vertex);
 * cfg.circle_segment_count = 22;
 * cfg.curve_segment_count = 22;
 * cfg.arc_segment_count = 22;
 * cfg.global_alpha = 1.0f;
 * cfg.tex_null = dev->tex_null;
 * //
 * // setup buffers and convert
 * struct nk_buffer cmds, verts, idx;
 * nk_buffer_init_default(&cmds);
 * nk_buffer_init_default(&verts);
 * nk_buffer_init_default(&idx);
 * nk_convert(&ctx, &cmds, &verts, &idx, &cfg);
 * //
 * // draw
 * nk_draw_foreach(cmd, &ctx, &cmds) {
 * if (!cmd->elem_count) continue;
 *     //[...]
 * }
 * nk_buffer_free(&cms);
 * nk_buffer_free(&verts);
 * nk_buffer_free(&idx);
 * ```
 *
 * # Reference
 * Function            | Description
 * --------------------|-------------------------------------------------------
 * \ref nk__begin       | Returns the first draw command in the context draw command list to be drawn
 * \ref nk__next        | Increments the draw command iterator to the next command inside the context draw command list
 * \ref nk_foreach      | Iterates over each draw command inside the context draw command list
 * \ref nk_convert      | Converts from the abstract draw commands list into a hardware accessible vertex format
 * \ref nk_draw_begin   | Returns the first vertex command in the context vertex draw list to be executed
 * \ref nk__draw_next   | Increments the vertex command iterator to the next command inside the context vertex command list
 * \ref nk__draw_end    | Returns the end of the vertex draw list
 * \ref nk_draw_foreach | Iterates over each vertex draw command inside the vertex draw list
 */

enum nk_anti_aliasing : int32 { NK_ANTI_ALIASING_OFF, NK_ANTI_ALIASING_ON }
enum nk_convert_result : int32
{
	NK_CONVERT_SUCCESS = 0,
	NK_CONVERT_INVALID_PARAM = 1,
	NK_CONVERT_COMMAND_BUFFER_FULL = NK_FLAG!(1),
	NK_CONVERT_VERTEX_BUFFER_FULL = NK_FLAG!(2),
	NK_CONVERT_ELEMENT_BUFFER_FULL = NK_FLAG!(3)
}
[CRepr] struct nk_draw_null_texture
{
	public nk_handle texture; /**!< texture handle to a texture with a white pixel */
	public nk_vec2 uv; /**!< coordinates to a white pixel in the texture  */
}
[CRepr] struct nk_convert_config
{
	public float global_alpha; /**!< global alpha value */
	public nk_anti_aliasing line_AA; /**!< line anti-aliasing flag can be turned off if you are tight on memory */
	public nk_anti_aliasing shape_AA; /**!< shape anti-aliasing flag can be turned off if you are tight on memory */
	public uint32 circle_segment_count; /**!< number of segments used for circles: default to 22 */
	public uint32 arc_segment_count; /**!< number of segments used for arcs: default to 22 */
	public uint32 curve_segment_count; /**!< number of segments used for curves: default to 22 */
	public nk_draw_null_texture tex_null; /**!< handle to texture with a white pixel for shape drawing */
	public nk_draw_vertex_layout_element* vertex_layout; /**!< describes the vertex output format and packing */
	public nk_size vertex_size; /**!< sizeof one vertex for vertex packing */
	public nk_size vertex_alignment; /**!< vertex alignment: Can be obtained by NK_ALIGNOF */
}

static
{
/**
 * \brief Returns a draw command list iterator to iterate all draw
 * commands accumulated over one frame.
 *
 * \details
 * ```c
 *  nk_command* nk__begin(nk_context*);
 * ```
 *
 * \param[in] ctx     | must point to an previously initialized `nk_context` struct at the end of a frame
 *
 * \returns draw command pointer pointing to the first command inside the draw command list
 */
	[CLink] public static extern  nk_command* nk__begin(nk_context*);

/**
 * \brief Returns draw command pointer pointing to the next command inside the draw command list
 *
 * \details
 * ```c
 *  nk_command* nk__next(nk_context*,  nk_command*);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 * \param[in] cmd     | Must point to an previously a draw command either returned by `nk__begin` or `nk__next`
 *
 * \returns draw command pointer pointing to the next command inside the draw command list
 */
	[CLink] public static extern  nk_command* nk__next(nk_context*,  nk_command*);

/**
 * \brief Iterates over each draw command inside the context draw command list
 *
 * ```c
 * #define nk_foreach(c, ctx)
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 * \param[in] cmd     | Command pointer initialized to NULL
 */
//#define nk_foreach(c, ctx) for((c) = nk__begin(ctx); (c) != 0; (c) = nk__next(ctx,c))

#if NK_INCLUDE_VERTEX_BUFFER_OUTPUT

/**
 * \brief Converts all internal draw commands into vertex draw commands and fills
 * three buffers with vertexes, vertex draw commands and vertex indices.
 *
 * \details
 * The vertex format as well as some other configuration values have to be
 * configured by filling out a `nk_convert_config` struct.
 *
 * ```c
 * nk_flags nk_convert(nk_context *ctx, struct nk_buffer *cmds,
 *     struct nk_buffer *vertices, struct nk_buffer *elements,  nk_convert_config*);
 * ```
 *
 * \param[in] ctx      Must point to an previously initialized `nk_context` struct at the end of a frame
 * \param[out] cmds     Must point to a previously initialized buffer to hold converted vertex draw commands
 * \param[out] vertices Must point to a previously initialized buffer to hold all produced vertices
 * \param[out] elements Must point to a previously initialized buffer to hold all produced vertex indices
 * \param[in] config   Must point to a filled out `nk_config` struct to configure the conversion process
 *
 * \returns one of enum nk_convert_result error codes
 *
 * Parameter                       | Description
 * --------------------------------|-----------------------------------------------------------
 * NK_CONVERT_SUCCESS              | Signals a successful draw command to vertex buffer conversion
 * NK_CONVERT_INVALID_PARAM        | An invalid argument was passed in the function call
 * NK_CONVERT_COMMAND_BUFFER_FULL  | The provided buffer for storing draw commands is full or failed to allocate more memory
 * NK_CONVERT_VERTEX_BUFFER_FULL   | The provided buffer for storing vertices is full or failed to allocate more memory
 * NK_CONVERT_ELEMENT_BUFFER_FULL  | The provided buffer for storing indices is full or failed to allocate more memory
 */
	[CLink] public static extern nk_flags nk_convert(nk_context*,  nk_buffer* cmds,  nk_buffer* vertices,  nk_buffer* elements,  nk_convert_config*);

/**
 * \brief Returns a draw vertex command buffer iterator to iterate over the vertex draw command buffer
 *
 * \details
 * ```c
 *  nk_draw_command* nk__draw_begin( nk_context*,  nk_buffer*);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 * \param[in] buf     | Must point to an previously by `nk_convert` filled out vertex draw command buffer
 *
 * \returns vertex draw command pointer pointing to the first command inside the vertex draw command buffer
 */
	[CLink] public static extern  nk_draw_command* nk__draw_begin(nk_context*,  nk_buffer*);

/**

 * # # nk__draw_end
 * \returns the vertex draw command at the end of the vertex draw command buffer
 *
 * ```c
 *  nk_draw_command* nk__draw_end( nk_context *ctx,  nk_buffer *buf);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 * \param[in] buf     | Must point to an previously by `nk_convert` filled out vertex draw command buffer
 *
 * \returns vertex draw command pointer pointing to the end of the last vertex draw command inside the vertex draw command buffer

 */
	[CLink] public static extern  nk_draw_command* nk__draw_end(nk_context*,  nk_buffer*);

/**
 * # # nk__draw_next
 * Increments the vertex draw command buffer iterator
 *
 * ```c
 *  nk_draw_command* nk__draw_next( nk_draw_command*,  nk_buffer*,  nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] cmd     | Must point to an previously either by `nk__draw_begin` or `nk__draw_next` returned vertex draw command
 * \param[in] buf     | Must point to an previously by `nk_convert` filled out vertex draw command buffer
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 *
 * \returns vertex draw command pointer pointing to the end of the last vertex draw command inside the vertex draw command buffer

 */
	[CLink] public static extern  nk_draw_command* nk__draw_next(nk_draw_command*,  nk_buffer*,  nk_context*);

/**
 * # # nk_draw_foreach
 * Iterates over each vertex draw command inside a vertex draw command buffer
 *
 * ```c
 * #define nk_draw_foreach(cmd,ctx, b)
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] cmd     | `nk_draw_command`iterator set to NULL
 * \param[in] buf     | Must point to an previously by `nk_convert` filled out vertex draw command buffer
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct at the end of a frame
 */

//#define nk_draw_foreach(cmd,ctx, b) for((cmd)=nk__draw_begin(ctx, b); (cmd)!=0; (cmd)=nk__draw_next(cmd, b, ctx))
	/*public static void nk_draw_foreach(nk_draw_command* cmd, nk_context* ctx, )
	{

	}*/
#endif
}
/* =============================================================================
 *
 *                                  WINDOW
 *
 * =============================================================================*/
/**
 * \page Window
 * Windows are the main persistent state used inside nuklear and are life time
 * controlled by simply "retouching" (i.e.\ calling) each window each frame.
 * All widgets inside nuklear can only be added inside the function pair `nk_begin_xxx`
 * and `nk_end`. Calling any widgets outside these two functions will result in an
 * assert in debug or no state change in release mode.<br /><br />
 *
 * Each window holds frame persistent state like position, size, flags, state tables,
 * and some garbage collected internal persistent widget state. Each window
 * is linked into a window stack list which determines the drawing and overlapping
 * order. The topmost window thereby is the currently active window.<br /><br />
 *
 * To change window position inside the stack occurs either automatically by
 * user input by being clicked on or programmatically by calling `nk_window_focus`.
 * Windows by default are visible unless explicitly being defined with flag
 * `NK_WINDOW_HIDDEN`, the user clicked the close button on windows with flag
 * `NK_WINDOW_CLOSABLE` or if a window was explicitly hidden by calling
 * `nk_window_show`. To explicitly close and destroy a window call `nk_window_close`.<br /><br />
 *
 * # Usage
 * To create and keep a window you have to call one of the two `nk_begin_xxx`
 * functions to start window declarations and `nk_end` at the end. Furthermore it
 * is recommended to check the return value of `nk_begin_xxx` and only process
 * widgets inside the window if the value is not 0. Either way you have to call
 * `nk_end` at the end of window declarations. Furthermore, do not attempt to
 * nest `nk_begin_xxx` calls which will hopefully result in an assert or if not
 * in a segmentation fault.
 *
 * ```c
 * if (nk_begin_xxx(...) {
 *     // [... widgets ...]
 * }
 * nk_end(ctx);
 * ```
 *
 * In the grand concept window and widget declarations need to occur after input
 * handling and before drawing to screen. Not doing so can result in higher
 * latency or at worst invalid behavior. Furthermore make sure that `nk_clear`
 * is called at the end of the frame. While nuklear's default platform backends
 * already call `nk_clear` for you if you write your own backend not calling
 * `nk_clear` can cause asserts or even worse undefined behavior.
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     Event evt;
 *     nk_input_begin(&ctx);
 *     while (GetEvent(&evt)) {
 *         if (evt.type == MOUSE_MOVE)
 *             nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
 *         else if (evt.type == [...]) {
 *             nk_input_xxx(...);
 *         }
 *     }
 *     nk_input_end(&ctx);
 *
 *     if (nk_begin_xxx(...) {
 *         //[...]
 *     }
 *     nk_end(ctx);
 *
 *      nk_command *cmd = 0;
 *     nk_foreach(cmd, &ctx) {
 *     case NK_COMMAND_LINE:
 *         your_draw_line_function(...)
 *         break;
 *     case NK_COMMAND_RECT
 *         your_draw_rect_function(...)
 *         break;
 *     case //...:
 *         //[...]
 *     }
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 *
 * # Reference
 * Function                                 | Description
 * -----------------------------------------|----------------------------------------
 * \ref nk_begin                            | Starts a new window; needs to be called every frame for every window (unless hidden) or otherwise the window gets removed
 * \ref nk_begin_titled                     | Extended window start with separated title and identifier to allow multiple windows with same name but not title
 * \ref nk_end                              | Needs to be called at the end of the window building process to process scaling, scrollbars and general cleanup
 *
 * Function                                 | Description
 * -----------------------------------------|----------------------------------------
 * \ref nk_window_find                      | Finds and returns the window with give name
 * \ref nk_window_get_bounds                | Returns a rectangle with screen position and size of the currently processed window.
 * \ref nk_window_get_position              | Returns the position of the currently processed window
 * \ref nk_window_get_size                  | Returns the size with width and height of the currently processed window
 * \ref nk_window_get_width                 | Returns the width of the currently processed window
 * \ref nk_window_get_height                | Returns the height of the currently processed window
 * \ref nk_window_get_panel                 | Returns the underlying panel which contains all processing state of the current window
 * \ref nk_window_get_content_region        | Returns the position and size of the currently visible and non-clipped space inside the currently processed window
 * \ref nk_window_get_content_region_min    | Returns the upper rectangle position of the currently visible and non-clipped space inside the currently processed window
 * \ref nk_window_get_content_region_max    | Returns the upper rectangle position of the currently visible and non-clipped space inside the currently processed window
 * \ref nk_window_get_content_region_size   | Returns the size of the currently visible and non-clipped space inside the currently processed window
 * \ref nk_window_get_canvas                | Returns the draw command buffer. Can be used to draw custom widgets
 * \ref nk_window_get_scroll                | Gets the scroll offset of the current window
 * \ref nk_window_has_focus                 | Returns if the currently processed window is currently active
 * \ref nk_window_is_collapsed              | Returns if the window with given name is currently minimized/collapsed
 * \ref nk_window_is_closed                 | Returns if the currently processed window was closed
 * \ref nk_window_is_hidden                 | Returns if the currently processed window was hidden
 * \ref nk_window_is_active                 | Same as nk_window_has_focus for some reason
 * \ref nk_window_is_hovered                | Returns if the currently processed window is currently being hovered by mouse
 * \ref nk_window_is_any_hovered            | Return if any window currently hovered
 * \ref nk_item_is_any_active               | Returns if any window or widgets is currently hovered or active
 *
 * Function                                 | Description
 * -----------------------------------------|----------------------------------------
 * \ref nk_window_set_bounds                | Updates position and size of the currently processed window
 * \ref nk_window_set_position              | Updates position of the currently process window
 * \ref nk_window_set_size                  | Updates the size of the currently processed window
 * \ref nk_window_set_focus                 | Set the currently processed window as active window
 * \ref nk_window_set_scroll                | Sets the scroll offset of the current window
 *
 * Function                                 | Description
 * -----------------------------------------|----------------------------------------
 * \ref nk_window_close                     | Closes the window with given window name which deletes the window at the end of the frame
 * \ref nk_window_collapse                  | Collapses the window with given window name
 * \ref nk_window_collapse_if               | Collapses the window with given window name if the given condition was met
 * \ref nk_window_show                      | Hides a visible or reshows a hidden window
 * \ref nk_window_show_if                   | Hides/shows a window depending on condition

 * # nk_panel_flags
 * Flag                        | Description
 * ----------------------------|----------------------------------------
 * NK_WINDOW_BORDER            | Draws a border around the window to visually separate window from the background
 * NK_WINDOW_MOVABLE           | The movable flag indicates that a window can be moved by user input or by dragging the window header
 * NK_WINDOW_SCALABLE          | The scalable flag indicates that a window can be scaled by user input by dragging a scaler icon at the button of the window
 * NK_WINDOW_CLOSABLE          | Adds a closable icon into the header
 * NK_WINDOW_MINIMIZABLE       | Adds a minimize icon into the header
 * NK_WINDOW_NO_SCROLLBAR      | Removes the scrollbar from the window
 * NK_WINDOW_TITLE             | Forces a header at the top at the window showing the title
 * NK_WINDOW_SCROLL_AUTO_HIDE  | Automatically hides the window scrollbar if no user interaction: also requires delta time in `nk_context` to be set each frame
 * NK_WINDOW_BACKGROUND        | Always keep window in the background
 * NK_WINDOW_SCALE_LEFT        | Puts window scaler in the left-bottom corner instead right-bottom
 * NK_WINDOW_NO_INPUT          | Prevents window of scaling, moving or getting focus
 *
 * # nk_collapse_states
 * State           | Description
 * ----------------|-----------------------------------------------------------
 * NK_MINIMIZED| UI section is collapsed and not visible until maximized
 * NK_MAXIMIZED| UI section is extended and visible until minimized
 */

enum nk_panel_flags : int32
{
	NK_WINDOW_BORDER            = NK_FLAG!(0),
	NK_WINDOW_MOVABLE           = NK_FLAG!(1),
	NK_WINDOW_SCALABLE          = NK_FLAG!(2),
	NK_WINDOW_CLOSABLE          = NK_FLAG!(3),
	NK_WINDOW_MINIMIZABLE       = NK_FLAG!(4),
	NK_WINDOW_NO_SCROLLBAR      = NK_FLAG!(5),
	NK_WINDOW_TITLE             = NK_FLAG!(6),
	NK_WINDOW_SCROLL_AUTO_HIDE  = NK_FLAG!(7),
	NK_WINDOW_BACKGROUND        = NK_FLAG!(8),
	NK_WINDOW_SCALE_LEFT        = NK_FLAG!(9),
	NK_WINDOW_NO_INPUT          = NK_FLAG!(10)
}

static
{
/**
 * # # nk_begin
 * Starts a new window; needs to be called every frame for every
 * window (unless hidden) or otherwise the window gets removed
 *
 * ```c
 * nk_bool nk_begin(nk_context *ctx, char8*title, struct nk_rect bounds, nk_flags flags);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] title   | Window title and identifier. Needs to be persistent over frames to identify the window
 * \param[in] bounds  | Initial position and window size. However if you do not define `NK_WINDOW_SCALABLE` or `NK_WINDOW_MOVABLE` you can set window position and size every frame
 * \param[in] flags   | Window flags defined in the nk_panel_flags section with a number of different window behaviors
 *
 * \returns `true(1)` if the window can be filled up with widgets from this point
 * until `nk_end` or `false(0)` otherwise for example if minimized

 */
	[CLink] public static extern nk_bool nk_begin(nk_context* ctx, char8* title, nk_rect bounds, nk_flags flags);

/**
 * # # nk_begin_titled
 * Extended window start with separated title and identifier to allow multiple
 * windows with same title but not name
 *
 * ```c
 * nk_bool nk_begin_titled(nk_context *ctx, char8*name, char8*title, struct nk_rect bounds, nk_flags flags);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Window identifier. Needs to be persistent over frames to identify the window
 * \param[in] title   | Window title displayed inside header if flag `NK_WINDOW_TITLE` or either `NK_WINDOW_CLOSABLE` or `NK_WINDOW_MINIMIZED` was set
 * \param[in] bounds  | Initial position and window size. However if you do not define `NK_WINDOW_SCALABLE` or `NK_WINDOW_MOVABLE` you can set window position and size every frame
 * \param[in] flags   | Window flags defined in the nk_panel_flags section with a number of different window behaviors
 *
 * \returns `true(1)` if the window can be filled up with widgets from this point
 * until `nk_end` or `false(0)` otherwise for example if minimized

 */
	[CLink] public static extern nk_bool nk_begin_titled(nk_context* ctx, char8* name, char8* title, nk_rect bounds, nk_flags flags);

/**
 * # # nk_end
 * Needs to be called at the end of the window building process to process scaling, scrollbars and general cleanup.
 * All widget calls after this functions will result in asserts or no state changes
 *
 * ```c
 * void nk_end(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct

 */
	[CLink] public static extern void nk_end(nk_context* ctx);

/**
 * # # nk_window_find
 * Finds and returns a window from passed name
 *
 * ```c
 * struct nk_window *nk_window_find(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Window identifier
 *
 * \returns a `nk_window` struct pointing to the identified window or NULL if
 * no window with the given name was found
 */
	[CLink] public static extern nk_window* nk_window_find(nk_context* ctx, char8* name);

/**
 * # # nk_window_get_bounds
 * \returns a rectangle with screen position and size of the currently processed window
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * struct nk_rect nk_window_get_bounds( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns a `nk_rect` struct with window upper left window position and size

 */
	[CLink] public static extern nk_rect nk_window_get_bounds(nk_context* ctx);

/**
 * # # nk_window_get_position
 * \returns the position of the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * struct nk_vec2 nk_window_get_position( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns a `nk_vec2` struct with window upper left position

 */
	[CLink] public static extern nk_vec2 nk_window_get_position(nk_context* ctx);

/**
 * # # nk_window_get_size
 * \returns the size with width and height of the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * struct nk_vec2 nk_window_get_size( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns a `nk_vec2` struct with window width and height

 */
	[CLink] public static extern nk_vec2 nk_window_get_size(nk_context* ctx);

/**
 * nk_window_get_width
 * \returns the width of the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * float nk_window_get_width( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns the current window width
 */
	[CLink] public static extern float nk_window_get_width(nk_context* ctx);

/**
 * # # nk_window_get_height
 * \returns the height of the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * float nk_window_get_height( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns the current window height

 */
	[CLink] public static extern float nk_window_get_height(nk_context* ctx);

/**
 * # # nk_window_get_panel
 * \returns the underlying panel which contains all processing state of the current window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * !!! \warning
 *     Do not keep the returned panel pointer around, it is only valid until `nk_end`
 * ```c
 * struct nk_panel* nk_window_get_panel(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns a pointer to window internal `nk_panel` state.

 */
	[CLink] public static extern nk_panel* nk_window_get_panel(nk_context* ctx);

/**
 * # # nk_window_get_content_region
 * \returns the position and size of the currently visible and non-clipped space
 * inside the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * struct nk_rect nk_window_get_content_region(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `nk_rect` struct with screen position and size (no scrollbar offset)
 * of the visible space inside the current window

 */
	[CLink] public static extern nk_rect nk_window_get_content_region(nk_context* ctx);

/**
 * # # nk_window_get_content_region_min
 * \returns the upper left position of the currently visible and non-clipped
 * space inside the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * struct nk_vec2 nk_window_get_content_region_min(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * returns `nk_vec2` struct with  upper left screen position (no scrollbar offset)
 * of the visible space inside the current window

 */
	[CLink] public static extern nk_vec2 nk_window_get_content_region_min(nk_context* ctx);

/**
 * # # nk_window_get_content_region_max
 * \returns the lower right screen position of the currently visible and
 * non-clipped space inside the currently processed window.
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * struct nk_vec2 nk_window_get_content_region_max(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `nk_vec2` struct with lower right screen position (no scrollbar offset)
 * of the visible space inside the current window

 */
	[CLink] public static extern nk_vec2 nk_window_get_content_region_max(nk_context* ctx);

/**
 * # # nk_window_get_content_region_size
 * \returns the size of the currently visible and non-clipped space inside the
 * currently processed window
 *
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * struct nk_vec2 nk_window_get_content_region_size(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `nk_vec2` struct with size the visible space inside the current window

 */
	[CLink] public static extern nk_vec2 nk_window_get_content_region_size(nk_context* ctx);

/**
 * # # nk_window_get_canvas
 * \returns the draw command buffer. Can be used to draw custom widgets
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * !!! \warning
 *     Do not keep the returned command buffer pointer around it is only valid until `nk_end`
 *
 * ```c
 * nk_command_buffer* nk_window_get_canvas(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns a pointer to window internal `nk_command_buffer` struct used as
 * drawing canvas. Can be used to do custom drawing.
 */
	[CLink] public static extern nk_command_buffer* nk_window_get_canvas(nk_context* ctx);

/**
 * # # nk_window_get_scroll
 * Gets the scroll offset for the current window
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * void nk_window_get_scroll(nk_context *ctx, nk_uint *offset_x, nk_uint *offset_y);
 * ```
 *
 * Parameter    | Description
 * -------------|-----------------------------------------------------------
 * \param[in] ctx      | Must point to an previously initialized `nk_context` struct
 * \param[in] offset_x | A pointer to the x offset output (or NULL to ignore)
 * \param[in] offset_y | A pointer to the y offset output (or NULL to ignore)

 */
	[CLink] public static extern void nk_window_get_scroll(nk_context* ctx, nk_uint* offset_x, nk_uint* offset_y);

/**
 * # # nk_window_has_focus
 * \returns if the currently processed window is currently active
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * nk_bool nk_window_has_focus( nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `false(0)` if current window is not active or `true(1)` if it is

 */
	[CLink] public static extern nk_bool nk_window_has_focus(nk_context* ctx);

/**
 * # # nk_window_is_hovered
 * Return if the current window is being hovered
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 * ```c
 * nk_bool nk_window_is_hovered(nk_context *ctx);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `true(1)` if current window is hovered or `false(0)` otherwise

 */
	[CLink] public static extern nk_bool nk_window_is_hovered(nk_context* ctx);

/**
 * # # nk_window_is_collapsed
 * \returns if the window with given name is currently minimized/collapsed
 * ```c
 * nk_bool nk_window_is_collapsed(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of window you want to check if it is collapsed
 *
 * \returns `true(1)` if current window is minimized and `false(0)` if window not
 * found or is not minimized

 */
	[CLink] public static extern nk_bool nk_window_is_collapsed(nk_context* ctx, char8* name);

/**
 * # # nk_window_is_closed
 * \returns if the window with given name was closed by calling `nk_close`
 * ```c
 * nk_bool nk_window_is_closed(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of window you want to check if it is closed
 *
 * \returns `true(1)` if current window was closed or `false(0)` window not found or not closed

 */
	[CLink] public static extern nk_bool nk_window_is_closed(nk_context* ctx, char8* name);

/**
 * # # nk_window_is_hidden
 * \returns if the window with given name is hidden
 * ```c
 * nk_bool nk_window_is_hidden(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of window you want to check if it is hidden
 *
 * \returns `true(1)` if current window is hidden or `false(0)` window not found or visible

 */
	[CLink] public static extern nk_bool nk_window_is_hidden(nk_context* ctx, char8* name);

/**
 * # # nk_window_is_active
 * Same as nk_window_has_focus for some reason
 * ```c
 * nk_bool nk_window_is_active(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of window you want to check if it is active
 *
 * \returns `true(1)` if current window is active or `false(0)` window not found or not active
 */
	[CLink] public static extern nk_bool nk_window_is_active(nk_context* ctx, char8* name);

/**
 * # # nk_window_is_any_hovered
 * \returns if the any window is being hovered
 * ```c
 * nk_bool nk_window_is_any_hovered(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `true(1)` if any window is hovered or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_window_is_any_hovered(nk_context* ctx);

/**
 * # # nk_item_is_any_active
 * \returns if the any window is being hovered or any widget is currently active.
 * Can be used to decide if input should be processed by UI or your specific input handling.
 * Example could be UI and 3D camera to move inside a 3D space.
 * ```c
 * nk_bool nk_item_is_any_active(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 *
 * \returns `true(1)` if any window is hovered or any item is active or `false(0)` otherwise

 */
	[CLink] public static extern nk_bool nk_item_is_any_active(nk_context* ctx);

/**
 * # # nk_window_set_bounds
 * Updates position and size of window with passed in name
 * ```c
 * void nk_window_set_bounds(nk_context*, char8*name, struct nk_rect bounds);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to modify both position and size
 * \param[in] bounds  | Must point to a `nk_rect` struct with the new position and size

 */
	[CLink] public static extern void nk_window_set_bounds(nk_context* ctx, char8* name, nk_rect bounds);

/**
 * # # nk_window_set_position
 * Updates position of window with passed name
 * ```c
 * void nk_window_set_position(nk_context*, char8*name, struct nk_vec2 pos);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to modify both position
 * \param[in] pos     | Must point to a `nk_vec2` struct with the new position

 */
	[CLink] public static extern void nk_window_set_position(nk_context* ctx, char8* name, nk_vec2 pos);

/**
 * # # nk_window_set_size
 * Updates size of window with passed in name
 * ```c
 * void nk_window_set_size(nk_context*, char8*name, struct nk_vec2);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to modify both window size
 * \param[in] size    | Must point to a `nk_vec2` struct with new window size

 */
	[CLink] public static extern void nk_window_set_size(nk_context* ctx, char8* name, nk_vec2 size);

/**
 * # # nk_window_set_focus
 * Sets the window with given name as active
 * ```c
 * void nk_window_set_focus(nk_context*, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to set focus on

 */
	[CLink] public static extern void nk_window_set_focus(nk_context* ctx, char8* name);

/**
 * # # nk_window_set_scroll
 * Sets the scroll offset for the current window
 * !!! \warning
 *     Only call this function between calls `nk_begin_xxx` and `nk_end`
 *
 * ```c
 * void nk_window_set_scroll(nk_context *ctx, nk_uint offset_x, nk_uint offset_y);
 * ```
 *
 * Parameter    | Description
 * -------------|-----------------------------------------------------------
 * \param[in] ctx      | Must point to an previously initialized `nk_context` struct
 * \param[in] offset_x | The x offset to scroll to
 * \param[in] offset_y | The y offset to scroll to

 */
	[CLink] public static extern void nk_window_set_scroll(nk_context* ctx, nk_uint offset_x, nk_uint offset_y);

/**
 * # # nk_window_close
 * Closes a window and marks it for being freed at the end of the frame
 * ```c
 * void nk_window_close(nk_context *ctx, char8*name);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to close

 */
	[CLink] public static extern void nk_window_close(nk_context* ctx, char8* name);

/**
 * # # nk_window_collapse
 * Updates collapse state of a window with given name
 * ```c
 * void nk_window_collapse(nk_context*, char8*name, enum nk_collapse_states state);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to close
 * \param[in] state   | value out of nk_collapse_states section

 */
	[CLink] public static extern void nk_window_collapse(nk_context* ctx, char8* name, nk_collapse_states state);

/**
 * # # nk_window_collapse_if
 * Updates collapse state of a window with given name if given condition is met
 * ```c
 * void nk_window_collapse_if(nk_context*, char8*name, enum nk_collapse_states, int32 cond);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to either collapse or maximize
 * \param[in] state   | value out of nk_collapse_states section the window should be put into
 * \param[in] cond    | condition that has to be met to actually commit the collapse state change

 */
	[CLink] public static extern void nk_window_collapse_if(nk_context* ctx, char8* name, nk_collapse_states state, int32 cond);

/**
 * # # nk_window_show
 * updates visibility state of a window with given name
 * ```c
 * void nk_window_show(nk_context*, char8*name, enum nk_show_states);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to either collapse or maximize
 * \param[in] state   | state with either visible or hidden to modify the window with
 */
	[CLink] public static extern void nk_window_show(nk_context* ctx, char8* name, nk_show_states state);

/**
 * # # nk_window_show_if
 * Updates visibility state of a window with given name if a given condition is met
 * ```c
 * void nk_window_show_if(nk_context*, char8*name, enum nk_show_states, int32 cond);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] name    | Identifier of the window to either hide or show
 * \param[in] state   | state with either visible or hidden to modify the window with
 * \param[in] cond    | condition that has to be met to actually commit the visibility state change

 */
	[CLink] public static extern void nk_window_show_if(nk_context* ctx, char8* name, nk_show_states state, int32 cond);

/**
 * # # nk_window_show_if
 * Line for visual separation. Draws a line with thickness determined by the current row height.
 * ```c
 * void nk_rule_horizontal(nk_context *ctx, struct nk_color color, NK_BOOL rounding)
 * ```
 *
 * Parameter       | Description
 * ----------------|-------------------------------------------------------
 * \param[in] ctx         | Must point to an previously initialized `nk_context` struct
 * \param[in] color       | Color of the horizontal line
 * \param[in] rounding    | Whether or not to make the line round
 */
	[CLink] public static extern void nk_rule_horizontal(nk_context* ctx, nk_color color, nk_bool rounding);
}

/* =============================================================================
 *
 *                                  LAYOUT
 *
 * =============================================================================*/
/**
 * \page Layouting
 * Layouting in general describes placing widget inside a window with position and size.
 * While in this particular implementation there are five different APIs for layouting
 * each with different trade offs between control and ease of use. <br /><br />
 *
 * All layouting methods in this library are based around the concept of a row.
 * A row has a height the window content grows by and a number of columns and each
 * layouting method specifies how each widget is placed inside the row.
 * After a row has been allocated by calling a layouting functions and then
 * filled with widgets will advance an internal pointer over the allocated row. <br /><br />
 *
 * To actually define a layout you just call the appropriate layouting function
 * and each subsequent widget call will place the widget as specified. Important
 * here is that if you define more widgets then columns defined inside the layout
 * functions it will allocate the next row without you having to make another layouting <br /><br />
 * call.
 *
 * Biggest limitation with using all these APIs outside the `nk_layout_space_xxx` API
 * is that you have to define the row height for each. However the row height
 * often depends on the height of the font. <br /><br />
 *
 * To fix that internally nuklear uses a minimum row height that is set to the
 * height plus padding of currently active font and overwrites the row height
 * value if zero. <br /><br />
 *
 * If you manually want to change the minimum row height then
 * use nk_layout_set_min_row_height, and use nk_layout_reset_min_row_height to
 * reset it back to be derived from font height. <br /><br />
 *
 * Also if you change the font in nuklear it will automatically change the minimum
 * row height for you and. This means if you change the font but still want
 * a minimum row height smaller than the font you have to repush your value. <br /><br />
 *
 * For actually more advanced UI I would even recommend using the `nk_layout_space_xxx`
 * layouting method in combination with a cassowary constraint solver (there are
 * some versions on github with permissive license model) to take over all control over widget
 * layouting yourself. However for quick and dirty layouting using all the other layouting
 * functions should be fine.
 *
 * # Usage
 * 1.  __nk_layout_row_dynamic__<br /><br />
 *     The easiest layouting function is `nk_layout_row_dynamic`. It provides each
 *     widgets with same horizontal space inside the row and dynamically grows
 *     if the owning window grows in width. So the number of columns dictates
 *     the size of each widget dynamically by formula:
 *
 *     ```c
 *     widget_width = (window_width - padding - spacing) * (1/column_count)
 *     ```
 *
 *     Just like all other layouting APIs if you define more widget than columns this
 *     library will allocate a new row and keep all layouting parameters previously
 *     defined.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // first row with height: 30 composed of two widgets
 *         nk_layout_row_dynamic(&ctx, 30, 2);
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // second row with same parameter as defined above
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // third row uses 0 for height which will use auto layouting
 *         nk_layout_row_dynamic(&ctx, 0, 2);
 *         nk_widget(...);
 *         nk_widget(...);
 *     }
 *     nk_end(...);
 *     ```
 *
 * 2.  __nk_layout_row_static__<br /><br />
 *     Another easy layouting function is `nk_layout_row_static`. It provides each
 *     widget with same horizontal pixel width inside the row and does not grow
 *     if the owning window scales smaller or bigger.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // first row with height: 30 composed of two widgets with width: 80
 *         nk_layout_row_static(&ctx, 30, 80, 2);
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // second row with same parameter as defined above
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // third row uses 0 for height which will use auto layouting
 *         nk_layout_row_static(&ctx, 0, 80, 2);
 *         nk_widget(...);
 *         nk_widget(...);
 *     }
 *     nk_end(...);
 *     ```
 *
 * 3.  __nk_layout_row_xxx__<br /><br />
 *     A little bit more advanced layouting API are functions `nk_layout_row_begin`,
 *     `nk_layout_row_push` and `nk_layout_row_end`. They allow to directly
 *     specify each column pixel or window ratio in a row. It supports either
 *     directly setting per column pixel width or widget window ratio but not
 *     both. Furthermore it is a immediate mode API so each value is directly
 *     pushed before calling a widget. Therefore the layout is not automatically
 *     repeating like the last two layouting functions.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // first row with height: 25 composed of two widgets with width 60 and 40
 *         nk_layout_row_begin(ctx, NK_STATIC, 25, 2);
 *         nk_layout_row_push(ctx, 60);
 *         nk_widget(...);
 *         nk_layout_row_push(ctx, 40);
 *         nk_widget(...);
 *         nk_layout_row_end(ctx);
 *         //
 *         // second row with height: 25 composed of two widgets with window ratio 0.25 and 0.75
 *         nk_layout_row_begin(ctx, NK_DYNAMIC, 25, 2);
 *         nk_layout_row_push(ctx, 0.25f);
 *         nk_widget(...);
 *         nk_layout_row_push(ctx, 0.75f);
 *         nk_widget(...);
 *         nk_layout_row_end(ctx);
 *         //
 *         // third row with auto generated height: composed of two widgets with window ratio 0.25 and 0.75
 *         nk_layout_row_begin(ctx, NK_DYNAMIC, 0, 2);
 *         nk_layout_row_push(ctx, 0.25f);
 *         nk_widget(...);
 *         nk_layout_row_push(ctx, 0.75f);
 *         nk_widget(...);
 *         nk_layout_row_end(ctx);
 *     }
 *     nk_end(...);
 *     ```
 *
 * 4.  __nk_layout_row__<br /><br />
 *     The array counterpart to API nk_layout_row_xxx is the single nk_layout_row
 *     functions. Instead of pushing either pixel or window ratio for every widget
 *     it allows to define it by array. The trade of for less control is that
 *     `nk_layout_row` is automatically repeating. Otherwise the behavior is the
 *     same.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // two rows with height: 30 composed of two widgets with width 60 and 40
 *         const float ratio[] = {60,40};
 *         nk_layout_row(ctx, NK_STATIC, 30, 2, ratio);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // two rows with height: 30 composed of two widgets with window ratio 0.25 and 0.75
 *         const float ratio[] = {0.25, 0.75};
 *         nk_layout_row(ctx, NK_DYNAMIC, 30, 2, ratio);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *         //
 *         // two rows with auto generated height composed of two widgets with window ratio 0.25 and 0.75
 *         const float ratio[] = {0.25, 0.75};
 *         nk_layout_row(ctx, NK_DYNAMIC, 30, 2, ratio);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *     }
 *     nk_end(...);
 *     ```
 *
 * 5.  __nk_layout_row_template_xxx__<br /><br />
 *     The most complex and second most flexible API is a simplified flexbox version without
 *     line wrapping and weights for dynamic widgets. It is an immediate mode API but
 *     unlike `nk_layout_row_xxx` it has auto repeat behavior and needs to be called
 *     before calling the templated widgets.
 *     The row template layout has three different per widget size specifier. The first
 *     one is the `nk_layout_row_template_push_static`  with fixed widget pixel width.
 *     They do not grow if the row grows and will always stay the same.
 *     The second size specifier is `nk_layout_row_template_push_variable`
 *     which defines a minimum widget size but it also can grow if more space is available
 *     not taken by other widgets.
 *     Finally there are dynamic widgets with `nk_layout_row_template_push_dynamic`
 *     which are completely flexible and unlike variable widgets can even shrink
 *     to zero if not enough space is provided.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // two rows with height: 30 composed of three widgets
 *         nk_layout_row_template_begin(ctx, 30);
 *         nk_layout_row_template_push_dynamic(ctx);
 *         nk_layout_row_template_push_variable(ctx, 80);
 *         nk_layout_row_template_push_static(ctx, 80);
 *         nk_layout_row_template_end(ctx);
 *         //
 *         // first row
 *         nk_widget(...); // dynamic widget can go to zero if not enough space
 *         nk_widget(...); // variable widget with min 80 pixel but can grow bigger if enough space
 *         nk_widget(...); // static widget with fixed 80 pixel width
 *         //
 *         // second row same layout
 *         nk_widget(...);
 *         nk_widget(...);
 *         nk_widget(...);
 *     }
 *     nk_end(...);
 *     ```
 *
 * 6.  __nk_layout_space_xxx__<br /><br />
 *     Finally the most flexible API directly allows you to place widgets inside the
 *     window. The space layout API is an immediate mode API which does not support
 *     row auto repeat and directly sets position and size of a widget. Position
 *     and size hereby can be either specified as ratio of allocated space or
 *     allocated space local position and pixel size. Since this API is quite
 *     powerful there are a number of utility functions to get the available space
 *     and convert between local allocated space and screen space.
 *
 *     ```c
 *     if (nk_begin_xxx(...) {
 *         // static row with height: 500 (you can set column count to INT_MAX if you don't want to be bothered)
 *         nk_layout_space_begin(ctx, NK_STATIC, 500, INT_MAX);
 *         nk_layout_space_push(ctx, nk_rect(0,0,150,200));
 *         nk_widget(...);
 *         nk_layout_space_push(ctx, nk_rect(200,200,100,200));
 *         nk_widget(...);
 *         nk_layout_space_end(ctx);
 *         //
 *         // dynamic row with height: 500 (you can set column count to INT_MAX if you don't want to be bothered)
 *         nk_layout_space_begin(ctx, NK_DYNAMIC, 500, INT_MAX);
 *         nk_layout_space_push(ctx, nk_rect(0.5,0.5,0.1,0.1));
 *         nk_widget(...);
 *         nk_layout_space_push(ctx, nk_rect(0.7,0.6,0.1,0.1));
 *         nk_widget(...);
 *     }
 *     nk_end(...);
 *     ```
 *
 * # Reference
 * Function                                     | Description
 * ---------------------------------------------|------------------------------------
 * \ref nk_layout_set_min_row_height            | Set the currently used minimum row height to a specified value
 * \ref nk_layout_reset_min_row_height          | Resets the currently used minimum row height to font height
 * \ref nk_layout_widget_bounds                 | Calculates current width a static layout row can fit inside a window
 * \ref nk_layout_ratio_from_pixel              | Utility functions to calculate window ratio from pixel size
 * \ref nk_layout_row_dynamic                   | Current layout is divided into n same sized growing columns
 * \ref nk_layout_row_static                    | Current layout is divided into n same fixed sized columns
 * \ref nk_layout_row_begin                     | Starts a new row with given height and number of columns
 * \ref nk_layout_row_push                      | Pushes another column with given size or window ratio
 * \ref nk_layout_row_end                       | Finished previously started row
 * \ref nk_layout_row                           | Specifies row columns in array as either window ratio or size
 * \ref nk_layout_row_template_begin            | Begins the row template declaration
 * \ref nk_layout_row_template_push_dynamic     | Adds a dynamic column that dynamically grows and can go to zero if not enough space
 * \ref nk_layout_row_template_push_variable    | Adds a variable column that dynamically grows but does not shrink below specified pixel width
 * \ref nk_layout_row_template_push_static      | Adds a static column that does not grow and will always have the same size
 * \ref nk_layout_row_template_end              | Marks the end of the row template
 * \ref nk_layout_space_begin                   | Begins a new layouting space that allows to specify each widgets position and size
 * \ref nk_layout_space_push                    | Pushes position and size of the next widget in own coordinate space either as pixel or ratio
 * \ref nk_layout_space_end                     | Marks the end of the layouting space
 * \ref nk_layout_space_bounds                  | Callable after nk_layout_space_begin and returns total space allocated
 * \ref nk_layout_space_to_screen               | Converts vector from nk_layout_space coordinate space into screen space
 * \ref nk_layout_space_to_local                | Converts vector from screen space into nk_layout_space coordinates
 * \ref nk_layout_space_rect_to_screen          | Converts rectangle from nk_layout_space coordinate space into screen space
 * \ref nk_layout_space_rect_to_local           | Converts rectangle from screen space into nk_layout_space coordinates
 */



enum nk_widget_align : int32
{
	NK_WIDGET_ALIGN_LEFT        = 0x01,
	NK_WIDGET_ALIGN_CENTERED    = 0x02,
	NK_WIDGET_ALIGN_RIGHT       = 0x04,
	NK_WIDGET_ALIGN_TOP         = 0x08,
	NK_WIDGET_ALIGN_MIDDLE      = 0x10,
	NK_WIDGET_ALIGN_BOTTOM      = 0x20
}
enum nk_widget_alignment : int32
{
	NK_WIDGET_LEFT        = nk_widget_align.NK_WIDGET_ALIGN_MIDDLE | nk_widget_align.NK_WIDGET_ALIGN_LEFT,
	NK_WIDGET_CENTERED    = nk_widget_align.NK_WIDGET_ALIGN_MIDDLE | nk_widget_align.NK_WIDGET_ALIGN_CENTERED,
	NK_WIDGET_RIGHT       = nk_widget_align.NK_WIDGET_ALIGN_MIDDLE | nk_widget_align.NK_WIDGET_ALIGN_RIGHT
}

static
{
/**
 * Sets the currently used minimum row height.
 * !!! \warning
 *     The passed height needs to include both your preferred row height
 *     as well as padding. No internal padding is added.
 *
 * ```c
 * void nk_layout_set_min_row_height(nk_context*, float height);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] height  | New minimum row height to be used for auto generating the row height
 */
	[CLink] public static extern void nk_layout_set_min_row_height(nk_context*, float height);

/**
 * Reset the currently used minimum row height back to `font_height + text_padding + padding`
 * ```c
 * void nk_layout_reset_min_row_height(nk_context*);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 */
	[CLink] public static extern void nk_layout_reset_min_row_height(nk_context*);

/**
 * \brief Returns the width of the next row allocate by one of the layouting functions
 *
 * \details
 * ```c
 * struct nk_rect nk_layout_widget_bounds(nk_context*);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 *
 * \return `nk_rect` with both position and size of the next row
 */
	[CLink] public static extern nk_rect nk_layout_widget_bounds(nk_context* ctx);

/**
 * \brief Utility functions to calculate window ratio from pixel size
 *
 * \details
 * ```c
 * float nk_layout_ratio_from_pixel(nk_context*, float pixel_width);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] pixel   | Pixel_width to convert to window ratio
 *
 * \returns `nk_rect` with both position and size of the next row
 */
	[CLink] public static extern float nk_layout_ratio_from_pixel(nk_context* ctx, float pixel_width);

/**
 * \brief Sets current row layout to share horizontal space
 * between @cols number of widgets evenly. Once called all subsequent widget
 * calls greater than @cols will allocate a new row with same layout.
 *
 * \details
 * ```c
 * void nk_layout_row_dynamic(nk_context *ctx, float height, int32 cols);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 * \param[in] columns | Number of widget inside row
 */
	[CLink] public static extern void nk_layout_row_dynamic(nk_context* ctx, float height, int32 cols);

/**
 * \brief Sets current row layout to fill @cols number of widgets
 * in row with same @item_width horizontal size. Once called all subsequent widget
 * calls greater than @cols will allocate a new row with same layout.
 *
 * \details
 * ```c
 * void nk_layout_row_static(nk_context *ctx, float height, int32 item_width, int32 cols);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 * \param[in] width   | Holds pixel width of each widget in the row
 * \param[in] columns | Number of widget inside row
 */
	[CLink] public static extern void nk_layout_row_static(nk_context* ctx, float height, int32 item_width, int32 cols);

/**
 * \brief Starts a new dynamic or fixed row with given height and columns.
 *
 * \details
 * ```c
 * void nk_layout_row_begin(nk_context *ctx, enum nk_layout_format fmt, float row_height, int32 cols);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] fmt     | either `NK_DYNAMIC` for window ratio or `NK_STATIC` for fixed size columns
 * \param[in] height  | holds height of each widget in row or zero for auto layouting
 * \param[in] columns | Number of widget inside row
 */
	[CLink] public static extern void nk_layout_row_begin(nk_context* ctx, nk_layout_format fmt, float row_height, int32 cols);

/**
 * \breif Specifies either window ratio or width of a single column
 *
 * \details
 * ```c
 * void nk_layout_row_push(nk_context*, float value);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] value   | either a window ratio or fixed width depending on @fmt in previous `nk_layout_row_begin` call
 */
	[CLink] public static extern void nk_layout_row_push(nk_context*, float value);

/**
 * \brief Finished previously started row
 *
 * \details
 * ```c
 * void nk_layout_row_end(nk_context*);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 */
	[CLink] public static extern void nk_layout_row_end(nk_context*);

/**
 * \brief Specifies row columns in array as either window ratio or size
 *
 * \details
 * ```c
 * void nk_layout_row(nk_context*, enum nk_layout_format, float height, int32 cols, const float *ratio);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] fmt     | Either `NK_DYNAMIC` for window ratio or `NK_STATIC` for fixed size columns
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 * \param[in] columns | Number of widget inside row
 */
	[CLink] public static extern void nk_layout_row(nk_context*, nk_layout_format, float height, int32 cols, float* ratio);

/**
 * # # nk_layout_row_template_begin
 * Begins the row template declaration
 * ```c
 * void nk_layout_row_template_begin(nk_context*, float row_height);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 */
	[CLink] public static extern void nk_layout_row_template_begin(nk_context*, float row_height);

/**
 * # # nk_layout_row_template_push_dynamic
 * Adds a dynamic column that dynamically grows and can go to zero if not enough space
 * ```c
 * void nk_layout_row_template_push_dynamic(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 */
	[CLink] public static extern void nk_layout_row_template_push_dynamic(nk_context*);

/**
 * # # nk_layout_row_template_push_variable
 * Adds a variable column that dynamically grows but does not shrink below specified pixel width
 * ```c
 * void nk_layout_row_template_push_variable(nk_context*, float min_width);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] width   | Holds the minimum pixel width the next column must always be
 */
	[CLink] public static extern void nk_layout_row_template_push_variable(nk_context*, float min_width);

/**
 * # # nk_layout_row_template_push_static
 * Adds a static column that does not grow and will always have the same size
 * ```c
 * void nk_layout_row_template_push_static(nk_context*, float width);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] width   | Holds the absolute pixel width value the next column must be
 */
	[CLink] public static extern void nk_layout_row_template_push_static(nk_context*, float width);

/**
 * # # nk_layout_row_template_end
 * Marks the end of the row template
 * ```c
 * void nk_layout_row_template_end(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 */
	[CLink] public static extern void nk_layout_row_template_end(nk_context*);

/**
 * # # nk_layout_space_begin
 * Begins a new layouting space that allows to specify each widgets position and size.
 * ```c
 * void nk_layout_space_begin(nk_context*, enum nk_layout_format, float height, int32 widget_count);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_begin_xxx`
 * \param[in] fmt     | Either `NK_DYNAMIC` for window ratio or `NK_STATIC` for fixed size columns
 * \param[in] height  | Holds height of each widget in row or zero for auto layouting
 * \param[in] columns | Number of widgets inside row
 */
	[CLink] public static extern void nk_layout_space_begin(nk_context*, nk_layout_format, float height, int32 widget_count);

/**
 * # # nk_layout_space_push
 * Pushes position and size of the next widget in own coordinate space either as pixel or ratio
 * ```c
 * void nk_layout_space_push(nk_context *ctx, struct nk_rect bounds);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 * \param[in] bounds  | Position and size in laoyut space local coordinates
 */
	[CLink] public static extern void nk_layout_space_push(nk_context*, nk_rect bounds);

/**
 * # # nk_layout_space_end
 * Marks the end of the layout space
 * ```c
 * void nk_layout_space_end(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 */
	[CLink] public static extern void nk_layout_space_end(nk_context*);

/**
 * # # nk_layout_space_bounds
 * Utility function to calculate total space allocated for `nk_layout_space`
 * ```c
 * struct nk_rect nk_layout_space_bounds(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 *
 * \returns `nk_rect` holding the total space allocated
 */
	[CLink] public static extern nk_rect nk_layout_space_bounds(nk_context* ctx);

/**
 * # # nk_layout_space_to_screen
 * Converts vector from nk_layout_space coordinate space into screen space
 * ```c
 * struct nk_vec2 nk_layout_space_to_screen(nk_context*, struct nk_vec2);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 * \param[in] vec     | Position to convert from layout space into screen coordinate space
 *
 * \returns transformed `nk_vec2` in screen space coordinates
 */
	[CLink] public static extern nk_vec2 nk_layout_space_to_screen(nk_context* ctx, nk_vec2 vec);

/**
 * # # nk_layout_space_to_local
 * Converts vector from layout space into screen space
 * ```c
 * struct nk_vec2 nk_layout_space_to_local(nk_context*, struct nk_vec2);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 * \param[in] vec     | Position to convert from screen space into layout coordinate space
 *
 * \returns transformed `nk_vec2` in layout space coordinates
 */
	[CLink] public static extern nk_vec2 nk_layout_space_to_local(nk_context* ctx, nk_vec2 vec);

/**
 * # # nk_layout_space_rect_to_screen
 * Converts rectangle from screen space into layout space
 * ```c
 * struct nk_rect nk_layout_space_rect_to_screen(nk_context*, struct nk_rect);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 * \param[in] bounds  | Rectangle to convert from layout space into screen space
 *
 * \returns transformed `nk_rect` in screen space coordinates
 */
	[CLink] public static extern nk_rect nk_layout_space_rect_to_screen(nk_context* ctx, nk_rect bounds);

/**
 * # # nk_layout_space_rect_to_local
 * Converts rectangle from layout space into screen space
 * ```c
 * struct nk_rect nk_layout_space_rect_to_local(nk_context*, struct nk_rect);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 * \param[in] bounds  | Rectangle to convert from layout space into screen space
 *
 * \returns transformed `nk_rect` in layout space coordinates
 */
	[CLink] public static extern nk_rect nk_layout_space_rect_to_local(nk_context* ctx, nk_rect bounds);

/**
 * # # nk_spacer
 * Spacer is a dummy widget that consumes space as usual but doesn't draw anything
 * ```c
 * void nk_spacer(nk_context* );
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after call `nk_layout_space_begin`
 *
 */
	[CLink] public static extern void nk_spacer(nk_context* ctx);
}

static
{
/* =============================================================================
 *
 *                                  GROUP
 *
 * =============================================================================*/
/**
 * \page Groups
 * Groups are basically windows inside windows. They allow to subdivide space
 * in a window to layout widgets as a group. Almost all more complex widget
 * layouting requirements can be solved using groups and basic layouting
 * fuctionality. Groups just like windows are identified by an unique name and
 * internally keep track of scrollbar offsets by default. However additional
 * versions are provided to directly manage the scrollbar.
 *
 * # Usage
 * To create a group you have to call one of the three `nk_group_begin_xxx`
 * functions to start group declarations and `nk_group_end` at the end. Furthermore it
 * is required to check the return value of `nk_group_begin_xxx` and only process
 * widgets inside the window if the value is not 0.
 * Nesting groups is possible and even encouraged since many layouting schemes
 * can only be achieved by nesting. Groups, unlike windows, need `nk_group_end`
 * to be only called if the corresponding `nk_group_begin_xxx` call does not return 0:
 *
 * ```c
 * if (nk_group_begin_xxx(ctx, ...) {
 *     // [... widgets ...]
 *     nk_group_end(ctx);
 * }
 * ```
 *
 * In the grand concept groups can be called after starting a window
 * with `nk_begin_xxx` and before calling `nk_end`:
 *
 * ```c
 * struct nk_context ctx;
 * nk_init_xxx(&ctx, ...);
 * while (1) {
 *     // Input
 *     Event evt;
 *     nk_input_begin(&ctx);
 *     while (GetEvent(&evt)) {
 *         if (evt.type == MOUSE_MOVE)
 *             nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
 *         else if (evt.type == [...]) {
 *             nk_input_xxx(...);
 *         }
 *     }
 *     nk_input_end(&ctx);
 *     //
 *     // Window
 *     if (nk_begin_xxx(...) {
 *         // [...widgets...]
 *         nk_layout_row_dynamic(...);
 *         if (nk_group_begin_xxx(ctx, ...) {
 *             //[... widgets ...]
 *             nk_group_end(ctx);
 *         }
 *     }
 *     nk_end(ctx);
 *     //
 *     // Draw
 *      nk_command *cmd = 0;
 *     nk_foreach(cmd, &ctx) {
 *     switch (cmd->type) {
 *     case NK_COMMAND_LINE:
 *         your_draw_line_function(...)
 *         break;
 *     case NK_COMMAND_RECT
 *         your_draw_rect_function(...)
 *         break;
 *     case ...:
 *         // [...]
 *     }
 *     nk_clear(&ctx);
 * }
 * nk_free(&ctx);
 * ```
 * # Reference
 * Function                        | Description
 * --------------------------------|-------------------------------------------
 * \ref nk_group_begin                  | Start a new group with internal scrollbar handling
 * \ref nk_group_begin_titled           | Start a new group with separated name and title and internal scrollbar handling
 * \ref nk_group_end                    | Ends a group. Should only be called if nk_group_begin returned non-zero
 * \ref nk_group_scrolled_offset_begin  | Start a new group with manual separated handling of scrollbar x- and y-offset
 * \ref nk_group_scrolled_begin         | Start a new group with manual scrollbar handling
 * \ref nk_group_scrolled_end           | Ends a group with manual scrollbar handling. Should only be called if nk_group_begin returned non-zero
 * \ref nk_group_get_scroll             | Gets the scroll offset for the given group
 * \ref nk_group_set_scroll             | Sets the scroll offset for the given group
 */

 /**
 * \brief Starts a new widget group. Requires a previous layouting function to specify a pos/size.
 * ```c
 * nk_bool nk_group_begin(nk_context*, char8*title, nk_flags);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] title   | Must be an unique identifier for this group that is also used for the group header
 * \param[in] flags   | Window flags defined in the nk_panel_flags section with a number of different group behaviors
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_group_begin(nk_context*, char8* title, nk_flags);

 /**
 * \brief Starts a new widget group. Requires a previous layouting function to specify a pos/size.
 * ```c
 * nk_bool nk_group_begin_titled(nk_context*, char8*name, char8*title, nk_flags);
 * ```
 *
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] id      | Must be an unique identifier for this group
 * \param[in] title   | Group header title
 * \param[in] flags   | Window flags defined in the nk_panel_flags section with a number of different group behaviors
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_group_begin_titled(nk_context*, char8* name, char8* title, nk_flags);

/**
 * # # nk_group_end
 * Ends a widget group
 * ```c
 * void nk_group_end(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_group_end(nk_context*);

/**
 * # # nk_group_scrolled_offset_begin
 * starts a new widget group. requires a previous layouting function to specify
 * a size. Does not keep track of scrollbar.
 * ```c
 * nk_bool nk_group_scrolled_offset_begin(nk_context*, nk_uint *x_offset, nk_uint *y_offset, char8*title, nk_flags flags);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] x_offset| Scrollbar x-offset to offset all widgets inside the group horizontally.
 * \param[in] y_offset| Scrollbar y-offset to offset all widgets inside the group vertically
 * \param[in] title   | Window unique group title used to both identify and display in the group header
 * \param[in] flags   | Window flags from the nk_panel_flags section
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_group_scrolled_offset_begin(nk_context*, nk_uint* x_offset, nk_uint* y_offset, char8* title, nk_flags flags);

/**
 * # # nk_group_scrolled_begin
 * Starts a new widget group. requires a previous
 * layouting function to specify a size. Does not keep track of scrollbar.
 * ```c
 * nk_bool nk_group_scrolled_begin(nk_context*, struct nk_scroll *off, char8*title, nk_flags);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] off     | Both x- and y- scroll offset. Allows for manual scrollbar control
 * \param[in] title   | Window unique group title used to both identify and display in the group header
 * \param[in] flags   | Window flags from nk_panel_flags section
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_group_scrolled_begin(nk_context*, nk_scroll* off, char8* title, nk_flags);

/**
 * # # nk_group_scrolled_end
 * Ends a widget group after calling nk_group_scrolled_offset_begin or nk_group_scrolled_begin.
 * ```c
 * void nk_group_scrolled_end(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 */
	[CLink] public static extern void nk_group_scrolled_end(nk_context*);

/**
 * # # nk_group_get_scroll
 * Gets the scroll position of the given group.
 * ```c
 * void nk_group_get_scroll(nk_context*, char8*id, nk_uint *x_offset, nk_uint *y_offset);
 * ```
 *
 * Parameter    | Description
 * -------------|-----------------------------------------------------------
 * \param[in] ctx      | Must point to an previously initialized `nk_context` struct
 * \param[in] id       | The id of the group to get the scroll position of
 * \param[in] x_offset | A pointer to the x offset output (or NULL to ignore)
 * \param[in] y_offset | A pointer to the y offset output (or NULL to ignore)
 */
	[CLink] public static extern void nk_group_get_scroll(nk_context*, char8* id, nk_uint* x_offset, nk_uint* y_offset);

/**
 * # # nk_group_set_scroll
 * Sets the scroll position of the given group.
 * ```c
 * void nk_group_set_scroll(nk_context*, char8*id, nk_uint x_offset, nk_uint y_offset);
 * ```
 *
 * Parameter    | Description
 * -------------|-----------------------------------------------------------
 * \param[in] ctx      | Must point to an previously initialized `nk_context` struct
 * \param[in] id       | The id of the group to scroll
 * \param[in] x_offset | The x offset to scroll to
 * \param[in] y_offset | The y offset to scroll to
 */
	[CLink] public static extern void nk_group_set_scroll(nk_context*, char8* id, nk_uint x_offset, nk_uint y_offset);
}
/* =============================================================================
 *
 *                                  TREE
 *
 * =============================================================================*/
/**
 * \page Tree
 * Trees represent two different concept. First the concept of a collapsible
 * UI section that can be either in a hidden or visible state. They allow the UI
 * user to selectively minimize the current set of visible UI to comprehend.
 * The second concept are tree widgets for visual UI representation of trees.<br /><br />
 *
 * Trees thereby can be nested for tree representations and multiple nested
 * collapsible UI sections. All trees are started by calling of the
 * `nk_tree_xxx_push_tree` functions and ended by calling one of the
 * `nk_tree_xxx_pop_xxx()` functions. Each starting functions takes a title label
 * and optionally an image to be displayed and the initial collapse state from
 * the nk_collapse_states section.<br /><br />
 *
 * The runtime state of the tree is either stored outside the library by the caller
 * or inside which requires a unique ID. The unique ID can either be generated
 * automatically from `__FILE__` and `__LINE__` with function `nk_tree_push`,
 * by `__FILE__` and a user provided ID generated for example by loop index with
 * function `nk_tree_push_id` or completely provided from outside by user with
 * function `nk_tree_push_hashed`.
 *
 * # Usage
 * To create a tree you have to call one of the seven `nk_tree_xxx_push_xxx`
 * functions to start a collapsible UI section and `nk_tree_xxx_pop` to mark the
 * end.
 * Each starting function will either return `false(0)` if the tree is collapsed
 * or hidden and therefore does not need to be filled with content or `true(1)`
 * if visible and required to be filled.
 *
 * !!! Note
 *     The tree header does not require and layouting function and instead
 *     calculates a auto height based on the currently used font size
 *
 * The tree ending functions only need to be called if the tree content is
 * actually visible. So make sure the tree push function is guarded by `if`
 * and the pop call is only taken if the tree is visible.
 *
 * ```c
 * if (nk_tree_push(ctx, NK_TREE_TAB, "Tree", NK_MINIMIZED)) {
 *     nk_layout_row_dynamic(...);
 *     nk_widget(...);
 *     nk_tree_pop(ctx);
 * }
 * ```
 *
 * # Reference
 * Function                    | Description
 * ----------------------------|-------------------------------------------
 * nk_tree_push                | Start a collapsible UI section with internal state management
 * nk_tree_push_id             | Start a collapsible UI section with internal state management callable in a look
 * nk_tree_push_hashed         | Start a collapsible UI section with internal state management with full control over internal unique ID use to store state
 * nk_tree_image_push          | Start a collapsible UI section with image and label header
 * nk_tree_image_push_id       | Start a collapsible UI section with image and label header and internal state management callable in a look
 * nk_tree_image_push_hashed   | Start a collapsible UI section with image and label header and internal state management with full control over internal unique ID use to store state
 * nk_tree_pop                 | Ends a collapsible UI section
 * nk_tree_state_push          | Start a collapsible UI section with external state management
 * nk_tree_state_image_push    | Start a collapsible UI section with image and label header and external state management
 * nk_tree_state_pop           | Ends a collapsabale UI section
 *
 * # nk_tree_type
 * Flag            | Description
 * ----------------|----------------------------------------
 * NK_TREE_NODE    | Highlighted tree header to mark a collapsible UI section
 * NK_TREE_TAB     | Non-highlighted tree header closer to tree representations
 */

static
{

/**
 * # # nk_tree_push
 * Starts a collapsible UI section with internal state management
 * !!! \warning
 *     To keep track of the runtime tree collapsible state this function uses
 *     defines `__FILE__` and `__LINE__` to generate a unique ID. If you want
 *     to call this function in a loop please use `nk_tree_push_id` or
 *     `nk_tree_push_hashed` instead.
 *
 * ```c
 * #define nk_tree_push(ctx, type, title, state)
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
//#define nk_tree_push(ctx, type, title, state) nk_tree_push_hashed(ctx, type, title, state, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),__LINE__)

/**
 * # # nk_tree_push_id
 * Starts a collapsible UI section with internal state management callable in a look
 * ```c
 * #define nk_tree_push_id(ctx, type, title, state, id)
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 * \param[in] id      | Loop counter index if this function is called in a loop
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
//#define nk_tree_push_id(ctx, type, title, state, id) nk_tree_push_hashed(ctx, type, title, state, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),id)

/**
 * # # nk_tree_push_hashed
 * Start a collapsible UI section with internal state management with full
 * control over internal unique ID used to store state
 * ```c
 * nk_bool nk_tree_push_hashed(nk_context*, enum nk_tree_type, char8*title, enum nk_collapse_states initial_state, char8*hash, int32 len,int32 seed);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 * \param[in] hash    | Memory block or string to generate the ID from
 * \param[in] len     | Size of passed memory block or string in __hash__
 * \param[in] seed    | Seeding value if this function is called in a loop or default to `0`
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_tree_push_hashed(nk_context*, nk_tree_type, char8* title, nk_collapse_states initial_state, char8* hash, int32 len, int32 seed);

/**
 * # # nk_tree_image_push
 * Start a collapsible UI section with image and label header
 * !!! \warning
 *     To keep track of the runtime tree collapsible state this function uses
 *     defines `__FILE__` and `__LINE__` to generate a unique ID. If you want
 *     to call this function in a loop please use `nk_tree_image_push_id` or
 *     `nk_tree_image_push_hashed` instead.
 *
 * ```c
 * #define nk_tree_image_push(ctx, type, img, title, state)
 * ```
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] img     | Image to display inside the header on the left of the label
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
//#define nk_tree_image_push(ctx, type, img, title, state) nk_tree_image_push_hashed(ctx, type, img, title, state, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),__LINE__)

/**
 * # # nk_tree_image_push_id
 * Start a collapsible UI section with image and label header and internal state
 * management callable in a look
 *
 * ```c
 * #define nk_tree_image_push_id(ctx, type, img, title, state, id)
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] img     | Image to display inside the header on the left of the label
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 * \param[in] id      | Loop counter index if this function is called in a loop
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
//#define nk_tree_image_push_id(ctx, type, img, title, state, id) nk_tree_image_push_hashed(ctx, type, img, title, state, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),id)

/**
 * # # nk_tree_image_push_hashed
 * Start a collapsible UI section with internal state management with full
 * control over internal unique ID used to store state
 * ```c
 * nk_bool nk_tree_image_push_hashed(nk_context*, enum nk_tree_type, struct nk_image, char8*title, enum nk_collapse_states initial_state, char8*hash, int32 len,int32 seed);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] img     | Image to display inside the header on the left of the label
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Initial tree state value out of nk_collapse_states
 * \param[in] hash    | Memory block or string to generate the ID from
 * \param[in] len     | Size of passed memory block or string in __hash__
 * \param[in] seed    | Seeding value if this function is called in a loop or default to `0`
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_tree_image_push_hashed(nk_context*, nk_tree_type, nk_image, char8* title, nk_collapse_states initial_state, char8* hash, int32 len, int32 seed);

/**
 * # # nk_tree_pop
 * Ends a collapsabale UI section
 * ```c
 * void nk_tree_pop(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after calling `nk_tree_xxx_push_xxx`
 */
	[CLink] public static extern void nk_tree_pop(nk_context*);

/**
 * # # nk_tree_state_push
 * Start a collapsible UI section with external state management
 * ```c
 * nk_bool nk_tree_state_push(nk_context*, enum nk_tree_type, char8*title, enum nk_collapse_states *state);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after calling `nk_tree_xxx_push_xxx`
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Persistent state to update
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_tree_state_push(nk_context*, nk_tree_type, char8* title, nk_collapse_states* state);

/**
 * # # nk_tree_state_image_push
 * Start a collapsible UI section with image and label header and external state management
 * ```c
 * nk_bool nk_tree_state_image_push(nk_context*, enum nk_tree_type, struct nk_image, char8*title, enum nk_collapse_states *state);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after calling `nk_tree_xxx_push_xxx`
 * \param[in] img     | Image to display inside the header on the left of the label
 * \param[in] type    | Value from the nk_tree_type section to visually mark a tree node header as either a collapseable UI section or tree node
 * \param[in] title   | Label printed in the tree header
 * \param[in] state   | Persistent state to update
 *
 * \returns `true(1)` if visible and fillable with widgets or `false(0)` otherwise
 */
	[CLink] public static extern nk_bool nk_tree_state_image_push(nk_context*, nk_tree_type, nk_image, char8* title, nk_collapse_states* state);

/**
 * # # nk_tree_state_pop
 * Ends a collapsabale UI section
 * ```c
 * void nk_tree_state_pop(nk_context*);
 * ```
 *
 * Parameter   | Description
 * ------------|-----------------------------------------------------------
 * \param[in] ctx     | Must point to an previously initialized `nk_context` struct after calling `nk_tree_xxx_push_xxx`
 */
	[CLink] public static extern void nk_tree_state_pop(nk_context*);

//#define nk_tree_element_push(ctx, type, title, state, sel) nk_tree_element_push_hashed(ctx, type, title, state, sel, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),__LINE__)
//#define nk_tree_element_push_id(ctx, type, title, state, sel, id) nk_tree_element_push_hashed(ctx, type, title, state, sel, NK_FILE_LINE,nk_strlen(NK_FILE_LINE),id)
	[CLink] public static extern nk_bool nk_tree_element_push_hashed(nk_context*, nk_tree_type, char8* title, nk_collapse_states initial_state, nk_bool* selected, char8* hash, int32 len, int32 seed);
	[CLink] public static extern nk_bool nk_tree_element_image_push_hashed(nk_context*, nk_tree_type, nk_image, char8* title, nk_collapse_states initial_state, nk_bool* selected, char8* hash, int32 len, int32 seed);
	[CLink] public static extern void nk_tree_element_pop(nk_context*);
}
/* =============================================================================
 *
 *                                  LIST VIEW
 *
 * ============================================================================= */
[CRepr] struct nk_list_view
{
/* public: */
	public int32 begin, end, count;
/* private: */
	public int32 total_height;
	public nk_context* ctx;
	public nk_uint* scroll_pointer;
	public nk_uint scroll_value;
}
static
{
	[CLink] public static extern nk_bool nk_list_view_begin(nk_context*, nk_list_view* @out, char8* id, nk_flags, int32 row_height, int32 row_count);
	[CLink] public static extern void nk_list_view_end(nk_list_view*);
}
	/* =============================================================================
	 *
	 *                                  WIDGET
	 *
	 * ============================================================================= */
enum nk_widget_layout_states : int32
{
	NK_WIDGET_INVALID, /**< The widget cannot be seen and is completely out of view */
	NK_WIDGET_VALID, /**< The widget is completely inside the window and can be updated and drawn */
	NK_WIDGET_ROM, /**< The widget is partially visible and cannot be updated */
	NK_WIDGET_DISABLED /**< The widget is manually disabled and acts like NK_WIDGET_ROM */
}
enum nk_widget_states : int32
{
	NK_WIDGET_STATE_MODIFIED    = NK_FLAG!(1),
	NK_WIDGET_STATE_INACTIVE    = NK_FLAG!(2), /**!< widget is neither active nor hovered */
	NK_WIDGET_STATE_ENTERED     = NK_FLAG!(3), /**!< widget has been hovered on the current frame */
	NK_WIDGET_STATE_HOVER       = NK_FLAG!(4), /**!< widget is being hovered */
	NK_WIDGET_STATE_ACTIVED     = NK_FLAG!(5), /**!< widget is currently activated */
	NK_WIDGET_STATE_LEFT        = NK_FLAG!(6), /**!< widget is from this frame on not hovered anymore */
	NK_WIDGET_STATE_HOVERED     = NK_WIDGET_STATE_HOVER | NK_WIDGET_STATE_MODIFIED, /**!< widget is being hovered */
	NK_WIDGET_STATE_ACTIVE      = NK_WIDGET_STATE_ACTIVED | NK_WIDGET_STATE_MODIFIED /**!< widget is currently activated */
}
static
{
	[CLink] public static extern nk_widget_layout_states nk_widget(nk_rect*,  nk_context*);
	[CLink] public static extern nk_widget_layout_states nk_widget_fitting(nk_rect*,  nk_context*, nk_vec2);
	[CLink] public static extern nk_rect nk_widget_bounds(nk_context*);
	[CLink] public static extern nk_vec2 nk_widget_position(nk_context*);
	[CLink] public static extern nk_vec2 nk_widget_size(nk_context*);
	[CLink] public static extern float nk_widget_width(nk_context*);
	[CLink] public static extern float nk_widget_height(nk_context*);
	[CLink] public static extern nk_bool nk_widget_is_hovered(nk_context*);
	[CLink] public static extern nk_bool nk_widget_is_mouse_clicked(nk_context*, enum nk_buttons);
	[CLink] public static extern nk_bool nk_widget_has_mouse_click_down(nk_context*, enum nk_buttons, nk_bool down);
	[CLink] public static extern void nk_spacing(nk_context*, int32 cols);
	[CLink] public static extern void nk_widget_disable_begin(nk_context* ctx);
	[CLink] public static extern void nk_widget_disable_end(nk_context* ctx);
}
	/* =============================================================================
	 *
	 *                                  TEXT
	 *
	 * ============================================================================= */
enum nk_text_align : int32
{
	NK_TEXT_ALIGN_LEFT        = 0x01,
	NK_TEXT_ALIGN_CENTERED    = 0x02,
	NK_TEXT_ALIGN_RIGHT       = 0x04,
	NK_TEXT_ALIGN_TOP         = 0x08,
	NK_TEXT_ALIGN_MIDDLE      = 0x10,
	NK_TEXT_ALIGN_BOTTOM      = 0x20
}
enum nk_text_alignment : int32
{
	NK_TEXT_LEFT        = nk_text_align.NK_TEXT_ALIGN_MIDDLE | nk_text_align.NK_TEXT_ALIGN_LEFT,
	NK_TEXT_CENTERED    = nk_text_align.NK_TEXT_ALIGN_MIDDLE | nk_text_align.NK_TEXT_ALIGN_CENTERED,
	NK_TEXT_RIGHT       = nk_text_align.NK_TEXT_ALIGN_MIDDLE | nk_text_align.NK_TEXT_ALIGN_RIGHT
}
static
{
	[CLink] public static extern void nk_text(nk_context*, char8*, int32, nk_flags);
	[CLink] public static extern void nk_text_colored(nk_context*, char8*, int32, nk_flags, nk_color);
	[CLink] public static extern void nk_text_wrap(nk_context*, char8*, int32);
	[CLink] public static extern void nk_text_wrap_colored(nk_context*, char8*, int32, nk_color);
	[CLink] public static extern void nk_label(nk_context*, char8*, nk_flags align);
	[CLink] public static extern void nk_label_colored(nk_context*, char8*, nk_flags align, nk_color);
	[CLink] public static extern void nk_label_wrap(nk_context*, char8*);
	[CLink] public static extern void nk_label_colored_wrap(nk_context*, char8*, nk_color);
	[CLink] public static extern void nk_image(nk_context*, nk_image);
	[CLink] public static extern void nk_image_color(nk_context*, nk_image, nk_color);
#if NK_INCLUDE_STANDARD_VARARGS
	[CLink] public static extern void nk_labelf(nk_context*, nk_flags, char8*, ...) /*NK_PRINTF_VARARG_FUNC(3)*/;
	[CLink] public static extern void nk_labelf_colored(nk_context*, nk_flags, nk_color, char8*, ...) /*NK_PRINTF_VARARG_FUNC(4)*/;
	[CLink] public static extern void nk_labelf_wrap(nk_context*, char8*, ...) /*NK_PRINTF_VARARG_FUNC(2)*/;
	[CLink] public static extern void nk_labelf_colored_wrap(nk_context*, nk_color, char8*, ...) /*NK_PRINTF_VARARG_FUNC(3)*/;
	[CLink] public static extern void nk_labelfv(nk_context*, nk_flags, char8*, void* varArgs) /*NK_PRINTF_VALIST_FUNC(3)*/;
	[CLink] public static extern void nk_labelfv_colored(nk_context*, nk_flags, nk_color, char8*, void* varArgs) /*NK_PRINTF_VALIST_FUNC(4)*/;
	[CLink] public static extern void nk_labelfv_wrap(nk_context*, char8*, void* varArgs) /*NK_PRINTF_VALIST_FUNC(2)*/;
	[CLink] public static extern void nk_labelfv_colored_wrap(nk_context*, nk_color, char8*, void* varArgs) /*NK_PRINTF_VALIST_FUNC(3)*/;
	[CLink] public static extern void nk_value_bool(nk_context*, char8* prefix, int32);
	[CLink] public static extern void nk_value_int(nk_context*, char8* prefix, int32);
	[CLink] public static extern void nk_value_uint(nk_context*, char8* prefix, uint32);
	[CLink] public static extern void nk_value_float(nk_context*, char8* prefix, float);
	[CLink] public static extern void nk_value_color_byte(nk_context*, char8* prefix, nk_color);
	[CLink] public static extern void nk_value_color_float(nk_context*, char8* prefix, nk_color);
	[CLink] public static extern void nk_value_color_hex(nk_context*, char8* prefix, nk_color);
#endif

	/* =============================================================================
	 *
	 *                                  BUTTON
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_button_text(nk_context*, char8* title, int32 len);
	[CLink] public static extern nk_bool nk_button_label(nk_context*, char8* title);
	[CLink] public static extern nk_bool nk_button_color(nk_context*, nk_color);
	[CLink] public static extern nk_bool nk_button_symbol(nk_context*, nk_symbol_type);
	[CLink] public static extern nk_bool nk_button_image(nk_context*, nk_image img);
	[CLink] public static extern nk_bool nk_button_symbol_label(nk_context*, nk_symbol_type, char8*, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_button_symbol_text(nk_context*, nk_symbol_type, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_button_image_label(nk_context*, nk_image img, char8*, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_button_image_text(nk_context*, nk_image img, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_button_text_styled(nk_context*,  nk_style_button*, char8* title, int32 len);
	[CLink] public static extern nk_bool nk_button_label_styled(nk_context*,  nk_style_button*, char8* title);
	[CLink] public static extern nk_bool nk_button_symbol_styled(nk_context*,  nk_style_button*, nk_symbol_type);
	[CLink] public static extern nk_bool nk_button_image_styled(nk_context*,  nk_style_button*, nk_image img);
	[CLink] public static extern nk_bool nk_button_symbol_text_styled(nk_context*, nk_style_button*, nk_symbol_type, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_button_symbol_label_styled(nk_context* ctx,  nk_style_button* style, nk_symbol_type symbol, char8* title, nk_flags align);
	[CLink] public static extern nk_bool nk_button_image_label_styled(nk_context*, nk_style_button*, nk_image img, char8*, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_button_image_text_styled(nk_context*, nk_style_button*, nk_image img, char8*, int32, nk_flags alignment);
	[CLink] public static extern void nk_button_set_behavior(nk_context*, nk_button_behavior);
	[CLink] public static extern nk_bool nk_button_push_behavior(nk_context*, nk_button_behavior);
	[CLink] public static extern nk_bool nk_button_pop_behavior(nk_context*);
	/* =============================================================================
	 *
	 *                                  CHECKBOX
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_check_label(nk_context*, char8*, nk_bool active);
	[CLink] public static extern nk_bool nk_check_text(nk_context*, char8*, int32, nk_bool active);
	[CLink] public static extern nk_bool nk_check_text_align(nk_context*, char8*, int32, nk_bool active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern uint32 nk_check_flags_label(nk_context*, char8*, uint32 flags, uint32 value);
	[CLink] public static extern uint32 nk_check_flags_text(nk_context*, char8*, int32, uint32 flags, uint32 value);
	[CLink] public static extern nk_bool nk_checkbox_label(nk_context*, char8*, nk_bool* active);
	[CLink] public static extern nk_bool nk_checkbox_label_align(nk_context* ctx, char8* label, nk_bool* active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_checkbox_text(nk_context*, char8*, int32, nk_bool* active);
	[CLink] public static extern nk_bool nk_checkbox_text_align(nk_context* ctx, char8* text, int32 len, nk_bool* active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_checkbox_flags_label(nk_context*, char8*, uint32* flags, uint32 value);
	[CLink] public static extern nk_bool nk_checkbox_flags_text(nk_context*, char8*, int32, uint32* flags, uint32 value);
	/* =============================================================================
	 *
	 *                                  RADIO BUTTON
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_radio_label(nk_context*, char8*, nk_bool* active);
	[CLink] public static extern nk_bool nk_radio_label_align(nk_context* ctx, char8* label, nk_bool* active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_radio_text(nk_context*, char8*, int32, nk_bool* active);
	[CLink] public static extern nk_bool nk_radio_text_align(nk_context* ctx, char8* text, int32 len, nk_bool* active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_option_label(nk_context*, char8*, nk_bool active);
	[CLink] public static extern nk_bool nk_option_label_align(nk_context* ctx, char8* label, nk_bool active, nk_flags widget_alignment, nk_flags text_alignment);
	[CLink] public static extern nk_bool nk_option_text(nk_context*, char8*, int32, nk_bool active);
	[CLink] public static extern nk_bool nk_option_text_align(nk_context* ctx, char8* text, int32 len, nk_bool is_active, nk_flags widget_alignment, nk_flags text_alignment);
	/* =============================================================================
	 *
	 *                                  SELECTABLE
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_selectable_label(nk_context*, char8*, nk_flags align, nk_bool* value);
	[CLink] public static extern nk_bool nk_selectable_text(nk_context*, char8*, int32, nk_flags align, nk_bool* value);
	[CLink] public static extern nk_bool nk_selectable_image_label(nk_context*, struct nk_image,  char8*, nk_flags align, nk_bool* value);
	[CLink] public static extern nk_bool nk_selectable_image_text(nk_context*, struct nk_image, char8*, int32, nk_flags align, nk_bool* value);
	[CLink] public static extern nk_bool nk_selectable_symbol_label(nk_context*, enum nk_symbol_type,  char8*, nk_flags align, nk_bool* value);
	[CLink] public static extern nk_bool nk_selectable_symbol_text(nk_context*, enum nk_symbol_type, char8*, int32, nk_flags align, nk_bool* value);

	[CLink] public static extern nk_bool nk_select_label(nk_context*, char8*, nk_flags align, nk_bool value);
	[CLink] public static extern nk_bool nk_select_text(nk_context*, char8*, int32, nk_flags align, nk_bool value);
	[CLink] public static extern nk_bool nk_select_image_label(nk_context*, struct nk_image, char8*, nk_flags align, nk_bool value);
	[CLink] public static extern nk_bool nk_select_image_text(nk_context*, struct nk_image, char8*, int32, nk_flags align, nk_bool value);
	[CLink] public static extern nk_bool nk_select_symbol_label(nk_context*, enum nk_symbol_type,  char8*, nk_flags align, nk_bool value);
	[CLink] public static extern nk_bool nk_select_symbol_text(nk_context*, enum nk_symbol_type, char8*, int32, nk_flags align, nk_bool value);

	/* =============================================================================
	 *
	 *                                  SLIDER
	 *
	 * ============================================================================= */
	[CLink] public static extern float nk_slide_float(nk_context*, float min, float val, float max, float step);
	[CLink] public static extern int32 nk_slide_int(nk_context*, int32 min, int32 val, int32 max, int32 step);
	[CLink] public static extern nk_bool nk_slider_float(nk_context*, float min, float* val, float max, float step);
	[CLink] public static extern nk_bool nk_slider_int(nk_context*, int32 min, int32* val, int32 max, int32 step);

	/* =============================================================================
	 *
	 *                                   KNOB
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_knob_float(nk_context*, float min, float* val, float max, float step, nk_heading zero_direction, float dead_zone_degrees);
	[CLink] public static extern nk_bool nk_knob_int(nk_context*, int32 min, int32* val, int32 max, int32 step, nk_heading zero_direction, float dead_zone_degrees);

	/* =============================================================================
	 *
	 *                                  PROGRESSBAR
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_progress(nk_context*, nk_size* cur, nk_size max, nk_bool modifyable);
	[CLink] public static extern nk_size nk_prog(nk_context*, nk_size cur, nk_size max, nk_bool modifyable);

	/* =============================================================================
	 *
	 *                                  COLOR PICKER
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_colorf nk_color_picker(nk_context*, nk_colorf, nk_color_format);
	[CLink] public static extern nk_bool nk_color_pick(nk_context*, nk_colorf*, nk_color_format);
	/* =============================================================================
	 *
	 *                                  PROPERTIES
	 *
	 * =============================================================================*/
	/**
	 * \page Properties
	 * Properties are the main value modification widgets in Nuklear. Changing a value
	 * can be achieved by dragging, adding/removing incremental steps on button click
	 * or by directly typing a number.
	 *
	 * # Usage
	 * Each property requires a unique name for identification that is also used for
	 * displaying a label. If you want to use the same name multiple times make sure
	 * add a '#' before your name. The '#' will not be shown but will generate a
	 * unique ID. Each property also takes in a minimum and maximum value. If you want
	 * to make use of the complete number range of a type just use the provided
	 * type limits from `limits.h`. For example `INT_MIN` and `INT_MAX` for
	 * `nk_property_int` and `nk_propertyi`. In additional each property takes in
	 * a increment value that will be added or subtracted if either the increment
	 * decrement button is clicked. Finally there is a value for increment per pixel
	 * dragged that is added or subtracted from the value.
	 *
	 * ```c
	 * int32 value = 0;
	 * struct nk_context ctx;
	 * nk_init_xxx(&ctx, ...);
	 * while (1) {
	 *     // Input
	 *     Event evt;
	 *     nk_input_begin(&ctx);
	 *     while (GetEvent(&evt)) {
	 *         if (evt.type == MOUSE_MOVE)
	 *             nk_input_motion(&ctx, evt.motion.x, evt.motion.y);
	 *         else if (evt.type == [...]) {
	 *             nk_input_xxx(...);
	 *         }
	 *     }
	 *     nk_input_end(&ctx);
	 *     //
	 *     // Window
	 *     if (nk_begin_xxx(...) {
	 *         // Property
	 *         nk_layout_row_dynamic(...);
	 *         nk_property_int(ctx, "ID", INT_MIN, &value, INT_MAX, 1, 1);
	 *     }
	 *     nk_end(ctx);
	 *     //
	 *     // Draw
	 *      nk_command *cmd = 0;
	 *     nk_foreach(cmd, &ctx) {
	 *     switch (cmd->type) {
	 *     case NK_COMMAND_LINE:
	 *         your_draw_line_function(...)
	 *         break;
	 *     case NK_COMMAND_RECT
	 *         your_draw_rect_function(...)
	 *         break;
	 *     case ...:
	 *         // [...]
	 *     }
	 *     nk_clear(&ctx);
	 * }
	 * nk_free(&ctx);
	 * ```
	 *
	 * # Reference
	 * Function            | Description
	 * --------------------|-------------------------------------------
	 * \ref nk_property_int     | Integer property directly modifying a passed in value
	 * \ref nk_property_float   | Float property directly modifying a passed in value
	 * \ref nk_property_double  | Double property directly modifying a passed in value
	 * \ref nk_propertyi        | Integer property returning the modified int32 value
	 * \ref nk_propertyf        | Float property returning the modified float value
	 * \ref nk_propertyd        | Double property returning the modified double value
	 *

	 * # # nk_property_int
	 * Integer property directly modifying a passed in value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * void nk_property_int(nk_context *ctx, char8*name, int32 min, int32 *val, int32 max, int32 step, float inc_per_pixel);
	 * ```
	 *
	 * Parameter           | Description
	 * --------------------|-----------------------------------------------------------
	 * \param[in] ctx             | Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name            | String used both as a label as well as a unique identifier
	 * \param[in] min             | Minimum value not allowed to be underflown
	 * \param[in] val             | Integer pointer to be modified
	 * \param[in] max             | Maximum value not allowed to be overflown
	 * \param[in] step            | Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel   | Value per pixel added or subtracted on dragging
	 */
	[CLink] public static extern void nk_property_int(nk_context*, char8* name, int32 min, int32* val, int32 max, int32 step, float inc_per_pixel);

	/**
	 * # # nk_property_float
	 * Float property directly modifying a passed in value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * void nk_property_float(nk_context *ctx, char8*name, float min, float *val, float max, float step, float inc_per_pixel);
	 * ```
	 *
	 * Parameter           | Description
	 * --------------------|-----------------------------------------------------------
	 * \param[in] ctx             | Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name            | String used both as a label as well as a unique identifier
	 * \param[in] min             | Minimum value not allowed to be underflown
	 * \param[in] val             | Float pointer to be modified
	 * \param[in] max             | Maximum value not allowed to be overflown
	 * \param[in] step            | Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel   | Value per pixel added or subtracted on dragging
	 */
	[CLink] public static extern void nk_property_float(nk_context*, char8* name, float min, float* val, float max, float step, float inc_per_pixel);

	/**
	 * # # nk_property_double
	 * Double property directly modifying a passed in value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * void nk_property_double(nk_context *ctx, char8*name, double min, double *val, double max, double step, double inc_per_pixel);
	 * ```
	 *
	 * Parameter           | Description
	 * --------------------|-----------------------------------------------------------
	 * \param[in] ctx             | Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name            | String used both as a label as well as a unique identifier
	 * \param[in] min             | Minimum value not allowed to be underflown
	 * \param[in] val             | Double pointer to be modified
	 * \param[in] max             | Maximum value not allowed to be overflown
	 * \param[in] step            | Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel   | Value per pixel added or subtracted on dragging
	 */
	[CLink] public static extern void nk_property_double(nk_context*, char8* name, double min, double* val, double max, double step, float inc_per_pixel);

	/**
	 * # # nk_propertyi
	 * Integer property modifying a passed in value and returning the new value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * int32 nk_propertyi(nk_context *ctx, char8*name, int32 min, int32 val, int32 max, int32 step, float inc_per_pixel);
	 * ```
	 *
	 * \param[in] ctx              Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name             String used both as a label as well as a unique identifier
	 * \param[in] min              Minimum value not allowed to be underflown
	 * \param[in] val              Current integer value to be modified and returned
	 * \param[in] max              Maximum value not allowed to be overflown
	 * \param[in] step             Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel    Value per pixel added or subtracted on dragging
	 *
	 * \returns the new modified integer value
	 */
	[CLink] public static extern int32 nk_propertyi(nk_context*, char8* name, int32 min, int32 val, int32 max, int32 step, float inc_per_pixel);

	/**
	 * # # nk_propertyf
	 * Float property modifying a passed in value and returning the new value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * float nk_propertyf(nk_context *ctx, char8*name, float min, float val, float max, float step, float inc_per_pixel);
	 * ```
	 *
	 * \param[in] ctx              Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name             String used both as a label as well as a unique identifier
	 * \param[in] min              Minimum value not allowed to be underflown
	 * \param[in] val              Current float value to be modified and returned
	 * \param[in] max              Maximum value not allowed to be overflown
	 * \param[in] step             Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel    Value per pixel added or subtracted on dragging
	 *
	 * \returns the new modified float value
	 */
	[CLink] public static extern float nk_propertyf(nk_context*, char8* name, float min, float val, float max, float step, float inc_per_pixel);

	/**
	 * # # nk_propertyd
	 * Float property modifying a passed in value and returning the new value
	 * !!! \warning
	 *     To generate a unique property ID using the same label make sure to insert
	 *     a `#` at the beginning. It will not be shown but guarantees correct behavior.
	 *
	 * ```c
	 * float nk_propertyd(nk_context *ctx, char8*name, double min, double val, double max, double step, double inc_per_pixel);
	 * ```
	 *
	 * \param[in] ctx              Must point to an previously initialized `nk_context` struct after calling a layouting function
	 * \param[in] name             String used both as a label as well as a unique identifier
	 * \param[in] min              Minimum value not allowed to be underflown
	 * \param[in] val              Current double value to be modified and returned
	 * \param[in] max              Maximum value not allowed to be overflown
	 * \param[in] step             Increment added and subtracted on increment and decrement button
	 * \param[in] inc_per_pixel    Value per pixel added or subtracted on dragging
	 *
	 * \returns the new modified double value
	 */
	[CLink] public static extern double nk_propertyd(nk_context*, char8* name, double min, double val, double max, double step, float inc_per_pixel);
}
	/* =============================================================================
	 *
	 *                                  TEXT EDIT
	 *
	 * ============================================================================= */
enum nk_edit_flags : int32
{
	NK_EDIT_DEFAULT                 = 0,
	NK_EDIT_READ_ONLY               = NK_FLAG!(0),
	NK_EDIT_AUTO_SELECT             = NK_FLAG!(1),
	NK_EDIT_SIG_ENTER               = NK_FLAG!(2),
	NK_EDIT_ALLOW_TAB               = NK_FLAG!(3),
	NK_EDIT_NO_CURSOR               = NK_FLAG!(4),
	NK_EDIT_SELECTABLE              = NK_FLAG!(5),
	NK_EDIT_CLIPBOARD               = NK_FLAG!(6),
	NK_EDIT_CTRL_ENTER_NEWLINE      = NK_FLAG!(7),
	NK_EDIT_NO_HORIZONTAL_SCROLL    = NK_FLAG!(8),
	NK_EDIT_ALWAYS_INSERT_MODE      = NK_FLAG!(9),
	NK_EDIT_MULTILINE               = NK_FLAG!(10),
	NK_EDIT_GOTO_END_ON_ACTIVATE    = NK_FLAG!(11)
}
enum nk_edit_types : int32
{
	NK_EDIT_SIMPLE  = nk_edit_flags.NK_EDIT_ALWAYS_INSERT_MODE,
	NK_EDIT_FIELD   = .NK_EDIT_SIMPLE | (.)nk_edit_flags.NK_EDIT_SELECTABLE | (.)nk_edit_flags.NK_EDIT_CLIPBOARD,
	NK_EDIT_BOX     = nk_edit_flags.NK_EDIT_ALWAYS_INSERT_MODE | nk_edit_flags.NK_EDIT_SELECTABLE | nk_edit_flags.NK_EDIT_MULTILINE | nk_edit_flags.NK_EDIT_ALLOW_TAB | nk_edit_flags.NK_EDIT_CLIPBOARD,
	NK_EDIT_EDITOR  = nk_edit_flags.NK_EDIT_SELECTABLE | nk_edit_flags.NK_EDIT_MULTILINE | nk_edit_flags.NK_EDIT_ALLOW_TAB | nk_edit_flags.NK_EDIT_CLIPBOARD
}
enum nk_edit_events : int32
{
	NK_EDIT_ACTIVE      = NK_FLAG!(0), /**!< edit widget is currently being modified */
	NK_EDIT_INACTIVE    = NK_FLAG!(1), /**!< edit widget is not active and is not being modified */
	NK_EDIT_ACTIVATED   = NK_FLAG!(2), /**!< edit widget went from state inactive to state active */
	NK_EDIT_DEACTIVATED = NK_FLAG!(3), /**!< edit widget went from state active to state inactive */
	NK_EDIT_COMMITED    = NK_FLAG!(4) /**!< edit widget has received an enter and lost focus */
}
static
{
	[CLink] public static extern nk_flags nk_edit_string(nk_context*, nk_flags, char8* buffer, int32* len, int32 max, nk_plugin_filter);
	[CLink] public static extern nk_flags nk_edit_string_zero_terminated(nk_context*, nk_flags, char8* buffer, int32 max, nk_plugin_filter);
	[CLink] public static extern nk_flags nk_edit_buffer(nk_context*, nk_flags, nk_text_edit*, nk_plugin_filter);
	[CLink] public static extern void nk_edit_focus(nk_context*, nk_flags flags);
	[CLink] public static extern void nk_edit_unfocus(nk_context*);
	/* =============================================================================
	 *
	 *                                  CHART
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_chart_begin(nk_context*, nk_chart_type, int32 num, float min, float max);
	[CLink] public static extern nk_bool nk_chart_begin_colored(nk_context*, nk_chart_type, nk_color, nk_color active, int32 num, float min, float max);
	[CLink] public static extern void nk_chart_add_slot(nk_context* ctx,  nk_chart_type, int32 count, float min_value, float max_value);
	[CLink] public static extern void nk_chart_add_slot_colored(nk_context* ctx,  nk_chart_type, nk_color, nk_color active, int32 count, float min_value, float max_value);
	[CLink] public static extern nk_flags nk_chart_push(nk_context*, float);
	[CLink] public static extern nk_flags nk_chart_push_slot(nk_context*, float, int32);
	[CLink] public static extern void nk_chart_end(nk_context*);
	[CLink] public static extern void nk_plot(nk_context*, nk_chart_type, float* values, int32 count, int32 offset);
	[CLink] public static extern void nk_plot_function(nk_context*, nk_chart_type, void* userdata, function float(void* user, int32 index) value_getter, int32 count, int32 offset);
	/* =============================================================================
	 *
	 *                                  POPUP
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_popup_begin(nk_context*, nk_popup_type, char8*, nk_flags, nk_rect bounds);
	[CLink] public static extern void nk_popup_close(nk_context*);
	[CLink] public static extern void nk_popup_end(nk_context*);
	[CLink] public static extern void nk_popup_get_scroll(nk_context*, nk_uint* offset_x, nk_uint* offset_y);
	[CLink] public static extern void nk_popup_set_scroll(nk_context*, nk_uint offset_x, nk_uint offset_y);
	/* =============================================================================
	 *
	 *                                  COMBOBOX
	 *
	 * ============================================================================= */
	[CLink] public static extern int32 nk_combo(nk_context*, char8** items, int32 count, int32 selected, int32 item_height, nk_vec2 size);
	[CLink] public static extern int32 nk_combo_separator(nk_context*, char8* items_separated_by_separator, int32 separator, int32 selected, int32 count, int32 item_height, nk_vec2 size);
	[CLink] public static extern int32 nk_combo_string(nk_context*, char8* items_separated_by_zeros, int32 selected, int32 count, int32 item_height, nk_vec2 size);
	[CLink] public static extern int32 nk_combo_callback(nk_context*, function void(void*, int32, char8**) item_getter, void* userdata, int32 selected, int32 count, int32 item_height, nk_vec2 size);
	[CLink] public static extern void nk_combobox(nk_context*, char8** items, int32 count, int32* selected, int32 item_height, nk_vec2 size);
	[CLink] public static extern void nk_combobox_string(nk_context*, char8* items_separated_by_zeros, int32* selected, int32 count, int32 item_height, nk_vec2 size);
	[CLink] public static extern void nk_combobox_separator(nk_context*, char8* items_separated_by_separator, int32 separator, int32* selected, int32 count, int32 item_height, nk_vec2 size);
	[CLink] public static extern void nk_combobox_callback(nk_context*, function void(void*, int32, char8**) item_getter, void*, int32* selected, int32 count, int32 item_height, nk_vec2 size);
	/* =============================================================================
	 *
	 *                                  ABSTRACT COMBOBOX
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_combo_begin_text(nk_context*, char8* selected, int32, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_label(nk_context*, char8* selected, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_color(nk_context*, nk_color color, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_symbol(nk_context*,  nk_symbol_type,  nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_symbol_label(nk_context*, char8* selected, nk_symbol_type, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_symbol_text(nk_context*, char8* selected, int32, nk_symbol_type, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_image(nk_context*, nk_image img,  nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_image_label(nk_context*, char8* selected, nk_image, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_begin_image_text(nk_context*,  char8* selected, int32, nk_image, nk_vec2 size);
	[CLink] public static extern nk_bool nk_combo_item_label(nk_context*, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_combo_item_text(nk_context*, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_combo_item_image_label(nk_context*, nk_image, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_combo_item_image_text(nk_context*, nk_image, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_combo_item_symbol_label(nk_context*, nk_symbol_type, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_combo_item_symbol_text(nk_context*, nk_symbol_type, char8*, int32, nk_flags alignment);
	[CLink] public static extern void nk_combo_close(nk_context*);
	[CLink] public static extern void nk_combo_end(nk_context*);
	/* =============================================================================
	 *
	 *                                  CONTEXTUAL
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_bool nk_contextual_begin(nk_context*, nk_flags, nk_vec2, nk_rect trigger_bounds);
	[CLink] public static extern nk_bool nk_contextual_item_text(nk_context*, char8*, int32, nk_flags align);
	[CLink] public static extern nk_bool nk_contextual_item_label(nk_context*, char8*, nk_flags align);
	[CLink] public static extern nk_bool nk_contextual_item_image_label(nk_context*, nk_image, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_contextual_item_image_text(nk_context*, nk_image, char8*, int32 len, nk_flags alignment);
	[CLink] public static extern nk_bool nk_contextual_item_symbol_label(nk_context*, nk_symbol_type, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_contextual_item_symbol_text(nk_context*, nk_symbol_type, char8*, int32, nk_flags alignment);
	[CLink] public static extern void nk_contextual_close(nk_context*);
	[CLink] public static extern void nk_contextual_end(nk_context*);
	/* =============================================================================
	 *
	 *                                  TOOLTIP
	 *
	 * ============================================================================= */
	[CLink] public static extern void nk_tooltip(nk_context*, char8*);
#if NK_INCLUDE_STANDARD_VARARGS
	[CLink] public static extern void nk_tooltipf(nk_context*, char8*, ...) /*NK_PRINTF_VARARG_FUNC(2)*/;
	[CLink] public static extern void nk_tooltipfv(nk_context*, char8*, void* varArgs) /*NK_PRINTF_VALIST_FUNC(2)*/;
#endif
	[CLink] public static extern nk_bool nk_tooltip_begin(nk_context*, float width);
	[CLink] public static extern void nk_tooltip_end(nk_context*);
	/* =============================================================================
	 *
	 *                                  MENU
	 *
	 * ============================================================================= */
	[CLink] public static extern void nk_menubar_begin(nk_context*);
	[CLink] public static extern void nk_menubar_end(nk_context*);
	[CLink] public static extern nk_bool nk_menu_begin_text(nk_context*, char8* title, int32 title_len, nk_flags align, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_label(nk_context*, char8*, nk_flags align, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_image(nk_context*, char8*, nk_image, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_image_text(nk_context*, char8*, int32, nk_flags align, nk_image, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_image_label(nk_context*, char8*, nk_flags align, nk_image, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_symbol(nk_context*, char8*, nk_symbol_type, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_symbol_text(nk_context*, char8*, int32, nk_flags align, nk_symbol_type, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_begin_symbol_label(nk_context*, char8*, nk_flags align, nk_symbol_type, nk_vec2 size);
	[CLink] public static extern nk_bool nk_menu_item_text(nk_context*, char8*, int32, nk_flags align);
	[CLink] public static extern nk_bool nk_menu_item_label(nk_context*, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_menu_item_image_label(nk_context*, nk_image, char8*, nk_flags alignment);
	[CLink] public static extern nk_bool nk_menu_item_image_text(nk_context*, nk_image, char8*, int32 len, nk_flags alignment);
	[CLink] public static extern nk_bool nk_menu_item_symbol_text(nk_context*, nk_symbol_type, char8*, int32, nk_flags alignment);
	[CLink] public static extern nk_bool nk_menu_item_symbol_label(nk_context*, nk_symbol_type, char8*, nk_flags alignment);
	[CLink] public static extern void nk_menu_close(nk_context*);
	[CLink] public static extern void nk_menu_end(nk_context*);
}
	/* =============================================================================
	 *
	 *                                  STYLE
	 *
	 * ============================================================================= */
static
{
	public const float NK_WIDGET_DISABLED_FACTOR = 0.5f;
}

enum nk_style_colors : int32
{
	NK_COLOR_TEXT,
	NK_COLOR_WINDOW,
	NK_COLOR_HEADER,
	NK_COLOR_BORDER,
	NK_COLOR_BUTTON,
	NK_COLOR_BUTTON_HOVER,
	NK_COLOR_BUTTON_ACTIVE,
	NK_COLOR_TOGGLE,
	NK_COLOR_TOGGLE_HOVER,
	NK_COLOR_TOGGLE_CURSOR,
	NK_COLOR_SELECT,
	NK_COLOR_SELECT_ACTIVE,
	NK_COLOR_SLIDER,
	NK_COLOR_SLIDER_CURSOR,
	NK_COLOR_SLIDER_CURSOR_HOVER,
	NK_COLOR_SLIDER_CURSOR_ACTIVE,
	NK_COLOR_PROPERTY,
	NK_COLOR_EDIT,
	NK_COLOR_EDIT_CURSOR,
	NK_COLOR_COMBO,
	NK_COLOR_CHART,
	NK_COLOR_CHART_COLOR,
	NK_COLOR_CHART_COLOR_HIGHLIGHT,
	NK_COLOR_SCROLLBAR,
	NK_COLOR_SCROLLBAR_CURSOR,
	NK_COLOR_SCROLLBAR_CURSOR_HOVER,
	NK_COLOR_SCROLLBAR_CURSOR_ACTIVE,
	NK_COLOR_TAB_HEADER,
	NK_COLOR_KNOB,
	NK_COLOR_KNOB_CURSOR,
	NK_COLOR_KNOB_CURSOR_HOVER,
	NK_COLOR_KNOB_CURSOR_ACTIVE,
	NK_COLOR_COUNT
}
enum nk_style_cursor : int32
{
	NK_CURSOR_ARROW,
	NK_CURSOR_TEXT,
	NK_CURSOR_MOVE,
	NK_CURSOR_RESIZE_VERTICAL,
	NK_CURSOR_RESIZE_HORIZONTAL,
	NK_CURSOR_RESIZE_TOP_LEFT_DOWN_RIGHT,
	NK_CURSOR_RESIZE_TOP_RIGHT_DOWN_LEFT,
	NK_CURSOR_COUNT
}
static
{
	[CLink] public static extern void nk_style_default(nk_context*);
	[CLink] public static extern void nk_style_from_table(nk_context*,  nk_color*);
	[CLink] public static extern void nk_style_load_cursor(nk_context*, nk_style_cursor,  nk_cursor*);
	[CLink] public static extern void nk_style_load_all_cursors(nk_context*,  nk_cursor*);
	[CLink] public static extern char8* nk_style_get_color_by_name(nk_style_colors);
	[CLink] public static extern void nk_style_set_font(nk_context*,  nk_user_font*);
	[CLink] public static extern nk_bool nk_style_set_cursor(nk_context*, nk_style_cursor);
	[CLink] public static extern void nk_style_show_cursor(nk_context*);
	[CLink] public static extern void nk_style_hide_cursor(nk_context*);

	[CLink] public static extern nk_bool nk_style_push_font(nk_context*,  nk_user_font*);
	[CLink] public static extern nk_bool nk_style_push_float(nk_context*, float*, float);
	[CLink] public static extern nk_bool nk_style_push_vec2(nk_context*, nk_vec2*, nk_vec2);
	[CLink] public static extern nk_bool nk_style_push_style_item(nk_context*, nk_style_item*, nk_style_item);
	[CLink] public static extern nk_bool nk_style_push_flags(nk_context*, nk_flags*, nk_flags);
	[CLink] public static extern nk_bool nk_style_push_color(nk_context*, nk_color*, nk_color);

	[CLink] public static extern nk_bool nk_style_pop_font(nk_context*);
	[CLink] public static extern nk_bool nk_style_pop_float(nk_context*);
	[CLink] public static extern nk_bool nk_style_pop_vec2(nk_context*);
	[CLink] public static extern nk_bool nk_style_pop_style_item(nk_context*);
	[CLink] public static extern nk_bool nk_style_pop_flags(nk_context*);
	[CLink] public static extern nk_bool nk_style_pop_color(nk_context*);
	/* =============================================================================
	 *
	 *                                  COLOR
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_color nk_rgb(int32 r, int32 g, int32 b);
	[CLink] public static extern nk_color nk_rgb_iv(int32* rgb);
	[CLink] public static extern nk_color nk_rgb_bv(nk_byte* rgb);
	[CLink] public static extern nk_color nk_rgb_f(float r, float g, float b);
	[CLink] public static extern nk_color nk_rgb_fv(float* rgb);
	[CLink] public static extern nk_color nk_rgb_cf(nk_colorf c);
	[CLink] public static extern nk_color nk_rgb_hex(char8* rgb);
	[CLink] public static extern nk_color nk_rgb_factor(nk_color col, float factor);

	[CLink] public static extern nk_color nk_rgba(int32 r, int32 g, int32 b, int32 a);
	[CLink] public static extern nk_color nk_rgba_u32(nk_uint);
	[CLink] public static extern nk_color nk_rgba_iv(int32* rgba);
	[CLink] public static extern nk_color nk_rgba_bv(nk_byte* rgba);
	[CLink] public static extern nk_color nk_rgba_f(float r, float g, float b, float a);
	[CLink] public static extern nk_color nk_rgba_fv(float* rgba);
	[CLink] public static extern nk_color nk_rgba_cf(nk_colorf c);
	[CLink] public static extern nk_color nk_rgba_hex(char8* rgb);

	[CLink] public static extern nk_colorf nk_hsva_colorf(float h, float s, float v, float a);
	[CLink] public static extern nk_colorf nk_hsva_colorfv(float* c);
	[CLink] public static extern void nk_colorf_hsva_f(float* out_h, float* out_s, float* out_v, float* out_a, nk_colorf @in);
	[CLink] public static extern void nk_colorf_hsva_fv(float* hsva, nk_colorf @in);

	[CLink] public static extern nk_color nk_hsv(int32 h, int32 s, int32 v);
	[CLink] public static extern nk_color nk_hsv_iv(int32* hsv);
	[CLink] public static extern nk_color nk_hsv_bv(nk_byte* hsv);
	[CLink] public static extern nk_color nk_hsv_f(float h, float s, float v);
	[CLink] public static extern nk_color nk_hsv_fv(float* hsv);

	[CLink] public static extern nk_color nk_hsva(int32 h, int32 s, int32 v, int32 a);
	[CLink] public static extern nk_color nk_hsva_iv(int32* hsva);
	[CLink] public static extern nk_color nk_hsva_bv(nk_byte* hsva);
	[CLink] public static extern nk_color nk_hsva_f(float h, float s, float v, float a);
	[CLink] public static extern nk_color nk_hsva_fv(float* hsva);

	/* color (conversion nuklear --> user) */
	[CLink] public static extern void nk_color_f(float* r, float* g, float* b, float* a, nk_color);
	[CLink] public static extern void nk_color_fv(float* rgba_out, nk_color);
	[CLink] public static extern nk_colorf nk_color_cf(nk_color);
	[CLink] public static extern void nk_color_d(double* r, double* g, double* b, double* a, nk_color);
	[CLink] public static extern void nk_color_dv(double* rgba_out, nk_color);

	[CLink] public static extern nk_uint nk_color_u32(nk_color);
	[CLink] public static extern void nk_color_hex_rgba(char8* output, nk_color);
	[CLink] public static extern void nk_color_hex_rgb(char8* output, nk_color);

	[CLink] public static extern void nk_color_hsv_i(int32* out_h, int32* out_s, int32* out_v, nk_color);
	[CLink] public static extern void nk_color_hsv_b(nk_byte* out_h, nk_byte* out_s, nk_byte* out_v, nk_color);
	[CLink] public static extern void nk_color_hsv_iv(int32* hsv_out, nk_color);
	[CLink] public static extern void nk_color_hsv_bv(nk_byte* hsv_out, nk_color);
	[CLink] public static extern void nk_color_hsv_f(float* out_h, float* out_s, float* out_v, nk_color);
	[CLink] public static extern void nk_color_hsv_fv(float* hsv_out, nk_color);

	[CLink] public static extern void nk_color_hsva_i(int32* h, int32* s, int32* v, int32* a, nk_color);
	[CLink] public static extern void nk_color_hsva_b(nk_byte* h, nk_byte* s, nk_byte* v, nk_byte* a, nk_color);
	[CLink] public static extern void nk_color_hsva_iv(int32* hsva_out, nk_color);
	[CLink] public static extern void nk_color_hsva_bv(nk_byte* hsva_out, nk_color);
	[CLink] public static extern void nk_color_hsva_f(float* out_h, float* out_s, float* out_v, float* out_a, nk_color);
	[CLink] public static extern void nk_color_hsva_fv(float* hsva_out, nk_color);
	/* =============================================================================
	 *
	 *                                  IMAGE
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_handle nk_handle_ptr(void*);
	[CLink] public static extern nk_handle nk_handle_id(int32);
	[CLink] public static extern nk_image nk_image_handle(nk_handle);
	[CLink] public static extern nk_image nk_image_ptr(void*);
	[CLink] public static extern nk_image nk_image_id(int32);
	[CLink] public static extern nk_bool nk_image_is_subimage(nk_image* img);
	[CLink] public static extern nk_image nk_subimage_ptr(void*, nk_ushort w, nk_ushort h, nk_rect sub_region);
	[CLink] public static extern nk_image nk_subimage_id(int32, nk_ushort w, nk_ushort h, nk_rect sub_region);
	[CLink] public static extern nk_image nk_subimage_handle(nk_handle, nk_ushort w, nk_ushort h, nk_rect sub_region);
	/* =============================================================================
	 *
	 *                                  9-SLICE
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_nine_slice nk_nine_slice_handle(nk_handle, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	[CLink] public static extern nk_nine_slice nk_nine_slice_ptr(void*, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	[CLink] public static extern nk_nine_slice nk_nine_slice_id(int32, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	[CLink] public static extern int32 nk_nine_slice_is_sub9slice(nk_nine_slice* img);
	[CLink] public static extern nk_nine_slice nk_sub9slice_ptr(void*, nk_ushort w, nk_ushort h, nk_rect sub_region, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	[CLink] public static extern nk_nine_slice nk_sub9slice_id(int32, nk_ushort w, nk_ushort h, nk_rect sub_region, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	[CLink] public static extern nk_nine_slice nk_sub9slice_handle(nk_handle, nk_ushort w, nk_ushort h, nk_rect sub_region, nk_ushort l, nk_ushort t, nk_ushort r, nk_ushort b);
	/* =============================================================================
	 *
	 *                                  MATH
	 *
	 * ============================================================================= */
	[CLink] public static extern nk_hash nk_murmur_hash(void* key, int32 len, nk_hash seed);
	[CLink] public static extern void nk_triangle_from_direction(nk_vec2* result, nk_rect r, float pad_x, float pad_y, enum nk_heading);

	[CLink] public static extern nk_vec2 nk_vec2(float x, float y);
	[CLink] public static extern nk_vec2 nk_vec2i(int32 x, int32 y);
	[CLink] public static extern nk_vec2 nk_vec2v(float* xy);
	[CLink] public static extern nk_vec2 nk_vec2iv(int32* xy);

	[CLink] public static extern nk_rect nk_get_null_rect(void);
	[CLink] public static extern nk_rect nk_rect(float x, float y, float w, float h);
	[CLink] public static extern nk_rect nk_recti(int32 x, int32 y, int32 w, int32 h);
	[CLink] public static extern nk_rect nk_recta(nk_vec2 pos, nk_vec2 size);
	[CLink] public static extern nk_rect nk_rectv(float* xywh);
	[CLink] public static extern nk_rect nk_rectiv(int32* xywh);
	[CLink] public static extern nk_vec2 nk_rect_pos(nk_rect);
	[CLink] public static extern nk_vec2 nk_rect_size(nk_rect);
	/* =============================================================================
	 *
	 *                                  STRING
	 *
	 * ============================================================================= */
	[CLink] public static extern int32 nk_strlen(char8* str);
	[CLink] public static extern int32 nk_stricmp(char8* s1, char8* s2);
	[CLink] public static extern int32 nk_stricmpn(char8* s1, char8* s2, int32 n);
	[CLink] public static extern int32 nk_strtoi(char8* str, char8** endptr);
	[CLink] public static extern float nk_strtof(char8* str, char8** endptr);
#if !NK_STRTOD
	public static double NK_STRTOD(char8* str, char8** endptr) => nk_strtod(str, endptr);
	[CLink] public static extern double nk_strtod(char8* str, char8** endptr);
#endif
	[CLink] public static extern int32 nk_strfilter(char8* text, char8* regexp);
	[CLink] public static extern int32 nk_strmatch_fuzzy_string(char8* str, char8* pattern, int32* out_score);
	[CLink] public static extern int32 nk_strmatch_fuzzy_text(char8* txt, int32 txt_len, char8* pattern, int32* out_score);
	/* =============================================================================
	 *
	 *                                  UTF-8
	 *
	 * ============================================================================= */
	[CLink] public static extern int32 nk_utf_decode(char8*, nk_rune*, int32);
	[CLink] public static extern int32 nk_utf_encode(nk_rune, char8*, int32);
	[CLink] public static extern int32 nk_utf_len(char8*, int32 byte_len);
	[CLink] public static extern char8* nk_utf_at(char8* buffer, int32 length, int32 index, nk_rune* unicode, int32* len);
}
	/* ===============================================================
	 *
	 *                          FONT
	 *
	 * ===============================================================*/
	/**
	 * \page Font
	 * Font handling in this library was designed to be quite customizable and lets
	 * you decide what you want to use and what you want to provide. There are three
	 * different ways to use the font atlas. The first two will use your font
	 * handling scheme and only requires essential data to run nuklear. The next
	 * slightly more advanced features is font handling with vertex buffer output.
	 * Finally the most complex API wise is using nuklear's font baking API.
	 *
	 * # Using your own implementation without vertex buffer output
	 *
	 * So first up the easiest way to do font handling is by just providing a
	 * `nk_user_font` struct which only requires the height in pixel of the used
	 * font and a callback to calculate the width of a string. This way of handling
	 * fonts is best fitted for using the normal draw shape command API where you
	 * do all the text drawing yourself and the library does not require any kind
	 * of deeper knowledge about which font handling mechanism you use.
	 * IMPORTANT: the `nk_user_font` pointer provided to nuklear has to persist
	 * over the complete life time! I know this sucks but it is currently the only
	 * way to switch between fonts.
	 *
	 * ```c
	 *     float your_text_width_calculation(nk_handle handle, float height, char8*text, int32 len)
	 *     {
	 *         your_font_type *type = handle.ptr;
	 *         float text_width = ...;
	 *         return text_width;
	 *     }
	 *
	 *     struct nk_user_font font;
	 *     font.userdata.ptr = &your_font_class_or_struct;
	 *     font.height = your_font_height;
	 *     font.width = your_text_width_calculation;
	 *
	 *     struct nk_context ctx;
	 *     nk_init_default(&ctx, &font);
	 * ```
	 * # Using your own implementation with vertex buffer output
	 *
	 * While the first approach works fine if you don't want to use the optional
	 * vertex buffer output it is not enough if you do. To get font handling working
	 * for these cases you have to provide two additional parameters inside the
	 * `nk_user_font`. First a texture atlas handle used to draw text as subimages
	 * of a bigger font atlas texture and a callback to query a character's glyph
	 * information (offset, size, ...). So it is still possible to provide your own
	 * font and use the vertex buffer output.
	 *
	 * ```c
	 *     float your_text_width_calculation(nk_handle handle, float height, char8*text, int32 len)
	 *     {
	 *         your_font_type *type = handle.ptr;
	 *         float text_width = ...;
	 *         return text_width;
	 *     }
	 *     void query_your_font_glyph(nk_handle handle, float font_height, struct nk_user_font_glyph *glyph, nk_rune codepoint, nk_rune next_codepoint)
	 *     {
	 *         your_font_type *type = handle.ptr;
	 *         glyph.width = ...;
	 *         glyph.height = ...;
	 *         glyph.xadvance = ...;
	 *         glyph.uv[0].x = ...;
	 *         glyph.uv[0].y = ...;
	 *         glyph.uv[1].x = ...;
	 *         glyph.uv[1].y = ...;
	 *         glyph.offset.x = ...;
	 *         glyph.offset.y = ...;
	 *     }
	 *
	 *     struct nk_user_font font;
	 *     font.userdata.ptr = &your_font_class_or_struct;
	 *     font.height = your_font_height;
	 *     font.width = your_text_width_calculation;
	 *     font.query = query_your_font_glyph;
	 *     font.texture.id = your_font_texture;
	 *
	 *     struct nk_context ctx;
	 *     nk_init_default(&ctx, &font);
	 * ```
	 *
	 * # Nuklear font baker
	 *
	 * The final approach if you do not have a font handling functionality or don't
	 * want to use it in this library is by using the optional font baker.
	 * The font baker APIs can be used to create a font plus font atlas texture
	 * and can be used with or without the vertex buffer output.
	 *
	 * It still uses the `nk_user_font` struct and the two different approaches
	 * previously stated still work. The font baker is not located inside
	 * `nk_context` like all other systems since it can be understood as more of
	 * an extension to nuklear and does not really depend on any `nk_context` state.
	 *
	 * Font baker need to be initialized first by one of the nk_font_atlas_init_xxx
	 * functions. If you don't care about memory just call the default version
	 * `nk_font_atlas_init_default` which will allocate all memory from the standard library.
	 * If you want to control memory allocation but you don't care if the allocated
	 * memory is temporary and therefore can be freed directly after the baking process
	 * is over or permanent you can call `nk_font_atlas_init`.
	 *
	 * After successfully initializing the font baker you can add Truetype(.ttf) fonts from
	 * different sources like memory or from file by calling one of the `nk_font_atlas_add_xxx`.
	 * functions. Adding font will permanently store each font, font config and ttf memory block(!)
	 * inside the font atlas and allows to reuse the font atlas. If you don't want to reuse
	 * the font baker by for example adding additional fonts you can call
	 * `nk_font_atlas_cleanup` after the baking process is over (after calling nk_font_atlas_end).
	 *
	 * As soon as you added all fonts you wanted you can now start the baking process
	 * for every selected glyph to image by calling `nk_font_atlas_bake`.
	 * The baking process returns image memory, width and height which can be used to
	 * either create your own image object or upload it to any graphics library.
	 * No matter which case you finally have to call `nk_font_atlas_end` which
	 * will free all temporary memory including the font atlas image so make sure
	 * you created our texture beforehand. `nk_font_atlas_end` requires a handle
	 * to your font texture or object and optionally fills a `struct nk_draw_null_texture`
	 * which can be used for the optional vertex output. If you don't want it just
	 * set the argument to `NULL`.
	 *
	 * At this point you are done and if you don't want to reuse the font atlas you
	 * can call `nk_font_atlas_cleanup` to free all truetype blobs and configuration
	 * memory. Finally if you don't use the font atlas and any of it's fonts anymore
	 * you need to call `nk_font_atlas_clear` to free all memory still being used.
	 *
	 * ```c
	 *     struct nk_font_atlas atlas;
	 *     nk_font_atlas_init_default(&atlas);
	 *     nk_font_atlas_begin(&atlas);
	 *     nk_font *font = nk_font_atlas_add_from_file(&atlas, "Path/To/Your/TTF_Font.ttf", 13, 0);
	 *     nk_font *font2 = nk_font_atlas_add_from_file(&atlas, "Path/To/Your/TTF_Font2.ttf", 16, 0);
	 *     const void* img = nk_font_atlas_bake(&atlas, &img_width, &img_height, NK_FONT_ATLAS_RGBA32);
	 *     nk_font_atlas_end(&atlas, nk_handle_id(texture), 0);
	 *
	 *     struct nk_context ctx;
	 *     nk_init_default(&ctx, &font->handle);
	 *     while (1) {
	 *
	 *     }
	 *     nk_font_atlas_clear(&atlas);
	 * ```
	 * The font baker API is probably the most complex API inside this library and
	 * I would suggest reading some of my examples `example/` to get a grip on how
	 * to use the font atlas. There are a number of details I left out. For example
	 * how to merge fonts, configure a font with `nk_font_config` to use other languages,
	 * use another texture coordinate format and a lot more:
	 *
	 * ```c
	 *     struct nk_font_config cfg = nk_font_config(font_pixel_height);
	 *     cfg.merge_mode = nk_false or nk_true;
	 *     cfg.range = nk_font_korean_glyph_ranges();
	 *     cfg.coord_type = NK_COORD_PIXEL;
	 *     nk_font *font = nk_font_atlas_add_from_file(&atlas, "Path/To/Your/TTF_Font.ttf", 13, &cfg);
	 * ```
	 */

	//[CRepr]struct nk_user_font_glyph;
typealias nk_text_width_f = function float(nk_handle, float h, char8*, int32 len);
typealias nk_query_font_glyph_f = function void(nk_handle handle, float font_height,
	nk_user_font_glyph* glyph,
	nk_rune codepoint, nk_rune next_codepoint);

#if NK_INCLUDE_VERTEX_BUFFER_OUTPUT || NK_INCLUDE_SOFTWARE_FONT
[CRepr] struct nk_user_font_glyph
{
	public nk_vec2[2] uv; /**!< texture coordinates */
	public nk_vec2 offset; /**!< offset between top left and glyph */
	public float width, height; /**!< size of the glyph  */
	public float xadvance; /**!< offset to the next glyph */
}
#endif

[CRepr] struct nk_user_font
{
	public nk_handle userdata; /**!< user provided font handle */
	public float height; /**!< max height of the font */
	public nk_text_width_f width; /**!< font string width in pixel callback */
#if NK_INCLUDE_VERTEX_BUFFER_OUTPUT
	public nk_query_font_glyph_f query; /**!< font glyph callback to query drawing info */
	public nk_handle texture; /**!< texture handle to the used font atlas or texture */
#endif
}

#if NK_INCLUDE_FONT_BAKING
enum nk_font_coord_type : int32
{
	NK_COORD_UV, /**!< texture coordinates inside font glyphs are clamped between 0-1 */
	NK_COORD_PIXEL /**!< texture coordinates inside font glyphs are in absolute pixel */
}

//[CRepr]struct nk_font;
[CRepr] struct nk_baked_font
{
	public float height; /**!< height of the font  */
	public float ascent; /**!< font glyphs ascent and descent  */
	public float descent; /**!< font glyphs ascent and descent  */
	public nk_rune glyph_offset; /**!< glyph array offset inside the font glyph baking output array  */
	public nk_rune glyph_count; /**!< number of glyphs of this font inside the glyph baking array output */
	public nk_rune* ranges; /**!< font codepoint ranges as pairs of (from/to) and 0 as last element */
}

[CRepr] struct nk_font_config
{
	public nk_font_config* next; /**!< NOTE: only used internally */
	public void* ttf_blob; /**!< pointer to loaded TTF file memory block.  * \note not needed for nk_font_atlas_add_from_memory and nk_font_atlas_add_from_file. */
	public nk_size ttf_size; /**!< size of the loaded TTF file memory block * \note not needed for nk_font_atlas_add_from_memory and nk_font_atlas_add_from_file. */

	public uint8 ttf_data_owned_by_atlas; /**!< used inside font atlas: default to: 0*/
	public uint8 merge_mode; /**!< merges this font into the last font */
	public uint8 pixel_snap; /**!< align every character to pixel boundary (if true set oversample (1,1)) */
	public uint8 oversample_v, oversample_h; /**!< rasterize at high quality for sub-pixel position */
	public uint8[3] padding;

	public float size; /**!< baked pixel height of the font */
	public nk_font_coord_type coord_type; /**!< texture coordinate format with either pixel or UV coordinates */
	public nk_vec2 spacing; /**!< extra pixel spacing between glyphs  */
	public nk_rune* range; /**!< list of unicode ranges (2 values per range, zero terminated) */
	public nk_baked_font* font; /**!< font to setup in the baking process: NOTE: not needed for font atlas */
	public nk_rune fallback_glyph; /**!< fallback glyph to use if a given rune is not found */
	public nk_font_config* n;
	public nk_font_config* p;
}

[CRepr] struct nk_font_glyph
{
	public nk_rune codepoint;
	public float xadvance;
	public float x0, y0, x1, y1, w, h;
	public float u0, v0, u1, v1;
}

[CRepr] struct nk_font
{
	public nk_font* next;
	public nk_user_font handle;
	public nk_baked_font info;
	public float scale;
	public nk_font_glyph* glyphs;
	public nk_font_glyph* fallback;
	public nk_rune fallback_codepoint;
	public nk_handle texture;
	public nk_font_config* config;
}

enum nk_font_atlas_format : int32
{
	NK_FONT_ATLAS_ALPHA8,
	NK_FONT_ATLAS_RGBA32
}

[CRepr] struct nk_font_atlas
{
	public void* pixel;
	public int32 tex_width;
	public int32 tex_height;

	public nk_allocator permanent;
	public nk_allocator temporary;

	public nk_recti custom;
	public nk_cursor[(int)nk_style_cursor.NK_CURSOR_COUNT] cursors;

	public int32 glyph_count;
	public nk_font_glyph* glyphs;
	public nk_font* default_font;
	public nk_font* fonts;
	public nk_font_config* config;
	public int32 font_num;
}
static
{
/** some language glyph codepoint ranges */
	[CLink] public static extern nk_rune* nk_font_default_glyph_ranges(void);
	[CLink] public static extern nk_rune* nk_font_chinese_glyph_ranges(void);
	[CLink] public static extern nk_rune* nk_font_cyrillic_glyph_ranges(void);
	[CLink] public static extern nk_rune* nk_font_korean_glyph_ranges(void);

#if NK_INCLUDE_DEFAULT_ALLOCATOR
	[CLink] public static extern void nk_font_atlas_init_default(nk_font_atlas*);
#endif
	[CLink] public static extern void nk_font_atlas_init(nk_font_atlas*,  nk_allocator*);
	[CLink] public static extern void nk_font_atlas_init_custom(nk_font_atlas*,  nk_allocator* persistent,  nk_allocator* transient);
	[CLink] public static extern void nk_font_atlas_begin(nk_font_atlas*);
	[CLink] public static extern nk_font_config nk_font_config(float pixel_height);
	[CLink] public static extern nk_font* nk_font_atlas_add(nk_font_atlas*,  nk_font_config*);
#if NK_INCLUDE_DEFAULT_FONT
	[CLink] public static extern nk_font* nk_font_atlas_add_default(nk_font_atlas*, float height,  nk_font_config*);
#endif
	[CLink] public static extern nk_font* nk_font_atlas_add_from_memory(nk_font_atlas* atlas, void* memory, nk_size size, float height,  nk_font_config* config);
#if NK_INCLUDE_STANDARD_IO
	[CLink] public static extern nk_font* nk_font_atlas_add_from_file(nk_font_atlas* atlas, char8* file_path, float height,  nk_font_config*);
#endif
	[CLink] public static extern nk_font* nk_font_atlas_add_compressed(nk_font_atlas*, void* memory, nk_size size, float height,  nk_font_config*);
	[CLink] public static extern nk_font* nk_font_atlas_add_compressed_base85(nk_font_atlas*, char8* data, float height,  nk_font_config* config);
	[CLink] public static extern void* nk_font_atlas_bake(nk_font_atlas*, int32* width, int32* height, nk_font_atlas_format);
	[CLink] public static extern void nk_font_atlas_end(nk_font_atlas*, nk_handle tex, nk_draw_null_texture*);
	[CLink] public static extern  nk_font_glyph* nk_font_find_glyph(nk_font*, nk_rune unicode);
	[CLink] public static extern void nk_font_atlas_cleanup(nk_font_atlas* atlas);
	[CLink] public static extern void nk_font_atlas_clear(nk_font_atlas*);
}
#endif


/* ==============================================================
 *
 *                          MEMORY BUFFER
 *
 * ===============================================================*/
/**
 * \page Memory Buffer
 * A basic (double)-buffer with linear allocation and resetting as only
 * freeing policy. The buffer's main purpose is to control all memory management
 * inside the GUI toolkit and still leave memory control as much as possible in
 * the hand of the user while also making sure the library is easy to use if
 * not as much control is needed.
 * In general all memory inside this library can be provided from the user in
 * three different ways.
 *
 * The first way and the one providing most control is by just passing a fixed
 * size memory block. In this case all control lies in the hand of the user
 * since he can exactly control where the memory comes from and how much memory
 * the library should consume. Of course using the fixed size API removes the
 * ability to automatically resize a buffer if not enough memory is provided so
 * you have to take over the resizing. While being a fixed sized buffer sounds
 * quite limiting, it is very effective in this library since the actual memory
 * consumption is quite stable and has a fixed upper bound for a lot of cases.
 *
 * If you don't want to think about how much memory the library should allocate
 * at all time or have a very dynamic UI with unpredictable memory consumption
 * habits but still want control over memory allocation you can use the dynamic
 * allocator based API. The allocator consists of two callbacks for allocating
 * and freeing memory and optional userdata so you can plugin your own allocator.
 *
 * The final and easiest way can be used by defining
 * NK_INCLUDE_DEFAULT_ALLOCATOR which uses the standard library memory
 * allocation functions malloc and free and takes over complete control over
 * memory in this library.
 */

[CRepr] struct nk_memory_status
{
	public void* memory;
	public uint32 type;
	public nk_size size;
	public nk_size allocated;
	public nk_size needed;
	public nk_size calls;
}

enum nk_allocation_type : int32
{
	NK_BUFFER_FIXED,
	NK_BUFFER_DYNAMIC
}

enum nk_buffer_allocation_type : int32
{
	NK_BUFFER_FRONT,
	NK_BUFFER_BACK,
	NK_BUFFER_MAX
}

[CRepr] struct nk_buffer_marker
{
	public nk_bool active;
	public nk_size offset;
}

[CRepr] struct nk_memory { public void* ptr; public nk_size size; }
[CRepr] struct nk_buffer
{
	public nk_buffer_marker[(int)nk_buffer_allocation_type.NK_BUFFER_MAX] marker; /**!< buffer marker to free a buffer to a certain offset */
	public nk_allocator pool; /**!< allocator callback for dynamic buffers */
	public nk_allocation_type type; /**!< memory management type */
	public nk_memory memory; /**!< memory and size of the current memory block */
	public float grow_factor; /**!< growing factor for dynamic memory management */
	public nk_size allocated; /**!< total amount of memory allocated */
	public nk_size needed; /**!< totally consumed memory given that enough memory is present */
	public nk_size calls; /**!< number of allocation calls */
	public nk_size size; /**!< current size of the buffer */
}

static
{
#if NK_INCLUDE_DEFAULT_ALLOCATOR
	[CLink] public static extern void nk_buffer_init_default(nk_buffer*);
#endif
	[CLink] public static extern void nk_buffer_init(nk_buffer*,  nk_allocator*, nk_size size);
	[CLink] public static extern void nk_buffer_init_fixed(nk_buffer*, void* memory, nk_size size);
	[CLink] public static extern void nk_buffer_info(nk_memory_status*,  nk_buffer*);
	[CLink] public static extern void nk_buffer_push(nk_buffer*, nk_buffer_allocation_type type, void* memory, nk_size size, nk_size align);
	[CLink] public static extern void nk_buffer_mark(nk_buffer*, nk_buffer_allocation_type type);
	[CLink] public static extern void nk_buffer_reset(nk_buffer*, nk_buffer_allocation_type type);
	[CLink] public static extern void nk_buffer_clear(nk_buffer*);
	[CLink] public static extern void nk_buffer_free(nk_buffer*);
	[CLink] public static extern void* nk_buffer_memory(nk_buffer*);
	[CLink] public static extern void* nk_buffer_memory_const(nk_buffer*);
	[CLink] public static extern nk_size nk_buffer_total(nk_buffer*);
}
/* ==============================================================
 *
 *                          STRING
 *
 * ===============================================================*/
/**  Basic string buffer which is only used in context with the text editor
 *  to manage and manipulate dynamic or fixed size string content. This is _NOT_
 *  the default string handling method. The only instance you should have any contact
 *  with this API is if you interact with an `nk_text_edit` object inside one of the
 *  copy and paste functions and even there only for more advanced cases. */
[CRepr] struct nk_str
{
	public nk_buffer buffer;
	public int32 len; /**!< in codepoints/runes/glyphs */
}

static
{
#if NK_INCLUDE_DEFAULT_ALLOCATOR
	[CLink] public static extern void nk_str_init_default(nk_str*);
#endif
	[CLink] public static extern void nk_str_init(nk_str*,  nk_allocator*, nk_size size);
	[CLink] public static extern void nk_str_init_fixed(nk_str*, void* memory, nk_size size);
	[CLink] public static extern void nk_str_clear(nk_str*);
	[CLink] public static extern void nk_str_free(nk_str*);

	[CLink] public static extern int32 nk_str_append_text_char(nk_str*, char8*, int32);
	[CLink] public static extern int32 nk_str_append_str_char(nk_str*, char8*);
	[CLink] public static extern int32 nk_str_append_text_utf8(nk_str*, char8*, int32);
	[CLink] public static extern int32 nk_str_append_str_utf8(nk_str*, char8*);
	[CLink] public static extern int32 nk_str_append_text_runes(nk_str*, nk_rune*, int32);
	[CLink] public static extern int32 nk_str_append_str_runes(nk_str*, nk_rune*);

	[CLink] public static extern int32 nk_str_insert_at_char(nk_str*, int32 pos, char8*, int32);
	[CLink] public static extern int32 nk_str_insert_at_rune(nk_str*, int32 pos, char8*, int32);

	[CLink] public static extern int32 nk_str_insert_text_char(nk_str*, int32 pos, char8*, int32);
	[CLink] public static extern int32 nk_str_insert_str_char(nk_str*, int32 pos, char8*);
	[CLink] public static extern int32 nk_str_insert_text_utf8(nk_str*, int32 pos, char8*, int32);
	[CLink] public static extern int32 nk_str_insert_str_utf8(nk_str*, int32 pos, char8*);
	[CLink] public static extern int32 nk_str_insert_text_runes(nk_str*, int32 pos, nk_rune*, int32);
	[CLink] public static extern int32 nk_str_insert_str_runes(nk_str*, int32 pos, nk_rune*);

	[CLink] public static extern void nk_str_remove_chars(nk_str*, int32 len);
	[CLink] public static extern void nk_str_remove_runes(nk_str* str, int32 len);
	[CLink] public static extern void nk_str_delete_chars(nk_str*, int32 pos, int32 len);
	[CLink] public static extern void nk_str_delete_runes(nk_str*, int32 pos, int32 len);

	[CLink] public static extern char8* nk_str_at_char(nk_str*, int32 pos);
	[CLink] public static extern char8* nk_str_at_rune(nk_str*, int32 pos, nk_rune* unicode, int32* len);
	[CLink] public static extern nk_rune nk_str_rune_at(nk_str*, int32 pos);
	[CLink] public static extern char8* nk_str_at_char_const(nk_str*, int32 pos);
	[CLink] public static extern char8* nk_str_at_const(nk_str*, int32 pos, nk_rune* unicode, int32* len);

	[CLink] public static extern char8* nk_str_get(nk_str*);
	[CLink] public static extern char8* nk_str_get_const(nk_str*);
	[CLink] public static extern int32 nk_str_len(nk_str*);
	[CLink] public static extern int32 nk_str_len_char(nk_str*);
}
/* ===============================================================
 *
 *                      TEXT EDITOR
 *
 * ===============================================================*/
/**
 * \page Text Editor
 * Editing text in this library is handled by either `nk_edit_string` or
 * `nk_edit_buffer`. But like almost everything in this library there are multiple
 * ways of doing it and a balance between control and ease of use with memory
 * as well as functionality controlled by flags.
 *
 * This library generally allows three different levels of memory control:
 * First of is the most basic way of just providing a simple char8 array with
 * string length. This method is probably the easiest way of handling simple
 * user text input. Main upside is complete control over memory while the biggest
 * downside in comparison with the other two approaches is missing undo/redo.
 *
 * For UIs that require undo/redo the second way was created. It is based on
 * a fixed size nk_text_edit struct, which has an internal undo/redo stack.
 * This is mainly useful if you want something more like a text editor but don't want
 * to have a dynamically growing buffer.
 *
 * The final way is using a dynamically growing nk_text_edit struct, which
 * has both a default version if you don't care where memory comes from and an
 * allocator version if you do. While the text editor is quite powerful for its
 * complexity I would not recommend editing gigabytes of data with it.
 * It is rather designed for uses cases which make sense for a GUI library not for
 * an full blown text editor.
 */

static
{
	public const uint32 NK_TEXTEDIT_UNDOSTATECOUNT     = 99;
	public const uint32 NK_TEXTEDIT_UNDOCHARCOUNT      = 999;
}

	//[CRepr]struct nk_text_edit;
[CRepr] struct nk_clipboard
{
	public nk_handle userdata;
	public nk_plugin_paste paste;
	public nk_plugin_copy copy;
}

[CRepr] struct nk_text_undo_record
{
	public int32 @where;
	public int16 insert_length;
	public int16 delete_length;
	public int16 char_storage;
}

[CRepr] struct nk_text_undo_state
{
	public nk_text_undo_record[NK_TEXTEDIT_UNDOSTATECOUNT] undo_rec;
	public nk_rune[NK_TEXTEDIT_UNDOCHARCOUNT] undo_char;
	public int16 undo_point;
	public int16 redo_point;
	public int16 undo_char_point;
	public int16 redo_char_point;
}

enum nk_text_edit_type : int32
{
	NK_TEXT_EDIT_SINGLE_LINE,
	NK_TEXT_EDIT_MULTI_LINE
}

enum nk_text_edit_mode : int32
{
	NK_TEXT_EDIT_MODE_VIEW,
	NK_TEXT_EDIT_MODE_INSERT,
	NK_TEXT_EDIT_MODE_REPLACE
}

[CRepr] struct nk_text_edit
{
	public nk_clipboard clip;
	public nk_str string;
	public nk_plugin_filter filter;
	public nk_vec2 scrollbar;

	public int32 cursor;
	public int32 select_start;
	public int32 select_end;
	public uint8 mode;
	public uint8 cursor_at_end_of_line;
	public uint8 initialized;
	public uint8 has_preferred_x;
	public uint8 single_line;
	public uint8 active;
	public uint8 padding1;
	public float preferred_x;
	public nk_text_undo_state undo;
}

static
{
/** filter function */
	[CLink] public static extern nk_bool nk_filter_default(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_ascii(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_float(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_decimal(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_hex(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_oct(nk_text_edit*, nk_rune unicode);
	[CLink] public static extern nk_bool nk_filter_binary(nk_text_edit*, nk_rune unicode);

/** text editor */
#if NK_INCLUDE_DEFAULT_ALLOCATOR
	[CLink] public static extern void nk_textedit_init_default(nk_text_edit*);
#endif
	[CLink] public static extern void nk_textedit_init(nk_text_edit*,  nk_allocator*, nk_size size);
	[CLink] public static extern void nk_textedit_init_fixed(nk_text_edit*, void* memory, nk_size size);
	[CLink] public static extern void nk_textedit_free(nk_text_edit*);
	[CLink] public static extern void nk_textedit_text(nk_text_edit*, char8*, int32 total_len);
	[CLink] public static extern void nk_textedit_delete(nk_text_edit*, int32 @where, int32 len);
	[CLink] public static extern void nk_textedit_delete_selection(nk_text_edit*);
	[CLink] public static extern void nk_textedit_select_all(nk_text_edit*);
	[CLink] public static extern nk_bool nk_textedit_cut(nk_text_edit*);
	[CLink] public static extern nk_bool nk_textedit_paste(nk_text_edit*, char8*, int32 len);
	[CLink] public static extern void nk_textedit_undo(nk_text_edit*);
	[CLink] public static extern void nk_textedit_redo(nk_text_edit*);
}
/* ===============================================================
 *
 *                          DRAWING
 *
 * ===============================================================*/
/**
 * \page Drawing
 * This library was designed to be render backend agnostic so it does
 * not draw anything to screen. Instead all drawn shapes, widgets
 * are made of, are buffered into memory and make up a command queue.
 * Each frame therefore fills the command buffer with draw commands
 * that then need to be executed by the user and his own render backend.
 * After that the command buffer needs to be cleared and a new frame can be
 * started. It is probably important to note that the command buffer is the main
 * drawing API and the optional vertex buffer API only takes this format and
 * converts it into a hardware accessible format.
 *
 * To use the command queue to draw your own widgets you can access the
 * command buffer of each window by calling `nk_window_get_canvas` after
 * previously having called `nk_begin`:
 *
 * ```c
 *     void draw_red_rectangle_widget(nk_context *ctx)
 *     {
 *         struct nk_command_buffer *canvas;
 *         struct nk_input *input = &ctx->input;
 *         canvas = nk_window_get_canvas(ctx);
 *
 *         struct nk_rect space;
 *         enum nk_widget_layout_states state;
 *         state = nk_widget(&space, ctx);
 *         if (!state) return;
 *
 *         if (state != NK_WIDGET_ROM)
 *             update_your_widget_by_user_input(...);
 *         nk_fill_rect(canvas, space, 0, nk_rgb(255,0,0));
 *     }
 *
 *     if (nk_begin(...)) {
 *         nk_layout_row_dynamic(ctx, 25, 1);
 *         draw_red_rectangle_widget(ctx);
 *     }
 *     nk_end(..)
 *
 * ```
 * Important to know if you want to create your own widgets is the `nk_widget`
 * call. It allocates space on the panel reserved for this widget to be used,
 * but also returns the state of the widget space. If your widget is not seen and does
 * not have to be updated it is '0' and you can just return. If it only has
 * to be drawn the state will be `NK_WIDGET_ROM` otherwise you can do both
 * update and draw your widget. The reason for separating is to only draw and
 * update what is actually necessary which is crucial for performance.
 */

enum nk_command_type : int32
{
	NK_COMMAND_NOP,
	NK_COMMAND_SCISSOR,
	NK_COMMAND_LINE,
	NK_COMMAND_CURVE,
	NK_COMMAND_RECT,
	NK_COMMAND_RECT_FILLED,
	NK_COMMAND_RECT_MULTI_COLOR,
	NK_COMMAND_CIRCLE,
	NK_COMMAND_CIRCLE_FILLED,
	NK_COMMAND_ARC,
	NK_COMMAND_ARC_FILLED,
	NK_COMMAND_TRIANGLE,
	NK_COMMAND_TRIANGLE_FILLED,
	NK_COMMAND_POLYGON,
	NK_COMMAND_POLYGON_FILLED,
	NK_COMMAND_POLYLINE,
	NK_COMMAND_TEXT,
	NK_COMMAND_IMAGE,
	NK_COMMAND_CUSTOM
}

 /** command base and header of every command inside the buffer */
[CRepr] struct nk_command
{
	public nk_command_type type;
	public nk_size next;
#if NK_INCLUDE_COMMAND_USERDATA
	public nk_handle userdata;
#endif
}

[CRepr] struct nk_command_scissor
{
	public nk_command header;
	public int16 x, y;
	public uint16 w, h;
}

[CRepr] struct nk_command_line
{
	public nk_command header;
	public uint16 line_thickness;
	public nk_vec2i begin;
	public nk_vec2i end;
	public nk_color color;
}

[CRepr] struct nk_command_curve
{
	public nk_command header;
	public uint16 line_thickness;
	public nk_vec2i begin;
	public nk_vec2i end;
	public nk_vec2i[2] ctrl;
	public nk_color color;
}

[CRepr] struct nk_command_rect
{
	public nk_command header;
	public uint16 rounding;
	public uint16 line_thickness;
	public int16 x, y;
	public uint16 w, h;
	public nk_color color;
}

[CRepr] struct nk_command_rect_filled
{
	public nk_command header;
	public uint16 rounding;
	public int16 x, y;
	public uint16 w, h;
	public nk_color color;
}

[CRepr] struct nk_command_rect_multi_color
{
	public nk_command header;
	public int16 x, y;
	public uint16 w, h;
	public nk_color left;
	public nk_color top;
	public nk_color bottom;
	public nk_color right;
}

[CRepr] struct nk_command_triangle
{
	public nk_command header;
	public uint16 line_thickness;
	public nk_vec2i a;
	public nk_vec2i b;
	public nk_vec2i c;
	public nk_color color;
}

[CRepr] struct nk_command_triangle_filled
{
	public nk_command header;
	public nk_vec2i a;
	public nk_vec2i b;
	public nk_vec2i c;
	public nk_color color;
}

[CRepr] struct nk_command_circle
{
	public nk_command header;
	public int16 x, y;
	public uint16 line_thickness;
	public uint16 w, h;
	public nk_color color;
}

[CRepr] struct nk_command_circle_filled
{
	public nk_command header;
	public int16 x, y;
	public uint16 w, h;
	public nk_color color;
}

[CRepr] struct nk_command_arc
{
	public nk_command header;
	public int16 cx, cy;
	public uint16 r;
	public uint16 line_thickness;
	public float[2] a;
	public nk_color color;
}

[CRepr] struct nk_command_arc_filled
{
	public nk_command header;
	public int16 cx, cy;
	public uint16 r;
	public float[2] a;
	public nk_color color;
}

[CRepr] struct nk_command_polygon
{
	public nk_command header;
	public nk_color color;
	public uint16 line_thickness;
	public uint16 point_count;
	public nk_vec2i[1] points;
}

[CRepr] struct nk_command_polygon_filled
{
	public nk_command header;
	public nk_color color;
	public uint16 point_count;
	public nk_vec2i[1] points;
}

[CRepr] struct nk_command_polyline
{
	public nk_command header;
	public nk_color color;
	public uint16 line_thickness;
	public uint16 point_count;
	public nk_vec2i[1] points;
}

[CRepr] struct nk_command_image
{
	public nk_command header;
	public int16 x, y;
	public uint16 w, h;
	public nk_image img;
	public nk_color col;
}

typealias nk_command_custom_callback = function void(void* canvas, int16 x, int16 y,
	uint16 w, uint16 h, nk_handle callback_data);
[CRepr] struct nk_command_custom
{
	public nk_command header;
	public int16 x, y;
	public uint16 w, h;
	public nk_handle callback_data;
	public nk_command_custom_callback callback;
}

[CRepr] struct nk_command_text
{
	public nk_command header;
	public nk_user_font* font;
	public nk_color background;
	public nk_color foreground;
	public int16 x, y;
	public uint16 w, h;
	public float height;
	public int32 length;
	public char8[2] string;
}

enum nk_command_clipping : int32
{
	NK_CLIPPING_OFF = nk_false,
	NK_CLIPPING_ON = nk_true
}

[CRepr] struct nk_command_buffer
{
	public nk_buffer* @base;
	public nk_rect clip;
	public int32 use_clipping;
	public nk_handle userdata;
	public nk_size begin, end, last;
}

static
{
/** shape outlines */
	[CLink] public static extern void nk_stroke_line(nk_command_buffer* b, float x0, float y0, float x1, float y1, float line_thickness, nk_color);
	[CLink] public static extern void nk_stroke_curve(nk_command_buffer*, float, float, float, float, float, float, float, float, float line_thickness, nk_color);
	[CLink] public static extern void nk_stroke_rect(nk_command_buffer*, nk_rect, float rounding, float line_thickness, nk_color);
	[CLink] public static extern void nk_stroke_circle(nk_command_buffer*, nk_rect, float line_thickness, nk_color);
	[CLink] public static extern void nk_stroke_arc(nk_command_buffer*, float cx, float cy, float radius, float a_min, float a_max, float line_thickness, nk_color);
	[CLink] public static extern void nk_stroke_triangle(nk_command_buffer*, float, float, float, float, float, float, float line_thichness, nk_color);
	[CLink] public static extern void nk_stroke_polyline(nk_command_buffer*, float* points, int32 point_count, float line_thickness, nk_color col);
	[CLink] public static extern void nk_stroke_polygon(nk_command_buffer*, float* points, int32 point_count, float line_thickness, nk_color);

/** filled shades */
	[CLink] public static extern void nk_fill_rect(nk_command_buffer*, nk_rect, float rounding, nk_color);
	[CLink] public static extern void nk_fill_rect_multi_color(nk_command_buffer*, nk_rect, nk_color left, nk_color top, nk_color right, nk_color bottom);
	[CLink] public static extern void nk_fill_circle(nk_command_buffer*, nk_rect, nk_color);
	[CLink] public static extern void nk_fill_arc(nk_command_buffer*, float cx, float cy, float radius, float a_min, float a_max, nk_color);
	[CLink] public static extern void nk_fill_triangle(nk_command_buffer*, float x0, float y0, float x1, float y1, float x2, float y2, nk_color);
	[CLink] public static extern void nk_fill_polygon(nk_command_buffer*, float* points, int32 point_count, nk_color);

/** misc */
	[CLink] public static extern void nk_draw_image(nk_command_buffer*, nk_rect,  nk_image*, nk_color);
	[CLink] public static extern void nk_draw_nine_slice(nk_command_buffer*, nk_rect,  nk_nine_slice*, nk_color);
	[CLink] public static extern void nk_draw_text(nk_command_buffer*, nk_rect, char8* text, int32 len,  nk_user_font*, nk_color, nk_color);
	[CLink] public static extern void nk_push_scissor(nk_command_buffer*, nk_rect);
	[CLink] public static extern void nk_push_custom(nk_command_buffer*, nk_rect, nk_command_custom_callback, nk_handle usr);
}
/* ===============================================================
 *
 *                          INPUT
 *
 * ===============================================================*/
[CRepr] struct nk_mouse_button
{
	public nk_bool down;
	public uint32 clicked;
	public nk_vec2 clicked_pos;
}
[CRepr] struct nk_mouse
{
	public nk_mouse_button[(int)nk_buttons.NK_BUTTON_MAX] buttons;
	public nk_vec2 pos;
#if NK_BUTTON_TRIGGER_ON_RELEASE
	public nk_vec2 down_pos;
#endif
	public nk_vec2 prev;
	public nk_vec2 delta;
	public nk_vec2 scroll_delta;
	public uint8 grab;
	public uint8 grabbed;
	public uint8 ungrab;
}

[CRepr] struct nk_key
{
	public nk_bool down;
	public uint32 clicked;
}
[CRepr] struct nk_keyboard
{
	public nk_key[(int)nk_keys.NK_KEY_MAX] keys;
	public char8[NK_INPUT_MAX] text;
	public int32 text_len;
}

[CRepr] struct nk_input
{
	public nk_keyboard keyboard;
	public nk_mouse mouse;
}

static
{
	[CLink] public static extern nk_bool nk_input_has_mouse_click(nk_input*, nk_buttons);
	[CLink] public static extern nk_bool nk_input_has_mouse_click_in_rect(nk_input*, nk_buttons, nk_rect);
	[CLink] public static extern nk_bool nk_input_has_mouse_click_in_button_rect(nk_input*, nk_buttons, nk_rect);
	[CLink] public static extern nk_bool nk_input_has_mouse_click_down_in_rect(nk_input*, nk_buttons, nk_rect, nk_bool down);
	[CLink] public static extern nk_bool nk_input_is_mouse_click_in_rect(nk_input*, nk_buttons, nk_rect);
	[CLink] public static extern nk_bool nk_input_is_mouse_click_down_in_rect(nk_input* i, nk_buttons id, nk_rect b, nk_bool down);
	[CLink] public static extern nk_bool nk_input_any_mouse_click_in_rect(nk_input*, nk_rect);
	[CLink] public static extern nk_bool nk_input_is_mouse_prev_hovering_rect(nk_input*, nk_rect);
	[CLink] public static extern nk_bool nk_input_is_mouse_hovering_rect(nk_input*, nk_rect);
	[CLink] public static extern nk_bool nk_input_is_mouse_moved(nk_input*);
	[CLink] public static extern nk_bool nk_input_mouse_clicked(nk_input*, nk_buttons, nk_rect);
	[CLink] public static extern nk_bool nk_input_is_mouse_down(nk_input*, nk_buttons);
	[CLink] public static extern nk_bool nk_input_is_mouse_pressed(nk_input*, nk_buttons);
	[CLink] public static extern nk_bool nk_input_is_mouse_released(nk_input*, nk_buttons);
	[CLink] public static extern nk_bool nk_input_is_key_pressed(nk_input*, nk_keys);
	[CLink] public static extern nk_bool nk_input_is_key_released(nk_input*, nk_keys);
	[CLink] public static extern nk_bool nk_input_is_key_down(nk_input*, nk_keys);
}
	/* ===============================================================
	 *
	 *                          DRAW LIST
	 *
	 * ===============================================================*/
#if NK_INCLUDE_VERTEX_BUFFER_OUTPUT
	/**
	 * \page "Draw List"
	 * The optional vertex buffer draw list provides a 2D drawing context
	 * with antialiasing functionality which takes basic filled or outlined shapes
	 * or a path and outputs vertexes, elements and draw commands.
	 * The actual draw list API is not required to be used directly while using this
	 * library since converting the default library draw command output is done by
	 * just calling `nk_convert` but I decided to still make this library accessible
	 * since it can be useful.
	 *
	 * The draw list is based on a path buffering and polygon and polyline
	 * rendering API which allows a lot of ways to draw 2D content to screen.
	 * In fact it is probably more powerful than needed but allows even more crazy
	 * things than this library provides by default.
	 */

#if NK_UINT_DRAW_INDEX
	typealias nk_draw_index =  nk_uint ;
#else
typealias nk_draw_index =  nk_ushort;
#endif
enum nk_draw_list_stroke : int32
{
	NK_STROKE_OPEN = nk_false, /***< build up path has no connection back to the beginning */
	NK_STROKE_CLOSED = nk_true /***< build up path has a connection back to the beginning */
}

enum nk_draw_vertex_layout_attribute : int32
{
	NK_VERTEX_POSITION,
	NK_VERTEX_COLOR,
	NK_VERTEX_TEXCOORD,
	NK_VERTEX_ATTRIBUTE_COUNT
}

[AllowDuplicates]
enum nk_draw_vertex_layout_format : int32
{
	NK_FORMAT_SCHAR,
	NK_FORMAT_SSHORT,
	NK_FORMAT_SINT,
	NK_FORMAT_UCHAR,
	NK_FORMAT_USHORT,
	NK_FORMAT_UINT,
	NK_FORMAT_FLOAT,
	NK_FORMAT_DOUBLE,

	NK_FORMAT_COLOR_BEGIN,
	NK_FORMAT_R8G8B8 = NK_FORMAT_COLOR_BEGIN,
	NK_FORMAT_R16G15B16,
	NK_FORMAT_R32G32B32,

	NK_FORMAT_R8G8B8A8,
	NK_FORMAT_B8G8R8A8,
	NK_FORMAT_R16G15B16A16,
	NK_FORMAT_R32G32B32A32,
	NK_FORMAT_R32G32B32A32_FLOAT,
	NK_FORMAT_R32G32B32A32_DOUBLE,

	NK_FORMAT_RGB32,
	NK_FORMAT_RGBA32,
	NK_FORMAT_COLOR_END = NK_FORMAT_RGBA32,
	NK_FORMAT_COUNT
}

//#define NK_VERTEX_LAYOUT_END NK_VERTEX_ATTRIBUTE_COUNT,NK_FORMAT_COUNT,0
[CRepr] struct nk_draw_vertex_layout_element
{
	public nk_draw_vertex_layout_attribute attribute;
	public nk_draw_vertex_layout_format format;
	public nk_size offset;
}

[CRepr] struct nk_draw_command
{
	public uint32 elem_count; /**< number of elements in the current draw batch */
	public nk_rect clip_rect; /**< current screen clipping rectangle */
	public nk_handle texture; /**< current texture to set */
#if NK_INCLUDE_COMMAND_USERDATA
	public nk_handle userdata;
#endif
}

[CRepr] struct nk_draw_list
{
	public nk_rect clip_rect;
	public nk_vec2[12] circle_vtx;
	public nk_convert_config config;

	public nk_buffer* buffer;
	public nk_buffer* vertices;
	public nk_buffer* elements;

	public uint32 element_count;
	public uint32 vertex_count;
	public uint32 cmd_count;
	public nk_size cmd_offset;

	public uint32 path_count;
	public uint32 path_offset;

	public nk_anti_aliasing line_AA;
	public nk_anti_aliasing shape_AA;

#if NK_INCLUDE_COMMAND_USERDATA
	public nk_handle userdata;
#endif
}

static
{
/* draw list */
	[CLink] public static extern void nk_draw_list_init(nk_draw_list*);
	[CLink] public static extern void nk_draw_list_setup(nk_draw_list*,  nk_convert_config*, nk_buffer* cmds, nk_buffer* vertices, nk_buffer* elements, nk_anti_aliasing line_aa, nk_anti_aliasing shape_aa);

/* drawing */
//#define nk_draw_list_foreach(cmd, can, b) for((cmd)=nk__draw_list_begin(can, b); (cmd)!=0; (cmd)=nk__draw_list_next(cmd, b, can))
	[CLink] public static extern  nk_draw_command* nk__draw_list_begin(nk_draw_list*,  nk_buffer*);
	[CLink] public static extern  nk_draw_command* nk__draw_list_next(nk_draw_command*,  nk_buffer*,  nk_draw_list*);
	[CLink] public static extern  nk_draw_command* nk__draw_list_end(nk_draw_list*,  nk_buffer*);

/* path */
	[CLink] public static extern void nk_draw_list_path_clear(nk_draw_list*);
	[CLink] public static extern void nk_draw_list_path_line_to(nk_draw_list*, nk_vec2 pos);
	[CLink] public static extern void nk_draw_list_path_arc_to_fast(nk_draw_list*, nk_vec2 center, float radius, int32 a_min, int32 a_max);
	[CLink] public static extern void nk_draw_list_path_arc_to(nk_draw_list*, nk_vec2 center, float radius, float a_min, float a_max, uint32 segments);
	[CLink] public static extern void nk_draw_list_path_rect_to(nk_draw_list*, nk_vec2 a, nk_vec2 b, float rounding);
	[CLink] public static extern void nk_draw_list_path_curve_to(nk_draw_list*, nk_vec2 p2, nk_vec2 p3, nk_vec2 p4, uint32 num_segments);
	[CLink] public static extern void nk_draw_list_path_fill(nk_draw_list*, nk_color);
	[CLink] public static extern void nk_draw_list_path_stroke(nk_draw_list*, nk_color, nk_draw_list_stroke closed, float thickness);

/* stroke */
	[CLink] public static extern void nk_draw_list_stroke_line(nk_draw_list*, nk_vec2 a, nk_vec2 b, nk_color, float thickness);
	[CLink] public static extern void nk_draw_list_stroke_rect(nk_draw_list*, nk_rect rect, nk_color, float rounding, float thickness);
	[CLink] public static extern void nk_draw_list_stroke_triangle(nk_draw_list*, nk_vec2 a, nk_vec2 b, nk_vec2 c, nk_color, float thickness);
	[CLink] public static extern void nk_draw_list_stroke_circle(nk_draw_list*, nk_vec2 center, float radius, nk_color, uint32 segs, float thickness);
	[CLink] public static extern void nk_draw_list_stroke_curve(nk_draw_list*, nk_vec2 p0, nk_vec2 cp0, nk_vec2 cp1, nk_vec2 p1, nk_color, uint32 segments, float thickness);
	[CLink] public static extern void nk_draw_list_stroke_poly_line(nk_draw_list*,  nk_vec2* pnts, uint32 cnt, nk_color, nk_draw_list_stroke, float thickness, nk_anti_aliasing);

/* fill */
	[CLink] public static extern void nk_draw_list_fill_rect(nk_draw_list*, nk_rect rect, nk_color, float rounding);
	[CLink] public static extern void nk_draw_list_fill_rect_multi_color(nk_draw_list*, nk_rect rect, nk_color left,  nk_color top, nk_color right, nk_color bottom);
	[CLink] public static extern void nk_draw_list_fill_triangle(nk_draw_list*, nk_vec2 a, nk_vec2 b, nk_vec2 c, nk_color);
	[CLink] public static extern void nk_draw_list_fill_circle(nk_draw_list*, nk_vec2 center, float radius, nk_color col, uint32 segs);
	[CLink] public static extern void nk_draw_list_fill_poly_convex(nk_draw_list*,  nk_vec2* points, uint32 count, nk_color, nk_anti_aliasing);

/* misc */
	[CLink] public static extern void nk_draw_list_add_image(nk_draw_list*, nk_image texture, nk_rect rect, nk_color);
	[CLink] public static extern void nk_draw_list_add_text(nk_draw_list*,  nk_user_font*, nk_rect, char8* text, int32 len, float font_height, nk_color);
#if NK_INCLUDE_COMMAND_USERDATA
	[CLink] public static extern void nk_draw_list_push_userdata(nk_draw_list*, nk_handle userdata);
#endif

}
#endif

/* ===============================================================
 *
 *                          GUI
 *
 * ===============================================================*/
enum nk_style_item_type : int32
{
	NK_STYLE_ITEM_COLOR,
	NK_STYLE_ITEM_IMAGE,
	NK_STYLE_ITEM_NINE_SLICE
}

[CRepr, Union] struct nk_style_item_data
{
	public nk_color color;
	public nk_image image;
	public nk_nine_slice slice;
}

[CRepr] struct nk_style_item
{
	public nk_style_item_type type;
	public nk_style_item_data data;
}

[CRepr] struct nk_style_text
{
	public nk_color color;
	public nk_vec2 padding;
	public float color_factor;
	public float disabled_factor;
}

[CRepr] struct nk_style_button
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;
	public float color_factor_background;

	/* text */
	public nk_color text_background;
	public nk_color text_normal;
	public nk_color text_hover;
	public nk_color text_active;
	public nk_flags text_alignment;
	public float color_factor_text;

	/* properties */
	public float border;
	public float rounding;
	public nk_vec2 padding;
	public nk_vec2 image_padding;
	public nk_vec2 touch_padding;
	public float disabled_factor;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle userdata) draw_begin;
	public function void(nk_command_buffer*, nk_handle userdata) draw_end;
}

[CRepr] struct nk_style_toggle
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* cursor */
	public nk_style_item cursor_normal;
	public nk_style_item cursor_hover;

	/* text */
	public nk_color text_normal;
	public nk_color text_hover;
	public nk_color text_active;
	public nk_color text_background;
	public nk_flags text_alignment;

	/* properties */
	public nk_vec2 padding;
	public nk_vec2 touch_padding;
	public float spacing;
	public float border;
	public float color_factor;
	public float disabled_factor;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_selectable
{
	/* background (inactive) */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item pressed;

	/* background (active) */
	public nk_style_item normal_active;
	public nk_style_item hover_active;
	public nk_style_item pressed_active;

	/* text color (inactive) */
	public nk_color text_normal;
	public nk_color text_hover;
	public nk_color text_pressed;

	/* text color (active) */
	public nk_color text_normal_active;
	public nk_color text_hover_active;
	public nk_color text_pressed_active;
	public nk_color text_background;
	public nk_flags text_alignment;

	/* properties */
	public float rounding;
	public nk_vec2 padding;
	public nk_vec2 touch_padding;
	public nk_vec2 image_padding;
	public float color_factor;
	public float disabled_factor;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_slider
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* background bar */
	public nk_color bar_normal;
	public nk_color bar_hover;
	public nk_color bar_active;
	public nk_color bar_filled;

	/* cursor */
	public nk_style_item cursor_normal;
	public nk_style_item cursor_hover;
	public nk_style_item cursor_active;

	/* properties */
	public float border;
	public float rounding;
	public float bar_height;
	public nk_vec2 padding;
	public nk_vec2 spacing;
	public nk_vec2 cursor_size;
	public float color_factor;
	public float disabled_factor;

	/* optional buttons */
	public int32 show_buttons;
	public nk_style_button inc_button;
	public nk_style_button dec_button;
	public nk_symbol_type inc_symbol;
	public nk_symbol_type dec_symbol;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_knob
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* knob */
	public nk_color knob_normal;
	public nk_color knob_hover;
	public nk_color knob_active;
	public nk_color knob_border_color;

	/* cursor */
	public nk_color cursor_normal;
	public nk_color cursor_hover;
	public nk_color cursor_active;

	/* properties */
	public float border;
	public float knob_border;
	public nk_vec2 padding;
	public nk_vec2 spacing;
	public float cursor_width;
	public float color_factor;
	public float disabled_factor;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_progress
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* cursor */
	public nk_style_item cursor_normal;
	public nk_style_item cursor_hover;
	public nk_style_item cursor_active;
	public nk_color cursor_border_color;

	/* properties */
	public float rounding;
	public float border;
	public float cursor_border;
	public float cursor_rounding;
	public nk_vec2 padding;
	public float color_factor;
	public float disabled_factor;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_scrollbar
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* cursor */
	public nk_style_item cursor_normal;
	public nk_style_item cursor_hover;
	public nk_style_item cursor_active;
	public nk_color cursor_border_color;

	/* properties */
	public float border;
	public float rounding;
	public float border_cursor;
	public float rounding_cursor;
	public nk_vec2 padding;
	public float color_factor;
	public float disabled_factor;

	/* optional buttons */
	public int32 show_buttons;
	public nk_style_button inc_button;
	public nk_style_button dec_button;
	public nk_symbol_type inc_symbol;
	public nk_symbol_type dec_symbol;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_edit
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;
	public nk_style_scrollbar scrollbar;

	/* cursor  */
	public nk_color cursor_normal;
	public nk_color cursor_hover;
	public nk_color cursor_text_normal;
	public nk_color cursor_text_hover;

	/* text (unselected) */
	public nk_color text_normal;
	public nk_color text_hover;
	public nk_color text_active;

	/* text (selected) */
	public nk_color selected_normal;
	public nk_color selected_hover;
	public nk_color selected_text_normal;
	public nk_color selected_text_hover;

	/* properties */
	public float border;
	public float rounding;
	public float cursor_size;
	public nk_vec2 scrollbar_size;
	public nk_vec2 padding;
	public float row_padding;
	public float color_factor;
	public float disabled_factor;
}

[CRepr] struct nk_style_property
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* text */
	public nk_color label_normal;
	public nk_color label_hover;
	public nk_color label_active;

	/* symbols */
	public nk_symbol_type sym_left;
	public nk_symbol_type sym_right;

	/* properties */
	public float border;
	public float rounding;
	public nk_vec2 padding;
	public float color_factor;
	public float disabled_factor;

	public nk_style_edit edit;
	public nk_style_button inc_button;
	public nk_style_button dec_button;

	/* optional user callbacks */
	public nk_handle userdata;
	public function void(nk_command_buffer*, nk_handle) draw_begin;
	public function void(nk_command_buffer*, nk_handle) draw_end;
}

[CRepr] struct nk_style_chart
{
	/* colors */
	public nk_style_item background;
	public nk_color border_color;
	public nk_color selected_color;
	public nk_color color;

	/* properties */
	public float border;
	public float rounding;
	public nk_vec2 padding;
	public float color_factor;
	public float disabled_factor;
	public nk_bool show_markers;
}

[CRepr] struct nk_style_combo
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;
	public nk_color border_color;

	/* label */
	public nk_color label_normal;
	public nk_color label_hover;
	public nk_color label_active;

	/* symbol */
	public nk_color symbol_normal;
	public nk_color symbol_hover;
	public nk_color symbol_active;

	/* button */
	public nk_style_button button;
	public nk_symbol_type sym_normal;
	public nk_symbol_type sym_hover;
	public nk_symbol_type sym_active;

	/* properties */
	public float border;
	public float rounding;
	public nk_vec2 content_padding;
	public nk_vec2 button_padding;
	public nk_vec2 spacing;
	public float color_factor;
	public float disabled_factor;
}

[CRepr] struct nk_style_tab
{
	/* background */
	public nk_style_item background;
	public nk_color border_color;
	public nk_color text;

	/* button */
	public nk_style_button tab_maximize_button;
	public nk_style_button tab_minimize_button;
	public nk_style_button node_maximize_button;
	public nk_style_button node_minimize_button;
	public nk_symbol_type sym_minimize;
	public nk_symbol_type sym_maximize;

	/* properties */
	public float border;
	public float rounding;
	public float indent;
	public nk_vec2 padding;
	public nk_vec2 spacing;
	public float color_factor;
	public float disabled_factor;
}

enum nk_style_header_align : int32
{
	NK_HEADER_LEFT,
	NK_HEADER_RIGHT
}
[CRepr] struct nk_style_window_header
{
	/* background */
	public nk_style_item normal;
	public nk_style_item hover;
	public nk_style_item active;

	/* button */
	public nk_style_button close_button;
	public nk_style_button minimize_button;
	public nk_symbol_type close_symbol;
	public nk_symbol_type minimize_symbol;
	public nk_symbol_type maximize_symbol;

	/* title */
	public nk_color label_normal;
	public nk_color label_hover;
	public nk_color label_active;

	/* properties */
	public nk_style_header_align align;
	public nk_vec2 padding;
	public nk_vec2 label_padding;
	public nk_vec2 spacing;
}

[CRepr] struct nk_style_window
{
	public nk_style_window_header header;
	public nk_style_item fixed_background;
	public nk_color background;

	public nk_color border_color;
	public nk_color popup_border_color;
	public nk_color combo_border_color;
	public nk_color contextual_border_color;
	public nk_color menu_border_color;
	public nk_color group_border_color;
	public nk_color tooltip_border_color;
	public nk_style_item scaler;

	public float border;
	public float combo_border;
	public float contextual_border;
	public float menu_border;
	public float group_border;
	public float tooltip_border;
	public float popup_border;
	public float min_row_height_padding;

	public float rounding;
	public nk_vec2 spacing;
	public nk_vec2 scrollbar_size;
	public nk_vec2 min_size;

	public nk_vec2 padding;
	public nk_vec2 group_padding;
	public nk_vec2 popup_padding;
	public nk_vec2 combo_padding;
	public nk_vec2 contextual_padding;
	public nk_vec2 menu_padding;
	public nk_vec2 tooltip_padding;
}

[CRepr] struct nk_style
{
	public nk_user_font* font;
	public nk_cursor*[(int)nk_style_cursor.NK_CURSOR_COUNT] cursors;
	public nk_cursor* cursor_active;
	public nk_cursor* cursor_last;
	public int32 cursor_visible;

	public nk_style_text text;
	public nk_style_button button;
	public nk_style_button contextual_button;
	public nk_style_button menu_button;
	public nk_style_toggle option;
	public nk_style_toggle checkbox;
	public nk_style_selectable selectable;
	public nk_style_slider slider;
	public nk_style_knob knob;
	public nk_style_progress progress;
	public nk_style_property property;
	public nk_style_edit edit;
	public nk_style_chart chart;
	public nk_style_scrollbar scrollh;
	public nk_style_scrollbar scrollv;
	public nk_style_tab tab;
	public nk_style_combo combo;
	public nk_style_window window;
}

static
{
	[CLink] public static extern nk_style_item nk_style_item_color(nk_color);
	[CLink] public static extern nk_style_item nk_style_item_image(nk_image img);
	[CLink] public static extern nk_style_item nk_style_item_nine_slice(nk_nine_slice slice);
	[CLink] public static extern nk_style_item nk_style_item_hide(void);
}
	/*==============================================================
	 *                          PANEL
	 * =============================================================*/

static
{
	public const uint32 NK_MAX_LAYOUT_ROW_TEMPLATE_COLUMNS = 16;
	public const uint32 NK_CHART_MAX_SLOT = 4;
}

enum nk_panel_type : int32
{
	NK_PANEL_NONE       = 0,
	NK_PANEL_WINDOW     = NK_FLAG!(0),
	NK_PANEL_GROUP      = NK_FLAG!(1),
	NK_PANEL_POPUP      = NK_FLAG!(2),
	NK_PANEL_CONTEXTUAL = NK_FLAG!(4),
	NK_PANEL_COMBO      = NK_FLAG!(5),
	NK_PANEL_MENU       = NK_FLAG!(6),
	NK_PANEL_TOOLTIP    = NK_FLAG!(7)
}
enum nk_panel_set : int32
{
	NK_PANEL_SET_NONBLOCK = nk_panel_type.NK_PANEL_CONTEXTUAL | nk_panel_type.NK_PANEL_COMBO | nk_panel_type.NK_PANEL_MENU | nk_panel_type.NK_PANEL_TOOLTIP,
	NK_PANEL_SET_POPUP = .NK_PANEL_SET_NONBLOCK | (.)nk_panel_type.NK_PANEL_POPUP,
	NK_PANEL_SET_SUB = .NK_PANEL_SET_POPUP | (.)nk_panel_type.NK_PANEL_GROUP
}

[CRepr] struct nk_chart_slot
{
	public nk_chart_type type;
	public nk_color color;
	public nk_color highlight;
	public float min, max, range;
	public int32 count;
	public nk_vec2 last;
	public int32 index;
	public nk_bool show_markers;
}

[CRepr] struct nk_chart
{
	public int32 slot;
	public float x, y, w, h;
	public nk_chart_slot[NK_CHART_MAX_SLOT] slots;
}

enum nk_panel_row_layout_type : int32
{
	NK_LAYOUT_DYNAMIC_FIXED = 0,
	NK_LAYOUT_DYNAMIC_ROW,
	NK_LAYOUT_DYNAMIC_FREE,
	NK_LAYOUT_DYNAMIC,
	NK_LAYOUT_STATIC_FIXED,
	NK_LAYOUT_STATIC_ROW,
	NK_LAYOUT_STATIC_FREE,
	NK_LAYOUT_STATIC,
	NK_LAYOUT_TEMPLATE,
	NK_LAYOUT_COUNT
}
[CRepr] struct nk_row_layout
{
	public nk_panel_row_layout_type type;
	public int32 index;
	public float height;
	public float min_height;
	public int32 columns;
	public float* ratio;
	public float item_width;
	public float item_height;
	public float item_offset;
	public float filled;
	public nk_rect item;
	public int32 tree_depth;
	public float[NK_MAX_LAYOUT_ROW_TEMPLATE_COLUMNS] templates;
}

[CRepr] struct nk_popup_buffer
{
	public nk_size begin;
	public nk_size parent;
	public nk_size last;
	public nk_size end;
	public nk_bool active;
}

[CRepr] struct nk_menu_state
{
	public float x, y, w, h;
	public nk_scroll offset;
}

[CRepr] struct nk_panel
{
	public nk_panel_type type;
	public nk_flags flags;
	public nk_rect bounds;
	public nk_uint* offset_x;
	public nk_uint* offset_y;
	public float at_x, at_y, max_x;
	public float footer_height;
	public float header_height;
	public float border;
	public uint32 has_scrolling;
	public nk_rect clip;
	public nk_menu_state menu;
	public nk_row_layout row;
	public nk_chart chart;
	public nk_command_buffer* buffer;
	public nk_panel* parent;
}

/*==============================================================
 *                          WINDOW
 * =============================================================*/
static
{
	public const uint32 NK_WINDOW_MAX_NAME = 64;
}
	//[CRepr]struct nk_table;
[AllowDuplicates]
enum nk_window_flags : int32
{
	NK_WINDOW_PRIVATE       = NK_FLAG!(11),
	NK_WINDOW_DYNAMIC       = NK_WINDOW_PRIVATE, /**< special window type growing up in height while being filled to a certain maximum height */
	NK_WINDOW_ROM           = NK_FLAG!(12), /**< sets window widgets into a read only mode and does not allow input changes */
	NK_WINDOW_NOT_INTERACTIVE = .NK_WINDOW_ROM | (.)nk_panel_flags.NK_WINDOW_NO_INPUT, /**< prevents all interaction caused by input to either window or widgets inside */
	NK_WINDOW_HIDDEN        = NK_FLAG!(13), /**< Hides window and stops any window interaction and drawing */
	NK_WINDOW_CLOSED        = NK_FLAG!(14), /**< Directly closes and frees the window at the end of the frame */
	NK_WINDOW_MINIMIZED     = NK_FLAG!(15), /**< marks the window as minimized */
	NK_WINDOW_REMOVE_ROM    = NK_FLAG!(16) /**< Removes read only mode at the end of the window */
}

[CRepr] struct nk_popup_state
{
	public nk_window* win;
	public nk_panel_type type;
	public nk_popup_buffer buf;
	public nk_hash name;
	public nk_bool active;
	public uint32 combo_count;
	public uint32 con_count, con_old;
	public uint32 active_con;
	public nk_rect header;
}

[CRepr] struct nk_edit_state
{
	public nk_hash name;
	public uint32 seq;
	public uint32 old;
	public int32 active, prev;
	public int32 cursor;
	public int32 sel_start;
	public int32 sel_end;
	public nk_scroll scrollbar;
	public uint8 mode;
	public uint8 single_line;
}

[CRepr] struct nk_property_state
{
	public int32 active, prev;
	public char8[NK_MAX_NUMBER_BUFFER] buffer;
	public int32 length;
	public int32 cursor;
	public int32 select_start;
	public int32 select_end;
	public nk_hash name;
	public uint32 seq;
	public uint32 old;
	public int32 state;
}

[CRepr] struct nk_window
{
	public uint32 seq;
	public nk_hash name;
	public char8[NK_WINDOW_MAX_NAME] name_string;
	public nk_flags flags;

	public nk_rect bounds;
	public nk_scroll scrollbar;
	public nk_command_buffer buffer;
	public nk_panel* layout;
	public float scrollbar_hiding_timer;

	/* persistent widget state */
	public nk_property_state property;
	public nk_popup_state popup;
	public nk_edit_state edit;
	public uint32 scrolled;
	public nk_bool widgets_disabled;

	public nk_table* tables;
	public uint32 table_count;

	/* window list hooks */
	public nk_window* next;
	public nk_window* prev;
	public nk_window* parent;
}

/*==============================================================
 *                          STACK
 * =============================================================*/
/**
 * \page Stack
 * The style modifier stack can be used to temporarily change a
 * property inside `nk_style`. For example if you want a special
 * red button you can temporarily push the old button color onto a stack
 * draw the button with a red color and then you just pop the old color
 * back from the stack:
 *
 *     nk_style_push_style_item(ctx, &ctx->style.button.normal, nk_style_item_color(nk_rgb(255,0,0)));
 *     nk_style_push_style_item(ctx, &ctx->style.button.hover, nk_style_item_color(nk_rgb(255,0,0)));
 *     nk_style_push_style_item(ctx, &ctx->style.button.active, nk_style_item_color(nk_rgb(255,0,0)));
 *     nk_style_push_vec2(ctx, &cx->style.button.padding, nk_vec2(2,2));
 *
 *     nk_button(...);
 *
 *     nk_style_pop_style_item(ctx);
 *     nk_style_pop_style_item(ctx);
 *     nk_style_pop_style_item(ctx);
 *     nk_style_pop_vec2(ctx);
 *
 * Nuklear has a stack for style_items, float properties, vector properties,
 * flags, colors, fonts and for button_behavior. Each has it's own fixed size stack
 * which can be changed at compile time.
 */

static
{
	public const uint32 NK_BUTTON_BEHAVIOR_STACK_SIZE = 8;

	public const uint32 NK_FONT_STACK_SIZE = 8;
	public const uint32 NK_STYLE_ITEM_STACK_SIZE = 16;
	public const uint32 NK_FLOAT_STACK_SIZE = 32;
	public const uint32 NK_VECTOR_STACK_SIZE = 16;
	public const uint32 NK_FLAGS_STACK_SIZE = 32;
	public const uint32 NK_COLOR_STACK_SIZE = 32;
}
	/*#define NK_CONFIGURATION_STACK_TYPE(prefix, name, type)\
		struct nk_config_stack_##name##_element {\
			prefix##_##type *address;\
			prefix##_##type old_value;\
		}
#define NK_CONFIG_STACK(type,size)\
		struct nk_config_stack_##type {\
			int32 head;\
			struct nk_config_stack_##type##_element elements[size];\
		}*/

typealias nk_float = float;
	/*NK_CONFIGURATION_STACK_TYPE(struct nk, style_item, style_item);
	NK_CONFIGURATION_STACK_TYPE(nk ,float, float);
	NK_CONFIGURATION_STACK_TYPE(struct nk, vec2, vec2);
	NK_CONFIGURATION_STACK_TYPE(nk ,flags, flags);
	NK_CONFIGURATION_STACK_TYPE(struct nk, color, color);
	NK_CONFIGURATION_STACK_TYPE( nk, user_font, user_font*);
	NK_CONFIGURATION_STACK_TYPE(enum nk, button_behavior, button_behavior);*/
		// NK_CONFIGURATION_STACK_TYPE(struct nk, style_item, style_item);
[CRepr] struct nk_config_stack_style_item_element
{
	public nk_style_item* address;
	public nk_style_item old_value;
}

// NK_CONFIGURATION_STACK_TYPE(nk, float, float);
[CRepr] struct nk_config_stack_float_element
{
	public nk_float* address;
	public nk_float old_value;
}

// NK_CONFIGURATION_STACK_TYPE(struct nk, vec2, vec2);
[CRepr] struct nk_config_stack_vec2_element
{
	public nk_vec2* address;
	public nk_vec2 old_value;
}

// NK_CONFIGURATION_STACK_TYPE(nk, flags, flags);
[CRepr] struct nk_config_stack_flags_element
{
	public nk_flags* address;
	public nk_flags old_value;
}

// NK_CONFIGURATION_STACK_TYPE(struct nk, color, color);
[CRepr] struct nk_config_stack_color_element
{
	public nk_color* address;
	public nk_color old_value;
}

// NK_CONFIGURATION_STACK_TYPE(nk, user_font, user_font*);
[CRepr] struct nk_config_stack_user_font_element
{
	public nk_user_font** address; // pointer to pointer
	public nk_user_font* old_value;
}

// NK_CONFIGURATION_STACK_TYPE(enum nk, button_behavior, button_behavior);
[CRepr] struct nk_config_stack_button_behavior_element
{
	public nk_button_behavior* address;
	public nk_button_behavior old_value;
}

/*NK_CONFIG_STACK(style_item, NK_STYLE_ITEM_STACK_SIZE);
NK_CONFIG_STACK(float, NK_FLOAT_STACK_SIZE);
NK_CONFIG_STACK(vec2, NK_VECTOR_STACK_SIZE);
NK_CONFIG_STACK(flags, NK_FLAGS_STACK_SIZE);
NK_CONFIG_STACK(color, NK_COLOR_STACK_SIZE);
NK_CONFIG_STACK(user_font, NK_FONT_STACK_SIZE);
NK_CONFIG_STACK(button_behavior, NK_BUTTON_BEHAVIOR_STACK_SIZE);*/

// NK_CONFIG_STACK(style_item, NK_STYLE_ITEM_STACK_SIZE);
[CRepr] struct nk_config_stack_style_item
{
	public int32 head;
	public nk_config_stack_style_item_element[NK_STYLE_ITEM_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(float, NK_FLOAT_STACK_SIZE);
[CRepr] struct nk_config_stack_float
{
	public int32 head;
	public nk_config_stack_float_element[NK_FLOAT_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(vec2, NK_VECTOR_STACK_SIZE);
[CRepr] struct nk_config_stack_vec2
{
	public int32 head;
	public nk_config_stack_vec2_element[NK_VECTOR_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(flags, NK_FLAGS_STACK_SIZE);
[CRepr] struct nk_config_stack_flags
{
	public int32 head;
	public nk_config_stack_flags_element[NK_FLAGS_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(color, NK_COLOR_STACK_SIZE);
[CRepr] struct nk_config_stack_color
{
	public int32 head;
	public nk_config_stack_color_element[NK_COLOR_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(user_font, NK_FONT_STACK_SIZE);
[CRepr] struct nk_config_stack_user_font
{
	public int32 head;
	public nk_config_stack_user_font_element[NK_FONT_STACK_SIZE] elements;
}

// NK_CONFIG_STACK(button_behavior, NK_BUTTON_BEHAVIOR_STACK_SIZE);
[CRepr] struct nk_config_stack_button_behavior
{
	public int32 head;
	public nk_config_stack_button_behavior_element[NK_BUTTON_BEHAVIOR_STACK_SIZE] elements;
}

[CRepr] struct nk_configuration_stacks
{
	public nk_config_stack_style_item style_items;
	public nk_config_stack_float floats;
	public nk_config_stack_vec2 vectors;
	public nk_config_stack_flags flags;
	public nk_config_stack_color colors;
	public nk_config_stack_user_font fonts;
	public nk_config_stack_button_behavior button_behaviors;
}

/*==============================================================
 *                          CONTEXT
 * =============================================================*/
static
{
	public const int32 NK_VALUE_PAGE_CAPACITY = (((NK_MAX<int>(sizeof(nk_window), sizeof(nk_panel)) / sizeof(nk_uint))) / 2);

}
[CRepr] struct nk_table
{
	public uint32 seq;
	public uint32 size;
	public nk_hash[NK_VALUE_PAGE_CAPACITY] keys;
	public nk_uint[NK_VALUE_PAGE_CAPACITY] values;
	public nk_table* next;
	public nk_table* prev;
}

[CRepr, Union] struct nk_page_data
{
	public nk_table tbl;
	public nk_panel pan;
	public nk_window win;
}

[CRepr] struct nk_page_element
{
	public nk_page_data data;
	public nk_page_element* next;
	public nk_page_element* prev;
}

[CRepr] struct nk_page
{
	public uint32 size;
	public nk_page* next;
	public nk_page_element[1] win;
}

[CRepr] struct nk_pool
{
	public nk_allocator alloc;
	public nk_allocation_type type;
	public uint32 page_count;
	public nk_page* pages;
	public nk_page_element* freelist;
	public uint32 capacity;
	public nk_size size;
	public nk_size cap;
}

[CRepr] struct nk_context
{
/* public: can be accessed freely */
	public nk_input input;
	public nk_style style;
	public nk_buffer memory;
	public nk_clipboard clip;
	public nk_flags last_widget_state;
	public nk_button_behavior button_behavior;
	public nk_configuration_stacks stacks;
	public float delta_time_seconds;

/* private:
	should only be accessed if you
	know what you are doing */
#if NK_INCLUDE_VERTEX_BUFFER_OUTPUT
	public nk_draw_list draw_list;
#endif
#if NK_INCLUDE_COMMAND_USERDATA
	public nk_handle userdata;
#endif
	/** text editor objects are quite big because of an internal
	 * undo/redo stack. Therefore it does not make sense to have one for
	 * each window for temporary use cases, so I only provide *one* instance
	 * for all windows. This works because the content is cleared anyway */
	public nk_text_edit text_edit;
	/** draw buffer used for overlay drawing operation like cursor */
	public nk_command_buffer overlay;

	/** windows */
	public int32 build;
	public int32 use_pool;
	public nk_pool pool;
	public nk_window* begin;
	public nk_window* end;
	public nk_window* active;
	public nk_window* current;
	public nk_page_element* freelist;
	public uint32 count;
	public uint32 seq;
}

static
{
/* ==============================================================
 *                          MATH
 * =============================================================== */
	public const float NK_PI = 3.141592654f;
	public const float NK_PI_HALF = 1.570796326f;
//public const uint32 NK_UTF_INVALID =0xFFFD;
	public const uint32 NK_MAX_FLOAT_PRECISION = 2;
}

/*#define NK_UNUSED(x) ((void)(x))
#define NK_SATURATE(x) (NK_MAX(0, NK_MIN(1.0f, x)))
#define NK_LEN(a) (sizeof(a)/sizeof(a)[0])
#define NK_ABS(a) (((a) < 0) ? -(a) : (a))
#define NK_BETWEEN(x, a, b) ((a) <= (x) && (x) < (b))
#define NK_INBOX(px, py, x, y, w, h)\
	(NK_BETWEEN(px,x,x+w) && NK_BETWEEN(py,y,y+h))
#define NK_INTERSECT(x0, y0, w0, h0, x1, y1, w1, h1) \
	((x1 < (x0 + w0)) && (x0 < (x1 + w1)) && \
	(y1 < (y0 + h0)) && (y0 < (y1 + h1)))
#define NK_CONTAINS(x, y, w, h, bx, by, bw, bh)\
	(NK_INBOX(x,y, bx, by, bw, bh) && NK_INBOX(x+w,y+h, bx, by, bw, bh))

#define nk_vec2_sub(a, b) nk_vec2((a).x - (b).x, (a).y - (b).y)
#define nk_vec2_add(a, b) nk_vec2((a).x + (b).x, (a).y + (b).y)
#define nk_vec2_len_sqr(a) ((a).x*(a).x+(a).y*(a).y)
#define nk_vec2_muls(a, t) nk_vec2((a).x * (t), (a).y * (t))

#define nk_ptr_add(t, p, i) ((t*)((void*)((nk_byte*)(p) + (i))))
#define nk_ptr_add_const(t, p, i) ((const t*)((const void*)((const nk_byte*)(p) + (i))))
#define nk_zero_struct(s) nk_zero(&s, sizeof(s))*/

/* ==============================================================
 *                          ALIGNMENT
 * =============================================================== */
/* Pointer to Integer type conversion for pointer alignment */
/*#if defined(__PTRDIFF_TYPE__) /* This case should work for GCC*/
# define NK_UINT_TO_PTR(x) ((void*)(__PTRDIFF_TYPE__)(x))
# define NK_PTR_TO_UINT(x) ((nk_size)(__PTRDIFF_TYPE__)(x))
#elif !defined(__GNUC__) /* works for compilers other than LLVM */
# define NK_UINT_TO_PTR(x) ((void*)&((char8*)0)[x])
# define NK_PTR_TO_UINT(x) ((nk_size)(((char8*)x)-(char8*)0))
#elif defined(NK_USE_FIXED_TYPES) /* used if we have <stdint.h> */
# define NK_UINT_TO_PTR(x) ((void*)(uintptr_t)(x))
# define NK_PTR_TO_UINT(x) ((uintptr_t)(x))
#else /* generates warning but works */
# define NK_UINT_TO_PTR(x) ((void*)(x))
# define NK_PTR_TO_UINT(x) ((nk_size)(x))
#endif*/

/*#define NK_ALIGN_PTR(x, mask)\
	(NK_UINT_TO_PTR((NK_PTR_TO_UINT((nk_byte*)(x) + (mask-1)) & ~(mask-1))))
#define NK_ALIGN_PTR_BACK(x, mask)\
	(NK_UINT_TO_PTR((NK_PTR_TO_UINT((nk_byte*)(x)) & ~(mask-1))))

#if ((defined(__GNUC__) && __GNUC__ >= 4) || defined(__clang__)) && !defined(EMSCRIPTEN)
#define NK_OFFSETOF(st,m) (__builtin_offsetof(st,m))
#else
#define NK_OFFSETOF(st,m) ((nk_ptr)&(((st*)0)->m))
#endif

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
template<typename T> struct nk_alignof;
template<typename T, int32 size_diff> struct nk_helper{enum {value = size_diff};};
template<typename T> struct nk_helper<T,0>{enum {value = nk_alignof<T>::value};};
template<typename T> struct nk_alignof{struct Big {T x; char8 c;}; enum {
	diff = sizeof(Big) - sizeof(T), value = nk_helper<Big, diff>::value};};
#define NK_ALIGNOF(t) (nk_alignof<t>::value)
#else
#define NK_ALIGNOF(t) NK_OFFSETOF(struct {char8 c; t _h;}, _h)
#endif*/

/*#define NK_CONTAINER_OF(ptr,type,member)\
	(type*)((void*)((char8*)(1 ? (ptr): &((type*)0)->member) - NK_OFFSETOF(type, member)))*/