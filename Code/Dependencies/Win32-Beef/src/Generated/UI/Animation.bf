using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.DirectComposition;
using System;

namespace Win32.UI.Animation;

#region Constants
public static
{
	public const int32 UI_ANIMATION_SECONDS_EVENTUALLY = -1;
	public const int32 UI_ANIMATION_REPEAT_INDEFINITELY = -1;
	public const int32 UI_ANIMATION_REPEAT_INDEFINITELY_CONCLUDE_AT_END = -1;
	public const int32 UI_ANIMATION_REPEAT_INDEFINITELY_CONCLUDE_AT_START = -2;
	public const int32 UI_ANIMATION_SECONDS_INFINITE = -1;
}
#endregion

#region TypeDefs
typealias UI_ANIMATION_KEYFRAME = int;

#endregion


#region Enums

[AllowDuplicates]
public enum UI_ANIMATION_UPDATE_RESULT : int32
{
	UI_ANIMATION_UPDATE_NO_CHANGE = 0,
	UI_ANIMATION_UPDATE_VARIABLES_CHANGED = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_MANAGER_STATUS : int32
{
	UI_ANIMATION_MANAGER_IDLE = 0,
	UI_ANIMATION_MANAGER_BUSY = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_MODE : int32
{
	UI_ANIMATION_MODE_DISABLED = 0,
	UI_ANIMATION_MODE_SYSTEM_DEFAULT = 1,
	UI_ANIMATION_MODE_ENABLED = 2,
}


[AllowDuplicates]
public enum UI_ANIMATION_REPEAT_MODE : int32
{
	UI_ANIMATION_REPEAT_MODE_NORMAL = 0,
	UI_ANIMATION_REPEAT_MODE_ALTERNATE = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_ROUNDING_MODE : int32
{
	UI_ANIMATION_ROUNDING_NEAREST = 0,
	UI_ANIMATION_ROUNDING_FLOOR = 1,
	UI_ANIMATION_ROUNDING_CEILING = 2,
}


[AllowDuplicates]
public enum UI_ANIMATION_STORYBOARD_STATUS : int32
{
	UI_ANIMATION_STORYBOARD_BUILDING = 0,
	UI_ANIMATION_STORYBOARD_SCHEDULED = 1,
	UI_ANIMATION_STORYBOARD_CANCELLED = 2,
	UI_ANIMATION_STORYBOARD_PLAYING = 3,
	UI_ANIMATION_STORYBOARD_TRUNCATED = 4,
	UI_ANIMATION_STORYBOARD_FINISHED = 5,
	UI_ANIMATION_STORYBOARD_READY = 6,
	UI_ANIMATION_STORYBOARD_INSUFFICIENT_PRIORITY = 7,
}


[AllowDuplicates]
public enum UI_ANIMATION_SCHEDULING_RESULT : int32
{
	UI_ANIMATION_SCHEDULING_UNEXPECTED_FAILURE = 0,
	UI_ANIMATION_SCHEDULING_INSUFFICIENT_PRIORITY = 1,
	UI_ANIMATION_SCHEDULING_ALREADY_SCHEDULED = 2,
	UI_ANIMATION_SCHEDULING_SUCCEEDED = 3,
	UI_ANIMATION_SCHEDULING_DEFERRED = 4,
}


[AllowDuplicates]
public enum UI_ANIMATION_PRIORITY_EFFECT : int32
{
	UI_ANIMATION_PRIORITY_EFFECT_FAILURE = 0,
	UI_ANIMATION_PRIORITY_EFFECT_DELAY = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_SLOPE : int32
{
	UI_ANIMATION_SLOPE_INCREASING = 0,
	UI_ANIMATION_SLOPE_DECREASING = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_DEPENDENCIES : uint32
{
	UI_ANIMATION_DEPENDENCY_NONE = 0,
	UI_ANIMATION_DEPENDENCY_INTERMEDIATE_VALUES = 1,
	UI_ANIMATION_DEPENDENCY_FINAL_VALUE = 2,
	UI_ANIMATION_DEPENDENCY_FINAL_VELOCITY = 4,
	UI_ANIMATION_DEPENDENCY_DURATION = 8,
}


[AllowDuplicates]
public enum UI_ANIMATION_IDLE_BEHAVIOR : int32
{
	UI_ANIMATION_IDLE_BEHAVIOR_CONTINUE = 0,
	UI_ANIMATION_IDLE_BEHAVIOR_DISABLE = 1,
}


[AllowDuplicates]
public enum UI_ANIMATION_TIMER_CLIENT_STATUS : int32
{
	UI_ANIMATION_TIMER_CLIENT_IDLE = 0,
	UI_ANIMATION_TIMER_CLIENT_BUSY = 1,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_UIAnimationManager = .(0x4c1fc63a, 0x695c, 0x47e8, 0xa3, 0x39, 0x1a, 0x19, 0x4b, 0xe3, 0xd0, 0xb8);


	public const Guid CLSID_UIAnimationManager2 = .(0xd25d8842, 0x8884, 0x4a4a, 0xb3, 0x21, 0x09, 0x13, 0x14, 0x37, 0x9b, 0xdd);


	public const Guid CLSID_UIAnimationTransitionLibrary = .(0x1d6322ad, 0xaa85, 0x4ef5, 0xa8, 0x28, 0x86, 0xd7, 0x10, 0x67, 0xd1, 0x45);


	public const Guid CLSID_UIAnimationTransitionLibrary2 = .(0x812f944a, 0xc5c8, 0x4cd9, 0xb0, 0xa6, 0xb3, 0xda, 0x80, 0x2f, 0x22, 0x8d);


	public const Guid CLSID_UIAnimationTransitionFactory = .(0x8a9b1cdd, 0xfcd7, 0x419c, 0x8b, 0x44, 0x42, 0xfd, 0x17, 0xdb, 0x18, 0x87);


	public const Guid CLSID_UIAnimationTransitionFactory2 = .(0x84302f97, 0x7f7b, 0x4040, 0xb1, 0x90, 0x72, 0xac, 0x9d, 0x18, 0xe4, 0x20);


	public const Guid CLSID_UIAnimationTimer = .(0xbfcd4a0c, 0x06b6, 0x4384, 0xb7, 0x68, 0x0d, 0xaa, 0x79, 0x2c, 0x38, 0x0e);


}
#endregion

#region COM Types
[CRepr]struct IUIAnimationManager : IUnknown
{
	public new const Guid IID = .(0x9169896c, 0xac8d, 0x4e7d, 0x94, 0xe5, 0x67, 0xfa, 0x4d, 0xc2, 0xf2, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double initialValue, IUIAnimationVariable** variable) CreateAnimationVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable* variable, IUIAnimationTransition* transition, double timeNow) ScheduleTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard** storyboard) CreateStoryboard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double completionDeadline) FinishAllStoryboards;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AbandonAllStoryboards;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double timeNow, UI_ANIMATION_UPDATE_RESULT* updateResult) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id, IUIAnimationVariable** variable) GetVariableFromTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id, IUIAnimationStoryboard** storyboard) GetStoryboardFromTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MANAGER_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MODE mode) SetAnimationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationManagerEventHandler* handler) SetManagerEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison* comparison) SetCancelPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison* comparison) SetTrimPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison* comparison) SetCompressPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison* comparison) SetConcludePriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay) SetDefaultLongestAcceptableDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
	}


	public HRESULT CreateAnimationVariable(double initialValue, IUIAnimationVariable** variable) mut => VT.[Friend]CreateAnimationVariable(&this, initialValue, variable);

	public HRESULT ScheduleTransition(IUIAnimationVariable* variable, IUIAnimationTransition* transition, double timeNow) mut => VT.[Friend]ScheduleTransition(&this, variable, transition, timeNow);

	public HRESULT CreateStoryboard(IUIAnimationStoryboard** storyboard) mut => VT.[Friend]CreateStoryboard(&this, storyboard);

	public HRESULT FinishAllStoryboards(double completionDeadline) mut => VT.[Friend]FinishAllStoryboards(&this, completionDeadline);

	public HRESULT AbandonAllStoryboards() mut => VT.[Friend]AbandonAllStoryboards(&this);

	public HRESULT Update(double timeNow, UI_ANIMATION_UPDATE_RESULT* updateResult) mut => VT.[Friend]Update(&this, timeNow, updateResult);

	public HRESULT GetVariableFromTag(IUnknown* object, uint32 id, IUIAnimationVariable** variable) mut => VT.[Friend]GetVariableFromTag(&this, object, id, variable);

	public HRESULT GetStoryboardFromTag(IUnknown* object, uint32 id, IUIAnimationStoryboard** storyboard) mut => VT.[Friend]GetStoryboardFromTag(&this, object, id, storyboard);

	public HRESULT GetStatus(UI_ANIMATION_MANAGER_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT SetAnimationMode(UI_ANIMATION_MODE mode) mut => VT.[Friend]SetAnimationMode(&this, mode);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT SetManagerEventHandler(IUIAnimationManagerEventHandler* handler) mut => VT.[Friend]SetManagerEventHandler(&this, handler);

	public HRESULT SetCancelPriorityComparison(IUIAnimationPriorityComparison* comparison) mut => VT.[Friend]SetCancelPriorityComparison(&this, comparison);

	public HRESULT SetTrimPriorityComparison(IUIAnimationPriorityComparison* comparison) mut => VT.[Friend]SetTrimPriorityComparison(&this, comparison);

	public HRESULT SetCompressPriorityComparison(IUIAnimationPriorityComparison* comparison) mut => VT.[Friend]SetCompressPriorityComparison(&this, comparison);

	public HRESULT SetConcludePriorityComparison(IUIAnimationPriorityComparison* comparison) mut => VT.[Friend]SetConcludePriorityComparison(&this, comparison);

	public HRESULT SetDefaultLongestAcceptableDelay(double delay) mut => VT.[Friend]SetDefaultLongestAcceptableDelay(&this, delay);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);
}

