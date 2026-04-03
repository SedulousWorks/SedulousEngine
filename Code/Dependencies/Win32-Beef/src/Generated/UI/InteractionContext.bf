using Win32.UI.WindowsAndMessaging;
using Win32.Foundation;
using Win32.UI.Input.Pointer;
using System;

namespace Win32.UI.InteractionContext;

#region TypeDefs
typealias HINTERACTIONCONTEXT = int;

#endregion


#region Enums

[AllowDuplicates]
public enum INTERACTION_ID : int32
{
	INTERACTION_ID_NONE = 0,
	INTERACTION_ID_MANIPULATION = 1,
	INTERACTION_ID_TAP = 2,
	INTERACTION_ID_SECONDARY_TAP = 3,
	INTERACTION_ID_HOLD = 4,
	INTERACTION_ID_DRAG = 5,
	INTERACTION_ID_CROSS_SLIDE = 6,
	INTERACTION_ID_MAX = -1,
}


[AllowDuplicates]
public enum INTERACTION_FLAGS : uint32
{
	INTERACTION_FLAG_NONE = 0,
	INTERACTION_FLAG_BEGIN = 1,
	INTERACTION_FLAG_END = 2,
	INTERACTION_FLAG_CANCEL = 4,
	INTERACTION_FLAG_INERTIA = 8,
	INTERACTION_FLAG_MAX = 4294967295,
}


[AllowDuplicates]
public enum INTERACTION_CONFIGURATION_FLAGS : uint32
{
	INTERACTION_CONFIGURATION_FLAG_NONE = 0,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION = 1,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_TRANSLATION_X = 2,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_TRANSLATION_Y = 4,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_ROTATION = 8,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_SCALING = 16,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_TRANSLATION_INERTIA = 32,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_ROTATION_INERTIA = 64,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_SCALING_INERTIA = 128,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_RAILS_X = 256,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_RAILS_Y = 512,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_EXACT = 1024,
	INTERACTION_CONFIGURATION_FLAG_MANIPULATION_MULTIPLE_FINGER_PANNING = 2048,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE = 1,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE_HORIZONTAL = 2,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE_SELECT = 4,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE_SPEED_BUMP = 8,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE_REARRANGE = 16,
	INTERACTION_CONFIGURATION_FLAG_CROSS_SLIDE_EXACT = 32,
	INTERACTION_CONFIGURATION_FLAG_TAP = 1,
	INTERACTION_CONFIGURATION_FLAG_TAP_DOUBLE = 2,
	INTERACTION_CONFIGURATION_FLAG_TAP_MULTIPLE_FINGER = 4,
	INTERACTION_CONFIGURATION_FLAG_SECONDARY_TAP = 1,
	INTERACTION_CONFIGURATION_FLAG_HOLD = 1,
	INTERACTION_CONFIGURATION_FLAG_HOLD_MOUSE = 2,
	INTERACTION_CONFIGURATION_FLAG_HOLD_MULTIPLE_FINGER = 4,
	INTERACTION_CONFIGURATION_FLAG_DRAG = 1,
	INTERACTION_CONFIGURATION_FLAG_MAX = 4294967295,
}


[AllowDuplicates]
public enum INERTIA_PARAMETER : int32
{
	INERTIA_PARAMETER_TRANSLATION_DECELERATION = 1,
	INERTIA_PARAMETER_TRANSLATION_DISPLACEMENT = 2,
	INERTIA_PARAMETER_ROTATION_DECELERATION = 3,
	INERTIA_PARAMETER_ROTATION_ANGLE = 4,
	INERTIA_PARAMETER_EXPANSION_DECELERATION = 5,
	INERTIA_PARAMETER_EXPANSION_EXPANSION = 6,
	INERTIA_PARAMETER_MAX = -1,
}


[AllowDuplicates]
public enum INTERACTION_STATE : int32
{
	INTERACTION_STATE_IDLE = 0,
	INTERACTION_STATE_IN_INTERACTION = 1,
	INTERACTION_STATE_POSSIBLE_DOUBLE_TAP = 2,
	INTERACTION_STATE_MAX = -1,
}


[AllowDuplicates]
public enum INTERACTION_CONTEXT_PROPERTY : int32
{
	INTERACTION_CONTEXT_PROPERTY_MEASUREMENT_UNITS = 1,
	INTERACTION_CONTEXT_PROPERTY_INTERACTION_UI_FEEDBACK = 2,
	INTERACTION_CONTEXT_PROPERTY_FILTER_POINTERS = 3,
	INTERACTION_CONTEXT_PROPERTY_MAX = -1,
}


