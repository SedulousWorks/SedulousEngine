using System;
using System.Interop;
/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
	 claim that you wrote the original software. If you use this software
	 in a product, an acknowledgment in the product documentation would be
	 appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/**
 * # CategoryStdinc
 *
 * SDL provides its own implementation of some of the most important C runtime
 * functions.
 *
 * Using these functions allows an app to have access to common C
 * functionality without depending on a specific C runtime (or a C runtime at
 * all). More importantly, the SDL implementations work identically across
 * platforms, so apps can avoid surprises like snprintf() behaving differently
 * between Windows and Linux builds, or itoa() only existing on some
 * platforms.
 *
 * For many of the most common functions, like SDL_memcpy, SDL might just call
 * through to the usual C runtime behind the scenes, if it makes sense to do
 * so (if it's faster and always available/reliable on a given platform),
 * reducing library size and offering the most optimized option.
 *
 * SDL also offers other C-runtime-adjacent functionality in this header that
 * either isn't, strictly speaking, part of any C runtime standards, like
 * SDL_crc32() and SDL_reinterpret_cast, etc. It also offers a few better
 * options, like SDL_strlcpy(), which functions as a safer form of strcpy().
 */

namespace SDL3;

public static //extension SDL3
{
	public const uint SDL_SIZE_MAX = uint.MaxValue;

/**
 * Define a four character code as a uint32.
 *
 * \param A the first ASCII character.
 * \param B the second ASCII character.
 * \param C the third ASCII character.
 * \param D the fourth ASCII character.
 * \returns the four characters converted into a uint32, one character
 *          per-byte.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint32 SDL_FOURCC(char8 A, char8 B, char8 C, char8 D)
	{
		return (((uint32(uint8(A))) << 0) | ((uint32(uint8(B))) << 8) | ((uint32(uint8(C))) << 16) | ((uint32(uint8(D))) << 24));
	}


/**
 *  \name Basic data types
 */
/* @{ */

/**
 * A signed 8-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef int8_t Sint8;
	public const int8 SDL_MAX_SINT8   = int8.MaxValue; //((Sint8)0x7F)           /* 127 */
	public const int8 SDL_MIN_SINT8   = int8.MinValue; //((Sint8)(~0x7F))        /* -128 */

/**
 * An unsigned 8-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef uint8_t Uint8;
	public const uint8 SDL_MAX_UINT8   = uint8.MaxValue; //((Uint8)0xFF)           /* 255 */
	public const uint8 SDL_MIN_UINT8   = uint8.MinValue; //((Uint8)0x00)           /* 0 */

/**
 * A signed 16-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef int16_t Sint16;
	public const int16 SDL_MAX_SINT16  = int16.MaxValue; //((Sint16)0x7FFF)        /* 32767 */
	public const int16 SDL_MIN_SINT16  = int16.MinValue; //((Sint16)(~0x7FFF))     /* -32768 */

/**
 * An unsigned 16-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef uint16_t Uint16;
	public const uint16 SDL_MAX_UINT16  = uint16.MaxValue; //((Uint16)0xFFFF)        /* 65535 */
	public const uint16 SDL_MIN_UINT16  = uint16.MinValue; //((Uint16)0x0000)        /* 0 */

/**
 * A signed 32-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef int32_t Sint32;
	public const int32 SDL_MAX_SINT32  = int32.MaxValue; //((Sint32)0x7FFFFFFF)    /* 2147483647 */
	public const int32 SDL_MIN_SINT32  = int32.MinValue; //((Sint32)(~0x7FFFFFFF)) /* -2147483648 */

/**
 * An unsigned 32-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	//typedef uint32_t Uint32;
	public const uint32 SDL_MAX_UINT32  = uint32.MaxValue; //((Uint32)0xFFFFFFFFu)   /* 4294967295 */
	public const uint32 SDL_MIN_UINT32  = uint32.MinValue; //((Uint32)0x00000000)    /* 0 */

/**
 * A signed 64-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_SINT64_C
 */
	//typedef int64_t Sint64;
	public const int64 SDL_MAX_SINT64  = int64.MaxValue; //SDL_SINT64_C(0x7FFFFFFFFFFFFFFF)   /* 9223372036854775807 */
	public const int64 SDL_MIN_SINT64  = int64.MinValue; //~SDL_SINT64_C(0x7FFFFFFFFFFFFFFF)  /* -9223372036854775808 */

/**
 * An unsigned 64-bit integer type.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_UINT64_C
 */
	//typedef uint64_t Uint64;
	public const uint64 SDL_MAX_UINT64  = uint64.MaxValue; //SDL_UINT64_C(0xFFFFFFFFFFFFFFFF)   /* 18446744073709551615 */
	public const uint64 SDL_MIN_UINT64  = uint64.MinValue; //SDL_UINT64_C(0x0000000000000000)   /* 0 */
}

/**
 * SDL times are signed, 64-bit integers representing nanoseconds since the
 * Unix epoch (Jan 1, 1970).
 *
 * They can be converted between POSIX time_t values with SDL_NS_TO_SECONDS()
 * and SDL_SECONDS_TO_NS(), and between Windows FILETIME values with
 * SDL_TimeToWindows() and SDL_TimeFromWindows().
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_MAX_SINT64
 * \sa SDL_MIN_SINT64
 */
public typealias SDL_Time = int64;
public static //extension SDL3
{
	public const SDL_Time SDL_MAX_TIME = SDL_Time.MaxValue;
	public const SDL_Time SDL_MIN_TIME = SDL_Time.MinValue;

/* @} */ /* Basic data types */

/**
 *  \name Floating-point constants
 */
/* @{ */

	public const float SDL_FLT_EPSILON = float.Epsilon;


/**
 * Allocate uninitialized memory.
 *
 * The allocated memory returned by this function must be freed with
 * SDL_free().
 *
 * If `size` is 0, it will be set to 1.
 *
 * If the allocation is successful, the returned pointer is guaranteed to be
 * aligned to either the *fundamental alignment* (`alignof(max_align_t)` in
 * C11 and later) or `2 * sizeof(void *)`, whichever is smaller. Use
 * SDL_aligned_alloc() if you need to allocate memory aligned to an alignment
 * greater than this guarantee.
 *
 * \param size the size to allocate.
 * \returns a pointer to the allocated memory, or NULL if allocation failed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_free
 * \sa SDL_calloc
 * \sa SDL_realloc
 * \sa SDL_aligned_alloc
 */
	[CLink] public static extern void* SDL_malloc(uint size);

/**
 * Allocate a zero-initialized array.
 *
 * The memory returned by this function must be freed with SDL_free().
 *
 * If either of `nmemb` or `size` is 0, they will both be set to 1.
 *
 * If the allocation is successful, the returned pointer is guaranteed to be
 * aligned to either the *fundamental alignment* (`alignof(max_align_t)` in
 * C11 and later) or `2 * sizeof(void *)`, whichever is smaller.
 *
 * \param nmemb the number of elements in the array.
 * \param size the size of each element of the array.
 * \returns a pointer to the allocated array, or NULL if allocation failed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_free
 * \sa SDL_malloc
 * \sa SDL_realloc
 */
	[CLink] public static extern void* SDL_calloc(uint nmemb, uint size);

/**
 * Change the size of allocated memory.
 *
 * The memory returned by this function must be freed with SDL_free().
 *
 * If `size` is 0, it will be set to 1. Note that this is unlike some other C
 * runtime `realloc` implementations, which may treat `realloc(mem, 0)` the
 * same way as `free(mem)`.
 *
 * If `mem` is NULL, the behavior of this function is equivalent to
 * SDL_malloc(). Otherwise, the function can have one of three possible
 * outcomes:
 *
 * - If it returns the same pointer as `mem`, it means that `mem` was resized
 *   in place without freeing.
 * - If it returns a different non-NULL pointer, it means that `mem` was freed
 *   and cannot be dereferenced anymore.
 * - If it returns NULL (indicating failure), then `mem` will remain valid and
 *   must still be freed with SDL_free().
 *
 * If the allocation is successfully resized, the returned pointer is
 * guaranteed to be aligned to either the *fundamental alignment*
 * (`alignof(max_align_t)` in C11 and later) or `2 * sizeof(void *)`,
 * whichever is smaller.
 *
 * \param mem a pointer to allocated memory to reallocate, or NULL.
 * \param size the new size of the memory.
 * \returns a pointer to the newly allocated memory, or NULL if allocation
 *          failed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_free
 * \sa SDL_malloc
 * \sa SDL_calloc
 */
	[CLink] public static extern void* SDL_realloc(void* mem, uint size);

/**
 * Free allocated memory.
 *
 * The pointer is no longer valid after this call and cannot be dereferenced
 * anymore.
 *
 * If `mem` is NULL, this function does nothing.
 *
 * \param mem a pointer to allocated memory, or NULL.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_malloc
 * \sa SDL_calloc
 * \sa SDL_realloc
 */
	[CLink] public static extern void SDL_free(void* mem);
}

/**
 * A callback used to implement SDL_malloc().
 *
 * SDL will always ensure that the passed `size` is greater than 0.
 *
 * \param size the size to allocate.
 * \returns a pointer to the allocated memory, or NULL if allocation failed.
 *
 * \threadsafety It should be safe to call this callback from any thread.
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_malloc
 * \sa SDL_GetOriginalMemoryFunctions
 * \sa SDL_GetMemoryFunctions
 * \sa SDL_SetMemoryFunctions
 */
public typealias SDL_malloc_func = function void*(uint size);

/**
 * A callback used to implement SDL_calloc().
 *
 * SDL will always ensure that the passed `nmemb` and `size` are both greater
 * than 0.
 *
 * \param nmemb the number of elements in the array.
 * \param size the size of each element of the array.
 * \returns a pointer to the allocated array, or NULL if allocation failed.
 *
 * \threadsafety It should be safe to call this callback from any thread.
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_calloc
 * \sa SDL_GetOriginalMemoryFunctions
 * \sa SDL_GetMemoryFunctions
 * \sa SDL_SetMemoryFunctions
 */
public typealias SDL_calloc_func = function void*(uint nmemb, uint size);

/**
 * A callback used to implement SDL_realloc().
 *
 * SDL will always ensure that the passed `size` is greater than 0.
 *
 * \param mem a pointer to allocated memory to reallocate, or NULL.
 * \param size the new size of the memory.
 * \returns a pointer to the newly allocated memory, or NULL if allocation
 *          failed.
 *
 * \threadsafety It should be safe to call this callback from any thread.
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_realloc
 * \sa SDL_GetOriginalMemoryFunctions
 * \sa SDL_GetMemoryFunctions
 * \sa SDL_SetMemoryFunctions
 */
public typealias SDL_realloc_func = function void*(void* mem, uint size);

/**
 * A callback used to implement SDL_free().
 *
 * SDL will always ensure that the passed `mem` is a non-NULL pointer.
 *
 * \param mem a pointer to allocated memory.
 *
 * \threadsafety It should be safe to call this callback from any thread.
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_free
 * \sa SDL_GetOriginalMemoryFunctions
 * \sa SDL_GetMemoryFunctions
 * \sa SDL_SetMemoryFunctions
 */
public typealias SDL_free_func = function void(void* mem);