[CRepr]struct IUIAnimationVariable : IUnknown
{
	public new const Guid IID = .(0x8ceeb155, 0x2849, 0x4ce5, 0x94, 0x48, 0x91, 0xff, 0x70, 0xe1, 0xe4, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* finalValue) GetFinalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* previousValue) GetPreviousValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* value) GetIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* finalValue) GetFinalIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* previousValue) GetPreviousIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard** storyboard) GetCurrentStoryboard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double bound) SetLowerBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double bound) SetUpperBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_ROUNDING_MODE mode) SetRoundingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariableChangeHandler* handler) SetVariableChangeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariableIntegerChangeHandler* handler) SetVariableIntegerChangeHandler;
	}


	public HRESULT GetValue(double* value) mut => VT.[Friend]GetValue(&this, value);

	public HRESULT GetFinalValue(double* finalValue) mut => VT.[Friend]GetFinalValue(&this, finalValue);

	public HRESULT GetPreviousValue(double* previousValue) mut => VT.[Friend]GetPreviousValue(&this, previousValue);

	public HRESULT GetIntegerValue(int32* value) mut => VT.[Friend]GetIntegerValue(&this, value);

	public HRESULT GetFinalIntegerValue(int32* finalValue) mut => VT.[Friend]GetFinalIntegerValue(&this, finalValue);

	public HRESULT GetPreviousIntegerValue(int32* previousValue) mut => VT.[Friend]GetPreviousIntegerValue(&this, previousValue);

	public HRESULT GetCurrentStoryboard(IUIAnimationStoryboard** storyboard) mut => VT.[Friend]GetCurrentStoryboard(&this, storyboard);

	public HRESULT SetLowerBound(double bound) mut => VT.[Friend]SetLowerBound(&this, bound);

	public HRESULT SetUpperBound(double bound) mut => VT.[Friend]SetUpperBound(&this, bound);

	public HRESULT SetRoundingMode(UI_ANIMATION_ROUNDING_MODE mode) mut => VT.[Friend]SetRoundingMode(&this, mode);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetTag(IUnknown** object, uint32* id) mut => VT.[Friend]GetTag(&this, object, id);

	public HRESULT SetVariableChangeHandler(IUIAnimationVariableChangeHandler* handler) mut => VT.[Friend]SetVariableChangeHandler(&this, handler);

	public HRESULT SetVariableIntegerChangeHandler(IUIAnimationVariableIntegerChangeHandler* handler) mut => VT.[Friend]SetVariableIntegerChangeHandler(&this, handler);
}

[CRepr]struct IUIAnimationStoryboard : IUnknown
{
	public new const Guid IID = .(0xa8ff128f, 0x9bf9, 0x4af1, 0x9e, 0x67, 0xe5, 0xe4, 0x10, 0xde, 0xfb, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable* variable, IUIAnimationTransition* transition) AddTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_KEYFRAME existingKeyframe, double offset, UI_ANIMATION_KEYFRAME* keyframe) AddKeyframeAtOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME* keyframe) AddKeyframeAfterTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable* variable, IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME startKeyframe) AddTransitionAtKeyframe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable* variable, IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe) AddTransitionBetweenKeyframes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe, int32 repetitionCount) RepeatBetweenKeyframes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable* variable) HoldVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay) SetLongestAcceptableDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double timeNow, UI_ANIMATION_SCHEDULING_RESULT* schedulingResult) Schedule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Conclude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double completionDeadline) Finish;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abandon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_STORYBOARD_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* elapsedTime) GetElapsedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboardEventHandler* handler) SetStoryboardEventHandler;
	}


	public HRESULT AddTransition(IUIAnimationVariable* variable, IUIAnimationTransition* transition) mut => VT.[Friend]AddTransition(&this, variable, transition);

	public HRESULT AddKeyframeAtOffset(UI_ANIMATION_KEYFRAME existingKeyframe, double offset, UI_ANIMATION_KEYFRAME* keyframe) mut => VT.[Friend]AddKeyframeAtOffset(&this, existingKeyframe, offset, keyframe);

	public HRESULT AddKeyframeAfterTransition(IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME* keyframe) mut => VT.[Friend]AddKeyframeAfterTransition(&this, transition, keyframe);

	public HRESULT AddTransitionAtKeyframe(IUIAnimationVariable* variable, IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME startKeyframe) mut => VT.[Friend]AddTransitionAtKeyframe(&this, variable, transition, startKeyframe);

	public HRESULT AddTransitionBetweenKeyframes(IUIAnimationVariable* variable, IUIAnimationTransition* transition, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe) mut => VT.[Friend]AddTransitionBetweenKeyframes(&this, variable, transition, startKeyframe, endKeyframe);

	public HRESULT RepeatBetweenKeyframes(UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe, int32 repetitionCount) mut => VT.[Friend]RepeatBetweenKeyframes(&this, startKeyframe, endKeyframe, repetitionCount);

	public HRESULT HoldVariable(IUIAnimationVariable* variable) mut => VT.[Friend]HoldVariable(&this, variable);

	public HRESULT SetLongestAcceptableDelay(double delay) mut => VT.[Friend]SetLongestAcceptableDelay(&this, delay);

	public HRESULT Schedule(double timeNow, UI_ANIMATION_SCHEDULING_RESULT* schedulingResult) mut => VT.[Friend]Schedule(&this, timeNow, schedulingResult);

	public HRESULT Conclude() mut => VT.[Friend]Conclude(&this);

	public HRESULT Finish(double completionDeadline) mut => VT.[Friend]Finish(&this, completionDeadline);

	public HRESULT Abandon() mut => VT.[Friend]Abandon(&this);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetTag(IUnknown** object, uint32* id) mut => VT.[Friend]GetTag(&this, object, id);

	public HRESULT GetStatus(UI_ANIMATION_STORYBOARD_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT GetElapsedTime(double* elapsedTime) mut => VT.[Friend]GetElapsedTime(&this, elapsedTime);

	public HRESULT SetStoryboardEventHandler(IUIAnimationStoryboardEventHandler* handler) mut => VT.[Friend]SetStoryboardEventHandler(&this, handler);
}