[AllowDuplicates]
public enum CROSS_SLIDE_THRESHOLD : int32
{
	CROSS_SLIDE_THRESHOLD_SELECT_START = 0,
	CROSS_SLIDE_THRESHOLD_SPEED_BUMP_START = 1,
	CROSS_SLIDE_THRESHOLD_SPEED_BUMP_END = 2,
	CROSS_SLIDE_THRESHOLD_REARRANGE_START = 3,
	CROSS_SLIDE_THRESHOLD_COUNT = 4,
	CROSS_SLIDE_THRESHOLD_MAX = -1,
}


[AllowDuplicates]
public enum CROSS_SLIDE_FLAGS : uint32
{
	CROSS_SLIDE_FLAGS_NONE = 0,
	CROSS_SLIDE_FLAGS_SELECT = 1,
	CROSS_SLIDE_FLAGS_SPEED_BUMP = 2,
	CROSS_SLIDE_FLAGS_REARRANGE = 4,
	CROSS_SLIDE_FLAGS_MAX = 4294967295,
}


[AllowDuplicates]
public enum MOUSE_WHEEL_PARAMETER : int32
{
	MOUSE_WHEEL_PARAMETER_CHAR_TRANSLATION_X = 1,
	MOUSE_WHEEL_PARAMETER_CHAR_TRANSLATION_Y = 2,
	MOUSE_WHEEL_PARAMETER_DELTA_SCALE = 3,
	MOUSE_WHEEL_PARAMETER_DELTA_ROTATION = 4,
	MOUSE_WHEEL_PARAMETER_PAGE_TRANSLATION_X = 5,
	MOUSE_WHEEL_PARAMETER_PAGE_TRANSLATION_Y = 6,
	MOUSE_WHEEL_PARAMETER_MAX = -1,
}


[AllowDuplicates]
public enum TAP_PARAMETER : int32
{
	TAP_PARAMETER_MIN_CONTACT_COUNT = 0,
	TAP_PARAMETER_MAX_CONTACT_COUNT = 1,
	TAP_PARAMETER_MAX = -1,
}


[AllowDuplicates]
public enum HOLD_PARAMETER : int32
{
	HOLD_PARAMETER_MIN_CONTACT_COUNT = 0,
	HOLD_PARAMETER_MAX_CONTACT_COUNT = 1,
	HOLD_PARAMETER_THRESHOLD_RADIUS = 2,
	HOLD_PARAMETER_THRESHOLD_START_DELAY = 3,
	HOLD_PARAMETER_MAX = -1,
}


[AllowDuplicates]
public enum TRANSLATION_PARAMETER : int32
{
	TRANSLATION_PARAMETER_MIN_CONTACT_COUNT = 0,
	TRANSLATION_PARAMETER_MAX_CONTACT_COUNT = 1,
	TRANSLATION_PARAMETER_MAX = -1,
}


[AllowDuplicates]
public enum MANIPULATION_RAILS_STATE : int32
{
	MANIPULATION_RAILS_STATE_UNDECIDED = 0,
	MANIPULATION_RAILS_STATE_FREE = 1,
	MANIPULATION_RAILS_STATE_RAILED = 2,
	MANIPULATION_RAILS_STATE_MAX = -1,
}

#endregion

#region Function Pointers
public function void INTERACTION_CONTEXT_OUTPUT_CALLBACK(void* clientData, INTERACTION_CONTEXT_OUTPUT* output);

public function void INTERACTION_CONTEXT_OUTPUT_CALLBACK2(void* clientData, INTERACTION_CONTEXT_OUTPUT2* output);

#endregion

#region Structs
[CRepr]
public struct MANIPULATION_TRANSFORM
{
	public float translationX;
	public float translationY;
	public float scale;
	public float expansion;
	public float rotation;
}

[CRepr]
public struct MANIPULATION_VELOCITY
{
	public float velocityX;
	public float velocityY;
	public float velocityExpansion;
	public float velocityAngular;
}

[CRepr]
public struct INTERACTION_ARGUMENTS_MANIPULATION
{
	public MANIPULATION_TRANSFORM delta;
	public MANIPULATION_TRANSFORM cumulative;
	public MANIPULATION_VELOCITY velocity;
	public MANIPULATION_RAILS_STATE railsState;
}

[CRepr]
public struct INTERACTION_ARGUMENTS_TAP
{
	public uint32 count;
}

[CRepr]
public struct INTERACTION_ARGUMENTS_CROSS_SLIDE
{
	public CROSS_SLIDE_FLAGS flags;
}

