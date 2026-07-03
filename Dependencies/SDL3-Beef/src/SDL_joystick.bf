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
 * # CategoryJoystick
 *
 * SDL joystick support.
 *
 * This is the lower-level joystick handling. If you want the simpler option,
 * where what each button does is well-defined, you should use the gamepad API
 * instead.
 *
 * The term "instance_id" is the current instantiation of a joystick device in
 * the system. If the joystick is removed and then re-inserted then it will
 * get a new instance_id. instance_id's are monotonically increasing
 * identifiers of a joystick plugged in.
 *
 * The term "player_index" is the number assigned to a player on a specific
 * controller. For XInput controllers this returns the XInput user index. Many
 * joysticks will not be able to supply this information.
 *
 * SDL_GUID is used as a stable 128-bit identifier for a joystick device that
 * does not change over time. It identifies class of the device (a X360 wired
 * controller for example). This identifier is platform dependent.
 *
 * In order to use these functions, SDL_Init() must have been called with the
 * SDL_INIT_JOYSTICK flag. This causes SDL to scan the system for joysticks,
 * and load appropriate drivers.
 *
 * If you would like to receive joystick updates while the application is in
 * the background, you should set the following hint before calling
 * SDL_Init(): SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS
 *
 * SDL can provide virtual joysticks as well: the app defines an imaginary
 * controller with SDL_AttachVirtualJoystick(), and then can provide inputs
 * for it via SDL_SetJoystickVirtualAxis(), SDL_SetJoystickVirtualButton(),
 * etc. As this data is supplied, it will look like a normal joystick to SDL,
 * just not backed by a hardware driver. This has been used to make unusual
 * devices, like VR headset controllers, look like normal joysticks, or
 * provide recording/playback of game inputs, etc.
 */

namespace SDL3;

/**
 * The joystick structure used to identify an SDL joystick.
 *
 * This is opaque data.
 *
 * \since This struct is available since SDL 3.2.0.
 */
[CRepr] public struct SDL_Joystick;

/**
 * This is a unique ID for a joystick for the time it is connected to the
 * system, and is never reused for the lifetime of the application.
 *
 * If the joystick is disconnected and reconnected, it will get a new ID.
 *
 * The value 0 is an invalid ID.
 *
 * \since This datatype is available since SDL 3.2.0.
 */
public typealias SDL_JoystickID = uint32;

/**
 * An enum of some common joystick types.
 *
 * In some cases, SDL can identify a low-level joystick as being a certain
 * type of device, and will report it through SDL_GetJoystickType (or
 * SDL_GetJoystickTypeForID).
 *
 * This is by no means a complete list of everything that can be plugged into
 * a computer.
 *
 * You may refer to
 * [XInput Controller Types](https://learn.microsoft.com/en-us/windows/win32/xinput/xinput-and-controller-subtypes)
 * table for a general understanding of each joystick type.
 *
 * \since This enum is available since SDL 3.2.0.
 */
public enum SDL_JoystickType : int32
{
	SDL_JOYSTICK_TYPE_UNKNOWN,
	SDL_JOYSTICK_TYPE_GAMEPAD,
	SDL_JOYSTICK_TYPE_WHEEL,
	SDL_JOYSTICK_TYPE_ARCADE_STICK,
	SDL_JOYSTICK_TYPE_FLIGHT_STICK,
	SDL_JOYSTICK_TYPE_DANCE_PAD,
	SDL_JOYSTICK_TYPE_GUITAR,
	SDL_JOYSTICK_TYPE_DRUM_KIT,
	SDL_JOYSTICK_TYPE_ARCADE_PAD,
	SDL_JOYSTICK_TYPE_THROTTLE,
	SDL_JOYSTICK_TYPE_COUNT
}

/**
 * Possible connection states for a joystick device.
 *
 * This is used by SDL_GetJoystickConnectionState to report how a device is
 * connected to the system.
 *
 * \since This enum is available since SDL 3.2.0.
 */
public enum SDL_JoystickConnectionState : int32
{
	SDL_JOYSTICK_CONNECTION_INVALID = -1,
	SDL_JOYSTICK_CONNECTION_UNKNOWN,
	SDL_JOYSTICK_CONNECTION_WIRED,
	SDL_JOYSTICK_CONNECTION_WIRELESS
}