[CRepr]struct IUIAnimationTransition : IUnknown
{
	public new const Guid IID = .(0xdc6ce252, 0xf731, 0x41cf, 0xb6, 0x10, 0x61, 0x4b, 0x6c, 0xa0, 0x49, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double value) SetInitialValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double velocity) SetInitialVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDurationKnown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* duration) GetDuration;
	}


	public HRESULT SetInitialValue(double value) mut => VT.[Friend]SetInitialValue(&this, value);

	public HRESULT SetInitialVelocity(double velocity) mut => VT.[Friend]SetInitialVelocity(&this, velocity);

	public HRESULT IsDurationKnown() mut => VT.[Friend]IsDurationKnown(&this);

	public HRESULT GetDuration(double* duration) mut => VT.[Friend]GetDuration(&this, duration);
}

[CRepr]struct IUIAnimationManagerEventHandler : IUnknown
{
	public new const Guid IID = .(0x783321ed, 0x78a3, 0x4366, 0xb5, 0x74, 0x6a, 0xf6, 0x07, 0xa6, 0x47, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MANAGER_STATUS newStatus, UI_ANIMATION_MANAGER_STATUS previousStatus) OnManagerStatusChanged;
	}


	public HRESULT OnManagerStatusChanged(UI_ANIMATION_MANAGER_STATUS newStatus, UI_ANIMATION_MANAGER_STATUS previousStatus) mut => VT.[Friend]OnManagerStatusChanged(&this, newStatus, previousStatus);
}

[CRepr]struct IUIAnimationVariableChangeHandler : IUnknown
{
	public new const Guid IID = .(0x6358b7ba, 0x87d2, 0x42d5, 0xbf, 0x71, 0x82, 0xe9, 0x19, 0xdd, 0x58, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard* storyboard, IUIAnimationVariable* variable, double newValue, double previousValue) OnValueChanged;
	}


	public HRESULT OnValueChanged(IUIAnimationStoryboard* storyboard, IUIAnimationVariable* variable, double newValue, double previousValue) mut => VT.[Friend]OnValueChanged(&this, storyboard, variable, newValue, previousValue);
}

[CRepr]struct IUIAnimationVariableIntegerChangeHandler : IUnknown
{
	public new const Guid IID = .(0xbb3e1550, 0x356e, 0x44b0, 0x99, 0xda, 0x85, 0xac, 0x60, 0x17, 0x86, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard* storyboard, IUIAnimationVariable* variable, int32 newValue, int32 previousValue) OnIntegerValueChanged;
	}


	public HRESULT OnIntegerValueChanged(IUIAnimationStoryboard* storyboard, IUIAnimationVariable* variable, int32 newValue, int32 previousValue) mut => VT.[Friend]OnIntegerValueChanged(&this, storyboard, variable, newValue, previousValue);
}

[CRepr]struct IUIAnimationStoryboardEventHandler : IUnknown
{
	public new const Guid IID = .(0x3d5c9008, 0xec7c, 0x4364, 0x9f, 0x8a, 0x9a, 0xf3, 0xc5, 0x8c, 0xba, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard* storyboard, UI_ANIMATION_STORYBOARD_STATUS newStatus, UI_ANIMATION_STORYBOARD_STATUS previousStatus) OnStoryboardStatusChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard* storyboard) OnStoryboardUpdated;
	}


	public HRESULT OnStoryboardStatusChanged(IUIAnimationStoryboard* storyboard, UI_ANIMATION_STORYBOARD_STATUS newStatus, UI_ANIMATION_STORYBOARD_STATUS previousStatus) mut => VT.[Friend]OnStoryboardStatusChanged(&this, storyboard, newStatus, previousStatus);

	public HRESULT OnStoryboardUpdated(IUIAnimationStoryboard* storyboard) mut => VT.[Friend]OnStoryboardUpdated(&this, storyboard);
}

[CRepr]struct IUIAnimationPriorityComparison : IUnknown
{
	public new const Guid IID = .(0x83fa9b74, 0x5f86, 0x4618, 0xbc, 0x6a, 0xa2, 0xfa, 0xc1, 0x9b, 0x3f, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard* scheduledStoryboard, IUIAnimationStoryboard* newStoryboard, UI_ANIMATION_PRIORITY_EFFECT priorityEffect) HasPriority;
	}


	public HRESULT HasPriority(IUIAnimationStoryboard* scheduledStoryboard, IUIAnimationStoryboard* newStoryboard, UI_ANIMATION_PRIORITY_EFFECT priorityEffect) mut => VT.[Friend]HasPriority(&this, scheduledStoryboard, newStoryboard, priorityEffect);
}

[CRepr]struct IUIAnimationTransitionLibrary : IUnknown
{
	public new const Guid IID = .(0xca5a14b1, 0xd24f, 0x48b8, 0x8f, 0xe4, 0xc7, 0x81, 0x69, 0xba, 0x95, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double finalValue, IUIAnimationTransition** transition) CreateInstantaneousTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, IUIAnimationTransition** transition) CreateConstantTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay, double finalValue, double hold, IUIAnimationTransition** transition) CreateDiscreteTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, IUIAnimationTransition** transition) CreateLinearTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double speed, double finalValue, IUIAnimationTransition** transition) CreateLinearTransitionFromSpeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double period, IUIAnimationTransition** transition) CreateSinusoidalTransitionFromVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double minimumValue, double maximumValue, double period, UI_ANIMATION_SLOPE slope, IUIAnimationTransition** transition) CreateSinusoidalTransitionFromRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, double accelerationRatio, double decelerationRatio, IUIAnimationTransition** transition) CreateAccelerateDecelerateTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, IUIAnimationTransition** transition) CreateReversalTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, double finalVelocity, IUIAnimationTransition** transition) CreateCubicTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double maximumDuration, double finalValue, IUIAnimationTransition** transition) CreateSmoothStopTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double finalValue, double finalVelocity, double acceleration, IUIAnimationTransition** transition) CreateParabolicTransitionFromAcceleration;
	}


	public HRESULT CreateInstantaneousTransition(double finalValue, IUIAnimationTransition** transition) mut => VT.[Friend]CreateInstantaneousTransition(&this, finalValue, transition);

	public HRESULT CreateConstantTransition(double duration, IUIAnimationTransition** transition) mut => VT.[Friend]CreateConstantTransition(&this, duration, transition);

	public HRESULT CreateDiscreteTransition(double delay, double finalValue, double hold, IUIAnimationTransition** transition) mut => VT.[Friend]CreateDiscreteTransition(&this, delay, finalValue, hold, transition);

	public HRESULT CreateLinearTransition(double duration, double finalValue, IUIAnimationTransition** transition) mut => VT.[Friend]CreateLinearTransition(&this, duration, finalValue, transition);

	public HRESULT CreateLinearTransitionFromSpeed(double speed, double finalValue, IUIAnimationTransition** transition) mut => VT.[Friend]CreateLinearTransitionFromSpeed(&this, speed, finalValue, transition);

	public HRESULT CreateSinusoidalTransitionFromVelocity(double duration, double period, IUIAnimationTransition** transition) mut => VT.[Friend]CreateSinusoidalTransitionFromVelocity(&this, duration, period, transition);

	public HRESULT CreateSinusoidalTransitionFromRange(double duration, double minimumValue, double maximumValue, double period, UI_ANIMATION_SLOPE slope, IUIAnimationTransition** transition) mut => VT.[Friend]CreateSinusoidalTransitionFromRange(&this, duration, minimumValue, maximumValue, period, slope, transition);

	public HRESULT CreateAccelerateDecelerateTransition(double duration, double finalValue, double accelerationRatio, double decelerationRatio, IUIAnimationTransition** transition) mut => VT.[Friend]CreateAccelerateDecelerateTransition(&this, duration, finalValue, accelerationRatio, decelerationRatio, transition);

	public HRESULT CreateReversalTransition(double duration, IUIAnimationTransition** transition) mut => VT.[Friend]CreateReversalTransition(&this, duration, transition);

	public HRESULT CreateCubicTransition(double duration, double finalValue, double finalVelocity, IUIAnimationTransition** transition) mut => VT.[Friend]CreateCubicTransition(&this, duration, finalValue, finalVelocity, transition);

	public HRESULT CreateSmoothStopTransition(double maximumDuration, double finalValue, IUIAnimationTransition** transition) mut => VT.[Friend]CreateSmoothStopTransition(&this, maximumDuration, finalValue, transition);

	public HRESULT CreateParabolicTransitionFromAcceleration(double finalValue, double finalVelocity, double acceleration, IUIAnimationTransition** transition) mut => VT.[Friend]CreateParabolicTransitionFromAcceleration(&this, finalValue, finalVelocity, acceleration, transition);
}

