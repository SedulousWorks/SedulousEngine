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
 * # CategoryClipboard
 *
 * SDL provides access to the system clipboard, both for reading information
 * from other processes and publishing information of its own.
 *
 * This is not just text! SDL apps can access and publish data by mimetype.
 *
 * ## Basic use (text)
 *
 * Obtaining and publishing simple text to the system clipboard is as easy as
 * calling SDL_GetClipboardText() and SDL_SetClipboardText(), respectively.
 * These deal with C strings in UTF-8 encoding. Data transmission and encoding
 * conversion is completely managed by SDL.
 *
 * ## Clipboard callbacks (data other than text)
 *
 * Things get more complicated when the clipboard contains something other
 * than text. Not only can the system clipboard contain data of any type, in
 * some cases it can contain the same data in different formats! For example,
 * an image painting app might let the user copy a graphic to the clipboard,
 * and offers it in .BMP, .JPG, or .PNG format for other apps to consume.
 *
 * Obtaining clipboard data ("pasting") like this is a matter of calling
 * SDL_GetClipboardData() and telling it the mimetype of the data you want.
 * But how does one know if that format is available? SDL_HasClipboardData()
 * can report if a specific mimetype is offered, and
 * SDL_GetClipboardMimeTypes() can provide the entire list of mimetypes
 * available, so the app can decide what to do with the data and what formats
 * it can support.
 *
 * Setting the clipboard ("copying") to arbitrary data is done with
 * SDL_SetClipboardData. The app does not provide the data in this call, but
 * rather the mimetypes it is willing to provide and a callback function.
 * During the callback, the app will generate the data. This allows massive
 * data sets to be provided to the clipboard, without any data being copied
 * before it is explicitly requested. More specifically, it allows an app to
 * offer data in multiple formats without providing a copy of all of them
 * upfront. If the app has an image that it could provide in PNG or JPG
 * format, it doesn't have to encode it to either of those unless and until
 * something tries to paste it.
 *
 * ## Primary Selection
 *
 * The X11 and Wayland video targets have a concept of the "primary selection"
 * in addition to the usual clipboard. This is generally highlighted (but not
 * explicitly copied) text from various apps. SDL offers APIs for this through
 * SDL_GetPrimarySelectionText() and SDL_SetPrimarySelectionText(). SDL offers
 * these APIs on platforms without this concept, too, but only so far that it
 * will keep a copy of a string that the app sets for later retrieval; the
 * operating system will not ever attempt to change the string externally if
 * it doesn't support a primary selection.
 */

namespace SDL3;

public static //extension SDL3
{
/* Function prototypes */

/**
 * Put UTF-8 text into the clipboard.
 *
 * \param text the text to store in the clipboard.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetClipboardText
 * \sa SDL_HasClipboardText
 */
	[CLink] public static extern bool SDL_SetClipboardText(char8* text);

/**
 * Get UTF-8 text from the clipboard.
 *
 * This function returns an empty string if there is not enough memory left
 * for a copy of the clipboard's content.
 *
 * \returns the clipboard text on success or an empty string on failure; call
 *          SDL_GetError() for more information. This should be freed with
 *          SDL_free() when it is no longer needed.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_HasClipboardText
 * \sa SDL_SetClipboardText
 */
	[CLink] public static extern char8*  SDL_GetClipboardText();

/**
 * Query whether the clipboard exists and contains a non-empty text string.
 *
 * \returns true if the clipboard has text, or false if it does not.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetClipboardText
 * \sa SDL_SetClipboardText
 */
	[CLink] public static extern bool SDL_HasClipboardText();

/**
 * Put UTF-8 text into the primary selection.
 *
 * \param text the text to store in the primary selection.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetPrimarySelectionText
 * \sa SDL_HasPrimarySelectionText
 */
	[CLink] public static extern bool SDL_SetPrimarySelectionText(char8* text);

/**
 * Get UTF-8 text from the primary selection.
 *
 * This function returns an empty string if there is not enough memory left
 * for a copy of the primary selection's content.
 *
 * \returns the primary selection text on success or an empty string on
 *          failure; call SDL_GetError() for more information. This should be
 *          freed with SDL_free() when it is no longer needed.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_HasPrimarySelectionText
 * \sa SDL_SetPrimarySelectionText
 */
	[CLink] public static extern char8*  SDL_GetPrimarySelectionText();

/**
 * Query whether the primary selection exists and contains a non-empty text
 * string.
 *
 * \returns true if the primary selection has text, or false if it does not.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetPrimarySelectionText
 * \sa SDL_SetPrimarySelectionText
 */
	[CLink] public static extern bool SDL_HasPrimarySelectionText();
}

