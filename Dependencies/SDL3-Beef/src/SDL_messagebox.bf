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
 * # CategoryMessagebox
 *
 * SDL offers a simple message box API, which is useful for simple alerts,
 * such as informing the user when something fatal happens at startup without
 * the need to build a UI for it (or informing the user _before_ your UI is
 * ready).
 *
 * These message boxes are native system dialogs where possible.
 *
 * There is both a customizable function (SDL_ShowMessageBox()) that offers
 * lots of options for what to display and reports on what choice the user
 * made, and also a much-simplified version (SDL_ShowSimpleMessageBox()),
 * merely takes a text message and title, and waits until the user presses a
 * single "OK" UI button. Often, this is all that is necessary.
 */

namespace SDL3;

/**
 * Message box flags.
 *
 * If supported will display warning icon, etc.
 *
 * \since This datatype is available since SDL 3.2.0.
 */
public enum SDL_MessageBoxFlags : uint32 //public typealias SDL_MessageBoxFlags = uint32;
{
	SDL_MESSAGEBOX_ERROR                    = 0x00000010, /**< error dialog */
	SDL_MESSAGEBOX_WARNING                  = 0x00000020, /**< warning dialog */
	SDL_MESSAGEBOX_INFORMATION              = 0x00000040, /**< informational dialog */
	SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT    = 0x00000080, /**< buttons placed left to right */
	SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT    = 0x00000100, /**< buttons placed right to left */
}

/**
 * SDL_MessageBoxButtonData flags.
 *
 * \since This datatype is available since SDL 3.2.0.
 */
public enum SDL_MessageBoxButtonFlags : uint32 //public typealias SDL_MessageBoxButtonFlags = uint32;
{
	SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT = 0x00000001, /**< Marks the default button when return is hit */
	SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT = 0x00000002, /**< Marks the default button when escape is hit */
}
/**
 * Individual button data.
 *
 * \since This struct is available since SDL 3.2.0.
 */
[CRepr] public struct SDL_MessageBoxButtonData
{
	public SDL_MessageBoxButtonFlags flags;
	public int32 buttonID; /**< User defined button id (value returned via SDL_ShowMessageBox) */
	public char8* text; /**< The UTF-8 button text */
}

/**
 * RGB value used in a message box color scheme
 *
 * \since This struct is available since SDL 3.2.0.
 */
[CRepr] public struct SDL_MessageBoxColor
{
	uint8 r, g, b;
}

/**
 * An enumeration of indices inside the colors array of
 * SDL_MessageBoxColorScheme.
 */
public enum SDL_MessageBoxColorType : int32
{
	SDL_MESSAGEBOX_COLOR_BACKGROUND,
	SDL_MESSAGEBOX_COLOR_TEXT,
	SDL_MESSAGEBOX_COLOR_BUTTON_BORDER,
	SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND,
	SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED,
	SDL_MESSAGEBOX_COLOR_COUNT /**< Size of the colors array of SDL_MessageBoxColorScheme. */
}

/**
 * A set of colors to use for message box dialogs
 *
 * \since This struct is available since SDL 3.2.0.
 */
[CRepr] public struct SDL_MessageBoxColorScheme
{
	public SDL_MessageBoxColor[(int32)SDL_MessageBoxColorType.SDL_MESSAGEBOX_COLOR_COUNT] colors;
}

/**
 * MessageBox structure containing title, text, window, etc.
 *
 * \since This struct is available since SDL 3.2.0.
 */
[CRepr] public struct SDL_MessageBoxData
{
	public SDL_MessageBoxFlags flags;
	public SDL_Window* window; /**< Parent window, can be NULL */
	public char8* title; /**< UTF-8 title */
	public char8* message; /**< UTF-8 message text */

	public int32 numbuttons;
	public SDL_MessageBoxButtonData* buttons;

	public SDL_MessageBoxColorScheme* colorScheme; /**< SDL_MessageBoxColorScheme, can be NULL to use system settings */
}

public static //extension SDL3
{

/**
 * Create a modal message box.
 *
 * If your needs aren't complex, it might be easier to use
 * SDL_ShowSimpleMessageBox.
 *
 * This function should be called on the thread that created the parent
 * window, or on the main thread if the messagebox has no parent. It will
 * block execution of that thread until the user clicks a button or closes the
 * messagebox.
 *
 * This function may be called at any time, even before SDL_Init(). This makes
 * it useful for reporting errors like a failure to create a renderer or
 * OpenGL context.
 *
 * On X11, SDL rolls its own dialog box with X11 primitives instead of a
 * formal toolkit like GTK+ or Qt.
 *
 * Note that if SDL_Init() would fail because there isn't any available video
 * target, this function is likely to fail for the same reasons. If this is a
 * concern, check the return value from this function and fall back to writing
 * to stderr if you can.
 *
 * \param messageboxdata the SDL_MessageBoxData structure with title, text and
 *                       other options.
 * \param buttonid the pointer to which user id of hit button should be
 *                 copied.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ShowSimpleMessageBox
 */
	[CLink] public static extern bool SDL_ShowMessageBox(SDL_MessageBoxData* messageboxdata, int32* buttonid);

/**
 * Display a simple modal message box.
 *
 * If your needs aren't complex, this function is preferred over
 * SDL_ShowMessageBox.
 *
 * `flags` may be any of the following:
 *
 * - `SDL_MESSAGEBOX_ERROR`: error dialog
 * - `SDL_MESSAGEBOX_WARNING`: warning dialog
 * - `SDL_MESSAGEBOX_INFORMATION`: informational dialog
 *
 * This function should be called on the thread that created the parent
 * window, or on the main thread if the messagebox has no parent. It will
 * block execution of that thread until the user clicks a button or closes the
 * messagebox.
 *
 * This function may be called at any time, even before SDL_Init(). This makes
 * it useful for reporting errors like a failure to create a renderer or
 * OpenGL context.
 *
 * On X11, SDL rolls its own dialog box with X11 primitives instead of a
 * formal toolkit like GTK+ or Qt.
 *
 * Note that if SDL_Init() would fail because there isn't any available video
 * target, this function is likely to fail for the same reasons. If this is a
 * concern, check the return value from this function and fall back to writing
 * to stderr if you can.
 *
 * \param flags an SDL_MessageBoxFlags value.
 * \param title UTF-8 title text.
 * \param message UTF-8 message text.
 * \param window the parent window, or NULL for no parent.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ShowMessageBox
 */
	[CLink] public static extern bool SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags flags, char8* title, char8* message, SDL_Window* window);
}