[CRepr]struct IUIAnimationInterpolator : IUnknown
{
	public new const Guid IID = .(0x7815cbba, 0xddf7, 0x478c, 0xa4, 0x6c, 0x7b, 0x6c, 0x73, 0x8b, 0x79, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double initialValue, double initialVelocity) SetInitialValueAndVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration) SetDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* duration) GetDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value) GetFinalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double offset, double* value) InterpolateValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double offset, double* velocity) InterpolateVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_DEPENDENCIES* initialValueDependencies, UI_ANIMATION_DEPENDENCIES* initialVelocityDependencies, UI_ANIMATION_DEPENDENCIES* durationDependencies) GetDependencies;
	}


	public HRESULT SetInitialValueAndVelocity(double initialValue, double initialVelocity) mut => VT.[Friend]SetInitialValueAndVelocity(&this, initialValue, initialVelocity);

	public HRESULT SetDuration(double duration) mut => VT.[Friend]SetDuration(&this, duration);

	public HRESULT GetDuration(double* duration) mut => VT.[Friend]GetDuration(&this, duration);

	public HRESULT GetFinalValue(double* value) mut => VT.[Friend]GetFinalValue(&this, value);

	public HRESULT InterpolateValue(double offset, double* value) mut => VT.[Friend]InterpolateValue(&this, offset, value);

	public HRESULT InterpolateVelocity(double offset, double* velocity) mut => VT.[Friend]InterpolateVelocity(&this, offset, velocity);

	public HRESULT GetDependencies(UI_ANIMATION_DEPENDENCIES* initialValueDependencies, UI_ANIMATION_DEPENDENCIES* initialVelocityDependencies, UI_ANIMATION_DEPENDENCIES* durationDependencies) mut => VT.[Friend]GetDependencies(&this, initialValueDependencies, initialVelocityDependencies, durationDependencies);
}

[CRepr]struct IUIAnimationTransitionFactory : IUnknown
{
	public new const Guid IID = .(0xfcd91e03, 0x3e3b, 0x45ad, 0xbb, 0xb1, 0x6d, 0xfc, 0x81, 0x53, 0x74, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationInterpolator* interpolator, IUIAnimationTransition** transition) CreateTransition;
	}


	public HRESULT CreateTransition(IUIAnimationInterpolator* interpolator, IUIAnimationTransition** transition) mut => VT.[Friend]CreateTransition(&this, interpolator, transition);
}

[CRepr]struct IUIAnimationTimer : IUnknown
{
	public new const Guid IID = .(0x6b0efad1, 0xa053, 0x41d6, 0x90, 0x85, 0x33, 0xa6, 0x89, 0x14, 0x46, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationTimerUpdateHandler* updateHandler, UI_ANIMATION_IDLE_BEHAVIOR idleBehavior) SetTimerUpdateHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationTimerEventHandler* handler) SetTimerEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* seconds) GetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 framesPerSecond) SetFrameRateThreshold;
	}


	public HRESULT SetTimerUpdateHandler(IUIAnimationTimerUpdateHandler* updateHandler, UI_ANIMATION_IDLE_BEHAVIOR idleBehavior) mut => VT.[Friend]SetTimerUpdateHandler(&this, updateHandler, idleBehavior);

	public HRESULT SetTimerEventHandler(IUIAnimationTimerEventHandler* handler) mut => VT.[Friend]SetTimerEventHandler(&this, handler);

	public HRESULT Enable() mut => VT.[Friend]Enable(&this);

	public HRESULT Disable() mut => VT.[Friend]Disable(&this);

	public HRESULT IsEnabled() mut => VT.[Friend]IsEnabled(&this);

	public HRESULT GetTime(double* seconds) mut => VT.[Friend]GetTime(&this, seconds);

	public HRESULT SetFrameRateThreshold(uint32 framesPerSecond) mut => VT.[Friend]SetFrameRateThreshold(&this, framesPerSecond);
}

[CRepr]struct IUIAnimationTimerUpdateHandler : IUnknown
{
	public new const Guid IID = .(0x195509b7, 0x5d5e, 0x4e3e, 0xb2, 0x78, 0xee, 0x37, 0x59, 0xb3, 0x67, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double timeNow, UI_ANIMATION_UPDATE_RESULT* result) OnUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationTimerClientEventHandler* handler) SetTimerClientEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearTimerClientEventHandler;
	}


	public HRESULT OnUpdate(double timeNow, UI_ANIMATION_UPDATE_RESULT* result) mut => VT.[Friend]OnUpdate(&this, timeNow, result);

	public HRESULT SetTimerClientEventHandler(IUIAnimationTimerClientEventHandler* handler) mut => VT.[Friend]SetTimerClientEventHandler(&this, handler);

	public HRESULT ClearTimerClientEventHandler() mut => VT.[Friend]ClearTimerClientEventHandler(&this);
}

[CRepr]struct IUIAnimationTimerClientEventHandler : IUnknown
{
	public new const Guid IID = .(0xbedb4db6, 0x94fa, 0x4bfb, 0xa4, 0x7f, 0xef, 0x2d, 0x9e, 0x40, 0x8c, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_TIMER_CLIENT_STATUS newStatus, UI_ANIMATION_TIMER_CLIENT_STATUS previousStatus) OnTimerClientStatusChanged;
	}


	public HRESULT OnTimerClientStatusChanged(UI_ANIMATION_TIMER_CLIENT_STATUS newStatus, UI_ANIMATION_TIMER_CLIENT_STATUS previousStatus) mut => VT.[Friend]OnTimerClientStatusChanged(&this, newStatus, previousStatus);
}

[CRepr]struct IUIAnimationTimerEventHandler : IUnknown
{
	public new const Guid IID = .(0x274a7dea, 0xd771, 0x4095, 0xab, 0xbd, 0x8d, 0xf7, 0xab, 0xd2, 0x3c, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnPreUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnPostUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 framesPerSecond) OnRenderingTooSlow;
	}


	public HRESULT OnPreUpdate() mut => VT.[Friend]OnPreUpdate(&this);

	public HRESULT OnPostUpdate() mut => VT.[Friend]OnPostUpdate(&this);

	public HRESULT OnRenderingTooSlow(uint32 framesPerSecond) mut => VT.[Friend]OnRenderingTooSlow(&this, framesPerSecond);
}