[CRepr]
public struct INTERACTION_CONTEXT_OUTPUT
{
	[CRepr, Union]
	public struct _arguments_e__Union
	{
		public INTERACTION_ARGUMENTS_MANIPULATION manipulation;
		public INTERACTION_ARGUMENTS_TAP tap;
		public INTERACTION_ARGUMENTS_CROSS_SLIDE crossSlide;
	}
	public INTERACTION_ID interactionId;
	public INTERACTION_FLAGS interactionFlags;
	public POINTER_INPUT_TYPE inputType;
	public float x;
	public float y;
	public _arguments_e__Union arguments;
}

[CRepr]
public struct INTERACTION_CONTEXT_OUTPUT2
{
	[CRepr, Union]
	public struct _arguments_e__Union
	{
		public INTERACTION_ARGUMENTS_MANIPULATION manipulation;
		public INTERACTION_ARGUMENTS_TAP tap;
		public INTERACTION_ARGUMENTS_CROSS_SLIDE crossSlide;
	}
	public INTERACTION_ID interactionId;
	public INTERACTION_FLAGS interactionFlags;
	public POINTER_INPUT_TYPE inputType;
	public uint32 contactCount;
	public uint32 currentContactCount;
	public float x;
	public float y;
	public _arguments_e__Union arguments;
}

[CRepr]
public struct INTERACTION_CONTEXT_CONFIGURATION
{
	public INTERACTION_ID interactionId;
	public INTERACTION_CONFIGURATION_FLAGS enable;
}

[CRepr]
public struct CROSS_SLIDE_PARAMETER
{
	public CROSS_SLIDE_THRESHOLD threshold;
	public float distance;
}

#endregion

#region Functions
public static
{
	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateInteractionContext(HINTERACTIONCONTEXT* interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DestroyInteractionContext(HINTERACTIONCONTEXT interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterOutputCallbackInteractionContext(HINTERACTIONCONTEXT interactionContext, INTERACTION_CONTEXT_OUTPUT_CALLBACK outputCallback, void* clientData);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterOutputCallbackInteractionContext2(HINTERACTIONCONTEXT interactionContext, INTERACTION_CONTEXT_OUTPUT_CALLBACK2 outputCallback, void* clientData);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetInteractionConfigurationInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 configurationCount, INTERACTION_CONTEXT_CONFIGURATION* configuration);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetInteractionConfigurationInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 configurationCount, INTERACTION_CONTEXT_CONFIGURATION* configuration);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetPropertyInteractionContext(HINTERACTIONCONTEXT interactionContext, INTERACTION_CONTEXT_PROPERTY contextProperty, uint32 value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetPropertyInteractionContext(HINTERACTIONCONTEXT interactionContext, INTERACTION_CONTEXT_PROPERTY contextProperty, uint32* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetInertiaParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, INERTIA_PARAMETER inertiaParameter, float value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetInertiaParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, INERTIA_PARAMETER inertiaParameter, float* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetCrossSlideParametersInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 parameterCount, CROSS_SLIDE_PARAMETER* crossSlideParameters);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCrossSlideParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, CROSS_SLIDE_THRESHOLD threshold, float* distance);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetTapParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, TAP_PARAMETER parameter, float value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetTapParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, TAP_PARAMETER parameter, float* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetHoldParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, HOLD_PARAMETER parameter, float value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetHoldParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, HOLD_PARAMETER parameter, float* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetTranslationParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, TRANSLATION_PARAMETER parameter, float value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetTranslationParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, TRANSLATION_PARAMETER parameter, float* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetMouseWheelParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, MOUSE_WHEEL_PARAMETER parameter, float value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetMouseWheelParameterInteractionContext(HINTERACTIONCONTEXT interactionContext, MOUSE_WHEEL_PARAMETER parameter, float* value);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ResetInteractionContext(HINTERACTIONCONTEXT interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetStateInteractionContext(HINTERACTIONCONTEXT interactionContext, POINTER_INFO* pointerInfo, INTERACTION_STATE* state);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddPointerInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 pointerId);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RemovePointerInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 pointerId);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProcessPointerFramesInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 entriesCount, uint32 pointerCount, POINTER_INFO* pointerInfo);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BufferPointerPacketsInteractionContext(HINTERACTIONCONTEXT interactionContext, uint32 entriesCount, POINTER_INFO* pointerInfo);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProcessBufferedPacketsInteractionContext(HINTERACTIONCONTEXT interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProcessInertiaInteractionContext(HINTERACTIONCONTEXT interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StopInteractionContext(HINTERACTIONCONTEXT interactionContext);

	[Import("NInput.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetPivotInteractionContext(HINTERACTIONCONTEXT interactionContext, float x, float y, float radius);

}
#endregion