public static //extension SDL3
{
/**
 * The largest value an SDL_Joystick's axis can report.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_JOYSTICK_AXIS_MIN
 */
	public const int32 SDL_JOYSTICK_AXIS_MAX   = 32767;

/**
 * The smallest value an SDL_Joystick's axis can report.
 *
 * This is a negative number!
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_JOYSTICK_AXIS_MAX
 */
	public const int32 SDL_JOYSTICK_AXIS_MIN   = -32768;

/* Function prototypes */

/**
 * Locking for atomic access to the joystick API.
 *
 * The SDL joystick functions are thread-safe, however you can lock the
 * joysticks while processing to guarantee that the joystick list won't change
 * and joystick and gamepad events will not be delivered.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void SDL_LockJoysticks();

/**
 * Unlocking for atomic access to the joystick API.
 *
 * \threadsafety This should be called from the same thread that called
 *               SDL_LockJoysticks().
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void SDL_UnlockJoysticks();

/**
 * Return whether a joystick is currently connected.
 *
 * \returns true if a joystick is connected, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern bool SDL_HasJoystick();

/**
 * Get a list of currently connected joysticks.
 *
 * \param count a pointer filled in with the number of joysticks returned, may
 *              be NULL.
 * \returns a 0 terminated array of joystick instance IDs or NULL on failure;
 *          call SDL_GetError() for more information. This should be freed
 *          with SDL_free() when it is no longer needed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_HasJoystick
 * \sa SDL_OpenJoystick
 */
	[CLink] public static extern SDL_JoystickID* SDL_GetJoysticks(int32* count);

/**
 * Get the implementation dependent name of a joystick.
 *
 * This can be called before any joysticks are opened.
 *
 * \param instance_id the joystick instance ID.
 * \returns the name of the selected joystick. If no name can be found, this
 *          function returns NULL; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickName
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern char8* SDL_GetJoystickNameForID(SDL_JoystickID instance_id);

/**
 * Get the implementation dependent path of a joystick.
 *
 * This can be called before any joysticks are opened.
 *
 * \param instance_id the joystick instance ID.
 * \returns the path of the selected joystick. If no path can be found, this
 *          function returns NULL; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickPath
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern char8* SDL_GetJoystickPathForID(SDL_JoystickID instance_id);

/**
 * Get the player index of a joystick.
 *
 * This can be called before any joysticks are opened.
 *
 * \param instance_id the joystick instance ID.
 * \returns the player index of a joystick, or -1 if it's not available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickPlayerIndex
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern int32 SDL_GetJoystickPlayerIndexForID(SDL_JoystickID instance_id);

/**
 * Get the implementation-dependent GUID of a joystick.
 *
 * This can be called before any joysticks are opened.
 *
 * \param instance_id the joystick instance ID.
 * \returns the GUID of the selected joystick. If called with an invalid
 *          instance_id, this function returns a zero GUID.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickGUID
 * \sa SDL_GUIDToString
 */
	[CLink] public static extern SDL_GUID SDL_GetJoystickGUIDForID(SDL_JoystickID instance_id);

/**
 * Get the USB vendor ID of a joystick, if available.
 *
 * This can be called before any joysticks are opened. If the vendor ID isn't
 * available this function returns 0.
 *
 * \param instance_id the joystick instance ID.
 * \returns the USB vendor ID of the selected joystick. If called with an
 *          invalid instance_id, this function returns 0.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickVendor
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern uint16 SDL_GetJoystickVendorForID(SDL_JoystickID instance_id);

/**
 * Get the USB product ID of a joystick, if available.
 *
 * This can be called before any joysticks are opened. If the product ID isn't
 * available this function returns 0.
 *
 * \param instance_id the joystick instance ID.
 * \returns the USB product ID of the selected joystick. If called with an
 *          invalid instance_id, this function returns 0.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickProduct
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern uint16 SDL_GetJoystickProductForID(SDL_JoystickID instance_id);

/**
 * Get the product version of a joystick, if available.
 *
 * This can be called before any joysticks are opened. If the product version
 * isn't available this function returns 0.
 *
 * \param instance_id the joystick instance ID.
 * \returns the product version of the selected joystick. If called with an
 *          invalid instance_id, this function returns 0.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickProductVersion
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern uint16 SDL_GetJoystickProductVersionForID(SDL_JoystickID instance_id);

/**
 * Get the type of a joystick, if available.
 *
 * This can be called before any joysticks are opened.
 *
 * \param instance_id the joystick instance ID.
 * \returns the SDL_JoystickType of the selected joystick. If called with an
 *          invalid instance_id, this function returns
 *          `SDL_JOYSTICK_TYPE_UNKNOWN`.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickType
 * \sa SDL_GetJoysticks
 */
	[CLink] public static extern SDL_JoystickType SDL_GetJoystickTypeForID(SDL_JoystickID instance_id);

/**
 * Open a joystick for use.
 *
 * The joystick subsystem must be initialized before a joystick can be opened
 * for use.
 *
 * \param instance_id the joystick instance ID.
 * \returns a joystick identifier or NULL on failure; call SDL_GetError() for
 *          more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_CloseJoystick
 */
	[CLink] public static extern SDL_Joystick* SDL_OpenJoystick(SDL_JoystickID instance_id);

/**
 * Get the SDL_Joystick associated with an instance ID, if it has been opened.
 *
 * \param instance_id the instance ID to get the SDL_Joystick for.
 * \returns an SDL_Joystick on success or NULL on failure or if it hasn't been
 *          opened yet; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern SDL_Joystick* SDL_GetJoystickFromID(SDL_JoystickID instance_id);

/**
 * Get the SDL_Joystick associated with a player index.
 *
 * \param player_index the player index to get the SDL_Joystick for.
 * \returns an SDL_Joystick on success or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickPlayerIndex
 * \sa SDL_SetJoystickPlayerIndex
 */
	[CLink] public static extern SDL_Joystick* SDL_GetJoystickFromPlayerIndex(int32 player_index);
}