[CRepr]struct IUIAnimationManager2 : IUnknown
{
	public new const Guid IID = .(0xd8b6f7d4, 0x4109, 0x4d3f, 0xac, 0xee, 0x87, 0x99, 0x26, 0x96, 0x8c, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* initialValue, uint32 cDimension, IUIAnimationVariable2** variable) CreateAnimationVectorVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double initialValue, IUIAnimationVariable2** variable) CreateAnimationVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, double timeNow) ScheduleTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2** storyboard) CreateStoryboard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double completionDeadline) FinishAllStoryboards;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AbandonAllStoryboards;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double timeNow, UI_ANIMATION_UPDATE_RESULT* updateResult) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id, IUIAnimationVariable2** variable) GetVariableFromTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id, IUIAnimationStoryboard2** storyboard) GetStoryboardFromTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* seconds) EstimateNextEventTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MANAGER_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MODE mode) SetAnimationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationManagerEventHandler2* handler, BOOL fRegisterForNextAnimationEvent) SetManagerEventHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison2* comparison) SetCancelPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison2* comparison) SetTrimPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison2* comparison) SetCompressPriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPriorityComparison2* comparison) SetConcludePriorityComparison;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay) SetDefaultLongestAcceptableDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
	}


	public HRESULT CreateAnimationVectorVariable(double* initialValue, uint32 cDimension, IUIAnimationVariable2** variable) mut => VT.[Friend]CreateAnimationVectorVariable(&this, initialValue, cDimension, variable);

	public HRESULT CreateAnimationVariable(double initialValue, IUIAnimationVariable2** variable) mut => VT.[Friend]CreateAnimationVariable(&this, initialValue, variable);

	public HRESULT ScheduleTransition(IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, double timeNow) mut => VT.[Friend]ScheduleTransition(&this, variable, transition, timeNow);

	public HRESULT CreateStoryboard(IUIAnimationStoryboard2** storyboard) mut => VT.[Friend]CreateStoryboard(&this, storyboard);

	public HRESULT FinishAllStoryboards(double completionDeadline) mut => VT.[Friend]FinishAllStoryboards(&this, completionDeadline);

	public HRESULT AbandonAllStoryboards() mut => VT.[Friend]AbandonAllStoryboards(&this);

	public HRESULT Update(double timeNow, UI_ANIMATION_UPDATE_RESULT* updateResult) mut => VT.[Friend]Update(&this, timeNow, updateResult);

	public HRESULT GetVariableFromTag(IUnknown* object, uint32 id, IUIAnimationVariable2** variable) mut => VT.[Friend]GetVariableFromTag(&this, object, id, variable);

	public HRESULT GetStoryboardFromTag(IUnknown* object, uint32 id, IUIAnimationStoryboard2** storyboard) mut => VT.[Friend]GetStoryboardFromTag(&this, object, id, storyboard);

	public HRESULT EstimateNextEventTime(double* seconds) mut => VT.[Friend]EstimateNextEventTime(&this, seconds);

	public HRESULT GetStatus(UI_ANIMATION_MANAGER_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT SetAnimationMode(UI_ANIMATION_MODE mode) mut => VT.[Friend]SetAnimationMode(&this, mode);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT SetManagerEventHandler(IUIAnimationManagerEventHandler2* handler, BOOL fRegisterForNextAnimationEvent) mut => VT.[Friend]SetManagerEventHandler(&this, handler, fRegisterForNextAnimationEvent);

	public HRESULT SetCancelPriorityComparison(IUIAnimationPriorityComparison2* comparison) mut => VT.[Friend]SetCancelPriorityComparison(&this, comparison);

	public HRESULT SetTrimPriorityComparison(IUIAnimationPriorityComparison2* comparison) mut => VT.[Friend]SetTrimPriorityComparison(&this, comparison);

	public HRESULT SetCompressPriorityComparison(IUIAnimationPriorityComparison2* comparison) mut => VT.[Friend]SetCompressPriorityComparison(&this, comparison);

	public HRESULT SetConcludePriorityComparison(IUIAnimationPriorityComparison2* comparison) mut => VT.[Friend]SetConcludePriorityComparison(&this, comparison);

	public HRESULT SetDefaultLongestAcceptableDelay(double delay) mut => VT.[Friend]SetDefaultLongestAcceptableDelay(&this, delay);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);
}

[CRepr]struct IUIAnimationVariable2 : IUnknown
{
	public new const Guid IID = .(0x4914b304, 0x96ab, 0x44d9, 0x9e, 0x77, 0xd5, 0x10, 0x9b, 0x7e, 0x74, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dimension) GetDimension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value, uint32 cDimension) GetVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation* animation) GetCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDCompositionAnimation** animation, uint32 cDimension) GetVectorCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* finalValue) GetFinalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* finalValue, uint32 cDimension) GetFinalVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* previousValue) GetPreviousValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* previousValue, uint32 cDimension) GetPreviousVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* value) GetIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* value, uint32 cDimension) GetIntegerVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* finalValue) GetFinalIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* finalValue, uint32 cDimension) GetFinalIntegerVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* previousValue) GetPreviousIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* previousValue, uint32 cDimension) GetPreviousIntegerVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2** storyboard) GetCurrentStoryboard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double bound) SetLowerBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* bound, uint32 cDimension) SetLowerBoundVector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double bound) SetUpperBound;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* bound, uint32 cDimension) SetUpperBoundVector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_ROUNDING_MODE mode) SetRoundingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariableChangeHandler2* handler, BOOL fRegisterForNextAnimationEvent) SetVariableChangeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariableIntegerChangeHandler2* handler, BOOL fRegisterForNextAnimationEvent) SetVariableIntegerChangeHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariableCurveChangeHandler2* handler) SetVariableCurveChangeHandler;
	}


	public HRESULT GetDimension(uint32* dimension) mut => VT.[Friend]GetDimension(&this, dimension);

	public HRESULT GetValue(double* value) mut => VT.[Friend]GetValue(&this, value);

	public HRESULT GetVectorValue(double* value, uint32 cDimension) mut => VT.[Friend]GetVectorValue(&this, value, cDimension);

	public HRESULT GetCurve(IDCompositionAnimation* animation) mut => VT.[Friend]GetCurve(&this, animation);

	public HRESULT GetVectorCurve(IDCompositionAnimation** animation, uint32 cDimension) mut => VT.[Friend]GetVectorCurve(&this, animation, cDimension);

	public HRESULT GetFinalValue(double* finalValue) mut => VT.[Friend]GetFinalValue(&this, finalValue);

	public HRESULT GetFinalVectorValue(double* finalValue, uint32 cDimension) mut => VT.[Friend]GetFinalVectorValue(&this, finalValue, cDimension);

	public HRESULT GetPreviousValue(double* previousValue) mut => VT.[Friend]GetPreviousValue(&this, previousValue);

	public HRESULT GetPreviousVectorValue(double* previousValue, uint32 cDimension) mut => VT.[Friend]GetPreviousVectorValue(&this, previousValue, cDimension);

	public HRESULT GetIntegerValue(int32* value) mut => VT.[Friend]GetIntegerValue(&this, value);

	public HRESULT GetIntegerVectorValue(int32* value, uint32 cDimension) mut => VT.[Friend]GetIntegerVectorValue(&this, value, cDimension);

	public HRESULT GetFinalIntegerValue(int32* finalValue) mut => VT.[Friend]GetFinalIntegerValue(&this, finalValue);

	public HRESULT GetFinalIntegerVectorValue(int32* finalValue, uint32 cDimension) mut => VT.[Friend]GetFinalIntegerVectorValue(&this, finalValue, cDimension);

	public HRESULT GetPreviousIntegerValue(int32* previousValue) mut => VT.[Friend]GetPreviousIntegerValue(&this, previousValue);

	public HRESULT GetPreviousIntegerVectorValue(int32* previousValue, uint32 cDimension) mut => VT.[Friend]GetPreviousIntegerVectorValue(&this, previousValue, cDimension);

	public HRESULT GetCurrentStoryboard(IUIAnimationStoryboard2** storyboard) mut => VT.[Friend]GetCurrentStoryboard(&this, storyboard);

	public HRESULT SetLowerBound(double bound) mut => VT.[Friend]SetLowerBound(&this, bound);

	public HRESULT SetLowerBoundVector(double* bound, uint32 cDimension) mut => VT.[Friend]SetLowerBoundVector(&this, bound, cDimension);

	public HRESULT SetUpperBound(double bound) mut => VT.[Friend]SetUpperBound(&this, bound);

	public HRESULT SetUpperBoundVector(double* bound, uint32 cDimension) mut => VT.[Friend]SetUpperBoundVector(&this, bound, cDimension);

	public HRESULT SetRoundingMode(UI_ANIMATION_ROUNDING_MODE mode) mut => VT.[Friend]SetRoundingMode(&this, mode);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetTag(IUnknown** object, uint32* id) mut => VT.[Friend]GetTag(&this, object, id);

	public HRESULT SetVariableChangeHandler(IUIAnimationVariableChangeHandler2* handler, BOOL fRegisterForNextAnimationEvent) mut => VT.[Friend]SetVariableChangeHandler(&this, handler, fRegisterForNextAnimationEvent);

	public HRESULT SetVariableIntegerChangeHandler(IUIAnimationVariableIntegerChangeHandler2* handler, BOOL fRegisterForNextAnimationEvent) mut => VT.[Friend]SetVariableIntegerChangeHandler(&this, handler, fRegisterForNextAnimationEvent);

	public HRESULT SetVariableCurveChangeHandler(IUIAnimationVariableCurveChangeHandler2* handler) mut => VT.[Friend]SetVariableCurveChangeHandler(&this, handler);
}