/**
 * Callback function that will be called when data for the specified mime-type
 * is requested by the OS.
 *
 * The callback function is called with NULL as the mime_type when the
 * clipboard is cleared or new data is set. The clipboard is automatically
 * cleared in SDL_Quit().
 *
 * \param userdata a pointer to the provided user data.
 * \param mime_type the requested mime-type.
 * \param size a pointer filled in with the length of the returned data.
 * \returns a pointer to the data for the provided mime-type. Returning NULL
 *          or setting the length to 0 will cause zero length data to be sent
 *          to the "receiver", which should be able to handle this. The
 *          returned data will not be freed, so it needs to be retained and
 *          dealt with internally.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetClipboardData
 */
public typealias SDL_ClipboardDataCallback = function void*(void* userdata, char8* mime_type, uint* size);

/**
 * Callback function that will be called when the clipboard is cleared, or
 * when new data is set.
 *
 * \param userdata a pointer to the provided user data.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetClipboardData
 */
public typealias SDL_ClipboardCleanupCallback = function void(void* userdata);

public static //extension SDL3
{

/**
 * Offer clipboard data to the OS.
 *
 * Tell the operating system that the application is offering clipboard data
 * for each of the provided mime-types. Once another application requests the
 * data the callback function will be called, allowing it to generate and
 * respond with the data for the requested mime-type.
 *
 * The size of text data does not include any terminator, and the text does
 * not need to be null-terminated (e.g., you can directly copy a portion of a
 * document).
 *
 * \param callback a function pointer to the function that provides the
 *                 clipboard data.
 * \param cleanup a function pointer to the function that cleans up the
 *                clipboard data.
 * \param userdata an opaque pointer that will be forwarded to the callbacks.
 * \param mime_types a list of mime-types that are being offered. SDL copies
 *                   the given list.
 * \param num_mime_types the number of mime-types in the mime_types list.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_ClearClipboardData
 * \sa SDL_GetClipboardData
 * \sa SDL_HasClipboardData
 */
	[CLink] public static extern bool SDL_SetClipboardData(SDL_ClipboardDataCallback callback, SDL_ClipboardCleanupCallback cleanup, void* userdata, char8** mime_types, uint num_mime_types);

/**
 * Clear the clipboard data.
 *
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetClipboardData
 */
	[CLink] public static extern bool SDL_ClearClipboardData();

/**
 * Get the data from the clipboard for a given mime type.
 *
 * The size of text data does not include the terminator, but the text is
 * guaranteed to be null-terminated.
 *
 * \param mime_type the mime type to read from the clipboard.
 * \param size a pointer filled in with the length of the returned data.
 * \returns the retrieved data buffer or NULL on failure; call SDL_GetError()
 *          for more information. This should be freed with SDL_free() when it
 *          is no longer needed.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_HasClipboardData
 * \sa SDL_SetClipboardData
 */
	[CLink] public static extern void* SDL_GetClipboardData(char8* mime_type, uint* size);

/**
 * Query whether there is data in the clipboard for the provided mime type.
 *
 * \param mime_type the mime type to check for data.
 * \returns true if data exists in the clipboard for the provided mime type,
 *          false if it does not.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetClipboardData
 * \sa SDL_GetClipboardData
 */
	[CLink] public static extern bool SDL_HasClipboardData(char8* mime_type);

/**
 * Retrieve the list of mime types available in the clipboard.
 *
 * \param num_mime_types a pointer filled with the number of mime types, may
 *                       be NULL.
 * \returns a null-terminated array of strings with mime types, or NULL on
 *          failure; call SDL_GetError() for more information. This should be
 *          freed with SDL_free() when it is no longer needed.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetClipboardData
 */
	[CLink] public static extern char8** SDL_GetClipboardMimeTypes(uint* num_mime_types);
}