/**
 * The structure that describes a virtual joystick touchpad.
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_VirtualJoystickDesc
 */
[CRepr] public struct SDL_VirtualJoystickTouchpadDesc
{
	public uint16 nfingers; /**< the number of simultaneous fingers on this touchpad */
	public uint16[3] padding;
}

/**
 * The structure that describes a virtual joystick sensor.
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_VirtualJoystickDesc
 */
[CRepr] public struct SDL_VirtualJoystickSensorDesc
{
	public SDL_SensorType type; /**< the type of this sensor */
	public float rate; /**< the update frequency of this sensor, may be 0.0f */
}

/**
 * The structure that describes a virtual joystick.
 *
 * This structure should be initialized using SDL_INIT_INTERFACE(). All
 * elements of this structure are optional.
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_AttachVirtualJoystick
 * \sa SDL_INIT_INTERFACE
 * \sa SDL_VirtualJoystickSensorDesc
 * \sa SDL_VirtualJoystickTouchpadDesc
 */
[CRepr] public struct SDL_VirtualJoystickDesc
{
	public uint32 version; /**< the version of this interface */
	public uint16 type; /**< `SDL_JoystickType` */
	public uint16 padding; /**< unused */
	public uint16 vendor_id; /**< the USB vendor ID of this joystick */
	public uint16 product_id; /**< the USB product ID of this joystick */
	public uint16 naxes; /**< the number of axes on this joystick */
	public uint16 nbuttons; /**< the number of buttons on this joystick */
	public uint16 nballs; /**< the number of balls on this joystick */
	public uint16 nhats; /**< the number of hats on this joystick */
	public uint16 ntouchpads; /**< the number of touchpads on this joystick, requires `touchpads` to point at valid descriptions */
	public uint16 nsensors; /**< the number of sensors on this joystick, requires `sensors` to point at valid descriptions */
	public uint16[2] padding2; /**< unused */
	public uint32 button_mask; /**< A mask of which buttons are valid for this controller
							 e.g. (1 << SDL_GAMEPAD_BUTTON_SOUTH) */
	public uint32 axis_mask; /**< A mask of which axes are valid for this controller
							 e.g. (1 << SDL_GAMEPAD_AXIS_LEFTX) */
	public char8* name; /**< the name of the joystick */
	public SDL_VirtualJoystickTouchpadDesc* touchpads; /**< A pointer to an array of touchpad descriptions, required if `ntouchpads` is > 0 */
	public SDL_VirtualJoystickSensorDesc* sensors; /**< A pointer to an array of sensor descriptions, required if `nsensors` is > 0 */

	public void* userdata; /**< User data pointer passed to callbacks */
	public function void(void* userdata) Update; /**< Called when the joystick state should be updated */
	public function void(void* userdata, int32 player_index) SetPlayerIndex; /**< Called when the player index is set */
	public function bool(void* userdata, uint16 low_frequency_rumble, uint16 high_frequency_rumble) Rumble; /**< Implements SDL_RumbleJoystick() */
	public function bool(void* userdata, uint16 left_rumble, uint16 right_rumble) RumbleTriggers; /**< Implements SDL_RumbleJoystickTriggers() */
	public function bool(void* userdata, uint8 red, uint8 green, uint8 blue) SetLED; /**< Implements SDL_SetJoystickLED() */
	public function bool(void* userdata, void* data, int32 size) SendEffect; /**< Implements SDL_SendJoystickEffect() */
	public function bool(void* userdata, bool enabled) SetSensorsEnabled; /**< Implements SDL_SetGamepadSensorEnabled() */
	public function void(void* userdata) Cleanup; /**< Cleans up the userdata when the joystick is detached */
}