[CRepr]struct IUIAnimationTransition2 : IUnknown
{
	public new const Guid IID = .(0x62ff9123, 0xa85a, 0x4e9b, 0xa2, 0x18, 0x43, 0x5a, 0x93, 0xe2, 0x68, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dimension) GetDimension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double value) SetInitialValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value, uint32 cDimension) SetInitialVectorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double velocity) SetInitialVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* velocity, uint32 cDimension) SetInitialVectorVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDurationKnown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* duration) GetDuration;
	}


	public HRESULT GetDimension(uint32* dimension) mut => VT.[Friend]GetDimension(&this, dimension);

	public HRESULT SetInitialValue(double value) mut => VT.[Friend]SetInitialValue(&this, value);

	public HRESULT SetInitialVectorValue(double* value, uint32 cDimension) mut => VT.[Friend]SetInitialVectorValue(&this, value, cDimension);

	public HRESULT SetInitialVelocity(double velocity) mut => VT.[Friend]SetInitialVelocity(&this, velocity);

	public HRESULT SetInitialVectorVelocity(double* velocity, uint32 cDimension) mut => VT.[Friend]SetInitialVectorVelocity(&this, velocity, cDimension);

	public HRESULT IsDurationKnown() mut => VT.[Friend]IsDurationKnown(&this);

	public HRESULT GetDuration(double* duration) mut => VT.[Friend]GetDuration(&this, duration);
}

[CRepr]struct IUIAnimationManagerEventHandler2 : IUnknown
{
	public new const Guid IID = .(0xf6e022ba, 0xbff3, 0x42ec, 0x90, 0x33, 0xe0, 0x73, 0xf3, 0x3e, 0x83, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_MANAGER_STATUS newStatus, UI_ANIMATION_MANAGER_STATUS previousStatus) OnManagerStatusChanged;
	}


	public HRESULT OnManagerStatusChanged(UI_ANIMATION_MANAGER_STATUS newStatus, UI_ANIMATION_MANAGER_STATUS previousStatus) mut => VT.[Friend]OnManagerStatusChanged(&this, newStatus, previousStatus);
}

[CRepr]struct IUIAnimationVariableChangeHandler2 : IUnknown
{
	public new const Guid IID = .(0x63acc8d2, 0x6eae, 0x4bb0, 0xb8, 0x79, 0x58, 0x6d, 0xd8, 0xcf, 0xbe, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* storyboard, IUIAnimationVariable2* variable, double* newValue, double* previousValue, uint32 cDimension) OnValueChanged;
	}


	public HRESULT OnValueChanged(IUIAnimationStoryboard2* storyboard, IUIAnimationVariable2* variable, double* newValue, double* previousValue, uint32 cDimension) mut => VT.[Friend]OnValueChanged(&this, storyboard, variable, newValue, previousValue, cDimension);
}

[CRepr]struct IUIAnimationVariableIntegerChangeHandler2 : IUnknown
{
	public new const Guid IID = .(0x829b6cf1, 0x4f3a, 0x4412, 0xae, 0x09, 0xb2, 0x43, 0xeb, 0x4c, 0x6b, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* storyboard, IUIAnimationVariable2* variable, int32* newValue, int32* previousValue, uint32 cDimension) OnIntegerValueChanged;
	}


	public HRESULT OnIntegerValueChanged(IUIAnimationStoryboard2* storyboard, IUIAnimationVariable2* variable, int32* newValue, int32* previousValue, uint32 cDimension) mut => VT.[Friend]OnIntegerValueChanged(&this, storyboard, variable, newValue, previousValue, cDimension);
}

[CRepr]struct IUIAnimationVariableCurveChangeHandler2 : IUnknown
{
	public new const Guid IID = .(0x72895e91, 0x0145, 0x4c21, 0x91, 0x92, 0x5a, 0xab, 0x40, 0xed, 0xdf, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable) OnCurveChanged;
	}


	public HRESULT OnCurveChanged(IUIAnimationVariable2* variable) mut => VT.[Friend]OnCurveChanged(&this, variable);
}

[CRepr]struct IUIAnimationStoryboardEventHandler2 : IUnknown
{
	public new const Guid IID = .(0xbac5f55a, 0xba7c, 0x414c, 0xb5, 0x99, 0xfb, 0xf8, 0x50, 0xf5, 0x53, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* storyboard, UI_ANIMATION_STORYBOARD_STATUS newStatus, UI_ANIMATION_STORYBOARD_STATUS previousStatus) OnStoryboardStatusChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* storyboard) OnStoryboardUpdated;
	}


	public HRESULT OnStoryboardStatusChanged(IUIAnimationStoryboard2* storyboard, UI_ANIMATION_STORYBOARD_STATUS newStatus, UI_ANIMATION_STORYBOARD_STATUS previousStatus) mut => VT.[Friend]OnStoryboardStatusChanged(&this, storyboard, newStatus, previousStatus);

	public HRESULT OnStoryboardUpdated(IUIAnimationStoryboard2* storyboard) mut => VT.[Friend]OnStoryboardUpdated(&this, storyboard);
}

[CRepr]struct IUIAnimationLoopIterationChangeHandler2 : IUnknown
{
	public new const Guid IID = .(0x2d3b15a4, 0x4762, 0x47ab, 0xa0, 0x30, 0xb2, 0x32, 0x21, 0xdf, 0x3a, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* storyboard, uint id, uint32 newIterationCount, uint32 oldIterationCount) OnLoopIterationChanged;
	}


	public HRESULT OnLoopIterationChanged(IUIAnimationStoryboard2* storyboard, uint id, uint32 newIterationCount, uint32 oldIterationCount) mut => VT.[Friend]OnLoopIterationChanged(&this, storyboard, id, newIterationCount, oldIterationCount);
}