public static //extension SDL3
{
/**
 * Get the original set of SDL memory functions.
 *
 * This is what SDL_malloc and friends will use by default, if there has been
 * no call to SDL_SetMemoryFunctions. This is not necessarily using the C
 * runtime's `malloc` functions behind the scenes! Different platforms and
 * build configurations might do any number of unexpected things.
 *
 * \param malloc_func filled with malloc function.
 * \param calloc_func filled with calloc function.
 * \param realloc_func filled with realloc function.
 * \param free_func filled with free function.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void SDL_GetOriginalMemoryFunctions(SDL_malloc_func* malloc_func,
		SDL_calloc_func* calloc_func,
		SDL_realloc_func* realloc_func,
		SDL_free_func* free_func);

/**
 * Get the current set of SDL memory functions.
 *
 * \param malloc_func filled with malloc function.
 * \param calloc_func filled with calloc function.
 * \param realloc_func filled with realloc function.
 * \param free_func filled with free function.
 *
 * \threadsafety This does not hold a lock, so do not call this in the
 *               unlikely event of a background thread calling
 *               SDL_SetMemoryFunctions simultaneously.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetMemoryFunctions
 * \sa SDL_GetOriginalMemoryFunctions
 */
	[CLink] public static extern void SDL_GetMemoryFunctions(SDL_malloc_func* malloc_func,
		SDL_calloc_func* calloc_func,
		SDL_realloc_func* realloc_func,
		SDL_free_func* free_func);

/**
 * Replace SDL's memory allocation functions with a custom set.
 *
 * It is not safe to call this function once any allocations have been made,
 * as future calls to SDL_free will use the new allocator, even if they came
 * from an SDL_malloc made with the old one!
 *
 * If used, usually this needs to be the first call made into the SDL library,
 * if not the very first thing done at program startup time.
 *
 * \param malloc_func custom malloc function.
 * \param calloc_func custom calloc function.
 * \param realloc_func custom realloc function.
 * \param free_func custom free function.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread, but one
 *               should not replace the memory functions once any allocations
 *               are made!
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetMemoryFunctions
 * \sa SDL_GetOriginalMemoryFunctions
 */
	[CLink] public static extern bool SDL_SetMemoryFunctions(SDL_malloc_func malloc_func,
		SDL_calloc_func calloc_func,
		SDL_realloc_func realloc_func,
		SDL_free_func free_func);

/**
 * Allocate memory aligned to a specific alignment.
 *
 * The memory returned by this function must be freed with SDL_aligned_free(),
 * _not_ SDL_free().
 *
 * If `alignment` is less than the size of `void *`, it will be increased to
 * match that.
 *
 * The returned memory address will be a multiple of the alignment value, and
 * the size of the memory allocated will be a multiple of the alignment value.
 *
 * \param alignment the alignment of the memory.
 * \param size the size to allocate.
 * \returns a pointer to the aligned memory, or NULL if allocation failed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_aligned_free
 */
	[CLink] public static extern void* SDL_aligned_alloc(uint alignment, uint size);

/**
 * Free memory allocated by SDL_aligned_alloc().
 *
 * The pointer is no longer valid after this call and cannot be dereferenced
 * anymore.
 *
 * If `mem` is NULL, this function does nothing.
 *
 * \param mem a pointer previously returned by SDL_aligned_alloc(), or NULL.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_aligned_alloc
 */
	[CLink] public static extern void SDL_aligned_free(void* mem);

/**
 * Get the number of outstanding (unfreed) allocations.
 *
 * \returns the number of allocations or -1 if allocation counting is
 *          disabled.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_GetNumAllocations();

}

/**
 * A thread-safe set of environment variables
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironment
 * \sa SDL_CreateEnvironment
 * \sa SDL_GetEnvironmentVariable
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 * \sa SDL_DestroyEnvironment
 */
[CRepr] public struct SDL_Environment;

public static //extension SDL3
{
/**
 * Get the process environment.
 *
 * This is initialized at application start and is not affected by setenv()
 * and unsetenv() calls after that point. Use SDL_SetEnvironmentVariable() and
 * SDL_UnsetEnvironmentVariable() if you want to modify this environment, or
 * SDL_setenv_unsafe() or SDL_unsetenv_unsafe() if you want changes to persist
 * in the C runtime environment after SDL_Quit().
 *
 * \returns a pointer to the environment for the process or NULL on failure;
 *          call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironmentVariable
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern SDL_Environment* SDL_GetEnvironment();

/**
 * Create a set of environment variables
 *
 * \param populated true to initialize it from the C runtime environment,
 *                  false to create an empty environment.
 * \returns a pointer to the new environment or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety If `populated` is false, it is safe to call this function
 *               from any thread, otherwise it is safe if no other threads are
 *               calling setenv() or unsetenv()
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironmentVariable
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 * \sa SDL_DestroyEnvironment
 */
	[CLink] public static extern SDL_Environment* SDL_CreateEnvironment(bool populated);

/**
 * Get the value of a variable in the environment.
 *
 * \param env the environment to query.
 * \param name the name of the variable to get.
 * \returns a pointer to the value of the variable or NULL if it can't be
 *          found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironment
 * \sa SDL_CreateEnvironment
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern char8* SDL_GetEnvironmentVariable(SDL_Environment* env, char8* name);

/**
 * Get all variables in the environment.
 *
 * \param env the environment to query.
 * \returns a NULL terminated array of pointers to environment variables in
 *          the form "variable=value" or NULL on failure; call SDL_GetError()
 *          for more information. This is a single allocation that should be
 *          freed with SDL_free() when it is no longer needed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironment
 * \sa SDL_CreateEnvironment
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern char8** SDL_GetEnvironmentVariables(SDL_Environment* env);

/**
 * Set the value of a variable in the environment.
 *
 * \param env the environment to modify.
 * \param name the name of the variable to set.
 * \param value the value of the variable to set.
 * \param overwrite true to overwrite the variable if it exists, false to
 *                  return success without setting the variable if it already
 *                  exists.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironment
 * \sa SDL_CreateEnvironment
 * \sa SDL_GetEnvironmentVariable
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern bool SDL_SetEnvironmentVariable(SDL_Environment* env, char8* name, char8* value, bool overwrite);

/**
 * Clear a variable from the environment.
 *
 * \param env the environment to modify.
 * \param name the name of the variable to unset.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetEnvironment
 * \sa SDL_CreateEnvironment
 * \sa SDL_GetEnvironmentVariable
 * \sa SDL_GetEnvironmentVariables
 * \sa SDL_SetEnvironmentVariable
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern bool SDL_UnsetEnvironmentVariable(SDL_Environment* env, char8* name);

/**
 * Destroy a set of environment variables.
 *
 * \param env the environment to destroy.
 *
 * \threadsafety It is safe to call this function from any thread, as long as
 *               the environment is no longer in use.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_CreateEnvironment
 */
	[CLink] public static extern void SDL_DestroyEnvironment(SDL_Environment* env);

/**
 * Get the value of a variable in the environment.
 *
 * This function uses SDL's cached copy of the environment and is thread-safe.
 *
 * \param name the name of the variable to get.
 * \returns a pointer to the value of the variable or NULL if it can't be
 *          found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_getenv(char8* name);

/**
 * Get the value of a variable in the environment.
 *
 * This function bypasses SDL's cached copy of the environment and is not
 * thread-safe.
 *
 * \param name the name of the variable to get.
 * \returns a pointer to the value of the variable or NULL if it can't be
 *          found.
 *
 * \threadsafety This function is not thread safe, consider using SDL_getenv()
 *               instead.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_getenv
 */
	[CLink] public static extern char8* SDL_getenv_unsafe(char8* name);

/**
 * Set the value of a variable in the environment.
 *
 * \param name the name of the variable to set.
 * \param value the value of the variable to set.
 * \param overwrite 1 to overwrite the variable if it exists, 0 to return
 *                  success without setting the variable if it already exists.
 * \returns 0 on success, -1 on error.
 *
 * \threadsafety This function is not thread safe, consider using
 *               SDL_SetEnvironmentVariable() instead.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetEnvironmentVariable
 */
	[CLink] public static extern int32 SDL_setenv_unsafe(char8* name, char8* value, int32 overwrite);

/**
 * Clear a variable from the environment.
 *
 * \param name the name of the variable to unset.
 * \returns 0 on success, -1 on error.
 *
 * \threadsafety This function is not thread safe, consider using
 *               SDL_UnsetEnvironmentVariable() instead.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_UnsetEnvironmentVariable
 */
	[CLink] public static extern int32 SDL_unsetenv_unsafe(char8* name);
}

/**
 * A callback used with SDL sorting and binary search functions.
 *
 * \param a a pointer to the first element being compared.
 * \param b a pointer to the second element being compared.
 * \returns -1 if `a` should be sorted before `b`, 1 if `b` should be sorted
 *          before `a`, 0 if they are equal. If two elements are equal, their
 *          order in the sorted array is undefined.
 *
 * \since This callback is available since SDL 3.2.0.
 *
 * \sa SDL_bsearch
 * \sa SDL_qsort
 */
public typealias SDL_CompareCallback = function int32(void* a, void* b);

public static //extension SDL3
{
/**
 * Sort an array.
 *
 * For example:
 *
 * ```c
 * typedef struct {
 *     int32 key;
 *     char8* string;
 * } data;
 *
 * int32 SDLCALL compare(void* a, void* b)
 * {
 *     data* A = (const data *)a;
 *     data* B = (const data *)b;
 *
 *     if (A->n < B->n) {
 *         return -1;
 *     } else if (B->n < A->n) {
 *         return 1;
 *     } else {
 *         return 0;
 *     }
 * }
 *
 * data values[] = {
 *     { 3, "third" }, { 1, "first" }, { 2, "second" }
 * };
 *
 * SDL_qsort(values, SDL_arraysize(values), sizeof(values[0]), compare);
 * ```
 *
 * \param base a pointer to the start of the array.
 * \param nmemb the number of elements in the array.
 * \param size the size of the elements in the array.
 * \param compare a function used to compare elements in the array.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_bsearch
 * \sa SDL_qsort_r
 */
	[CLink] public static extern void SDL_qsort(void* @base, uint nmemb, uint size, SDL_CompareCallback compare);

/**
 * Perform a binary search on a previously sorted array.
 *
 * For example:
 *
 * ```c
 * typedef struct {
 *     int32 key;
 *     char8* string;
 * } data;
 *
	 * int32 SDLCALL compare(const void *a, const void *b)
 * {
	 *     const data *A = (const data *)a;
	 *     const data *B = (const data *)b;
 *
 *     if (A->n < B->n) {
 *         return -1;
 *     } else if (B->n < A->n) {
 *         return 1;
 *     } else {
 *         return 0;
 *     }
 * }
 *
 * data values[] = {
 *     { 1, "first" }, { 2, "second" }, { 3, "third" }
 * };
 * data key = { 2, NULL };
 *
 * data *result = SDL_bsearch(&key, values, SDL_arraysize(values), sizeof(values[0]), compare);
 * ```
 *
 * \param key a pointer to a key equal to the element being searched for.
 * \param base a pointer to the start of the array.
 * \param nmemb the number of elements in the array.
 * \param size the size of the elements in the array.
 * \param compare a function used to compare elements in the array.
 * \returns a pointer to the matching element in the array, or NULL if not
 *          found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_bsearch_r
 * \sa SDL_qsort
 */
	[CLink] public static extern void* SDL_bsearch(void* key, void* @base, uint nmemb, uint size, SDL_CompareCallback compare);
}

/**
 * A callback used with SDL sorting and binary search functions.
 *
 * \param userdata the `userdata` pointer passed to the sort function.
 * \param a a pointer to the first element being compared.
 * \param b a pointer to the second element being compared.
 * \returns -1 if `a` should be sorted before `b`, 1 if `b` should be sorted
 *          before `a`, 0 if they are equal. If two elements are equal, their
 *          order in the sorted array is undefined.
 *
 * \since This callback is available since SDL 3.2.0.
 *
 * \sa SDL_qsort_r
 * \sa SDL_bsearch_r
 */
public typealias SDL_CompareCallback_r = function int32(void* userdata, void* a, void* b);

public static //extension SDL3
{

/**
 * Sort an array, passing a userdata pointer to the compare function.
 *
 * For example:
 *
 * ```c
 * typedef enum {
 *     sort_increasing,
 *     sort_decreasing,
 * } sort_method;
 *
 * typedef struct {
 *     int32 key;
 *     char8* string;
 * } data;
 *
	 * int32 SDLCALL compare(const void *userdata, const void *a, const void *b)
 * {
 *     sort_method method = (sort_method)(uintptr_t)userdata;
	 *     const data *A = (const data *)a;
	 *     const data *B = (const data *)b;
 *
 *     if (A->key < B->key) {
 *         return (method == sort_increasing) ? -1 : 1;
 *     } else if (B->key < A->key) {
 *         return (method == sort_increasing) ? 1 : -1;
 *     } else {
 *         return 0;
 *     }
 * }
 *
 * data values[] = {
 *     { 3, "third" }, { 1, "first" }, { 2, "second" }
 * };
 *
 * SDL_qsort_r(values, SDL_arraysize(values), sizeof(values[0]), compare, (const void *)(uintptr_t)sort_increasing);
 * ```
 *
 * \param base a pointer to the start of the array.
 * \param nmemb the number of elements in the array.
 * \param size the size of the elements in the array.
 * \param compare a function used to compare elements in the array.
 * \param userdata a pointer to pass to the compare function.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_bsearch_r
 * \sa SDL_qsort
 */
	[CLink] public static extern void SDL_qsort_r(void* @base, uint nmemb, uint size, SDL_CompareCallback_r compare, void* userdata);

/**
 * Perform a binary search on a previously sorted array, passing a userdata
 * pointer to the compare function.
 *
 * For example:
 *
 * ```c
 * typedef enum {
 *     sort_increasing,
 *     sort_decreasing,
 * } sort_method;
 *
 * typedef struct {
 *     int32 key;
 *     char8* string;
 * } data;
 *
	 * int32 SDLCALL compare(const void *userdata, const void *a, const void *b)
 * {
 *     sort_method method = (sort_method)(uintptr_t)userdata;
	 *     const data *A = (const data *)a;
	 *     const data *B = (const data *)b;
 *
 *     if (A->key < B->key) {
 *         return (method == sort_increasing) ? -1 : 1;
 *     } else if (B->key < A->key) {
 *         return (method == sort_increasing) ? 1 : -1;
 *     } else {
 *         return 0;
 *     }
 * }
 *
 * data values[] = {
 *     { 1, "first" }, { 2, "second" }, { 3, "third" }
 * };
 * data key = { 2, NULL };
 *
 * data *result = SDL_bsearch_r(&key, values, SDL_arraysize(values), sizeof(values[0]), compare, (const void *)(uintptr_t)sort_increasing);
 * ```
 *
 * \param key a pointer to a key equal to the element being searched for.
 * \param base a pointer to the start of the array.
 * \param nmemb the number of elements in the array.
 * \param size the size of the elements in the array.
 * \param compare a function used to compare elements in the array.
 * \param userdata a pointer to pass to the compare function.
 * \returns a pointer to the matching element in the array, or NULL if not
 *          found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_bsearch
 * \sa SDL_qsort_r
 */
	[CLink] public static extern void* SDL_bsearch_r(void* key, void* @base, uint nmemb, uint size, SDL_CompareCallback_r compare, void* userdata);

/**
 * Compute the absolute value of `x`.
 *
 * \param x an integer value.
 * \returns the absolute value of x.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_abs(int32 x);

/**
 * Return the lesser of two values.
 *
 * This is a helper macro that might be more clear than writing out the
 * comparisons directly, and works with any type that can be compared with the
 * `<` operator. However, it double-evaluates both its parameters, so do not
 * use expressions with side-effects here.
 *
 * \param x the first value to compare.
 * \param y the second value to compare.
 * \returns the lesser of `x` and `y`.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint32 SDL_min(uint32 x, uint32 y) => (((x) < (y)) ? (x) : (y));

/**
 * Return the greater of two values.
 *
 * This is a helper macro that might be more clear than writing out the
 * comparisons directly, and works with any type that can be compared with the
 * `>` operator. However, it double-evaluates both its parameters, so do not
 * use expressions with side-effects here.
 *
 * \param x the first value to compare.
 * \param y the second value to compare.
 * \returns the greater of `x` and `y`.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint32 SDL_max(uint32 x, uint32 y) => (((x) > (y)) ? (x) : (y));

/**
 * Return a value clamped to a range.
 *
 * If `x` is outside the range a values between `a` and `b`, the returned
 * value will be `a` or `b` as appropriate. Otherwise, `x` is returned.
 *
 * This macro will produce incorrect results if `b` is less than `a`.
 *
 * This is a helper macro that might be more clear than writing out the
 * comparisons directly, and works with any type that can be compared with the
 * `<` and `>` operators. However, it double-evaluates all its parameters, so
 * do not use expressions with side-effects here.
 *
 * \param x the value to compare.
 * \param a the low end value.
 * \param b the high end value.
 * \returns x, clamped between a and b.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint32 SDL_clamp(uint32 x, uint32 a, uint32 b) => (((x) < (a)) ? (a) : (((x) > (b)) ? (b) : (x)));

/**
 * Query if a character is alphabetic (a letter).
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * for English 'a-z' and 'A-Z' as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isalpha(int32 x);

/**
 * Query if a character is alphabetic (a letter) or a number.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * for English 'a-z', 'A-Z', and '0-9' as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isalnum(int32 x);

/**
 * Report if a character is blank (a space or tab).
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * 0x20 (space) or 0x9 (tab) as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isblank(int32 x);

/**
 * Report if a character is a control character.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * 0 through 0x1F, and 0x7F, as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_iscntrl(int32 x);

/**
 * Report if a character is a numeric digit.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * '0' (0x30) through '9' (0x39), as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isdigit(int32 x);

/**
 * Report if a character is a hexadecimal digit.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * 'A' through 'F', 'a' through 'f', and '0' through '9', as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isxdigit(int32 x);

/**
 * Report if a character is a punctuation mark.
 *
 * **WARNING**: Regardless of system locale, this is equivalent to
 * `((SDL_isgraph(x)) && (!SDL_isalnum(x)))`.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isgraph
 * \sa SDL_isalnum
 */
	[CLink] public static extern int32 SDL_ispunct(int32 x);

/**
 * Report if a character is whitespace.
 *
 * **WARNING**: Regardless of system locale, this will only treat the
 * following ASCII values as true:
 *
 * - space (0x20)
 * - tab (0x09)
 * - newline (0x0A)
 * - vertical tab (0x0B)
 * - form feed (0x0C)
 * - return (0x0D)
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isspace(int32 x);

/**
 * Report if a character is upper case.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * 'A' through 'Z' as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isupper(int32 x);

/**
 * Report if a character is lower case.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * 'a' through 'z' as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_islower(int32 x);

/**
 * Report if a character is "printable".
 *
 * Be advised that "printable" has a definition that goes back to text
 * terminals from the dawn of computing, making this a sort of special case
 * function that is not suitable for Unicode (or most any) text management.
 *
 * **WARNING**: Regardless of system locale, this will only treat ASCII values
 * ' ' (0x20) through '~' (0x7E) as true.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_isprint(int32 x);

/**
 * Report if a character is any "printable" except space.
 *
 * Be advised that "printable" has a definition that goes back to text
 * terminals from the dawn of computing, making this a sort of special case
 * function that is not suitable for Unicode (or most any) text management.
 *
 * **WARNING**: Regardless of system locale, this is equivalent to
 * `(SDL_isprint(x)) && ((x) != ' ')`.
 *
 * \param x character value to check.
 * \returns non-zero if x falls within the character class, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isprint
 */
	[CLink] public static extern int32 SDL_isgraph(int32 x);

/**
 * Convert low-ASCII English letters to uppercase.
 *
 * **WARNING**: Regardless of system locale, this will only convert ASCII
 * values 'a' through 'z' to uppercase.
 *
 * This function returns the uppercase equivalent of `x`. If a character
 * cannot be converted, or is already uppercase, this function returns `x`.
 *
 * \param x character value to check.
 * \returns capitalized version of x, or x if no conversion available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_toupper(int32 x);

/**
 * Convert low-ASCII English letters to lowercase.
 *
 * **WARNING**: Regardless of system locale, this will only convert ASCII
 * values 'A' through 'Z' to lowercase.
 *
 * This function returns the lowercase equivalent of `x`. If a character
 * cannot be converted, or is already lowercase, this function returns `x`.
 *
 * \param x character value to check.
 * \returns lowercase version of x, or x if no conversion available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_tolower(int32 x);

/**
 * Calculate a CRC-16 value.
 *
 * https://en.wikipedia.org/wiki/Cyclic_redundancy_check
 *
 * This function can be called multiple times, to stream data to be
 * checksummed in blocks. Each call must provide the previous CRC-16 return
 * value to be updated with the next block. The first call to this function
 * for a set of blocks should pass in a zero CRC value.
 *
 * \param crc the current checksum for this data set, or 0 for a new data set.
 * \param data a new block of data to add to the checksum.
 * \param len the size, in bytes, of the new block of data.
 * \returns a CRC-16 checksum value of all blocks in the data set.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint16 SDL_crc16(uint16 crc, void* data, uint len);

/**
 * Calculate a CRC-32 value.
 *
 * https://en.wikipedia.org/wiki/Cyclic_redundancy_check
 *
 * This function can be called multiple times, to stream data to be
 * checksummed in blocks. Each call must provide the previous CRC-32 return
 * value to be updated with the next block. The first call to this function
 * for a set of blocks should pass in a zero CRC value.
 *
 * \param crc the current checksum for this data set, or 0 for a new data set.
 * \param data a new block of data to add to the checksum.
 * \param len the size, in bytes, of the new block of data.
 * \returns a CRC-32 checksum value of all blocks in the data set.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint32 SDL_crc32(uint32 crc, void* data, uint len);

/**
 * Calculate a 32-bit MurmurHash3 value for a block of data.
 *
 * https://en.wikipedia.org/wiki/MurmurHash
 *
 * A seed may be specified, which changes the final results consistently, but
 * this does not work like SDL_crc16 and SDL_crc32: you can't feed a previous
 * result from this function back into itself as the next seed value to
 * calculate a hash in chunks; it won't produce the same hash as it would if
 * the same data was provided in a single call.
 *
 * If you aren't sure what to provide for a seed, zero is fine. Murmur3 is not
 * cryptographically secure, so it shouldn't be used for hashing top-secret
 * data.
 *
 * \param data the data to be hashed.
 * \param len the size of data, in bytes.
 * \param seed a value that alters the final hash value.
 * \returns a Murmur3 32-bit hash value.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint32 SDL_murmur3_32(void* data, uint len, uint32 seed);

/**
 * Copy non-overlapping memory.
 *
 * The memory regions must not overlap. If they do, use SDL_memmove() instead.
 *
 * \param dst The destination memory region. Must not be NULL, and must not
 *            overlap with `src`.
 * \param src The source memory region. Must not be NULL, and must not overlap
 *            with `dst`.
 * \param len The length in bytes of both `dst` and `src`.
 * \returns `dst`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_memmove
 */
	[CLink] public static extern void* SDL_memcpy(void* dst, void* src, uint len);

/**
 * Copy memory ranges that might overlap.
 *
 * It is okay for the memory regions to overlap. If you are confident that the
 * regions never overlap, using SDL_memcpy() may improve performance.
 *
 * \param dst The destination memory region. Must not be NULL.
 * \param src The source memory region. Must not be NULL.
 * \param len The length in bytes of both `dst` and `src`.
 * \returns `dst`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_memcpy
 */
	[CLink] public static extern void* SDL_memmove(void* dst, void* src, uint len);

/**
 * Initialize all bytes of buffer of memory to a specific value.
 *
 * This function will set `len` bytes, pointed to by `dst`, to the value
 * specified in `c`.
 *
 * Despite `c` being an `int32` instead of a `char`, this only operates on
 * bytes; `c` must be a value between 0 and 255, inclusive.
 *
 * \param dst the destination memory region. Must not be NULL.
 * \param c the byte value to set.
 * \param len the length, in bytes, to set in `dst`.
 * \returns `dst`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void* SDL_memset(void* dst, int32 c, uint len);

/**
 * Initialize all 32-bit words of buffer of memory to a specific value.
 *
 * This function will set a buffer of `dwords` uint32 values, pointed to by
 * `dst`, to the value specified in `val`.
 *
 * Unlike SDL_memset, this sets 32-bit values, not bytes, so it's not limited
 * to a range of 0-255.
 *
 * \param dst the destination memory region. Must not be NULL.
 * \param val the uint32 value to set.
 * \param dwords the number of uint32 values to set in `dst`.
 * \returns `dst`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void* SDL_memset4(void* dst, uint32 val, uint dwords);

/**
 * Clear an object's memory to zero.
 *
 * This is wrapper over SDL_memset that handles calculating the object size,
 * so there's no chance of copy/paste errors, and the code is cleaner.
 *
 * This requires an object, not a pointer to an object, nor an array.
 *
 * \param x the object to clear.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_zerop
 * \sa SDL_zeroa
 */
	//#define SDL_zero(x) SDL_memset(&(x), 0, sizeof((x)))

/**
 * Clear an object's memory to zero, using a pointer.
 *
 * This is wrapper over SDL_memset that handles calculating the object size,
 * so there's no chance of copy/paste errors, and the code is cleaner.
 *
 * This requires a pointer to an object, not an object itself, nor an array.
 *
 * \param x a pointer to the object to clear.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_zero
 * \sa SDL_zeroa
 */
	//#define SDL_zerop(x) SDL_memset((x), 0, sizeof(*(x)))

/**
 * Clear an array's memory to zero.
 *
 * This is wrapper over SDL_memset that handles calculating the array size, so
 * there's no chance of copy/paste errors, and the code is cleaner.
 *
 * This requires an array, not an object, nor a pointer to an object.
 *
 * \param x an array to clear.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_zero
 * \sa SDL_zerop
 */
	//#define SDL_zeroa(x) SDL_memset((x), 0, sizeof((x)))


/**
 * Compare two buffers of memory.
 *
 * \param s1 the first buffer to compare. NULL is not permitted!
 * \param s2 the second buffer to compare. NULL is not permitted!
 * \param len the number of bytes to compare between the buffers.
 * \returns less than zero if s1 is "less than" s2, greater than zero if s1 is
 *          "greater than" s2, and zero if the buffers match exactly for `len`
 *          bytes.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_memcmp(void* s1, void* s2, uint len);

/**
 * This works exactly like wcslen() but doesn't require access to a C runtime.
 *
 * Counts the number of wchar_t values in `wstr`, excluding the null
 * terminator.
 *
 * Like SDL_strlen only counts bytes and not codepoints in a UTF-8 string,
 * this counts wchar_t values in a string, even if the string's encoding is of
 * variable width, like UTF-16.
 *
 * Also be aware that wchar_t is different sizes on different platforms (4
 * bytes on Linux, 2 on Windows, etc).
 *
 * \param wstr The null-terminated wide string to read. Must not be NULL.
 * \returns the length (in wchar_t values, excluding the null terminator) of
 *          `wstr`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_wcsnlen
 * \sa SDL_utf8strlen
 * \sa SDL_utf8strnlen
 */
	[CLink] public static extern uint SDL_wcslen(c_wchar* wstr);

/**
 * This works exactly like wcsnlen() but doesn't require access to a C
 * runtime.
 *
 * Counts up to a maximum of `maxlen` wchar_t values in `wstr`, excluding the
 * null terminator.
 *
 * Like SDL_strnlen only counts bytes and not codepoints in a UTF-8 string,
 * this counts wchar_t values in a string, even if the string's encoding is of
 * variable width, like UTF-16.
 *
 * Also be aware that wchar_t is different sizes on different platforms (4
 * bytes on Linux, 2 on Windows, etc).
 *
 * Also, `maxlen` is a count of wide characters, not bytes!
 *
 * \param wstr The null-terminated wide string to read. Must not be NULL.
 * \param maxlen The maximum amount of wide characters to count.
 * \returns the length (in wide characters, excluding the null terminator) of
 *          `wstr` but never more than `maxlen`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_wcslen
 * \sa SDL_utf8strlen
 * \sa SDL_utf8strnlen
 */
	[CLink] public static extern uint SDL_wcsnlen(c_wchar* wstr, uint maxlen);

/**
 * Copy a wide string.
 *
 * This function copies `maxlen` - 1 wide characters from `src` to `dst`, then
 * appends a null terminator.
 *
 * `src` and `dst` must not overlap.
 *
 * If `maxlen` is 0, no wide characters are copied and no null terminator is
 * written.
 *
 * \param dst The destination buffer. Must not be NULL, and must not overlap
 *            with `src`.
 * \param src The null-terminated wide string to copy. Must not be NULL, and
 *            must not overlap with `dst`.
 * \param maxlen The length (in wide characters) of the destination buffer.
 * \returns the length (in wide characters, excluding the null terminator) of
 *          `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_wcslcat
 */
	[CLink] public static extern uint SDL_wcslcpy(c_wchar* dst, c_wchar* src, uint maxlen);

/**
 * Concatenate wide strings.
 *
 * This function appends up to `maxlen` - SDL_wcslen(dst) - 1 wide characters
 * from `src` to the end of the wide string in `dst`, then appends a null
 * terminator.
 *
 * `src` and `dst` must not overlap.
 *
 * If `maxlen` - SDL_wcslen(dst) - 1 is less than or equal to 0, then `dst` is
 * unmodified.
 *
 * \param dst The destination buffer already containing the first
 *            null-terminated wide string. Must not be NULL and must not
 *            overlap with `src`.
 * \param src The second null-terminated wide string. Must not be NULL, and
 *            must not overlap with `dst`.
 * \param maxlen The length (in wide characters) of the destination buffer.
 * \returns the length (in wide characters, excluding the null terminator) of
 *          the string in `dst` plus the length of `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_wcslcpy
 */
	[CLink] public static extern uint SDL_wcslcat(c_wchar* dst, c_wchar* src, uint maxlen);

/**
 * Allocate a copy of a wide string.
 *
 * This allocates enough space for a null-terminated copy of `wstr`, using
 * SDL_malloc, and then makes a copy of the string into this space.
 *
 * The returned string is owned by the caller, and should be passed to
 * SDL_free when no longer needed.
 *
 * \param wstr the string to copy.
 * \returns a pointer to the newly-allocated wide string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern c_wchar*  SDL_wcsdup(c_wchar* wstr);

/**
 * Search a wide string for the first instance of a specific substring.
 *
 * The search ends once it finds the requested substring, or a null terminator
 * byte to end the string.
 *
 * Note that this looks for strings of _wide characters_, not _codepoints_, so
 * it's legal to search for malformed and incomplete UTF-16 sequences.
 *
 * \param haystack the wide string to search. Must not be NULL.
 * \param needle the wide string to search for. Must not be NULL.
 * \returns a pointer to the first instance of `needle` in the string, or NULL
 *          if not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern c_wchar*  SDL_wcsstr(c_wchar* haystack, c_wchar* needle);

/**
 * Search a wide string, up to n wide chars, for the first instance of a
 * specific substring.
 *
 * The search ends once it finds the requested substring, or a null terminator
 * value to end the string, or `maxlen` wide character have been examined. It
 * is possible to use this function on a wide string without a null
 * terminator.
 *
 * Note that this looks for strings of _wide characters_, not _codepoints_, so
 * it's legal to search for malformed and incomplete UTF-16 sequences.
 *
 * \param haystack the wide string to search. Must not be NULL.
 * \param needle the wide string to search for. Must not be NULL.
 * \param maxlen the maximum number of wide characters to search in
 *               `haystack`.
 * \returns a pointer to the first instance of `needle` in the string, or NULL
 *          if not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern c_wchar*  SDL_wcsnstr(c_wchar* haystack, c_wchar* needle, uint maxlen);

/**
 * Compare two null-terminated wide strings.
 *
 * This only compares wchar_t values until it hits a null-terminating
 * character; it does not care if the string is well-formed UTF-16 (or UTF-32,
 * depending on your platform's wchar_t size), or uses valid Unicode values.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_wcscmp(c_wchar* str1, c_wchar* str2);

/**
 * Compare two wide strings up to a number of wchar_t values.
 *
 * This only compares wchar_t values; it does not care if the string is
 * well-formed UTF-16 (or UTF-32, depending on your platform's wchar_t size),
 * or uses valid Unicode values.
 *
 * Note that while this function is intended to be used with UTF-16 (or
 * UTF-32, depending on your platform's definition of wchar_t), it is
 * comparing raw wchar_t values and not Unicode codepoints: `maxlen` specifies
 * a wchar_t limit! If the limit lands in the middle of a multi-wchar UTF-16
 * sequence, it will only compare a portion of the final character.
 *
 * `maxlen` specifies a maximum number of wchar_t to compare; if the strings
 * match to this number of wide chars (or both have matched to a
 * null-terminator character before this count), they will be considered
 * equal.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \param maxlen the maximum number of wchar_t to compare.
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_wcsncmp(c_wchar* str1, c_wchar* str2, uint maxlen);

/**
 * Compare two null-terminated wide strings, case-insensitively.
 *
 * This will work with Unicode strings, using a technique called
 * "case-folding" to handle the vast majority of case-sensitive human
 * languages regardless of system locale. It can deal with expanding values: a
 * German Eszett character can compare against two ASCII 's' chars and be
 * considered a match, for example. A notable exception: it does not handle
 * the Turkish 'i' character; human language is complicated!
 *
 * Depending on your platform, "wchar_t" might be 2 bytes, and expected to be
 * UTF-16 encoded (like Windows), or 4 bytes in UTF-32 format. Since this
 * handles Unicode, it expects the string to be well-formed and not a
 * null-terminated string of arbitrary bytes. Characters that are not valid
 * UTF-16 (or UTF-32) are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), which is to say two strings of random bits may turn out to
 * match if they convert to the same amount of replacement characters.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_wcscasecmp(c_wchar* str1, c_wchar* str2);

/**
 * Compare two wide strings, case-insensitively, up to a number of wchar_t.
 *
 * This will work with Unicode strings, using a technique called
 * "case-folding" to handle the vast majority of case-sensitive human
 * languages regardless of system locale. It can deal with expanding values: a
 * German Eszett character can compare against two ASCII 's' chars and be
 * considered a match, for example. A notable exception: it does not handle
 * the Turkish 'i' character; human language is complicated!
 *
 * Depending on your platform, "wchar_t" might be 2 bytes, and expected to be
 * UTF-16 encoded (like Windows), or 4 bytes in UTF-32 format. Since this
 * handles Unicode, it expects the string to be well-formed and not a
 * null-terminated string of arbitrary bytes. Characters that are not valid
 * UTF-16 (or UTF-32) are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), which is to say two strings of random bits may turn out to
 * match if they convert to the same amount of replacement characters.
 *
 * Note that while this function might deal with variable-sized characters,
 * `maxlen` specifies a _wchar_ limit! If the limit lands in the middle of a
 * multi-byte UTF-16 sequence, it may convert a portion of the final character
 * to one or more Unicode character U+FFFD (REPLACEMENT CHARACTER) so as not
 * to overflow a buffer.
 *
 * `maxlen` specifies a maximum number of wchar_t values to compare; if the
 * strings match to this number of wchar_t (or both have matched to a
 * null-terminator character before this number of bytes), they will be
 * considered equal.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \param maxlen the maximum number of wchar_t values to compare.
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_wcsncasecmp(c_wchar* str1, c_wchar* str2, uint maxlen);

/**
 * Parse a `long` from a wide string.
 *
 * If `str` starts with whitespace, then those whitespace characters are
 * skipped before attempting to parse the number.
 *
 * If the parsed number does not fit inside a `long`, the result is clamped to
 * the minimum and maximum representable `long` values.
 *
 * \param str The null-terminated wide string to read. Must not be NULL.
 * \param endp If not NULL, the address of the first invalid wide character
 *             (i.e. the next character after the parsed number) will be
 *             written to this pointer.
 * \param base The base of the integer to read. Supported values are 0 and 2
 *             to 36 inclusive. If 0, the base will be inferred from the
 *             number's prefix (0x for hexadecimal, 0 for octal, decimal
 *             otherwise).
 * \returns the parsed `long`, or 0 if no number could be parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strtol
 */
	[CLink] public static extern int64 SDL_wcstol(c_wchar* str, c_wchar** endp, int32 @base);

/**
 * This works exactly like strlen() but doesn't require access to a C runtime.
 *
 * Counts the bytes in `str`, excluding the null terminator.
 *
 * If you need the length of a UTF-8 string, consider using SDL_utf8strlen().
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \returns the length (in bytes, excluding the null terminator) of `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strnlen
 * \sa SDL_utf8strlen
 * \sa SDL_utf8strnlen
 */
	[CLink] public static extern uint SDL_strlen(char8* str);

/**
 * This works exactly like strnlen() but doesn't require access to a C
 * runtime.
 *
 * Counts up to a maximum of `maxlen` bytes in `str`, excluding the null
 * terminator.
 *
 * If you need the length of a UTF-8 string, consider using SDL_utf8strnlen().
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \param maxlen The maximum amount of bytes to count.
 * \returns the length (in bytes, excluding the null terminator) of `src` but
 *          never more than `maxlen`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strlen
 * \sa SDL_utf8strlen
 * \sa SDL_utf8strnlen
 */
	[CLink] public static extern uint SDL_strnlen(char8* str, uint maxlen);

/**
 * Copy a string.
 *
 * This function copies up to `maxlen` - 1 characters from `src` to `dst`,
 * then appends a null terminator.
 *
 * If `maxlen` is 0, no characters are copied and no null terminator is
 * written.
 *
 * If you want to copy an UTF-8 string but need to ensure that multi-byte
 * sequences are not truncated, consider using SDL_utf8strlcpy().
 *
 * \param dst The destination buffer. Must not be NULL, and must not overlap
 *            with `src`.
 * \param src The null-terminated string to copy. Must not be NULL, and must
 *            not overlap with `dst`.
 * \param maxlen The length (in characters) of the destination buffer.
 * \returns the length (in characters, excluding the null terminator) of
 *          `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strlcat
 * \sa SDL_utf8strlcpy
 */
	[CLink] public static extern uint SDL_strlcpy(char8* dst, char8* src, uint maxlen);

/**
 * Copy an UTF-8 string.
 *
 * This function copies up to `dst_bytes` - 1 bytes from `src` to `dst` while
 * also ensuring that the string written to `dst` does not end in a truncated
 * multi-byte sequence. Finally, it appends a null terminator.
 *
 * `src` and `dst` must not overlap.
 *
 * Note that unlike SDL_strlcpy(), this function returns the number of bytes
 * written, not the length of `src`.
 *
 * \param dst The destination buffer. Must not be NULL, and must not overlap
 *            with `src`.
 * \param src The null-terminated UTF-8 string to copy. Must not be NULL, and
 *            must not overlap with `dst`.
 * \param dst_bytes The length (in bytes) of the destination buffer. Must not
 *                  be 0.
 * \returns the number of bytes written, excluding the null terminator.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strlcpy
 */
	[CLink] public static extern uint SDL_utf8strlcpy(char8* dst, char8* src, uint dst_bytes);

/**
 * Concatenate strings.
 *
 * This function appends up to `maxlen` - SDL_strlen(dst) - 1 characters from
 * `src` to the end of the string in `dst`, then appends a null terminator.
 *
 * `src` and `dst` must not overlap.
 *
 * If `maxlen` - SDL_strlen(dst) - 1 is less than or equal to 0, then `dst` is
 * unmodified.
 *
 * \param dst The destination buffer already containing the first
 *            null-terminated string. Must not be NULL and must not overlap
 *            with `src`.
 * \param src The second null-terminated string. Must not be NULL, and must
 *            not overlap with `dst`.
 * \param maxlen The length (in characters) of the destination buffer.
 * \returns the length (in characters, excluding the null terminator) of the
 *          string in `dst` plus the length of `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strlcpy
 */
	[CLink] public static extern uint SDL_strlcat(char8* dst, char8* src, uint maxlen);

/**
 * Allocate a copy of a string.
 *
 * This allocates enough space for a null-terminated copy of `str`, using
 * SDL_malloc, and then makes a copy of the string into this space.
 *
 * The returned string is owned by the caller, and should be passed to
 * SDL_free when no longer needed.
 *
 * \param str the string to copy.
 * \returns a pointer to the newly-allocated string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strdup(char8* str);

/**
 * Allocate a copy of a string, up to n characters.
 *
 * This allocates enough space for a null-terminated copy of `str`, up to
 * `maxlen` bytes, using SDL_malloc, and then makes a copy of the string into
 * this space.
 *
 * If the string is longer than `maxlen` bytes, the returned string will be
 * `maxlen` bytes long, plus a null-terminator character that isn't included
 * in the count.
 *
 * The returned string is owned by the caller, and should be passed to
 * SDL_free when no longer needed.
 *
 * \param str the string to copy.
 * \param maxlen the maximum length of the copied string, not counting the
 *               null-terminator character.
 * \returns a pointer to the newly-allocated string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strndup(char8* str, uint maxlen);

/**
 * Reverse a string's contents.
 *
 * This reverses a null-terminated string in-place. Only the content of the
 * string is reversed; the null-terminator character remains at the end of the
 * reversed string.
 *
 * **WARNING**: This function reverses the _bytes_ of the string, not the
 * codepoints. If `str` is a UTF-8 string with Unicode codepoints > 127, this
 * will ruin the string data. You should only use this function on strings
 * that are completely comprised of low ASCII characters.
 *
 * \param str the string to reverse.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strrev(char8* str);

/**
 * Convert a string to uppercase.
 *
 * **WARNING**: Regardless of system locale, this will only convert ASCII
 * values 'A' through 'Z' to uppercase.
 *
 * This function operates on a null-terminated string of bytes--even if it is
 * malformed UTF-8!--and converts ASCII characters 'a' through 'z' to their
 * uppercase equivalents in-place, returning the original `str` pointer.
 *
 * \param str the string to convert in-place. Can not be NULL.
 * \returns the `str` pointer passed into this function.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strlwr
 */
	[CLink] public static extern char8* SDL_strupr(char8* str);

/**
 * Convert a string to lowercase.
 *
 * **WARNING**: Regardless of system locale, this will only convert ASCII
 * values 'A' through 'Z' to lowercase.
 *
 * This function operates on a null-terminated string of bytes--even if it is
 * malformed UTF-8!--and converts ASCII characters 'A' through 'Z' to their
 * lowercase equivalents in-place, returning the original `str` pointer.
 *
 * \param str the string to convert in-place. Can not be NULL.
 * \returns the `str` pointer passed into this function.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_strupr
 */
	[CLink] public static extern char8* SDL_strlwr(char8* str);

/**
 * Search a string for the first instance of a specific byte.
 *
 * The search ends once it finds the requested byte value, or a null
 * terminator byte to end the string.
 *
 * Note that this looks for _bytes_, not _characters_, so you cannot match
 * against a Unicode codepoint > 255, regardless of character encoding.
 *
 * \param str the string to search. Must not be NULL.
 * \param c the byte value to search for.
 * \returns a pointer to the first instance of `c` in the string, or NULL if
 *          not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strchr(char8* str, int32 c);

/**
 * Search a string for the last instance of a specific byte.
 *
 * The search must go until it finds a null terminator byte to end the string.
 *
 * Note that this looks for _bytes_, not _characters_, so you cannot match
 * against a Unicode codepoint > 255, regardless of character encoding.
 *
 * \param str the string to search. Must not be NULL.
 * \param c the byte value to search for.
 * \returns a pointer to the last instance of `c` in the string, or NULL if
 *          not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strrchr(char8* str, int32 c);

/**
 * Search a string for the first instance of a specific substring.
 *
 * The search ends once it finds the requested substring, or a null terminator
 * byte to end the string.
 *
 * Note that this looks for strings of _bytes_, not _characters_, so it's
 * legal to search for malformed and incomplete UTF-8 sequences.
 *
 * \param haystack the string to search. Must not be NULL.
 * \param needle the string to search for. Must not be NULL.
 * \returns a pointer to the first instance of `needle` in the string, or NULL
 *          if not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strstr(char8* haystack, char8* needle);

/**
 * Search a string, up to n bytes, for the first instance of a specific
 * substring.
 *
 * The search ends once it finds the requested substring, or a null terminator
 * byte to end the string, or `maxlen` bytes have been examined. It is
 * possible to use this function on a string without a null terminator.
 *
 * Note that this looks for strings of _bytes_, not _characters_, so it's
 * legal to search for malformed and incomplete UTF-8 sequences.
 *
 * \param haystack the string to search. Must not be NULL.
 * \param needle the string to search for. Must not be NULL.
 * \param maxlen the maximum number of bytes to search in `haystack`.
 * \returns a pointer to the first instance of `needle` in the string, or NULL
 *          if not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strnstr(char8* haystack, char8* needle, uint maxlen);

/**
 * Search a UTF-8 string for the first instance of a specific substring,
 * case-insensitively.
 *
 * This will work with Unicode strings, using a technique called
 * "case-folding" to handle the vast majority of case-sensitive human
 * languages regardless of system locale. It can deal with expanding values: a
 * German Eszett character can compare against two ASCII 's' chars and be
 * considered a match, for example. A notable exception: it does not handle
 * the Turkish 'i' character; human language is complicated!
 *
 * Since this handles Unicode, it expects the strings to be well-formed UTF-8
 * and not a null-terminated string of arbitrary bytes. Bytes that are not
 * valid UTF-8 are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), which is to say two strings of random bits may turn out to
 * match if they convert to the same amount of replacement characters.
 *
 * \param haystack the string to search. Must not be NULL.
 * \param needle the string to search for. Must not be NULL.
 * \returns a pointer to the first instance of `needle` in the string, or NULL
 *          if not found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strcasestr(char8* haystack, char8* needle);

/**
 * This works exactly like strtok_r() but doesn't require access to a C
 * runtime.
 *
 * Break a string up into a series of tokens.
 *
 * To start tokenizing a new string, `str` should be the non-NULL address of
 * the string to start tokenizing. Future calls to get the next token from the
 * same string should specify a NULL.
 *
 * Note that this function will overwrite pieces of `str` with null chars to
 * split it into tokens. This function cannot be used with const/read-only
 * strings!
 *
 * `saveptr` just needs to point to a `char8* ` that can be overwritten; SDL
 * will use this to save tokenizing state between calls. It is initialized if
 * `str` is non-NULL, and used to resume tokenizing when `str` is NULL.
 *
 * \param str the string to tokenize, or NULL to continue tokenizing.
 * \param delim the delimiter string that separates tokens.
 * \param saveptr pointer to a char8* , used for ongoing state.
 * \returns A pointer to the next token, or NULL if no tokens remain.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strtok_r(char8* str, char8* delim, char8** saveptr);

/**
 * Count the number of codepoints in a UTF-8 string.
 *
 * Counts the _codepoints_, not _bytes_, in `str`, excluding the null
 * terminator.
 *
 * If you need to count the bytes in a string instead, consider using
 * SDL_strlen().
 *
 * Since this handles Unicode, it expects the strings to be well-formed UTF-8
 * and not a null-terminated string of arbitrary bytes. Bytes that are not
 * valid UTF-8 are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), so a malformed or incomplete UTF-8 sequence might increase the
 * count by several replacement characters.
 *
 * \param str The null-terminated UTF-8 string to read. Must not be NULL.
 * \returns The length (in codepoints, excluding the null terminator) of
 *          `src`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_utf8strnlen
 * \sa SDL_strlen
 */
	[CLink] public static extern uint SDL_utf8strlen(char8* str);

/**
 * Count the number of codepoints in a UTF-8 string, up to n bytes.
 *
 * Counts the _codepoints_, not _bytes_, in `str`, excluding the null
 * terminator.
 *
 * If you need to count the bytes in a string instead, consider using
 * SDL_strnlen().
 *
 * The counting stops at `bytes` bytes (not codepoints!). This seems
 * counterintuitive, but makes it easy to express the total size of the
 * string's buffer.
 *
 * Since this handles Unicode, it expects the strings to be well-formed UTF-8
 * and not a null-terminated string of arbitrary bytes. Bytes that are not
 * valid UTF-8 are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), so a malformed or incomplete UTF-8 sequence might increase the
 * count by several replacement characters.
 *
 * \param str The null-terminated UTF-8 string to read. Must not be NULL.
 * \param bytes The maximum amount of bytes to count.
 * \returns The length (in codepoints, excluding the null terminator) of `src`
 *          but never more than `maxlen`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_utf8strlen
 * \sa SDL_strnlen
 */
	[CLink] public static extern uint SDL_utf8strnlen(char8* str, uint bytes);

/**
 * Convert an integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget possible negative
 * signs, null terminator bytes, etc).
 *
 * \param value the integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_uitoa
 * \sa SDL_ltoa
 * \sa SDL_lltoa
 */
	[CLink] public static extern char8* SDL_itoa(int32 value, char8* str, int32 radix);

/**
 * Convert an unsigned integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget null terminator
 * bytes, etc).
 *
 * \param value the unsigned integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_itoa
 * \sa SDL_ultoa
 * \sa SDL_ulltoa
 */
	[CLink] public static extern char8* SDL_uitoa(uint32 value, char8* str, int32 radix);

/**
 * Convert a long integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget possible negative
 * signs, null terminator bytes, etc).
 *
 * \param value the long integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ultoa
 * \sa SDL_itoa
 * \sa SDL_lltoa
 */
	[CLink] public static extern char8* SDL_ltoa(int64 value, char8* str, int32 radix);

/**
 * Convert an unsigned long integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget null terminator
 * bytes, etc).
 *
 * \param value the unsigned long integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ltoa
 * \sa SDL_uitoa
 * \sa SDL_ulltoa
 */
	[CLink] public static extern char8* SDL_ultoa(uint64 value, char8* str, int32 radix);

#if !SDL_NOLONGLONG

/**
 * Convert a long long integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget possible negative
 * signs, null terminator bytes, etc).
 *
 * \param value the long long integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ulltoa
 * \sa SDL_itoa
 * \sa SDL_ltoa
 */
	[CLink] public static extern char8* SDL_lltoa(int64 value, char8* str, int32 radix);

/**
 * Convert an unsigned long long integer into a string.
 *
 * This requires a radix to specified for string format. Specifying 10
 * produces a decimal number, 16 hexadecimal, etc. Must be in the range of 2
 * to 36.
 *
 * Note that this function will overflow a buffer if `str` is not large enough
 * to hold the output! It may be safer to use SDL_snprintf to clamp output, or
 * SDL_asprintf to allocate a buffer. Otherwise, it doesn't hurt to allocate
 * much more space than you expect to use (and don't forget null terminator
 * bytes, etc).
 *
 * \param value the unsigned long long integer to convert.
 * \param str the buffer to write the string into.
 * \param radix the radix to use for string generation.
 * \returns `str`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_lltoa
 * \sa SDL_uitoa
 * \sa SDL_ultoa
 */
	[CLink] public static extern char8* SDL_ulltoa(uint64 value, char8* str, int32 radix);
#endif

/**
 * Parse an `int32` from a string.
 *
 * The result of calling `SDL_atoi(str)` is equivalent to
 * `(int32)SDL_strtol(str, NULL, 10)`.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \returns the parsed `int32`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atof
 * \sa SDL_strtol
 * \sa SDL_strtoul
 * \sa SDL_strtoll
 * \sa SDL_strtoull
 * \sa SDL_strtod
 * \sa SDL_itoa
 */
	[CLink] public static extern int32 SDL_atoi(char8* str);

/**
 * Parse a `double` from a string.
 *
 * The result of calling `SDL_atof(str)` is equivalent to `SDL_strtod(str,
 * NULL)`.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \returns the parsed `double`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_strtol
 * \sa SDL_strtoul
 * \sa SDL_strtoll
 * \sa SDL_strtoull
 * \sa SDL_strtod
 */
	[CLink] public static extern double SDL_atof(char8* str);

/**
 * Parse a `long` from a string.
 *
 * If `str` starts with whitespace, then those whitespace characters are
 * skipped before attempting to parse the number.
 *
 * If the parsed number does not fit inside a `long`, the result is clamped to
 * the minimum and maximum representable `long` values.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \param endp If not NULL, the address of the first invalid character (i.e.
 *             the next character after the parsed number) will be written to
 *             this pointer.
 * \param base The base of the integer to read. Supported values are 0 and 2
 *             to 36 inclusive. If 0, the base will be inferred from the
 *             number's prefix (0x for hexadecimal, 0 for octal, decimal
 *             otherwise).
 * \returns the parsed `long`, or 0 if no number could be parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_atof
 * \sa SDL_strtoul
 * \sa SDL_strtoll
 * \sa SDL_strtoull
 * \sa SDL_strtod
 * \sa SDL_ltoa
 * \sa SDL_wcstol
 */
	[CLink] public static extern int64 SDL_strtol(char8* str, char8** endp, int32 @base);

/**
 * Parse an `unsigned long` from a string.
 *
 * If `str` starts with whitespace, then those whitespace characters are
 * skipped before attempting to parse the number.
 *
 * If the parsed number does not fit inside an `unsigned long`, the result is
 * clamped to the maximum representable `unsigned long` value.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \param endp If not NULL, the address of the first invalid character (i.e.
 *             the next character after the parsed number) will be written to
 *             this pointer.
 * \param base The base of the integer to read. Supported values are 0 and 2
 *             to 36 inclusive. If 0, the base will be inferred from the
 *             number's prefix (0x for hexadecimal, 0 for octal, decimal
 *             otherwise).
 * \returns the parsed `unsigned long`, or 0 if no number could be parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_atof
 * \sa SDL_strtol
 * \sa SDL_strtoll
 * \sa SDL_strtoull
 * \sa SDL_strtod
 * \sa SDL_ultoa
 */
	[CLink] public static extern uint64 SDL_strtoul(char8* str, char8** endp, int32 @base);

#if !SDL_NOLONGLONG

/**
 * Parse a `long long` from a string.
 *
 * If `str` starts with whitespace, then those whitespace characters are
 * skipped before attempting to parse the number.
 *
 * If the parsed number does not fit inside a `long long`, the result is
 * clamped to the minimum and maximum representable `long long` values.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \param endp If not NULL, the address of the first invalid character (i.e.
 *             the next character after the parsed number) will be written to
 *             this pointer.
 * \param base The base of the integer to read. Supported values are 0 and 2
 *             to 36 inclusive. If 0, the base will be inferred from the
 *             number's prefix (0x for hexadecimal, 0 for octal, decimal
 *             otherwise).
 * \returns the parsed `long long`, or 0 if no number could be parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_atof
 * \sa SDL_strtol
 * \sa SDL_strtoul
 * \sa SDL_strtoull
 * \sa SDL_strtod
 * \sa SDL_lltoa
 */
	[CLink] public static extern int64 SDL_strtoll(char8* str, char8** endp, int32 @base);

/**
 * Parse an `unsigned long long` from a string.
 *
 * If `str` starts with whitespace, then those whitespace characters are
 * skipped before attempting to parse the number.
 *
 * If the parsed number does not fit inside an `unsigned long long`, the
 * result is clamped to the maximum representable `unsigned long long` value.
 *
 * \param str The null-terminated string to read. Must not be NULL.
 * \param endp If not NULL, the address of the first invalid character (i.e.
 *             the next character after the parsed number) will be written to
 *             this pointer.
 * \param base The base of the integer to read. Supported values are 0 and 2
 *             to 36 inclusive. If 0, the base will be inferred from the
 *             number's prefix (0x for hexadecimal, 0 for octal, decimal
 *             otherwise).
 * \returns the parsed `unsigned long long`, or 0 if no number could be
 *          parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_atof
 * \sa SDL_strtol
 * \sa SDL_strtoll
 * \sa SDL_strtoul
 * \sa SDL_strtod
 * \sa SDL_ulltoa
 */
	[CLink] public static extern uint64 SDL_strtoull(char8* str, char8** endp, int32 @base);
#endif

/**
 * Parse a `double` from a string.
 *
 * This function makes fewer guarantees than the C runtime `strtod`:
 *
 * - Only decimal notation is guaranteed to be supported. The handling of
 *   scientific and hexadecimal notation is unspecified.
 * - Whether or not INF and NAN can be parsed is unspecified.
 * - The precision of the result is unspecified.
 *
 * \param str the null-terminated string to read. Must not be NULL.
 * \param endp if not NULL, the address of the first invalid character (i.e.
 *             the next character after the parsed number) will be written to
 *             this pointer.
 * \returns the parsed `double`, or 0 if no number could be parsed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atoi
 * \sa SDL_atof
 * \sa SDL_strtol
 * \sa SDL_strtoll
 * \sa SDL_strtoul
 * \sa SDL_strtoull
 */
	[CLink] public static extern double SDL_strtod(char8* str, char8** endp);

/**
 * Compare two null-terminated UTF-8 strings.
 *
 * Due to the nature of UTF-8 encoding, this will work with Unicode strings,
 * since effectively this function just compares bytes until it hits a
 * null-terminating character. Also due to the nature of UTF-8, this can be
 * used with SDL_qsort() to put strings in (roughly) alphabetical order.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_strcmp(char8* str1, char8* str2);

/**
 * Compare two UTF-8 strings up to a number of bytes.
 *
 * Due to the nature of UTF-8 encoding, this will work with Unicode strings,
 * since effectively this function just compares bytes until it hits a
 * null-terminating character. Also due to the nature of UTF-8, this can be
 * used with SDL_qsort() to put strings in (roughly) alphabetical order.
 *
 * Note that while this function is intended to be used with UTF-8, it is
 * doing a bytewise comparison, and `maxlen` specifies a _byte_ limit! If the
 * limit lands in the middle of a multi-byte UTF-8 sequence, it will only
 * compare a portion of the final character.
 *
 * `maxlen` specifies a maximum number of bytes to compare; if the strings
 * match to this number of bytes (or both have matched to a null-terminator
 * character before this number of bytes), they will be considered equal.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \param maxlen the maximum number of _bytes_ to compare.
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_strncmp(char8* str1, char8* str2, uint maxlen);

/**
 * Compare two null-terminated UTF-8 strings, case-insensitively.
 *
 * This will work with Unicode strings, using a technique called
 * "case-folding" to handle the vast majority of case-sensitive human
 * languages regardless of system locale. It can deal with expanding values: a
 * German Eszett character can compare against two ASCII 's' chars and be
 * considered a match, for example. A notable exception: it does not handle
 * the Turkish 'i' character; human language is complicated!
 *
 * Since this handles Unicode, it expects the string to be well-formed UTF-8
 * and not a null-terminated string of arbitrary bytes. Bytes that are not
 * valid UTF-8 are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), which is to say two strings of random bits may turn out to
 * match if they convert to the same amount of replacement characters.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_strcasecmp(char8* str1, char8* str2);


/**
 * Compare two UTF-8 strings, case-insensitively, up to a number of bytes.
 *
 * This will work with Unicode strings, using a technique called
 * "case-folding" to handle the vast majority of case-sensitive human
 * languages regardless of system locale. It can deal with expanding values: a
 * German Eszett character can compare against two ASCII 's' chars and be
 * considered a match, for example. A notable exception: it does not handle
 * the Turkish 'i' character; human language is complicated!
 *
 * Since this handles Unicode, it expects the string to be well-formed UTF-8
 * and not a null-terminated string of arbitrary bytes. Bytes that are not
 * valid UTF-8 are treated as Unicode character U+FFFD (REPLACEMENT
 * CHARACTER), which is to say two strings of random bits may turn out to
 * match if they convert to the same amount of replacement characters.
 *
 * Note that while this function is intended to be used with UTF-8, `maxlen`
 * specifies a _byte_ limit! If the limit lands in the middle of a multi-byte
 * UTF-8 sequence, it may convert a portion of the final character to one or
 * more Unicode character U+FFFD (REPLACEMENT CHARACTER) so as not to overflow
 * a buffer.
 *
 * `maxlen` specifies a maximum number of bytes to compare; if the strings
 * match to this number of bytes (or both have matched to a null-terminator
 * character before this number of bytes), they will be considered equal.
 *
 * \param str1 the first string to compare. NULL is not permitted!
 * \param str2 the second string to compare. NULL is not permitted!
 * \param maxlen the maximum number of bytes to compare.
 * \returns less than zero if str1 is "less than" str2, greater than zero if
 *          str1 is "greater than" str2, and zero if the strings match
 *          exactly.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_strncasecmp(char8* str1, char8* str2, uint maxlen);

/**
 * Searches a string for the first occurrence of any character contained in a
 * breakset, and returns a pointer from the string to that character.
 *
 * \param str The null-terminated string to be searched. Must not be NULL, and
 *            must not overlap with `breakset`.
 * \param breakset A null-terminated string containing the list of characters
 *                 to look for. Must not be NULL, and must not overlap with
 *                 `str`.
 * \returns A pointer to the location, in str, of the first occurrence of a
 *          character present in the breakset, or NULL if none is found.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_strpbrk(char8* str, char8* breakset);

/**
 * The Unicode REPLACEMENT CHARACTER codepoint.
 *
 * SDL_StepUTF8() and SDL_StepBackUTF8() report this codepoint when they
 * encounter a UTF-8 string with encoding errors.
 *
 * This tends to render as something like a question mark in most places.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_StepBackUTF8
 * \sa SDL_StepUTF8
 */
	//#define SDL_INVALID_UNICODE_CODEPOINT 0xFFFD

/**
 * Decode a UTF-8 string, one Unicode codepoint at a time.
 *
 * This will return the first Unicode codepoint in the UTF-8 encoded string in
 * `*pstr`, and then advance `*pstr` past any consumed bytes before returning.
 *
 * It will not access more than `*pslen` bytes from the string. `*pslen` will
 * be adjusted, as well, subtracting the number of bytes consumed.
 *
 * `pslen` is allowed to be NULL, in which case the string _must_ be
 * NULL-terminated, as the function will blindly read until it sees the NULL
 * char.
 *
 * if `*pslen` is zero, it assumes the end of string is reached and returns a
 * zero codepoint regardless of the contents of the string buffer.
 *
 * If the resulting codepoint is zero (a NULL terminator), or `*pslen` is
 * zero, it will not advance `*pstr` or `*pslen` at all.
 *
 * Generally this function is called in a loop until it returns zero,
 * adjusting its parameters each iteration.
 *
 * If an invalid UTF-8 sequence is encountered, this function returns
 * SDL_INVALID_UNICODE_CODEPOINT and advances the string/length by one byte
 * (which is to say, a multibyte sequence might produce several
 * SDL_INVALID_UNICODE_CODEPOINT returns before it syncs to the next valid
 * UTF-8 sequence).
 *
 * Several things can generate invalid UTF-8 sequences, including overlong
 * encodings, the use of UTF-16 surrogate values, and truncated data. Please
 * refer to
 * [RFC3629](https://www.ietf.org/rfc/rfc3629.txt)
 * for details.
 *
 * \param pstr a pointer to a UTF-8 string pointer to be read and adjusted.
 * \param pslen a pointer to the number of bytes in the string, to be read and
 *              adjusted. NULL is allowed.
 * \returns the first Unicode codepoint in the string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint32 SDL_StepUTF8(char8** pstr, uint* pslen);

/**
 * Decode a UTF-8 string in reverse, one Unicode codepoint at a time.
 *
 * This will go to the start of the previous Unicode codepoint in the string,
 * move `*pstr` to that location and return that codepoint.
 *
 * If `*pstr` is already at the start of the string), it will not advance
 * `*pstr` at all.
 *
 * Generally this function is called in a loop until it returns zero,
 * adjusting its parameter each iteration.
 *
 * If an invalid UTF-8 sequence is encountered, this function returns
 * SDL_INVALID_UNICODE_CODEPOINT.
 *
 * Several things can generate invalid UTF-8 sequences, including overlong
 * encodings, the use of UTF-16 surrogate values, and truncated data. Please
 * refer to
 * [RFC3629](https://www.ietf.org/rfc/rfc3629.txt)
 * for details.
 *
 * \param start a pointer to the beginning of the UTF-8 string.
 * \param pstr a pointer to a UTF-8 string pointer to be read and adjusted.
 * \returns the previous Unicode codepoint in the string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint32 SDL_StepBackUTF8(char8* start, char8** pstr);

/**
 * Convert a single Unicode codepoint to UTF-8.
 *
 * The buffer pointed to by `dst` must be at least 4 bytes long, as this
 * function may generate between 1 and 4 bytes of output.
 *
 * This function returns the first byte _after_ the newly-written UTF-8
 * sequence, which is useful for encoding multiple codepoints in a loop, or
 * knowing where to write a NULL-terminator character to end the string (in
 * either case, plan to have a buffer of _more_ than 4 bytes!).
 *
 * If `codepoint` is an invalid value (outside the Unicode range, or a UTF-16
 * surrogate value, etc), this will use U+FFFD (REPLACEMENT CHARACTER) for the
 * codepoint instead, and not set an error.
 *
 * If `dst` is NULL, this returns NULL immediately without writing to the
 * pointer and without setting an error.
 *
 * \param codepoint a Unicode codepoint to convert to UTF-8.
 * \param dst the location to write the encoded UTF-8. Must point to at least
 *            4 bytes!
 * \returns the first byte past the newly-written UTF-8 sequence.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_UCS4ToUTF8(uint32 codepoint, char8* dst);

/**
 * This works exactly like sscanf() but doesn't require access to a C runtime.
 *
 * Scan a string, matching a format string, converting each '%' item and
 * storing it to pointers provided through variable arguments.
 *
 * \param text the string to scan. Must not be NULL.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ... a list of pointers to values to be filled in with scanned items.
 * \returns the number of items that matched the format string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_sscanf(char8* text, char8* fmt, ...);

/**
 * This works exactly like vsscanf() but doesn't require access to a C
 * runtime.
 *
 * Functions identically to SDL_sscanf(), except it takes a `va_list` instead
 * of using `...` variable arguments.
 *
 * \param text the string to scan. Must not be NULL.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ap a `va_list` of pointers to values to be filled in with scanned
 *           items.
 * \returns the number of items that matched the format string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_vsscanf(char8* text, char8* fmt, VarArgs ap);

/**
 * This works exactly like snprintf() but doesn't require access to a C
 * runtime.
 *
 * Format a string of up to `maxlen`-1 bytes, converting each '%' item with
 * values provided through variable arguments.
 *
 * While some C runtimes differ on how to deal with too-large strings, this
 * function null-terminates the output, by treating the null-terminator as
 * part of the `maxlen` count. Note that if `maxlen` is zero, however, no
 * bytes will be written at all.
 *
 * This function returns the number of _bytes_ (not _characters_) that should
 * be written, excluding the null-terminator character. If this returns a
 * number >= `maxlen`, it means the output string was truncated. A negative
 * return value means an error occurred.
 *
 * Referencing the output string's pointer with a format item is undefined
 * behavior.
 *
 * \param text the buffer to write the string into. Must not be NULL.
 * \param maxlen the maximum bytes to write, including the null-terminator.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ... a list of values to be used with the format string.
 * \returns the number of bytes that should be written, not counting the
 *          null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_snprintf(char8* text, uint maxlen, char8* fmt, ...);

/**
 * This works exactly like swprintf() but doesn't require access to a C
 * runtime.
 *
 * Format a wide string of up to `maxlen`-1 wchar_t values, converting each
 * '%' item with values provided through variable arguments.
 *
 * While some C runtimes differ on how to deal with too-large strings, this
 * function null-terminates the output, by treating the null-terminator as
 * part of the `maxlen` count. Note that if `maxlen` is zero, however, no wide
 * characters will be written at all.
 *
 * This function returns the number of _wide characters_ (not _codepoints_)
 * that should be written, excluding the null-terminator character. If this
 * returns a number >= `maxlen`, it means the output string was truncated. A
 * negative return value means an error occurred.
 *
 * Referencing the output string's pointer with a format item is undefined
 * behavior.
 *
 * \param text the buffer to write the wide string into. Must not be NULL.
 * \param maxlen the maximum wchar_t values to write, including the
 *               null-terminator.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ... a list of values to be used with the format string.
 * \returns the number of wide characters that should be written, not counting
 *          the null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_swprintf(c_wchar* text, uint maxlen, c_wchar* fmt, ...);

/**
 * This works exactly like vsnprintf() but doesn't require access to a C
 * runtime.
 *
 * Functions identically to SDL_snprintf(), except it takes a `va_list`
 * instead of using `...` variable arguments.
 *
 * \param text the buffer to write the string into. Must not be NULL.
 * \param maxlen the maximum bytes to write, including the null-terminator.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ap a `va_list` values to be used with the format string.
 * \returns the number of bytes that should be written, not counting the
 *          null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_vsnprintf(char8* text, uint maxlen, char8* fmt, VarArgs ap);

/**
 * This works exactly like vswprintf() but doesn't require access to a C
 * runtime.
 *
 * Functions identically to SDL_swprintf(), except it takes a `va_list`
 * instead of using `...` variable arguments.
 *
 * \param text the buffer to write the string into. Must not be NULL.
 * \param maxlen the maximum wide characters to write, including the
 *               null-terminator.
 * \param fmt a printf-style format wide string. Must not be NULL.
 * \param ap a `va_list` values to be used with the format string.
 * \returns the number of wide characters that should be written, not counting
 *          the null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_vswprintf(c_wchar* text, uint maxlen, c_wchar* fmt, VarArgs ap);

/**
 * This works exactly like asprintf() but doesn't require access to a C
 * runtime.
 *
 * Functions identically to SDL_snprintf(), except it allocates a buffer large
 * enough to hold the output string on behalf of the caller.
 *
 * On success, this function returns the number of bytes (not characters)
 * comprising the output string, not counting the null-terminator character,
 * and sets `*strp` to the newly-allocated string.
 *
 * On error, this function returns a negative number, and the value of `*strp`
 * is undefined.
 *
 * The returned string is owned by the caller, and should be passed to
 * SDL_free when no longer needed.
 *
 * \param strp on output, is set to the new string. Must not be NULL.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ... a list of values to be used with the format string.
 * \returns the number of bytes in the newly-allocated string, not counting
 *          the null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_asprintf(char8** strp, char8* fmt, ...);

/**
 * This works exactly like vasprintf() but doesn't require access to a C
 * runtime.
 *
 * Functions identically to SDL_asprintf(), except it takes a `va_list`
 * instead of using `...` variable arguments.
 *
 * \param strp on output, is set to the new string. Must not be NULL.
 * \param fmt a printf-style format string. Must not be NULL.
 * \param ap a `va_list` values to be used with the format string.
 * \returns the number of bytes in the newly-allocated string, not counting
 *          the null-terminator char, or a negative value on error.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_vasprintf(char8** strp, char8* fmt, VarArgs ap);

/**
 * Seeds the pseudo-random number generator.
 *
 * Reusing the seed number will cause SDL_rand() to repeat the same stream of
 * 'random' numbers.
 *
 * \param seed the value to use as a random number seed, or 0 to use
 *             SDL_GetPerformanceCounter().
 *
 * \threadsafety This should be called on the same thread that calls
 *               SDL_rand()
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_rand
 * \sa SDL_rand_bits
 * \sa SDL_randf
 */
	[CLink] public static extern void SDL_srand(uint64 seed);

/**
 * Generate a pseudo-random number less than n for positive n
 *
 * The method used is faster and of better quality than `rand() % n`. Odds are
 * roughly 99.9% even for n = 1 million. Evenness is better for smaller n, and
 * much worse as n gets bigger.
 *
 * Example: to simulate a d6 use `SDL_rand(6) + 1` The +1 converts 0..5 to
 * 1..6
 *
 * If you want to generate a pseudo-random number in the full range of int32,
 * you should use: (int32)SDL_rand_bits()
 *
 * If you want reproducible output, be sure to initialize with SDL_srand()
 * first.
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \param n the number of possible outcomes. n must be positive.
 * \returns a random value in the range of [0 .. n-1].
 *
 * \threadsafety All calls should be made from a single thread
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_srand
 * \sa SDL_randf
 */
	[CLink] public static extern int32 SDL_rand(int32 n);

/**
 * Generate a uniform pseudo-random floating point number less than 1.0
 *
 * If you want reproducible output, be sure to initialize with SDL_srand()
 * first.
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \returns a random value in the range of [0.0, 1.0).
 *
 * \threadsafety All calls should be made from a single thread
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_srand
 * \sa SDL_rand
 */
	[CLink] public static extern float SDL_randf();

/**
 * Generate 32 pseudo-random bits.
 *
 * You likely want to use SDL_rand() to get a psuedo-random number instead.
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \returns a random value in the range of [0-SDL_MAX_UINT32].
 *
 * \threadsafety All calls should be made from a single thread
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_rand
 * \sa SDL_randf
 * \sa SDL_srand
 */
	[CLink] public static extern uint32 SDL_rand_bits();

/**
 * Generate a pseudo-random number less than n for positive n
 *
 * The method used is faster and of better quality than `rand() % n`. Odds are
 * roughly 99.9% even for n = 1 million. Evenness is better for smaller n, and
 * much worse as n gets bigger.
 *
 * Example: to simulate a d6 use `SDL_rand_r(state, 6) + 1` The +1 converts
 * 0..5 to 1..6
 *
 * If you want to generate a pseudo-random number in the full range of int32,
 * you should use: (int32)SDL_rand_bits_r(state)
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \param state a pointer to the current random number state, this may not be
 *              NULL.
 * \param n the number of possible outcomes. n must be positive.
 * \returns a random value in the range of [0 .. n-1].
 *
 * \threadsafety This function is thread-safe, as long as the state pointer
 *               isn't shared between threads.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_rand
 * \sa SDL_rand_bits_r
 * \sa SDL_randf_r
 */
	[CLink] public static extern int32 SDL_rand_r(uint64* state, int32 n);

/**
 * Generate a uniform pseudo-random floating point number less than 1.0
 *
 * If you want reproducible output, be sure to initialize with SDL_srand()
 * first.
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \param state a pointer to the current random number state, this may not be
 *              NULL.
 * \returns a random value in the range of [0.0, 1.0).
 *
 * \threadsafety This function is thread-safe, as long as the state pointer
 *               isn't shared between threads.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_rand_bits_r
 * \sa SDL_rand_r
 * \sa SDL_randf
 */
	[CLink] public static extern float SDL_randf_r(uint64* state);

/**
 * Generate 32 pseudo-random bits.
 *
 * You likely want to use SDL_rand_r() to get a psuedo-random number instead.
 *
 * There are no guarantees as to the quality of the random sequence produced,
 * and this should not be used for security (cryptography, passwords) or where
 * money is on the line (loot-boxes, casinos). There are many random number
 * libraries available with different characteristics and you should pick one
 * of those to meet any serious needs.
 *
 * \param state a pointer to the current random number state, this may not be
 *              NULL.
 * \returns a random value in the range of [0-SDL_MAX_UINT32].
 *
 * \threadsafety This function is thread-safe, as long as the state pointer
 *               isn't shared between threads.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_rand_r
 * \sa SDL_randf_r
 */
	[CLink] public static extern uint32 SDL_rand_bits_r(uint64* state);

/**
 * The value of Pi, as a double-precision floating point literal.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_PI_F
 */
	public const double SDL_PI_D   = 3.141592653589793238462643383279502884; /**< pi (double) */


/**
 * The value of Pi, as a single-precision floating point literal.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_PI_D
 */
	public const float SDL_PI_F   = 3.141592653589793238462643383279502884F; /**< pi (float) */

/**
 * Compute the arc cosine of `x`.
 *
 * The definition of `y = acos(x)` is `x = cos(y)`.
 *
 * Domain: `-1 <= x <= 1`
 *
 * Range: `0 <= y <= Pi`
 *
 * This function operates on double-precision floating point values, use
 * SDL_acosf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc cosine of `x`, in radians.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_acosf
 * \sa SDL_asin
 * \sa SDL_cos
 */
	[CLink] public static extern double SDL_acos(double x);

/**
 * Compute the arc cosine of `x`.
 *
 * The definition of `y = acos(x)` is `x = cos(y)`.
 *
 * Domain: `-1 <= x <= 1`
 *
 * Range: `0 <= y <= Pi`
 *
 * This function operates on single-precision floating point values, use
 * SDL_acos for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc cosine of `x`, in radians.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_acos
 * \sa SDL_asinf
 * \sa SDL_cosf
 */
	[CLink] public static extern float SDL_acosf(float x);

/**
 * Compute the arc sine of `x`.
 *
 * The definition of `y = asin(x)` is `x = sin(y)`.
 *
 * Domain: `-1 <= x <= 1`
 *
 * Range: `-Pi/2 <= y <= Pi/2`
 *
 * This function operates on double-precision floating point values, use
 * SDL_asinf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc sine of `x`, in radians.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_asinf
 * \sa SDL_acos
 * \sa SDL_sin
 */
	[CLink] public static extern double SDL_asin(double x);

/**
 * Compute the arc sine of `x`.
 *
 * The definition of `y = asin(x)` is `x = sin(y)`.
 *
 * Domain: `-1 <= x <= 1`
 *
 * Range: `-Pi/2 <= y <= Pi/2`
 *
 * This function operates on single-precision floating point values, use
 * SDL_asin for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc sine of `x`, in radians.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_asin
 * \sa SDL_acosf
 * \sa SDL_sinf
 */
	[CLink] public static extern float SDL_asinf(float x);

/**
 * Compute the arc tangent of `x`.
 *
 * The definition of `y = atan(x)` is `x = tan(y)`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-Pi/2 <= y <= Pi/2`
 *
 * This function operates on double-precision floating point values, use
 * SDL_atanf for single-precision floats.
 *
 * To calculate the arc tangent of y / x, use SDL_atan2.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc tangent of of `x` in radians, or 0 if `x = 0`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atanf
 * \sa SDL_atan2
 * \sa SDL_tan
 */
	[CLink] public static extern double SDL_atan(double x);

/**
 * Compute the arc tangent of `x`.
 *
 * The definition of `y = atan(x)` is `x = tan(y)`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-Pi/2 <= y <= Pi/2`
 *
 * This function operates on single-precision floating point values, use
 * SDL_atan for dboule-precision floats.
 *
 * To calculate the arc tangent of y / x, use SDL_atan2f.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns arc tangent of of `x` in radians, or 0 if `x = 0`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atan
 * \sa SDL_atan2f
 * \sa SDL_tanf
 */
	[CLink] public static extern float SDL_atanf(float x);

/**
 * Compute the arc tangent of `y / x`, using the signs of x and y to adjust
 * the result's quadrant.
 *
 * The definition of `z = atan2(x, y)` is `y = x tan(z)`, where the quadrant
 * of z is determined based on the signs of x and y.
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`
 *
 * Range: `-Pi <= y <= Pi`
 *
 * This function operates on double-precision floating point values, use
 * SDL_atan2f for single-precision floats.
 *
 * To calculate the arc tangent of a single value, use SDL_atan.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param y floating point value of the numerator (y coordinate).
 * \param x floating point value of the denominator (x coordinate).
 * \returns arc tangent of of `y / x` in radians, or, if `x = 0`, either
 *          `-Pi/2`, `0`, or `Pi/2`, depending on the value of `y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atan2f
 * \sa SDL_atan
 * \sa SDL_tan
 */
	[CLink] public static extern double SDL_atan2(double y, double x);

/**
 * Compute the arc tangent of `y / x`, using the signs of x and y to adjust
 * the result's quadrant.
 *
 * The definition of `z = atan2(x, y)` is `y = x tan(z)`, where the quadrant
 * of z is determined based on the signs of x and y.
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`
 *
 * Range: `-Pi <= y <= Pi`
 *
 * This function operates on single-precision floating point values, use
 * SDL_atan2 for double-precision floats.
 *
 * To calculate the arc tangent of a single value, use SDL_atanf.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param y floating point value of the numerator (y coordinate).
 * \param x floating point value of the denominator (x coordinate).
 * \returns arc tangent of of `y / x` in radians, or, if `x = 0`, either
 *          `-Pi/2`, `0`, or `Pi/2`, depending on the value of `y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_atan2
 * \sa SDL_atan
 * \sa SDL_tan
 */
	[CLink] public static extern float SDL_atan2f(float y, float x);

/**
 * Compute the ceiling of `x`.
 *
 * The ceiling of `x` is the smallest integer `y` such that `y >= x`, i.e `x`
 * rounded up to the nearest integer.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on double-precision floating point values, use
 * SDL_ceilf for single-precision floats.
 *
 * \param x floating point value.
 * \returns the ceiling of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ceilf
 * \sa SDL_floor
 * \sa SDL_trunc
 * \sa SDL_round
 * \sa SDL_lround
 */
	[CLink] public static extern double SDL_ceil(double x);

/**
 * Compute the ceiling of `x`.
 *
 * The ceiling of `x` is the smallest integer `y` such that `y >= x`, i.e `x`
 * rounded up to the nearest integer.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on single-precision floating point values, use
 * SDL_ceil for double-precision floats.
 *
 * \param x floating point value.
 * \returns the ceiling of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ceil
 * \sa SDL_floorf
 * \sa SDL_truncf
 * \sa SDL_roundf
 * \sa SDL_lroundf
 */
	[CLink] public static extern float SDL_ceilf(float x);

/**
 * Copy the sign of one floating-point value to another.
 *
 * The definition of copysign is that ``copysign(x, y) = abs(x) * sign(y)``.
 *
 * Domain: `-INF <= x <= INF`, ``-INF <= y <= f``
 *
 * Range: `-INF <= z <= INF`
 *
 * This function operates on double-precision floating point values, use
 * SDL_copysignf for single-precision floats.
 *
 * \param x floating point value to use as the magnitude.
 * \param y floating point value to use as the sign.
 * \returns the floating point value with the sign of y and the magnitude of
 *          x.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_copysignf
 * \sa SDL_fabs
 */
	[CLink] public static extern double SDL_copysign(double x, double y);

/**
 * Copy the sign of one floating-point value to another.
 *
 * The definition of copysign is that ``copysign(x, y) = abs(x) * sign(y)``.
 *
 * Domain: `-INF <= x <= INF`, ``-INF <= y <= f``
 *
 * Range: `-INF <= z <= INF`
 *
 * This function operates on single-precision floating point values, use
 * SDL_copysign for double-precision floats.
 *
 * \param x floating point value to use as the magnitude.
 * \param y floating point value to use as the sign.
 * \returns the floating point value with the sign of y and the magnitude of
 *          x.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_copysign
 * \sa SDL_fabsf
 */
	[CLink] public static extern float SDL_copysignf(float x, float y);

/**
 * Compute the cosine of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-1 <= y <= 1`
 *
 * This function operates on double-precision floating point values, use
 * SDL_cosf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns cosine of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_cosf
 * \sa SDL_acos
 * \sa SDL_sin
 */
	[CLink] public static extern double SDL_cos(double x);

/**
 * Compute the cosine of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-1 <= y <= 1`
 *
 * This function operates on single-precision floating point values, use
 * SDL_cos for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns cosine of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_cos
 * \sa SDL_acosf
 * \sa SDL_sinf
 */
	[CLink] public static extern float SDL_cosf(float x);

/**
 * Compute the exponential of `x`.
 *
 * The definition of `y = exp(x)` is `y = e^x`, where `e` is the base of the
 * natural logarithm. The inverse is the natural logarithm, SDL_log.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * The output will overflow if `exp(x)` is too large to be represented.
 *
 * This function operates on double-precision floating point values, use
 * SDL_expf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns value of `e^x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_expf
 * \sa SDL_log
 */
	[CLink] public static extern double SDL_exp(double x);

/**
 * Compute the exponential of `x`.
 *
 * The definition of `y = exp(x)` is `y = e^x`, where `e` is the base of the
 * natural logarithm. The inverse is the natural logarithm, SDL_logf.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * The output will overflow if `exp(x)` is too large to be represented.
 *
 * This function operates on single-precision floating point values, use
 * SDL_exp for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value.
 * \returns value of `e^x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_exp
 * \sa SDL_logf
 */
	[CLink] public static extern float SDL_expf(float x);

/**
 * Compute the absolute value of `x`
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * This function operates on double-precision floating point values, use
 * SDL_fabsf for single-precision floats.
 *
 * \param x floating point value to use as the magnitude.
 * \returns the absolute value of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_fabsf
 */
	[CLink] public static extern double SDL_fabs(double x);

/**
 * Compute the absolute value of `x`
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * This function operates on single-precision floating point values, use
 * SDL_fabs for double-precision floats.
 *
 * \param x floating point value to use as the magnitude.
 * \returns the absolute value of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_fabs
 */
	[CLink] public static extern float SDL_fabsf(float x);

/**
 * Compute the floor of `x`.
 *
 * The floor of `x` is the largest integer `y` such that `y <= x`, i.e `x`
 * rounded down to the nearest integer.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on double-precision floating point values, use
 * SDL_floorf for single-precision floats.
 *
 * \param x floating point value.
 * \returns the floor of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_floorf
 * \sa SDL_ceil
 * \sa SDL_trunc
 * \sa SDL_round
 * \sa SDL_lround
 */
	[CLink] public static extern double SDL_floor(double x);

/**
 * Compute the floor of `x`.
 *
 * The floor of `x` is the largest integer `y` such that `y <= x`, i.e `x`
 * rounded down to the nearest integer.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on single-precision floating point values, use
 * SDL_floor for double-precision floats.
 *
 * \param x floating point value.
 * \returns the floor of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_floor
 * \sa SDL_ceilf
 * \sa SDL_truncf
 * \sa SDL_roundf
 * \sa SDL_lroundf
 */
	[CLink] public static extern float SDL_floorf(float x);

/**
 * Truncate `x` to an integer.
 *
 * Rounds `x` to the next closest integer to 0. This is equivalent to removing
 * the fractional part of `x`, leaving only the integer part.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on double-precision floating point values, use
 * SDL_truncf for single-precision floats.
 *
 * \param x floating point value.
 * \returns `x` truncated to an integer.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_truncf
 * \sa SDL_fmod
 * \sa SDL_ceil
 * \sa SDL_floor
 * \sa SDL_round
 * \sa SDL_lround
 */
	[CLink] public static extern double SDL_trunc(double x);

/**
 * Truncate `x` to an integer.
 *
 * Rounds `x` to the next closest integer to 0. This is equivalent to removing
 * the fractional part of `x`, leaving only the integer part.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on single-precision floating point values, use
 * SDL_trunc for double-precision floats.
 *
 * \param x floating point value.
 * \returns `x` truncated to an integer.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_trunc
 * \sa SDL_fmodf
 * \sa SDL_ceilf
 * \sa SDL_floorf
 * \sa SDL_roundf
 * \sa SDL_lroundf
 */
	[CLink] public static extern float SDL_truncf(float x);

/**
 * Return the floating-point remainder of `x / y`
 *
 * Divides `x` by `y`, and returns the remainder.
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`, `y != 0`
 *
 * Range: `-y <= z <= y`
 *
 * This function operates on double-precision floating point values, use
 * SDL_fmodf for single-precision floats.
 *
 * \param x the numerator.
 * \param y the denominator. Must not be 0.
 * \returns the remainder of `x / y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_fmodf
 * \sa SDL_modf
 * \sa SDL_trunc
 * \sa SDL_ceil
 * \sa SDL_floor
 * \sa SDL_round
 * \sa SDL_lround
 */
	[CLink] public static extern double SDL_fmod(double x, double y);

/**
 * Return the floating-point remainder of `x / y`
 *
 * Divides `x` by `y`, and returns the remainder.
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`, `y != 0`
 *
 * Range: `-y <= z <= y`
 *
 * This function operates on single-precision floating point values, use
 * SDL_fmod for double-precision floats.
 *
 * \param x the numerator.
 * \param y the denominator. Must not be 0.
 * \returns the remainder of `x / y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_fmod
 * \sa SDL_truncf
 * \sa SDL_modff
 * \sa SDL_ceilf
 * \sa SDL_floorf
 * \sa SDL_roundf
 * \sa SDL_lroundf
 */
	[CLink] public static extern float SDL_fmodf(float x, float y);

/**
 * Return whether the value is infinity.
 *
 * \param x double-precision floating point value.
 * \returns non-zero if the value is infinity, 0 otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isinff
 */
	[CLink] public static extern int32 SDL_isinf(double x);

/**
 * Return whether the value is infinity.
 *
 * \param x floating point value.
 * \returns non-zero if the value is infinity, 0 otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isinf
 */
	[CLink] public static extern int32 SDL_isinff(float x);

/**
 * Return whether the value is NaN.
 *
 * \param x double-precision floating point value.
 * \returns non-zero if the value is NaN, 0 otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isnanf
 */
	[CLink] public static extern int32 SDL_isnan(double x);

/**
 * Return whether the value is NaN.
 *
 * \param x floating point value.
 * \returns non-zero if the value is NaN, 0 otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_isnan
 */
	[CLink] public static extern int32 SDL_isnanf(float x);

/**
 * Compute the natural logarithm of `x`.
 *
 * Domain: `0 < x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * It is an error for `x` to be less than or equal to 0.
 *
 * This function operates on double-precision floating point values, use
 * SDL_logf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than 0.
 * \returns the natural logarithm of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_logf
 * \sa SDL_log10
 * \sa SDL_exp
 */
	[CLink] public static extern double SDL_log(double x);

/**
 * Compute the natural logarithm of `x`.
 *
 * Domain: `0 < x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * It is an error for `x` to be less than or equal to 0.
 *
 * This function operates on single-precision floating point values, use
 * SDL_log for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than 0.
 * \returns the natural logarithm of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_log
 * \sa SDL_expf
 */
	[CLink] public static extern float SDL_logf(float x);

/**
 * Compute the base-10 logarithm of `x`.
 *
 * Domain: `0 < x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * It is an error for `x` to be less than or equal to 0.
 *
 * This function operates on double-precision floating point values, use
 * SDL_log10f for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than 0.
 * \returns the logarithm of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_log10f
 * \sa SDL_log
 * \sa SDL_pow
 */
	[CLink] public static extern double SDL_log10(double x);

/**
 * Compute the base-10 logarithm of `x`.
 *
 * Domain: `0 < x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * It is an error for `x` to be less than or equal to 0.
 *
 * This function operates on single-precision floating point values, use
 * SDL_log10 for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than 0.
 * \returns the logarithm of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_log10
 * \sa SDL_logf
 * \sa SDL_powf
 */
	[CLink] public static extern float SDL_log10f(float x);

/**
 * Split `x` into integer and fractional parts
 *
 * This function operates on double-precision floating point values, use
 * SDL_modff for single-precision floats.
 *
 * \param x floating point value.
 * \param y output pointer to store the integer part of `x`.
 * \returns the fractional part of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_modff
 * \sa SDL_trunc
 * \sa SDL_fmod
 */
	[CLink] public static extern double SDL_modf(double x, double* y);

/**
 * Split `x` into integer and fractional parts
 *
 * This function operates on single-precision floating point values, use
 * SDL_modf for double-precision floats.
 *
 * \param x floating point value.
 * \param y output pointer to store the integer part of `x`.
 * \returns the fractional part of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_modf
 * \sa SDL_truncf
 * \sa SDL_fmodf
 */
	[CLink] public static extern float SDL_modff(float x, float* y);

/**
 * Raise `x` to the power `y`
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`
 *
 * Range: `-INF <= z <= INF`
 *
 * If `y` is the base of the natural logarithm (e), consider using SDL_exp
 * instead.
 *
 * This function operates on double-precision floating point values, use
 * SDL_powf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x the base.
 * \param y the exponent.
 * \returns `x` raised to the power `y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_powf
 * \sa SDL_exp
 * \sa SDL_log
 */
	[CLink] public static extern double SDL_pow(double x, double y);

/**
 * Raise `x` to the power `y`
 *
 * Domain: `-INF <= x <= INF`, `-INF <= y <= INF`
 *
 * Range: `-INF <= z <= INF`
 *
 * If `y` is the base of the natural logarithm (e), consider using SDL_exp
 * instead.
 *
 * This function operates on single-precision floating point values, use
 * SDL_pow for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x the base.
 * \param y the exponent.
 * \returns `x` raised to the power `y`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_pow
 * \sa SDL_expf
 * \sa SDL_logf
 */
	[CLink] public static extern float SDL_powf(float x, float y);

/**
 * Round `x` to the nearest integer.
 *
 * Rounds `x` to the nearest integer. Values halfway between integers will be
 * rounded away from zero.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on double-precision floating point values, use
 * SDL_roundf for single-precision floats. To get the result as an integer
 * type, use SDL_lround.
 *
 * \param x floating point value.
 * \returns the nearest integer to `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_roundf
 * \sa SDL_lround
 * \sa SDL_floor
 * \sa SDL_ceil
 * \sa SDL_trunc
 */
	[CLink] public static extern double SDL_round(double x);

/**
 * Round `x` to the nearest integer.
 *
 * Rounds `x` to the nearest integer. Values halfway between integers will be
 * rounded away from zero.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`, y integer
 *
 * This function operates on single-precision floating point values, use
 * SDL_round for double-precision floats. To get the result as an integer
 * type, use SDL_lroundf.
 *
 * \param x floating point value.
 * \returns the nearest integer to `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_round
 * \sa SDL_lroundf
 * \sa SDL_floorf
 * \sa SDL_ceilf
 * \sa SDL_truncf
 */
	[CLink] public static extern float SDL_roundf(float x);

/**
 * Round `x` to the nearest integer representable as a long
 *
 * Rounds `x` to the nearest integer. Values halfway between integers will be
 * rounded away from zero.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `MIN_LONG <= y <= MAX_LONG`
 *
 * This function operates on double-precision floating point values, use
 * SDL_lroundf for single-precision floats. To get the result as a
 * floating-point type, use SDL_round.
 *
 * \param x floating point value.
 * \returns the nearest integer to `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_lroundf
 * \sa SDL_round
 * \sa SDL_floor
 * \sa SDL_ceil
 * \sa SDL_trunc
 */
	[CLink] public static extern int64 SDL_lround(double x);

/**
 * Round `x` to the nearest integer representable as a long
 *
 * Rounds `x` to the nearest integer. Values halfway between integers will be
 * rounded away from zero.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `MIN_LONG <= y <= MAX_LONG`
 *
 * This function operates on single-precision floating point values, use
 * SDL_lround for double-precision floats. To get the result as a
 * floating-point type, use SDL_roundf.
 *
 * \param x floating point value.
 * \returns the nearest integer to `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_lround
 * \sa SDL_roundf
 * \sa SDL_floorf
 * \sa SDL_ceilf
 * \sa SDL_truncf
 */
	[CLink] public static extern int64 SDL_lroundf(float x);

/**
 * Scale `x` by an integer power of two.
 *
 * Multiplies `x` by the `n`th power of the floating point radix (always 2).
 *
 * Domain: `-INF <= x <= INF`, `n` integer
 *
 * Range: `-INF <= y <= INF`
 *
 * This function operates on double-precision floating point values, use
 * SDL_scalbnf for single-precision floats.
 *
 * \param x floating point value to be scaled.
 * \param n integer exponent.
 * \returns `x * 2^n`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_scalbnf
 * \sa SDL_pow
 */
	[CLink] public static extern double SDL_scalbn(double x, int32 n);

/**
 * Scale `x` by an integer power of two.
 *
 * Multiplies `x` by the `n`th power of the floating point radix (always 2).
 *
 * Domain: `-INF <= x <= INF`, `n` integer
 *
 * Range: `-INF <= y <= INF`
 *
 * This function operates on single-precision floating point values, use
 * SDL_scalbn for double-precision floats.
 *
 * \param x floating point value to be scaled.
 * \param n integer exponent.
 * \returns `x * 2^n`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_scalbn
 * \sa SDL_powf
 */
	[CLink] public static extern float SDL_scalbnf(float x, int32 n);

/**
 * Compute the sine of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-1 <= y <= 1`
 *
 * This function operates on double-precision floating point values, use
 * SDL_sinf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns sine of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_sinf
 * \sa SDL_asin
 * \sa SDL_cos
 */
	[CLink] public static extern double SDL_sin(double x);

/**
 * Compute the sine of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-1 <= y <= 1`
 *
 * This function operates on single-precision floating point values, use
 * SDL_sin for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns sine of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_sin
 * \sa SDL_asinf
 * \sa SDL_cosf
 */
	[CLink] public static extern float SDL_sinf(float x);

/**
 * Compute the square root of `x`.
 *
 * Domain: `0 <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * This function operates on double-precision floating point values, use
 * SDL_sqrtf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than or equal to 0.
 * \returns square root of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_sqrtf
 */
	[CLink] public static extern double SDL_sqrt(double x);

/**
 * Compute the square root of `x`.
 *
 * Domain: `0 <= x <= INF`
 *
 * Range: `0 <= y <= INF`
 *
 * This function operates on single-precision floating point values, use
 * SDL_sqrt for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value. Must be greater than or equal to 0.
 * \returns square root of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_sqrt
 */
	[CLink] public static extern float SDL_sqrtf(float x);

/**
 * Compute the tangent of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * This function operates on double-precision floating point values, use
 * SDL_tanf for single-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns tangent of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_tanf
 * \sa SDL_sin
 * \sa SDL_cos
 * \sa SDL_atan
 * \sa SDL_atan2
 */
	[CLink] public static extern double SDL_tan(double x);

/**
 * Compute the tangent of `x`.
 *
 * Domain: `-INF <= x <= INF`
 *
 * Range: `-INF <= y <= INF`
 *
 * This function operates on single-precision floating point values, use
 * SDL_tan for double-precision floats.
 *
 * This function may use a different approximation across different versions,
 * platforms and configurations. i.e, it can return a different value given
 * the same input on different machines or operating systems, or if SDL is
 * updated.
 *
 * \param x floating point value, in radians.
 * \returns tangent of `x`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_tan
 * \sa SDL_sinf
 * \sa SDL_cosf
 * \sa SDL_atanf
 * \sa SDL_atan2f
 */
	[CLink] public static extern float SDL_tanf(float x);
}

/**
 * An opaque handle representing string encoding conversion state.
 *
 * \since This datatype is available since SDL 3.2.0.
 *
 * \sa SDL_iconv_open
 */
[CRepr] public struct SDL_iconv_data_t;
public typealias SDL_iconv_t =  SDL_iconv_data_t*;

public static // extension SDL3
{
/**
 * This function allocates a context for the specified character set
 * conversion.
 *
 * \param tocode The target character encoding, must not be NULL.
 * \param fromcode The source character encoding, must not be NULL.
 * \returns a handle that must be freed with SDL_iconv_close, or
 *          SDL_ICONV_ERROR on failure.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_iconv
 * \sa SDL_iconv_close
 * \sa SDL_iconv_string
 */
	[CLink] public static extern SDL_iconv_t SDL_iconv_open(char8* tocode,
		char8* fromcode);

/**
 * This function frees a context used for character set conversion.
 *
 * \param cd The character set conversion handle.
 * \returns 0 on success, or -1 on failure.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_iconv
 * \sa SDL_iconv_open
 * \sa SDL_iconv_string
 */
	[CLink] public static extern int32 SDL_iconv_close(SDL_iconv_t cd);

/**
 * This function converts text between encodings, reading from and writing to
 * a buffer.
 *
 * It returns the number of successful conversions on success. On error,
 * SDL_ICONV_E2BIG is returned when the output buffer is too small, or
 * SDL_ICONV_EILSEQ is returned when an invalid input sequence is encountered,
 * or SDL_ICONV_EINVAL is returned when an incomplete input sequence is
 * encountered.
 *
 * On exit:
 *
 * - inbuf will point to the beginning of the next multibyte sequence. On
 *   error, this is the location of the problematic input sequence. On
 *   success, this is the end of the input sequence.
 * - inbytesleft will be set to the number of bytes left to convert, which
 *   will be 0 on success.
 * - outbuf will point to the location where to store the next output byte.
 * - outbytesleft will be set to the number of bytes left in the output
 *   buffer.
 *
 * \param cd The character set conversion context, created in
 *           SDL_iconv_open().
 * \param inbuf Address of variable that points to the first character of the
 *              input sequence.
 * \param inbytesleft The number of bytes in the input buffer.
 * \param outbuf Address of variable that points to the output buffer.
 * \param outbytesleft The number of bytes in the output buffer.
 * \returns the number of conversions on success, or a negative error code.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_iconv_open
 * \sa SDL_iconv_close
 * \sa SDL_iconv_string
 */
	[CLink] public static extern uint SDL_iconv(SDL_iconv_t cd, char8** inbuf,
		uint* inbytesleft, char8** outbuf,
		uint* outbytesleft);

	public const uint SDL_ICONV_ERROR     = (uint) - 1; /**< Generic error. Check SDL_GetError()? */
	public const uint SDL_ICONV_E2BIG     = (uint) - 2; /**< Output buffer was too small. */
	public const uint SDL_ICONV_EILSEQ    = (uint) - 3; /**< Invalid input sequence was encountered. */
	public const uint SDL_ICONV_EINVAL    = (uint) - 4; /**< Incomplete input sequence was encountered. */


/**
 * Helper function to convert a string's encoding in one call.
 *
 * This function converts a buffer or string between encodings in one pass.
 *
 * The string does not need to be NULL-terminated; this function operates on
 * the number of bytes specified in `inbytesleft` whether there is a NULL
 * character anywhere in the buffer.
 *
 * The returned string is owned by the caller, and should be passed to
 * SDL_free when no longer needed.
 *
 * \param tocode the character encoding of the output string. Examples are
 *               "UTF-8", "UCS-4", etc.
 * \param fromcode the character encoding of data in `inbuf`.
 * \param inbuf the string to convert to a different encoding.
 * \param inbytesleft the size of the input string _in bytes_.
 * \returns a new string, converted to the new encoding, or NULL on error.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_iconv_open
 * \sa SDL_iconv_close
 * \sa SDL_iconv
 */
	[CLink] public static extern char8* SDL_iconv_string(char8* tocode,
		char8* fromcode,
		char8* inbuf,
		uint inbytesleft);

/* Some helper macros for common SDL_iconv_string cases... */

/**
 * Convert a UTF-8 string to the current locale's character encoding.
 *
 * This is a helper macro that might be more clear than calling
 * SDL_iconv_string directly. However, it double-evaluates its parameter, so
 * do not use an expression with side-effects here.
 *
 * \param S the string to convert.
 * \returns a new string, converted to the new encoding, or NULL on error.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static char8* SDL_iconv_utf8_locale(char8* S)  =>  SDL_iconv_string("", "UTF-8", S, SDL_strlen(S) + 1);

/**
 * Convert a UTF-8 string to UCS-2.
 *
 * This is a helper macro that might be more clear than calling
 * SDL_iconv_string directly. However, it double-evaluates its parameter, so
 * do not use an expression with side-effects here.
 *
 * \param S the string to convert.
 * \returns a new string, converted to the new encoding, or NULL on error.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint16* SDL_iconv_utf8_ucs2(char8* S)   =>   (uint16*)SDL_iconv_string("UCS-2", "UTF-8", S, SDL_strlen(S) + 1);

/**
 * Convert a UTF-8 string to UCS-4.
 *
 * This is a helper macro that might be more clear than calling
 * SDL_iconv_string directly. However, it double-evaluates its parameter, so
 * do not use an expression with side-effects here.
 *
 * \param S the string to convert.
 * \returns a new string, converted to the new encoding, or NULL on error.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static uint32* SDL_iconv_utf8_ucs4(char8* S)   =>   (uint32*)SDL_iconv_string("UCS-4", "UTF-8", S, SDL_strlen(S) + 1);

/**
 * Convert a wchar_t string to UTF-8.
 *
 * This is a helper macro that might be more clear than calling
 * SDL_iconv_string directly. However, it double-evaluates its parameter, so
 * do not use an expression with side-effects here.
 *
 * \param S the string to convert.
 * \returns a new string, converted to the new encoding, or NULL on error.
 *
 * \since This macro is available since SDL 3.2.0.
 */
	public static char8* SDL_iconv_wchar_utf8(c_wchar* S)   =>  SDL_iconv_string("UTF-8", "WCHAR_T", (char8*)S, (SDL_wcslen(S) + 1) * sizeof(c_wchar));

/**
 * Multiply two integers, checking for overflow.
 *
 * If `a * b` would overflow, return false.
 *
 * Otherwise store `a * b` via ret and return true.
 *
 * \param a the multiplicand.
 * \param b the multiplier.
 * \param ret on non-overflow output, stores the multiplication result, may
 *            not be NULL.
 * \returns false on overflow, true if result is multiplied without overflow.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[Inline] public static bool SDL_size_mul_check_overflow(uint a, uint b, uint* ret)
	{
		if (a != 0 && b > SDL_SIZE_MAX / a)
		{
			return false;
		}
		*ret = a * b;
		return true;
	}

/**
 * Add two integers, checking for overflow.
 *
 * If `a + b` would overflow, return false.
 *
 * Otherwise store `a + b` via ret and return true.
 *
 * \param a the first addend.
 * \param b the second addend.
 * \param ret on non-overflow output, stores the addition result, may not be
 *            NULL.
 * \returns false on overflow, true if result is added without overflow.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[Inline] public static bool SDL_size_add_check_overflow(uint a, uint b, uint* ret)
	{
		if (b > SDL_SIZE_MAX - a)
		{
			return false;
		}
		*ret = a + b;
		return true;
	}
}

public typealias SDL_FunctionPointer = function void();