public static //extension SDL3
{

/* Check the size of SDL_VirtualJoystickDesc
 *
 * If this assert fails, either the compiler is padding to an unexpected size,
 * or the interface has been updated and this should be updated to match and
 * the code using this interface should be updated to handle the old version.
 */
	private static void Assert_SDL_VirtualJoystickDesc_SIZE()
	{
		Compiler.Assert((sizeof(void*) == 4 && sizeof(SDL_VirtualJoystickDesc) == 84) ||
			(sizeof(void*) == 8 && sizeof(SDL_VirtualJoystickDesc) == 136));
	}

/**
 * Attach a new virtual joystick.
 *
 * Apps can create virtual joysticks, that exist without hardware directly
 * backing them, and have program-supplied inputs. Once attached, a virtual
 * joystick looks like any other joystick that SDL can access. These can be
 * used to make other things look like joysticks, or provide pre-recorded
 * input, etc.
 *
 * Once attached, the app can send joystick inputs to the new virtual joystick
 * using SDL_SetJoystickVirtualAxis(), etc.
 *
 * When no longer needed, the virtual joystick can be removed by calling
 * SDL_DetachVirtualJoystick().
 *
 * \param desc joystick description, initialized using SDL_INIT_INTERFACE().
 * \returns the joystick instance ID, or 0 on failure; call SDL_GetError() for
 *          more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_DetachVirtualJoystick
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualTouchpad
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern SDL_JoystickID SDL_AttachVirtualJoystick(SDL_VirtualJoystickDesc* desc);

/**
 * Detach a virtual joystick.
 *
 * \param instance_id the joystick instance ID, previously returned from
 *                    SDL_AttachVirtualJoystick().
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AttachVirtualJoystick
 */
	[CLink] public static extern bool SDL_DetachVirtualJoystick(SDL_JoystickID instance_id);

/**
 * Query whether or not a joystick is virtual.
 *
 * \param instance_id the joystick instance ID.
 * \returns true if the joystick is virtual, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_IsJoystickVirtual(SDL_JoystickID instance_id);

/**
 * Set the state of an axis on an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * Note that when sending trigger axes, you should scale the value to the full
 * range of int16. For example, a trigger at rest would have the value of
 * `SDL_JOYSTICK_AXIS_MIN`.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param axis the index of the axis on the virtual joystick to update.
 * \param value the new value for the specified axis.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualTouchpad
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern bool SDL_SetJoystickVirtualAxis(SDL_Joystick* joystick, int32 axis, int16 value);

/**
 * Generate ball motion on an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param ball the index of the ball on the virtual joystick to update.
 * \param xrel the relative motion on the X axis.
 * \param yrel the relative motion on the Y axis.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualTouchpad
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern bool SDL_SetJoystickVirtualBall(SDL_Joystick* joystick, int32 ball, int16 xrel, int16 yrel);

/**
 * Set the state of a button on an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param button the index of the button on the virtual joystick to update.
 * \param down true if the button is pressed, false otherwise.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualTouchpad
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern bool SDL_SetJoystickVirtualButton(SDL_Joystick* joystick, int32 button, bool down);

/**
 * Set the state of a hat on an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param hat the index of the hat on the virtual joystick to update.
 * \param value the new value for the specified hat.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualTouchpad
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern bool SDL_SetJoystickVirtualHat(SDL_Joystick* joystick, int32 hat, uint8 value);

/**
 * Set touchpad finger state on an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param touchpad the index of the touchpad on the virtual joystick to
 *                 update.
 * \param finger the index of the finger on the touchpad to set.
 * \param down true if the finger is pressed, false if the finger is released.
 * \param x the x coordinate of the finger on the touchpad, normalized 0 to 1,
 *          with the origin in the upper left.
 * \param y the y coordinate of the finger on the touchpad, normalized 0 to 1,
 *          with the origin in the upper left.
 * \param pressure the pressure of the finger.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualSensorData
 */
	[CLink] public static extern bool SDL_SetJoystickVirtualTouchpad(SDL_Joystick* joystick, int32 touchpad, int32 finger, bool down, float x, float y, float pressure);

/**
 * Send a sensor update for an opened virtual joystick.
 *
 * Please note that values set here will not be applied until the next call to
 * SDL_UpdateJoysticks, which can either be called directly, or can be called
 * indirectly through various other SDL APIs, including, but not limited to
 * the following: SDL_PollEvent, SDL_PumpEvents, SDL_WaitEventTimeout,
 * SDL_WaitEvent.
 *
 * \param joystick the virtual joystick on which to set state.
 * \param type the type of the sensor on the virtual joystick to update.
 * \param sensor_timestamp a 64-bit timestamp in nanoseconds associated with
 *                         the sensor reading.
 * \param data the data associated with the sensor reading.
 * \param num_values the number of values pointed to by `data`.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickVirtualAxis
 * \sa SDL_SetJoystickVirtualButton
 * \sa SDL_SetJoystickVirtualBall
 * \sa SDL_SetJoystickVirtualHat
 * \sa SDL_SetJoystickVirtualTouchpad
 */
	[CLink] public static extern bool SDL_SendJoystickVirtualSensorData(SDL_Joystick* joystick, SDL_SensorType type, uint64 sensor_timestamp, float* data, int32 num_values);

/**
 * Get the properties associated with a joystick.
 *
 * The following read-only properties are provided by SDL:
 *
 * - `SDL_PROP_JOYSTICK_CAP_MONO_LED_BOOLEAN`: true if this joystick has an
 *   LED that has adjustable brightness
 * - `SDL_PROP_JOYSTICK_CAP_RGB_LED_BOOLEAN`: true if this joystick has an LED
 *   that has adjustable color
 * - `SDL_PROP_JOYSTICK_CAP_PLAYER_LED_BOOLEAN`: true if this joystick has a
 *   player LED
 * - `SDL_PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN`: true if this joystick has
 *   left/right rumble
 * - `SDL_PROP_JOYSTICK_CAP_TRIGGER_RUMBLE_BOOLEAN`: true if this joystick has
 *   simple trigger rumble
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern SDL_PropertiesID SDL_GetJoystickProperties(SDL_Joystick* joystick);

	public const char8* SDL_PROP_JOYSTICK_CAP_MONO_LED_BOOLEAN          = "SDL.joystick.cap.mono_led";
	public const char8* SDL_PROP_JOYSTICK_CAP_RGB_LED_BOOLEAN           = "SDL.joystick.cap.rgb_led";
	public const char8* SDL_PROP_JOYSTICK_CAP_PLAYER_LED_BOOLEAN        = "SDL.joystick.cap.player_led";
	public const char8* SDL_PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN            = "SDL.joystick.cap.rumble";
	public const char8* SDL_PROP_JOYSTICK_CAP_TRIGGER_RUMBLE_BOOLEAN    = "SDL.joystick.cap.trigger_rumble";

/**
 * Get the implementation dependent name of a joystick.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the name of the selected joystick. If no name can be found, this
 *          function returns NULL; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickNameForID
 */
	[CLink] public static extern char8* SDL_GetJoystickName(SDL_Joystick* joystick);

/**
 * Get the implementation dependent path of a joystick.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the path of the selected joystick. If no path can be found, this
 *          function returns NULL; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickPathForID
 */
	[CLink] public static extern char8* SDL_GetJoystickPath(SDL_Joystick* joystick);

/**
 * Get the player index of an opened joystick.
 *
 * For XInput controllers this returns the XInput user index. Many joysticks
 * will not be able to supply this information.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the player index, or -1 if it's not available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickPlayerIndex
 */
	[CLink] public static extern int32 SDL_GetJoystickPlayerIndex(SDL_Joystick* joystick);

/**
 * Set the player index of an opened joystick.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \param player_index player index to assign to this joystick, or -1 to clear
 *                     the player index and turn off player LEDs.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickPlayerIndex
 */
	[CLink] public static extern bool SDL_SetJoystickPlayerIndex(SDL_Joystick* joystick, int32 player_index);

/**
 * Get the implementation-dependent GUID for the joystick.
 *
 * This function requires an open joystick.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the GUID of the given joystick. If called on an invalid index,
 *          this function returns a zero GUID; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickGUIDForID
 * \sa SDL_GUIDToString
 */
	[CLink] public static extern SDL_GUID SDL_GetJoystickGUID(SDL_Joystick* joystick);

/**
 * Get the USB vendor ID of an opened joystick, if available.
 *
 * If the vendor ID isn't available this function returns 0.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the USB vendor ID of the selected joystick, or 0 if unavailable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickVendorForID
 */
	[CLink] public static extern uint16 SDL_GetJoystickVendor(SDL_Joystick* joystick);

/**
 * Get the USB product ID of an opened joystick, if available.
 *
 * If the product ID isn't available this function returns 0.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the USB product ID of the selected joystick, or 0 if unavailable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickProductForID
 */
	[CLink] public static extern uint16 SDL_GetJoystickProduct(SDL_Joystick* joystick);

/**
 * Get the product version of an opened joystick, if available.
 *
 * If the product version isn't available this function returns 0.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the product version of the selected joystick, or 0 if unavailable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickProductVersionForID
 */
	[CLink] public static extern uint16 SDL_GetJoystickProductVersion(SDL_Joystick* joystick);

/**
 * Get the firmware version of an opened joystick, if available.
 *
 * If the firmware version isn't available this function returns 0.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the firmware version of the selected joystick, or 0 if
 *          unavailable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern uint16 SDL_GetJoystickFirmwareVersion(SDL_Joystick* joystick);

/**
 * Get the serial number of an opened joystick, if available.
 *
 * Returns the serial number of the joystick, or NULL if it is not available.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the serial number of the selected joystick, or NULL if
 *          unavailable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern char8* SDL_GetJoystickSerial(SDL_Joystick* joystick);

/**
 * Get the type of an opened joystick.
 *
 * \param joystick the SDL_Joystick obtained from SDL_OpenJoystick().
 * \returns the SDL_JoystickType of the selected joystick.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickTypeForID
 */
	[CLink] public static extern SDL_JoystickType SDL_GetJoystickType(SDL_Joystick* joystick);

/**
 * Get the device information encoded in a SDL_GUID structure.
 *
 * \param guid the SDL_GUID you wish to get info about.
 * \param vendor a pointer filled in with the device VID, or 0 if not
 *               available.
 * \param product a pointer filled in with the device PID, or 0 if not
 *                available.
 * \param version a pointer filled in with the device version, or 0 if not
 *                available.
 * \param crc16 a pointer filled in with a CRC used to distinguish different
 *              products with the same VID/PID, or 0 if not available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickGUIDForID
 */
	[CLink] public static extern void SDL_GetJoystickGUIDInfo(SDL_GUID guid, uint16* vendor, uint16* product, uint16* version, uint16* crc16);

/**
 * Get the status of a specified joystick.
 *
 * \param joystick the joystick to query.
 * \returns true if the joystick has been opened, false if it has not; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_JoystickConnected(SDL_Joystick* joystick);

/**
 * Get the instance ID of an opened joystick.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \returns the instance ID of the specified joystick on success or 0 on
 *          failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern SDL_JoystickID SDL_GetJoystickID(SDL_Joystick* joystick);

/**
 * Get the number of general axis controls on a joystick.
 *
 * Often, the directional pad on a game controller will either look like 4
 * separate buttons or a POV hat, and not axes, but all of this is up to the
 * device and platform.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \returns the number of axis controls/number of axes on success or -1 on
 *          failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickAxis
 * \sa SDL_GetNumJoystickBalls
 * \sa SDL_GetNumJoystickButtons
 * \sa SDL_GetNumJoystickHats
 */
	[CLink] public static extern int32 SDL_GetNumJoystickAxes(SDL_Joystick* joystick);

/**
 * Get the number of trackballs on a joystick.
 *
 * Joystick trackballs have only relative motion events associated with them
 * and their state cannot be polled.
 *
 * Most joysticks do not have trackballs.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \returns the number of trackballs on success or -1 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickBall
 * \sa SDL_GetNumJoystickAxes
 * \sa SDL_GetNumJoystickButtons
 * \sa SDL_GetNumJoystickHats
 */
	[CLink] public static extern int32 SDL_GetNumJoystickBalls(SDL_Joystick* joystick);

/**
 * Get the number of POV hats on a joystick.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \returns the number of POV hats on success or -1 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickHat
 * \sa SDL_GetNumJoystickAxes
 * \sa SDL_GetNumJoystickBalls
 * \sa SDL_GetNumJoystickButtons
 */
	[CLink] public static extern int32 SDL_GetNumJoystickHats(SDL_Joystick* joystick);

/**
 * Get the number of buttons on a joystick.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \returns the number of buttons on success or -1 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetJoystickButton
 * \sa SDL_GetNumJoystickAxes
 * \sa SDL_GetNumJoystickBalls
 * \sa SDL_GetNumJoystickHats
 */
	[CLink] public static extern int32 SDL_GetNumJoystickButtons(SDL_Joystick* joystick);

/**
 * Set the state of joystick event processing.
 *
 * If joystick events are disabled, you must call SDL_UpdateJoysticks()
 * yourself and check the state of the joystick when you want joystick
 * information.
 *
 * \param enabled whether to process joystick events or not.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_JoystickEventsEnabled
 * \sa SDL_UpdateJoysticks
 */
	[CLink] public static extern void SDL_SetJoystickEventsEnabled(bool enabled);

/**
 * Query the state of joystick event processing.
 *
 * If joystick events are disabled, you must call SDL_UpdateJoysticks()
 * yourself and check the state of the joystick when you want joystick
 * information.
 *
 * \returns true if joystick events are being processed, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetJoystickEventsEnabled
 */
	[CLink] public static extern bool SDL_JoystickEventsEnabled();

/**
 * Update the current state of the open joysticks.
 *
 * This is called automatically by the event loop if any joystick events are
 * enabled.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern void SDL_UpdateJoysticks();

/**
 * Get the current state of an axis control on a joystick.
 *
 * SDL makes no promises about what part of the joystick any given axis refers
 * to. Your game should have some sort of configuration UI to let users
 * specify what each axis should be bound to. Alternately, SDL's higher-level
 * Game Controller API makes a great effort to apply order to this lower-level
 * interface, so you know that a specific axis is the "left thumb stick," etc.
 *
 * The value returned by SDL_GetJoystickAxis() is a signed integer (-32768 to
 * 32767) representing the current position of the axis. It may be necessary
 * to impose certain tolerances on these values to account for jitter.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \param axis the axis to query; the axis indices start at index 0.
 * \returns a 16-bit signed integer representing the current position of the
 *          axis or 0 on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetNumJoystickAxes
 */
	[CLink] public static extern int16 SDL_GetJoystickAxis(SDL_Joystick* joystick, int32 axis);

/**
 * Get the initial state of an axis control on a joystick.
 *
 * The state is a value ranging from -32768 to 32767.
 *
 * The axis indices start at index 0.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \param axis the axis to query; the axis indices start at index 0.
 * \param state upon return, the initial value is supplied here.
 * \returns true if this axis has any initial value, or false if not.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_GetJoystickAxisInitialState(SDL_Joystick* joystick, int32 axis, int16* state);

/**
 * Get the ball axis change since the last poll.
 *
 * Trackballs can only return relative motion since the last call to
 * SDL_GetJoystickBall(), these motion deltas are placed into `dx` and `dy`.
 *
 * Most joysticks do not have trackballs.
 *
 * \param joystick the SDL_Joystick to query.
 * \param ball the ball index to query; ball indices start at index 0.
 * \param dx stores the difference in the x axis position since the last poll.
 * \param dy stores the difference in the y axis position since the last poll.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetNumJoystickBalls
 */
	[CLink] public static extern bool SDL_GetJoystickBall(SDL_Joystick* joystick, int32 ball, int32* dx, int32* dy);

/**
 * Get the current state of a POV hat on a joystick.
 *
 * The returned value will be one of the `SDL_HAT_*` values.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \param hat the hat index to get the state from; indices start at index 0.
 * \returns the current hat position.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetNumJoystickHats
 */
	[CLink] public static extern uint8 SDL_GetJoystickHat(SDL_Joystick* joystick, int32 hat);

	// todo: jayrulez - make enum
	public const uint32 SDL_HAT_CENTERED    = 0x00;
	public const uint32 SDL_HAT_UP          = 0x01;
	public const uint32 SDL_HAT_RIGHT       = 0x02;
	public const uint32 SDL_HAT_DOWN        = 0x04;
	public const uint32 SDL_HAT_LEFT        = 0x08;
	public const uint32 SDL_HAT_RIGHTUP     = (SDL_HAT_RIGHT | SDL_HAT_UP);
	public const uint32 SDL_HAT_RIGHTDOWN   = (SDL_HAT_RIGHT | SDL_HAT_DOWN);
	public const uint32 SDL_HAT_LEFTUP      = (SDL_HAT_LEFT | SDL_HAT_UP);
	public const uint32 SDL_HAT_LEFTDOWN    = (SDL_HAT_LEFT | SDL_HAT_DOWN);

/**
 * Get the current state of a button on a joystick.
 *
 * \param joystick an SDL_Joystick structure containing joystick information.
 * \param button the button index to get the state from; indices start at
 *               index 0.
 * \returns true if the button is pressed, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetNumJoystickButtons
 */
	[CLink] public static extern bool SDL_GetJoystickButton(SDL_Joystick* joystick, int32 button);

/**
 * Start a rumble effect.
 *
 * Each call to this function cancels any previous rumble effect, and calling
 * it with 0 intensity stops any rumbling.
 *
 * This function requires you to process SDL events or call
 * SDL_UpdateJoysticks() to update rumble state.
 *
 * \param joystick the joystick to vibrate.
 * \param low_frequency_rumble the intensity of the low frequency (left)
 *                             rumble motor, from 0 to 0xFFFF.
 * \param high_frequency_rumble the intensity of the high frequency (right)
 *                              rumble motor, from 0 to 0xFFFF.
 * \param duration_ms the duration of the rumble effect, in milliseconds.
 * \returns true, or false if rumble isn't supported on this joystick.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_RumbleJoystick(SDL_Joystick* joystick, uint16 low_frequency_rumble, uint16 high_frequency_rumble, uint32 duration_ms);

/**
 * Start a rumble effect in the joystick's triggers.
 *
 * Each call to this function cancels any previous trigger rumble effect, and
 * calling it with 0 intensity stops any rumbling.
 *
 * Note that this is rumbling of the _triggers_ and not the game controller as
 * a whole. This is currently only supported on Xbox One controllers. If you
 * want the (more common) whole-controller rumble, use SDL_RumbleJoystick()
 * instead.
 *
 * This function requires you to process SDL events or call
 * SDL_UpdateJoysticks() to update rumble state.
 *
 * \param joystick the joystick to vibrate.
 * \param left_rumble the intensity of the left trigger rumble motor, from 0
 *                    to 0xFFFF.
 * \param right_rumble the intensity of the right trigger rumble motor, from 0
 *                     to 0xFFFF.
 * \param duration_ms the duration of the rumble effect, in milliseconds.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_RumbleJoystick
 */
	[CLink] public static extern bool SDL_RumbleJoystickTriggers(SDL_Joystick* joystick, uint16 left_rumble, uint16 right_rumble, uint32 duration_ms);

/**
 * Update a joystick's LED color.
 *
 * An example of a joystick LED is the light on the back of a PlayStation 4's
 * DualShock 4 controller.
 *
 * For joysticks with a single color LED, the maximum of the RGB values will
 * be used as the LED brightness.
 *
 * \param joystick the joystick to update.
 * \param red the intensity of the red LED.
 * \param green the intensity of the green LED.
 * \param blue the intensity of the blue LED.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_SetJoystickLED(SDL_Joystick* joystick, uint8 red, uint8 green, uint8 blue);

/**
 * Send a joystick specific effect packet.
 *
 * \param joystick the joystick to affect.
 * \param data the data to send to the joystick.
 * \param size the size of the data to send to the joystick.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern bool SDL_SendJoystickEffect(SDL_Joystick* joystick, void* data, int32 size);

/**
 * Close a joystick previously opened with SDL_OpenJoystick().
 *
 * \param joystick the joystick device to close.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_OpenJoystick
 */
	[CLink] public static extern void SDL_CloseJoystick(SDL_Joystick* joystick);

/**
 * Get the connection state of a joystick.
 *
 * \param joystick the joystick to query.
 * \returns the connection state on success or
 *          `SDL_JOYSTICK_CONNECTION_INVALID` on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern SDL_JoystickConnectionState SDL_GetJoystickConnectionState(SDL_Joystick* joystick);

/**
 * Get the battery state of a joystick.
 *
 * You should never take a battery status as absolute truth. Batteries
 * (especially failing batteries) are delicate hardware, and the values
 * reported here are best estimates based on what that hardware reports. It's
 * not uncommon for older batteries to lose stored power much faster than it
 * reports, or completely drain when reporting it has 20 percent left, etc.
 *
 * \param joystick the joystick to query.
 * \param percent a pointer filled in with the percentage of battery life
 *                left, between 0 and 100, or NULL to ignore. This will be
 *                filled in with -1 we can't determine a value or there is no
 *                battery.
 * \returns the current battery state or `SDL_POWERSTATE_ERROR` on failure;
 *          call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 */
	[CLink] public static extern SDL_PowerState SDL_GetJoystickPowerInfo(SDL_Joystick* joystick, int32* percent);
}
