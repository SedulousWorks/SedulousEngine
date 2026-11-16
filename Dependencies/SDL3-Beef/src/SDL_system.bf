using System;
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
 * # CategorySystem
 *
 * Platform-specific SDL API functions. Only the Android ones the engine calls are bound.
 */

namespace SDL3;

public static //extension SDL3
{
#if BF_PLATFORM_ANDROID
/**
 * Get the Android Java Native Interface Environment of the current thread.
 *
 * \returns a pointer to Java native interface object (JNIEnv) to which the
 *          current thread is attached, or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void* SDL_GetAndroidJNIEnv();

/**
 * Retrieve the Java instance of the Android activity class.
 *
 * The jobject returned by the function is a local reference and must be
 * released by the caller.
 *
 * \returns the jobject representing the instance of the Activity class of the
 *          Android application, or NULL on failure; call SDL_GetError() for
 *          more information.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void* SDL_GetAndroidActivity();
#endif
}
