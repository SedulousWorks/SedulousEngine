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
 * # CategoryMain
 *
 * Redefine main() if necessary so that it is called by SDL.
 *
 * In order to make this consistent on all platforms, the application's main()
 * should look like this:
 *
 * ```c
 * #include <SDL3/SDL.h>
 * #include <SDL3/SDL_main.h>
 *
 * int32 main(int32 argc, char8* argv[])
 * {
 * }
 * ```
 *
 * SDL will take care of platform specific details on how it gets called.
 *
 * This is also where an app can be configured to use the main callbacks, via
 * the SDL_MAIN_USE_CALLBACKS macro.
 *
 * SDL_main.h is a "single-header library," which is to say that including
 * this header inserts code into your program, and you should only include it
 * once in most cases. SDL.h does not include this header automatically.
 *
 * For more information, see:
 *
 * https://wiki.libsdl.org/SDL3/README-main-functions
 */

namespace SDL3;

public static //extension SDL3
{
/**
 * App-implemented initial entry point for SDL_MAIN_USE_CALLBACKS apps.
 *
 * Apps implement this function when using SDL_MAIN_USE_CALLBACKS. If using a
 * standard "main" function, you should not supply this.
 *
 * This function is called by SDL once, at startup. The function should
 * initialize whatever is necessary, possibly create windows and open audio
 * devices, etc. The `argc` and `argv` parameters work like they would with a
 * standard "main" function.
 *
 * This function should not go into an infinite mainloop; it should do any
 * one-time setup it requires and then return.
 *
 * The app may optionally assign a pointer to `*appstate`. This pointer will
 * be provided on every future call to the other entry points, to allow
 * application state to be preserved between functions without the app needing
 * to use a global variable. If this isn't set, the pointer will be NULL in
 * future entry points.
 *
 * If this function returns SDL_APP_CONTINUE, the app will proceed to normal
 * operation, and will begin receiving repeated calls to SDL_AppIterate and
 * SDL_AppEvent for the life of the program. If this function returns
 * SDL_APP_FAILURE, SDL will call SDL_AppQuit and terminate the process with
 * an exit code that reports an error to the platform. If it returns
 * SDL_APP_SUCCESS, SDL calls SDL_AppQuit and terminates with an exit code
 * that reports success to the platform.
 *
 * This function is called by SDL on the main thread.
 *
 * \param appstate a place where the app can optionally store a pointer for
 *                 future use.
 * \param argc the standard ANSI C main's argc; number of elements in `argv`.
 * \param argv the standard ANSI C main's argv; array of command line
 *             arguments.
 * \returns SDL_APP_FAILURE to terminate with an error, SDL_APP_SUCCESS to
 *          terminate with success, SDL_APP_CONTINUE to continue.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AppIterate
 * \sa SDL_AppEvent
 * \sa SDL_AppQuit
 */
	[CLink] public static extern SDL_AppResult SDL_AppInit(void** appstate, int32 argc, char8*[] argv);

/**
 * App-implemented iteration entry point for SDL_MAIN_USE_CALLBACKS apps.
 *
 * Apps implement this function when using SDL_MAIN_USE_CALLBACKS. If using a
 * standard "main" function, you should not supply this.
 *
 * This function is called repeatedly by SDL after SDL_AppInit returns
 * SDL_APP_CONTINUE. The function should operate as a single iteration the
 * program's primary loop; it should update whatever state it needs and draw a
 * new frame of video, usually.
 *
 * On some platforms, this function will be called at the refresh rate of the
 * display (which might change during the life of your app!). There are no
 * promises made about what frequency this function might run at. You should
 * use SDL's timer functions if you need to see how much time has passed since
 * the last iteration.
 *
 * There is no need to process the SDL event queue during this function; SDL
 * will send events as they arrive in SDL_AppEvent, and in most cases the
 * event queue will be empty when this function runs anyhow.
 *
 * This function should not go into an infinite mainloop; it should do one
 * iteration of whatever the program does and return.
 *
 * The `appstate` parameter is an optional pointer provided by the app during
 * SDL_AppInit(). If the app never provided a pointer, this will be NULL.
 *
 * If this function returns SDL_APP_CONTINUE, the app will continue normal
 * operation, receiving repeated calls to SDL_AppIterate and SDL_AppEvent for
 * the life of the program. If this function returns SDL_APP_FAILURE, SDL will
 * call SDL_AppQuit and terminate the process with an exit code that reports
 * an error to the platform. If it returns SDL_APP_SUCCESS, SDL calls
 * SDL_AppQuit and terminates with an exit code that reports success to the
 * platform.
 *
 * This function is called by SDL on the main thread.
 *
 * \param appstate an optional pointer, provided by the app in SDL_AppInit.
 * \returns SDL_APP_FAILURE to terminate with an error, SDL_APP_SUCCESS to
 *          terminate with success, SDL_APP_CONTINUE to continue.
 *
 * \threadsafety This function may get called concurrently with SDL_AppEvent()
 *               for events not pushed on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AppInit
 * \sa SDL_AppEvent
 */
	[CLink] public static extern SDL_AppResult SDL_AppIterate(void* appstate);

/**
 * App-implemented event entry point for SDL_MAIN_USE_CALLBACKS apps.
 *
 * Apps implement this function when using SDL_MAIN_USE_CALLBACKS. If using a
 * standard "main" function, you should not supply this.
 *
 * This function is called as needed by SDL after SDL_AppInit returns
 * SDL_APP_CONTINUE. It is called once for each new event.
 *
 * There is (currently) no guarantee about what thread this will be called
 * from; whatever thread pushes an event onto SDL's queue will trigger this
 * function. SDL is responsible for pumping the event queue between each call
 * to SDL_AppIterate, so in normal operation one should only get events in a
 * serial fashion, but be careful if you have a thread that explicitly calls
 * SDL_PushEvent. SDL itself will push events to the queue on the main thread.
 *
 * Events sent to this function are not owned by the app; if you need to save
 * the data, you should copy it.
 *
 * This function should not go into an infinite mainloop; it should handle the
 * provided event appropriately and return.
 *
 * The `appstate` parameter is an optional pointer provided by the app during
 * SDL_AppInit(). If the app never provided a pointer, this will be NULL.
 *
 * If this function returns SDL_APP_CONTINUE, the app will continue normal
 * operation, receiving repeated calls to SDL_AppIterate and SDL_AppEvent for
 * the life of the program. If this function returns SDL_APP_FAILURE, SDL will
 * call SDL_AppQuit and terminate the process with an exit code that reports
 * an error to the platform. If it returns SDL_APP_SUCCESS, SDL calls
 * SDL_AppQuit and terminates with an exit code that reports success to the
 * platform.
 *
 * \param appstate an optional pointer, provided by the app in SDL_AppInit.
 * \param event the new event for the app to examine.
 * \returns SDL_APP_FAILURE to terminate with an error, SDL_APP_SUCCESS to
 *          terminate with success, SDL_APP_CONTINUE to continue.
 *
 * \threadsafety This function may get called concurrently with
 *               SDL_AppIterate() or SDL_AppQuit() for events not pushed from
 *               the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AppInit
 * \sa SDL_AppIterate
 */
	[CLink] public static extern SDL_AppResult SDL_AppEvent(void* appstate, SDL_Event* event);

/**
 * App-implemented deinit entry point for SDL_MAIN_USE_CALLBACKS apps.
 *
 * Apps implement this function when using SDL_MAIN_USE_CALLBACKS. If using a
 * standard "main" function, you should not supply this.
 *
 * This function is called once by SDL before terminating the program.
 *
 * This function will be called in all cases, even if SDL_AppInit requests
 * termination at startup.
 *
 * This function should not go into an infinite mainloop; it should
 * deinitialize any resources necessary, perform whatever shutdown activities,
 * and return.
 *
 * You do not need to call SDL_Quit() in this function, as SDL will call it
 * after this function returns and before the process terminates, but it is
 * safe to do so.
 *
 * The `appstate` parameter is an optional pointer provided by the app during
 * SDL_AppInit(). If the app never provided a pointer, this will be NULL. This
 * function call is the last time this pointer will be provided, so any
 * resources to it should be cleaned up here.
 *
 * This function is called by SDL on the main thread.
 *
 * \param appstate an optional pointer, provided by the app in SDL_AppInit.
 * \param result the result code that terminated the app (success or failure).
 *
 * \threadsafety SDL_AppEvent() may get called concurrently with this function
 *               if other threads that push events are still active.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AppInit
 */
	[CLink] public static extern void SDL_AppQuit(void* appstate, SDL_AppResult result);
}