[CRepr]struct IUIAnimationPriorityComparison2 : IUnknown
{
	public new const Guid IID = .(0x5b6d7a37, 0x4621, 0x467c, 0x8b, 0x05, 0x70, 0x13, 0x1d, 0xe6, 0x2d, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboard2* scheduledStoryboard, IUIAnimationStoryboard2* newStoryboard, UI_ANIMATION_PRIORITY_EFFECT priorityEffect) HasPriority;
	}


	public HRESULT HasPriority(IUIAnimationStoryboard2* scheduledStoryboard, IUIAnimationStoryboard2* newStoryboard, UI_ANIMATION_PRIORITY_EFFECT priorityEffect) mut => VT.[Friend]HasPriority(&this, scheduledStoryboard, newStoryboard, priorityEffect);
}

[CRepr]struct IUIAnimationTransitionLibrary2 : IUnknown
{
	public new const Guid IID = .(0x03cfae53, 0x9580, 0x4ee3, 0xb3, 0x63, 0x2e, 0xce, 0x51, 0xb4, 0xaf, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double finalValue, IUIAnimationTransition2** transition) CreateInstantaneousTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) CreateInstantaneousVectorTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, IUIAnimationTransition2** transition) CreateConstantTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay, double finalValue, double hold, IUIAnimationTransition2** transition) CreateDiscreteTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay, double* finalValue, uint32 cDimension, double hold, IUIAnimationTransition2** transition) CreateDiscreteVectorTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, IUIAnimationTransition2** transition) CreateLinearTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) CreateLinearVectorTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double speed, double finalValue, IUIAnimationTransition2** transition) CreateLinearTransitionFromSpeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double speed, double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) CreateLinearVectorTransitionFromSpeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double period, IUIAnimationTransition2** transition) CreateSinusoidalTransitionFromVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double minimumValue, double maximumValue, double period, UI_ANIMATION_SLOPE slope, IUIAnimationTransition2** transition) CreateSinusoidalTransitionFromRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, double accelerationRatio, double decelerationRatio, IUIAnimationTransition2** transition) CreateAccelerateDecelerateTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, IUIAnimationTransition2** transition) CreateReversalTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, double finalVelocity, IUIAnimationTransition2** transition) CreateCubicTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double* finalValue, double* finalVelocity, uint32 cDimension, IUIAnimationTransition2** transition) CreateCubicVectorTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double maximumDuration, double finalValue, IUIAnimationTransition2** transition) CreateSmoothStopTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double finalValue, double finalVelocity, double acceleration, IUIAnimationTransition2** transition) CreateParabolicTransitionFromAcceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double finalValue, double x1, double y1, double x2, double y2, IUIAnimationTransition2** ppTransition) CreateCubicBezierLinearTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration, double* finalValue, uint32 cDimension, double x1, double y1, double x2, double y2, IUIAnimationTransition2** ppTransition) CreateCubicBezierLinearVectorTransition;
	}


	public HRESULT CreateInstantaneousTransition(double finalValue, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateInstantaneousTransition(&this, finalValue, transition);

	public HRESULT CreateInstantaneousVectorTransition(double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateInstantaneousVectorTransition(&this, finalValue, cDimension, transition);

	public HRESULT CreateConstantTransition(double duration, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateConstantTransition(&this, duration, transition);

	public HRESULT CreateDiscreteTransition(double delay, double finalValue, double hold, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateDiscreteTransition(&this, delay, finalValue, hold, transition);

	public HRESULT CreateDiscreteVectorTransition(double delay, double* finalValue, uint32 cDimension, double hold, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateDiscreteVectorTransition(&this, delay, finalValue, cDimension, hold, transition);

	public HRESULT CreateLinearTransition(double duration, double finalValue, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateLinearTransition(&this, duration, finalValue, transition);

	public HRESULT CreateLinearVectorTransition(double duration, double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateLinearVectorTransition(&this, duration, finalValue, cDimension, transition);

	public HRESULT CreateLinearTransitionFromSpeed(double speed, double finalValue, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateLinearTransitionFromSpeed(&this, speed, finalValue, transition);

	public HRESULT CreateLinearVectorTransitionFromSpeed(double speed, double* finalValue, uint32 cDimension, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateLinearVectorTransitionFromSpeed(&this, speed, finalValue, cDimension, transition);

	public HRESULT CreateSinusoidalTransitionFromVelocity(double duration, double period, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateSinusoidalTransitionFromVelocity(&this, duration, period, transition);

	public HRESULT CreateSinusoidalTransitionFromRange(double duration, double minimumValue, double maximumValue, double period, UI_ANIMATION_SLOPE slope, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateSinusoidalTransitionFromRange(&this, duration, minimumValue, maximumValue, period, slope, transition);

	public HRESULT CreateAccelerateDecelerateTransition(double duration, double finalValue, double accelerationRatio, double decelerationRatio, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateAccelerateDecelerateTransition(&this, duration, finalValue, accelerationRatio, decelerationRatio, transition);

	public HRESULT CreateReversalTransition(double duration, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateReversalTransition(&this, duration, transition);

	public HRESULT CreateCubicTransition(double duration, double finalValue, double finalVelocity, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateCubicTransition(&this, duration, finalValue, finalVelocity, transition);

	public HRESULT CreateCubicVectorTransition(double duration, double* finalValue, double* finalVelocity, uint32 cDimension, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateCubicVectorTransition(&this, duration, finalValue, finalVelocity, cDimension, transition);

	public HRESULT CreateSmoothStopTransition(double maximumDuration, double finalValue, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateSmoothStopTransition(&this, maximumDuration, finalValue, transition);

	public HRESULT CreateParabolicTransitionFromAcceleration(double finalValue, double finalVelocity, double acceleration, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateParabolicTransitionFromAcceleration(&this, finalValue, finalVelocity, acceleration, transition);

	public HRESULT CreateCubicBezierLinearTransition(double duration, double finalValue, double x1, double y1, double x2, double y2, IUIAnimationTransition2** ppTransition) mut => VT.[Friend]CreateCubicBezierLinearTransition(&this, duration, finalValue, x1, y1, x2, y2, ppTransition);

	public HRESULT CreateCubicBezierLinearVectorTransition(double duration, double* finalValue, uint32 cDimension, double x1, double y1, double x2, double y2, IUIAnimationTransition2** ppTransition) mut => VT.[Friend]CreateCubicBezierLinearVectorTransition(&this, duration, finalValue, cDimension, x1, y1, x2, y2, ppTransition);
}

[CRepr]struct IUIAnimationPrimitiveInterpolation : IUnknown
{
	public new const Guid IID = .(0xbab20d63, 0x4361, 0x45da, 0xa2, 0x4f, 0xab, 0x85, 0x08, 0x84, 0x6b, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dimension, double beginOffset, float constantCoefficient, float linearCoefficient, float quadraticCoefficient, float cubicCoefficient) AddCubic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dimension, double beginOffset, float bias, float amplitude, float frequency, float phase) AddSinusoidal;
	}


	public HRESULT AddCubic(uint32 dimension, double beginOffset, float constantCoefficient, float linearCoefficient, float quadraticCoefficient, float cubicCoefficient) mut => VT.[Friend]AddCubic(&this, dimension, beginOffset, constantCoefficient, linearCoefficient, quadraticCoefficient, cubicCoefficient);

	public HRESULT AddSinusoidal(uint32 dimension, double beginOffset, float bias, float amplitude, float frequency, float phase) mut => VT.[Friend]AddSinusoidal(&this, dimension, beginOffset, bias, amplitude, frequency, phase);
}

[CRepr]struct IUIAnimationInterpolator2 : IUnknown
{
	public new const Guid IID = .(0xea76aff8, 0xea22, 0x4a23, 0xa0, 0xef, 0xa6, 0xa9, 0x66, 0x70, 0x35, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dimension) GetDimension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* initialValue, double* initialVelocity, uint32 cDimension) SetInitialValueAndVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double duration) SetDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* duration) GetDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* value, uint32 cDimension) GetFinalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double offset, double* value, uint32 cDimension) InterpolateValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double offset, double* velocity, uint32 cDimension) InterpolateVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationPrimitiveInterpolation* interpolation, uint32 cDimension) GetPrimitiveInterpolation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_DEPENDENCIES* initialValueDependencies, UI_ANIMATION_DEPENDENCIES* initialVelocityDependencies, UI_ANIMATION_DEPENDENCIES* durationDependencies) GetDependencies;
	}


	public HRESULT GetDimension(uint32* dimension) mut => VT.[Friend]GetDimension(&this, dimension);

	public HRESULT SetInitialValueAndVelocity(double* initialValue, double* initialVelocity, uint32 cDimension) mut => VT.[Friend]SetInitialValueAndVelocity(&this, initialValue, initialVelocity, cDimension);

	public HRESULT SetDuration(double duration) mut => VT.[Friend]SetDuration(&this, duration);

	public HRESULT GetDuration(double* duration) mut => VT.[Friend]GetDuration(&this, duration);

	public HRESULT GetFinalValue(double* value, uint32 cDimension) mut => VT.[Friend]GetFinalValue(&this, value, cDimension);

	public HRESULT InterpolateValue(double offset, double* value, uint32 cDimension) mut => VT.[Friend]InterpolateValue(&this, offset, value, cDimension);

	public HRESULT InterpolateVelocity(double offset, double* velocity, uint32 cDimension) mut => VT.[Friend]InterpolateVelocity(&this, offset, velocity, cDimension);

	public HRESULT GetPrimitiveInterpolation(IUIAnimationPrimitiveInterpolation* interpolation, uint32 cDimension) mut => VT.[Friend]GetPrimitiveInterpolation(&this, interpolation, cDimension);

	public HRESULT GetDependencies(UI_ANIMATION_DEPENDENCIES* initialValueDependencies, UI_ANIMATION_DEPENDENCIES* initialVelocityDependencies, UI_ANIMATION_DEPENDENCIES* durationDependencies) mut => VT.[Friend]GetDependencies(&this, initialValueDependencies, initialVelocityDependencies, durationDependencies);
}

[CRepr]struct IUIAnimationTransitionFactory2 : IUnknown
{
	public new const Guid IID = .(0x937d4916, 0xc1a6, 0x42d5, 0x88, 0xd8, 0x30, 0x34, 0x4d, 0x6e, 0xfe, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationInterpolator2* interpolator, IUIAnimationTransition2** transition) CreateTransition;
	}


	public HRESULT CreateTransition(IUIAnimationInterpolator2* interpolator, IUIAnimationTransition2** transition) mut => VT.[Friend]CreateTransition(&this, interpolator, transition);
}

[CRepr]struct IUIAnimationStoryboard2 : IUnknown
{
	public new const Guid IID = .(0xae289cd2, 0x12d4, 0x4945, 0x94, 0x19, 0x9e, 0x41, 0xbe, 0x03, 0x4d, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable, IUIAnimationTransition2* transition) AddTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_KEYFRAME existingKeyframe, double offset, UI_ANIMATION_KEYFRAME* keyframe) AddKeyframeAtOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME* keyframe) AddKeyframeAfterTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME startKeyframe) AddTransitionAtKeyframe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe) AddTransitionBetweenKeyframes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe, double cRepetition, UI_ANIMATION_REPEAT_MODE repeatMode, IUIAnimationLoopIterationChangeHandler2* pIterationChangeHandler, uint id, BOOL fRegisterForNextAnimationEvent) RepeatBetweenKeyframes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationVariable2* variable) HoldVariable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double delay) SetLongestAcceptableDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double secondsDuration) SetSkipDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double timeNow, UI_ANIMATION_SCHEDULING_RESULT* schedulingResult) Schedule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Conclude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double completionDeadline) Finish;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abandon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* object, uint32 id) SetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** object, uint32* id) GetTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_ANIMATION_STORYBOARD_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* elapsedTime) GetElapsedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIAnimationStoryboardEventHandler2* handler, BOOL fRegisterStatusChangeForNextAnimationEvent, BOOL fRegisterUpdateForNextAnimationEvent) SetStoryboardEventHandler;
	}


	public HRESULT AddTransition(IUIAnimationVariable2* variable, IUIAnimationTransition2* transition) mut => VT.[Friend]AddTransition(&this, variable, transition);

	public HRESULT AddKeyframeAtOffset(UI_ANIMATION_KEYFRAME existingKeyframe, double offset, UI_ANIMATION_KEYFRAME* keyframe) mut => VT.[Friend]AddKeyframeAtOffset(&this, existingKeyframe, offset, keyframe);

	public HRESULT AddKeyframeAfterTransition(IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME* keyframe) mut => VT.[Friend]AddKeyframeAfterTransition(&this, transition, keyframe);

	public HRESULT AddTransitionAtKeyframe(IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME startKeyframe) mut => VT.[Friend]AddTransitionAtKeyframe(&this, variable, transition, startKeyframe);

	public HRESULT AddTransitionBetweenKeyframes(IUIAnimationVariable2* variable, IUIAnimationTransition2* transition, UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe) mut => VT.[Friend]AddTransitionBetweenKeyframes(&this, variable, transition, startKeyframe, endKeyframe);

	public HRESULT RepeatBetweenKeyframes(UI_ANIMATION_KEYFRAME startKeyframe, UI_ANIMATION_KEYFRAME endKeyframe, double cRepetition, UI_ANIMATION_REPEAT_MODE repeatMode, IUIAnimationLoopIterationChangeHandler2* pIterationChangeHandler, uint id, BOOL fRegisterForNextAnimationEvent) mut => VT.[Friend]RepeatBetweenKeyframes(&this, startKeyframe, endKeyframe, cRepetition, repeatMode, pIterationChangeHandler, id, fRegisterForNextAnimationEvent);

	public HRESULT HoldVariable(IUIAnimationVariable2* variable) mut => VT.[Friend]HoldVariable(&this, variable);

	public HRESULT SetLongestAcceptableDelay(double delay) mut => VT.[Friend]SetLongestAcceptableDelay(&this, delay);

	public HRESULT SetSkipDuration(double secondsDuration) mut => VT.[Friend]SetSkipDuration(&this, secondsDuration);

	public HRESULT Schedule(double timeNow, UI_ANIMATION_SCHEDULING_RESULT* schedulingResult) mut => VT.[Friend]Schedule(&this, timeNow, schedulingResult);

	public HRESULT Conclude() mut => VT.[Friend]Conclude(&this);

	public HRESULT Finish(double completionDeadline) mut => VT.[Friend]Finish(&this, completionDeadline);

	public HRESULT Abandon() mut => VT.[Friend]Abandon(&this);

	public HRESULT SetTag(IUnknown* object, uint32 id) mut => VT.[Friend]SetTag(&this, object, id);

	public HRESULT GetTag(IUnknown** object, uint32* id) mut => VT.[Friend]GetTag(&this, object, id);

	public HRESULT GetStatus(UI_ANIMATION_STORYBOARD_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT GetElapsedTime(double* elapsedTime) mut => VT.[Friend]GetElapsedTime(&this, elapsedTime);

	public HRESULT SetStoryboardEventHandler(IUIAnimationStoryboardEventHandler2* handler, BOOL fRegisterStatusChangeForNextAnimationEvent, BOOL fRegisterUpdateForNextAnimationEvent) mut => VT.[Friend]SetStoryboardEventHandler(&this, handler, fRegisterStatusChangeForNextAnimationEvent, fRegisterUpdateForNextAnimationEvent);
}

#endregion