/**
 * The prototype for the application's main() function
 *
 * \param argc an ANSI-C style main function's argc.
 * \param argv an ANSI-C style main function's argv.
 * \returns an ANSI-C main return code; generally 0 is considered successful
 *          program completion, and small non-zero values are considered
 *          errors.
 *
 * \since This datatype is available since SDL 3.2.0.
 */
public typealias SDL_main_func = function int32(int32 argc, char8*[] argv);

public static //extension SDL3
{

/**
 * An app-supplied function for program entry.
 *
 * Apps do not directly create this function; they should create a standard
 * ANSI-C `main` function instead. If SDL needs to insert some startup code
 * before `main` runs, or the platform doesn't actually _use_ a function
 * called "main", SDL will do some macro magic to redefine `main` to
 * `SDL_main` and provide its own `main`.
 *
 * Apps should include `SDL_main.h` in the same file as their `main` function,
 * and they should not use that symbol for anything else in that file, as it
 * might get redefined.
 *
 * This function is only provided by the app if it isn't using
 * SDL_MAIN_USE_CALLBACKS.
 *
 * Program startup is a surprisingly complex topic. Please see
 * [README-main-functions](README-main-functions), (or
 * docs/README-main-functions.md in the source tree) for a more detailed
 * explanation.
 *
 * \param argc an ANSI-C style main function's argc.
 * \param argv an ANSI-C style main function's argv.
 * \returns an ANSI-C main return code; generally 0 is considered successful
 *          program completion, and small non-zero values are considered
 *          errors.
 *
 * \threadsafety This is the program entry point.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_main(int32 argc, char8*[] argv);

/**
 * Circumvent failure of SDL_Init() when not using SDL_main() as an entry
 * point.
 *
 * This function is defined in SDL_main.h, along with the preprocessor rule to
 * redefine main() as SDL_main(). Thus to ensure that your main() function
 * will not be changed it is necessary to define SDL_MAIN_HANDLED before
 * including SDL.h.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_Init
 */
	[CLink] public static extern void SDL_SetMainReady();

/**
 * Initializes and launches an SDL application, by doing platform-specific
 * initialization before calling your mainFunction and cleanups after it
 * returns, if that is needed for a specific platform, otherwise it just calls
 * mainFunction.
 *
 * You can use this if you want to use your own main() implementation without
 * using SDL_main (like when using SDL_MAIN_HANDLED). When using this, you do
 * *not* need SDL_SetMainReady().
 *
 * If `argv` is NULL, SDL will provide command line arguments, either by
 * querying the OS for them if possible, or supplying a filler array if not.
 *
 * \param argc the argc parameter from the application's main() function, or 0
 *             if the platform's main-equivalent has no argc.
 * \param argv the argv parameter from the application's main() function, or
 *             NULL if the platform's main-equivalent has no argv.
 * \param mainFunction your SDL app's C-style main(). NOT the function you're
 *                     calling this from! Its name doesn't matter; it doesn't
 *                     literally have to be `main`.
 * \param reserved should be NULL (reserved for future use, will probably be
 *                 platform-specific then).
 * \returns the return value from mainFunction: 0 on success, otherwise
 *          failure; SDL_GetError() might have more information on the
 *          failure.
 *
 * \threadsafety Generally this is called once, near startup, from the
 *               process's initial thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_RunApp(int32 argc, char8*[] argv, SDL_main_func mainFunction, void* reserved);

/**
 * An entry point for SDL's use in SDL_MAIN_USE_CALLBACKS.
 *
 * Generally, you should not call this function directly. This only exists to
 * hand off work into SDL as soon as possible, where it has a lot more control
 * and functionality available, and make the inline code in SDL_main.h as
 * small as possible.
 *
 * Not all platforms use this, it's actual use is hidden in a magic
 * header-only library, and you should not call this directly unless you
 * _really_ know what you're doing.
 *
 * \param argc standard Unix main argc.
 * \param argv standard Unix main argv.
 * \param appinit the application's SDL_AppInit function.
 * \param appiter the application's SDL_AppIterate function.
 * \param appevent the application's SDL_AppEvent function.
 * \param appquit the application's SDL_AppQuit function.
 * \returns standard Unix main return value.
 *
 * \threadsafety It is not safe to call this anywhere except as the only
 *               function call in SDL_main.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern int32 SDL_EnterAppMainCallbacks(int32 argc, char8*[] argv, SDL_AppInit_func appinit, SDL_AppIterate_func appiter, SDL_AppEvent_func appevent, SDL_AppQuit_func appquit);


#if BF_PLATFORM_WINDOWS //SDL_PLATFORM_WINDOWS

/**
 * Register a win32 window class for SDL's use.
 *
 * This can be called to set the application window class at startup. It is
 * safe to call this multiple times, as long as every call is eventually
 * paired with a call to SDL_UnregisterApp, but a second registration attempt
 * while a previous registration is still active will be ignored, other than
 * to increment a counter.
 *
 * Most applications do not need to, and should not, call this directly; SDL
 * will call it when initializing the video subsystem.
 *
 * If `name` is NULL, SDL currently uses `(CS_BYTEALIGNCLIENT | CS_OWNDC)` for
 * the style, regardless of what is specified here.
 *
 * \param name the window class name, in UTF-8 encoding. If NULL, SDL
 *             currently uses "SDL_app" but this isn't guaranteed.
 * \param style the value to use in WNDCLASSEX::style.
 * \param hInst the HINSTANCE to use in WNDCLASSEX::hInstance. If zero, SDL
 *              will use `GetModuleHandle(NULL)` instead.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_RegisterApp(char8* name, uint32 style, void* hInst);

/**
 * Deregister the win32 window class from an SDL_RegisterApp call.
 *
 * This can be called to undo the effects of SDL_RegisterApp.
 *
 * Most applications do not need to, and should not, call this directly; SDL
 * will call it when deinitializing the video subsystem.
 *
 * It is safe to call this multiple times, as long as every call is eventually
 * paired with a prior call to SDL_RegisterApp. The window class will only be
 * deregistered when the registration counter in SDL_RegisterApp decrements to
 * zero through calls to this function.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void SDL_UnregisterApp();

#endif /* defined(SDL_PLATFORM_WINDOWS) */ 

/**
 * Callback from the application to let the suspend continue.
 *
 * This function is only needed for Xbox GDK support; all other platforms will
 * do nothing and set an "unsupported" error message.
 *
 * \since This function is available since SDL 3.2.0.
 */
[CLink] public static extern void SDL_GDKSuspendComplete();
}
