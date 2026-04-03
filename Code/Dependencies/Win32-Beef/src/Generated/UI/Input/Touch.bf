using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.UI.Input.Touch;

#region TypeDefs
typealias HGESTUREINFO = int;

typealias HTOUCHINPUT = int;

#endregion


#region Enums

[AllowDuplicates]
public enum GESTURECONFIG_ID : uint32
{
	GID_BEGIN = 1,
	GID_END = 2,
	GID_ZOOM = 3,
	GID_PAN = 4,
	GID_ROTATE = 5,
	GID_TWOFINGERTAP = 6,
	GID_PRESSANDTAP = 7,
	GID_ROLLOVER = 7,
}


[AllowDuplicates]
public enum TOUCHEVENTF_FLAGS : uint32
{
	TOUCHEVENTF_MOVE = 1,
	TOUCHEVENTF_DOWN = 2,
	TOUCHEVENTF_UP = 4,
	TOUCHEVENTF_INRANGE = 8,
	TOUCHEVENTF_PRIMARY = 16,
	TOUCHEVENTF_NOCOALESCE = 32,
	TOUCHEVENTF_PEN = 64,
	TOUCHEVENTF_PALM = 128,
}


[AllowDuplicates]
public enum TOUCHINPUTMASKF_MASK : uint32
{
	TOUCHINPUTMASKF_TIMEFROMSYSTEM = 1,
	TOUCHINPUTMASKF_EXTRAINFO = 2,
	TOUCHINPUTMASKF_CONTACTAREA = 4,
}


[AllowDuplicates]
public enum REGISTER_TOUCH_WINDOW_FLAGS : uint32
{
	TWF_FINETOUCH = 1,
	TWF_WANTPALM = 2,
}


[AllowDuplicates]
public enum MANIPULATION_PROCESSOR_MANIPULATIONS : int32
{
	MANIPULATION_NONE = 0,
	MANIPULATION_TRANSLATE_X = 1,
	MANIPULATION_TRANSLATE_Y = 2,
	MANIPULATION_SCALE = 4,
	MANIPULATION_ROTATE = 8,
	MANIPULATION_ALL = 15,
}

#endregion


#region Structs
[CRepr]
public struct TOUCHINPUT
{
	public int32 x;
	public int32 y;
	public HANDLE hSource;
	public uint32 dwID;
	public TOUCHEVENTF_FLAGS dwFlags;
	public TOUCHINPUTMASKF_MASK dwMask;
	public uint32 dwTime;
	public uint dwExtraInfo;
	public uint32 cxContact;
	public uint32 cyContact;
}

[CRepr]
public struct GESTUREINFO
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public uint32 dwID;
	public HWND hwndTarget;
	public POINTS ptsLocation;
	public uint32 dwInstanceID;
	public uint32 dwSequenceID;
	public uint64 ullArguments;
	public uint32 cbExtraArgs;
}

[CRepr]
public struct GESTURENOTIFYSTRUCT
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public HWND hwndTarget;
	public POINTS ptsLocation;
	public uint32 dwInstanceID;
}

[CRepr]
public struct GESTURECONFIG
{
	public GESTURECONFIG_ID dwID;
	public uint32 dwWant;
	public uint32 dwBlock;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_InertiaProcessor = .(0xabb27087, 0x4ce0, 0x4e58, 0xa0, 0xcb, 0xe2, 0x4d, 0xf9, 0x68, 0x14, 0xbe);


	public const Guid CLSID_ManipulationProcessor = .(0x597d4fb0, 0x47fd, 0x4aff, 0x89, 0xb9, 0xc6, 0xcf, 0xae, 0x8c, 0xf0, 0x8e);


}
#endregion

#region COM Types
[CRepr]struct _IManipulationEvents : IUnknown
{
	public new const Guid IID = .(0x4f62c8da, 0x9c53, 0x4b22, 0x93, 0xdf, 0x92, 0x7a, 0x86, 0x2b, 0xbb, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y) ManipulationStarted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float translationDeltaX, float translationDeltaY, float scaleDelta, float expansionDelta, float rotationDelta, float cumulativeTranslationX, float cumulativeTranslationY, float cumulativeScale, float cumulativeExpansion, float cumulativeRotation) ManipulationDelta;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x, float y, float cumulativeTranslationX, float cumulativeTranslationY, float cumulativeScale, float cumulativeExpansion, float cumulativeRotation) ManipulationCompleted;
	}


	public HRESULT ManipulationStarted(float x, float y) mut => VT.[Friend]ManipulationStarted(&this, x, y);

	public HRESULT ManipulationDelta(float x, float y, float translationDeltaX, float translationDeltaY, float scaleDelta, float expansionDelta, float rotationDelta, float cumulativeTranslationX, float cumulativeTranslationY, float cumulativeScale, float cumulativeExpansion, float cumulativeRotation) mut => VT.[Friend]ManipulationDelta(&this, x, y, translationDeltaX, translationDeltaY, scaleDelta, expansionDelta, rotationDelta, cumulativeTranslationX, cumulativeTranslationY, cumulativeScale, cumulativeExpansion, cumulativeRotation);

	public HRESULT ManipulationCompleted(float x, float y, float cumulativeTranslationX, float cumulativeTranslationY, float cumulativeScale, float cumulativeExpansion, float cumulativeRotation) mut => VT.[Friend]ManipulationCompleted(&this, x, y, cumulativeTranslationX, cumulativeTranslationY, cumulativeScale, cumulativeExpansion, cumulativeRotation);
}

[CRepr]struct IInertiaProcessor : IUnknown
{
	public new const Guid IID = .(0x18b00c6d, 0xc5ee, 0x41b1, 0x90, 0xa9, 0x9d, 0x4a, 0x92, 0x90, 0x95, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* x) get_InitialOriginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x) put_InitialOriginX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* y) get_InitialOriginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float y) put_InitialOriginY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* x) get_InitialVelocityX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float x) put_InitialVelocityX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* y) get_InitialVelocityY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float y) put_InitialVelocityY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* velocity) get_InitialAngularVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float velocity) put_InitialAngularVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* velocity) get_InitialExpansionVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float velocity) put_InitialExpansionVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* radius) get_InitialRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float radius) put_InitialRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* left) get_BoundaryLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float left) put_BoundaryLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* top) get_BoundaryTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float top) put_BoundaryTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* right) get_BoundaryRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float right) put_BoundaryRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* bottom) get_BoundaryBottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float bottom) put_BoundaryBottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* left) get_ElasticMarginLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float left) put_ElasticMarginLeft;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* top) get_ElasticMarginTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float top) put_ElasticMarginTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* right) get_ElasticMarginRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float right) put_ElasticMarginRight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* bottom) get_ElasticMarginBottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float bottom) put_ElasticMarginBottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* displacement) get_DesiredDisplacement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float displacement) put_DesiredDisplacement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* rotation) get_DesiredRotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float rotation) put_DesiredRotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* expansion) get_DesiredExpansion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float expansion) put_DesiredExpansion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* deceleration) get_DesiredDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float deceleration) put_DesiredDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* deceleration) get_DesiredAngularDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float deceleration) put_DesiredAngularDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* deceleration) get_DesiredExpansionDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float deceleration) put_DesiredExpansionDeceleration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* timestamp) get_InitialTimestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timestamp) put_InitialTimestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* completed) Process;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timestamp, BOOL* completed) ProcessTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Complete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 timestamp) CompleteTime;
	}


	public HRESULT get_InitialOriginX(float* x) mut => VT.[Friend]get_InitialOriginX(&this, x);

	public HRESULT put_InitialOriginX(float x) mut => VT.[Friend]put_InitialOriginX(&this, x);

	public HRESULT get_InitialOriginY(float* y) mut => VT.[Friend]get_InitialOriginY(&this, y);

	public HRESULT put_InitialOriginY(float y) mut => VT.[Friend]put_InitialOriginY(&this, y);

	public HRESULT get_InitialVelocityX(float* x) mut => VT.[Friend]get_InitialVelocityX(&this, x);

	public HRESULT put_InitialVelocityX(float x) mut => VT.[Friend]put_InitialVelocityX(&this, x);

	public HRESULT get_InitialVelocityY(float* y) mut => VT.[Friend]get_InitialVelocityY(&this, y);

	public HRESULT put_InitialVelocityY(float y) mut => VT.[Friend]put_InitialVelocityY(&this, y);

	public HRESULT get_InitialAngularVelocity(float* velocity) mut => VT.[Friend]get_InitialAngularVelocity(&this, velocity);

	public HRESULT put_InitialAngularVelocity(float velocity) mut => VT.[Friend]put_InitialAngularVelocity(&this, velocity);

	public HRESULT get_InitialExpansionVelocity(float* velocity) mut => VT.[Friend]get_InitialExpansionVelocity(&this, velocity);

	public HRESULT put_InitialExpansionVelocity(float velocity) mut => VT.[Friend]put_InitialExpansionVelocity(&this, velocity);

	public HRESULT get_InitialRadius(float* radius) mut => VT.[Friend]get_InitialRadius(&this, radius);

	public HRESULT put_InitialRadius(float radius) mut => VT.[Friend]put_InitialRadius(&this, radius);

	public HRESULT get_BoundaryLeft(float* left) mut => VT.[Friend]get_BoundaryLeft(&this, left);

	public HRESULT put_BoundaryLeft(float left) mut => VT.[Friend]put_BoundaryLeft(&this, left);

	public HRESULT get_BoundaryTop(float* top) mut => VT.[Friend]get_BoundaryTop(&this, top);

	public HRESULT put_BoundaryTop(float top) mut => VT.[Friend]put_BoundaryTop(&this, top);

	public HRESULT get_BoundaryRight(float* right) mut => VT.[Friend]get_BoundaryRight(&this, right);

	public HRESULT put_BoundaryRight(float right) mut => VT.[Friend]put_BoundaryRight(&this, right);

	public HRESULT get_BoundaryBottom(float* bottom) mut => VT.[Friend]get_BoundaryBottom(&this, bottom);

	public HRESULT put_BoundaryBottom(float bottom) mut => VT.[Friend]put_BoundaryBottom(&this, bottom);

	public HRESULT get_ElasticMarginLeft(float* left) mut => VT.[Friend]get_ElasticMarginLeft(&this, left);

	public HRESULT put_ElasticMarginLeft(float left) mut => VT.[Friend]put_ElasticMarginLeft(&this, left);

	public HRESULT get_ElasticMarginTop(float* top) mut => VT.[Friend]get_ElasticMarginTop(&this, top);

	public HRESULT put_ElasticMarginTop(float top) mut => VT.[Friend]put_ElasticMarginTop(&this, top);

	public HRESULT get_ElasticMarginRight(float* right) mut => VT.[Friend]get_ElasticMarginRight(&this, right);

	public HRESULT put_ElasticMarginRight(float right) mut => VT.[Friend]put_ElasticMarginRight(&this, right);

	public HRESULT get_ElasticMarginBottom(float* bottom) mut => VT.[Friend]get_ElasticMarginBottom(&this, bottom);

	public HRESULT put_ElasticMarginBottom(float bottom) mut => VT.[Friend]put_ElasticMarginBottom(&this, bottom);

	public HRESULT get_DesiredDisplacement(float* displacement) mut => VT.[Friend]get_DesiredDisplacement(&this, displacement);

	public HRESULT put_DesiredDisplacement(float displacement) mut => VT.[Friend]put_DesiredDisplacement(&this, displacement);

	public HRESULT get_DesiredRotation(float* rotation) mut => VT.[Friend]get_DesiredRotation(&this, rotation);

	public HRESULT put_DesiredRotation(float rotation) mut => VT.[Friend]put_DesiredRotation(&this, rotation);

	public HRESULT get_DesiredExpansion(float* expansion) mut => VT.[Friend]get_DesiredExpansion(&this, expansion);

	public HRESULT put_DesiredExpansion(float expansion) mut => VT.[Friend]put_DesiredExpansion(&this, expansion);

	public HRESULT get_DesiredDeceleration(float* deceleration) mut => VT.[Friend]get_DesiredDeceleration(&this, deceleration);

	public HRESULT put_DesiredDeceleration(float deceleration) mut => VT.[Friend]put_DesiredDeceleration(&this, deceleration);

	public HRESULT get_DesiredAngularDeceleration(float* deceleration) mut => VT.[Friend]get_DesiredAngularDeceleration(&this, deceleration);

	public HRESULT put_DesiredAngularDeceleration(float deceleration) mut => VT.[Friend]put_DesiredAngularDeceleration(&this, deceleration);

	public HRESULT get_DesiredExpansionDeceleration(float* deceleration) mut => VT.[Friend]get_DesiredExpansionDeceleration(&this, deceleration);

	public HRESULT put_DesiredExpansionDeceleration(float deceleration) mut => VT.[Friend]put_DesiredExpansionDeceleration(&this, deceleration);

	public HRESULT get_InitialTimestamp(uint32* timestamp) mut => VT.[Friend]get_InitialTimestamp(&this, timestamp);

	public HRESULT put_InitialTimestamp(uint32 timestamp) mut => VT.[Friend]put_InitialTimestamp(&this, timestamp);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Process(BOOL* completed) mut => VT.[Friend]Process(&this, completed);

	public HRESULT ProcessTime(uint32 timestamp, BOOL* completed) mut => VT.[Friend]ProcessTime(&this, timestamp, completed);

	public HRESULT Complete() mut => VT.[Friend]Complete(&this);

	public HRESULT CompleteTime(uint32 timestamp) mut => VT.[Friend]CompleteTime(&this, timestamp);
}

[CRepr]struct IManipulationProcessor : IUnknown
{
	public new const Guid IID = .(0xa22ac519, 0x8300, 0x48a0, 0xbe, 0xf4, 0xf1, 0xbe, 0x87, 0x37, 0xdb, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MANIPULATION_PROCESSOR_MANIPULATIONS* manipulations) get_SupportedManipulations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MANIPULATION_PROCESSOR_MANIPULATIONS manipulations) put_SupportedManipulations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pivotPointX) get_PivotPointX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float pivotPointX) put_PivotPointX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pivotPointY) get_PivotPointY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float pivotPointY) put_PivotPointY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pivotRadius) get_PivotRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float pivotRadius) put_PivotRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CompleteManipulation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y) ProcessDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y) ProcessMove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y) ProcessUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y, uint32 timestamp) ProcessDownWithTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y, uint32 timestamp) ProcessMoveWithTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 manipulatorId, float x, float y, uint32 timestamp) ProcessUpWithTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* velocityX) GetVelocityX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* velocityY) GetVelocityY;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* expansionVelocity) GetExpansionVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* angularVelocity) GetAngularVelocity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* minRadius) get_MinimumScaleRotateRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float minRadius) put_MinimumScaleRotateRadius;
	}


	public HRESULT get_SupportedManipulations(MANIPULATION_PROCESSOR_MANIPULATIONS* manipulations) mut => VT.[Friend]get_SupportedManipulations(&this, manipulations);

	public HRESULT put_SupportedManipulations(MANIPULATION_PROCESSOR_MANIPULATIONS manipulations) mut => VT.[Friend]put_SupportedManipulations(&this, manipulations);

	public HRESULT get_PivotPointX(float* pivotPointX) mut => VT.[Friend]get_PivotPointX(&this, pivotPointX);

	public HRESULT put_PivotPointX(float pivotPointX) mut => VT.[Friend]put_PivotPointX(&this, pivotPointX);

	public HRESULT get_PivotPointY(float* pivotPointY) mut => VT.[Friend]get_PivotPointY(&this, pivotPointY);

	public HRESULT put_PivotPointY(float pivotPointY) mut => VT.[Friend]put_PivotPointY(&this, pivotPointY);

	public HRESULT get_PivotRadius(float* pivotRadius) mut => VT.[Friend]get_PivotRadius(&this, pivotRadius);

	public HRESULT put_PivotRadius(float pivotRadius) mut => VT.[Friend]put_PivotRadius(&this, pivotRadius);

	public HRESULT CompleteManipulation() mut => VT.[Friend]CompleteManipulation(&this);

	public HRESULT ProcessDown(uint32 manipulatorId, float x, float y) mut => VT.[Friend]ProcessDown(&this, manipulatorId, x, y);

	public HRESULT ProcessMove(uint32 manipulatorId, float x, float y) mut => VT.[Friend]ProcessMove(&this, manipulatorId, x, y);

	public HRESULT ProcessUp(uint32 manipulatorId, float x, float y) mut => VT.[Friend]ProcessUp(&this, manipulatorId, x, y);

	public HRESULT ProcessDownWithTime(uint32 manipulatorId, float x, float y, uint32 timestamp) mut => VT.[Friend]ProcessDownWithTime(&this, manipulatorId, x, y, timestamp);

	public HRESULT ProcessMoveWithTime(uint32 manipulatorId, float x, float y, uint32 timestamp) mut => VT.[Friend]ProcessMoveWithTime(&this, manipulatorId, x, y, timestamp);

	public HRESULT ProcessUpWithTime(uint32 manipulatorId, float x, float y, uint32 timestamp) mut => VT.[Friend]ProcessUpWithTime(&this, manipulatorId, x, y, timestamp);

	public HRESULT GetVelocityX(float* velocityX) mut => VT.[Friend]GetVelocityX(&this, velocityX);

	public HRESULT GetVelocityY(float* velocityY) mut => VT.[Friend]GetVelocityY(&this, velocityY);

	public HRESULT GetExpansionVelocity(float* expansionVelocity) mut => VT.[Friend]GetExpansionVelocity(&this, expansionVelocity);

	public HRESULT GetAngularVelocity(float* angularVelocity) mut => VT.[Friend]GetAngularVelocity(&this, angularVelocity);

	public HRESULT get_MinimumScaleRotateRadius(float* minRadius) mut => VT.[Friend]get_MinimumScaleRotateRadius(&this, minRadius);

	public HRESULT put_MinimumScaleRotateRadius(float minRadius) mut => VT.[Friend]put_MinimumScaleRotateRadius(&this, minRadius);
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTouchInputInfo(HTOUCHINPUT hTouchInput, uint32 cInputs, TOUCHINPUT* pInputs, int32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseTouchInputHandle(HTOUCHINPUT hTouchInput);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterTouchWindow(HWND hwnd, REGISTER_TOUCH_WINDOW_FLAGS ulFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterTouchWindow(HWND hwnd);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsTouchWindow(HWND hwnd, uint32* pulFlags);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetGestureInfo(HGESTUREINFO hGestureInfo, GESTUREINFO* pGestureInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetGestureExtraArgs(HGESTUREINFO hGestureInfo, uint32 cbExtraArgs, uint8* pExtraArgs);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseGestureInfoHandle(HGESTUREINFO hGestureInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetGestureConfig(HWND hwnd, uint32 dwReserved, uint32 cIDs, GESTURECONFIG* pGestureConfig, uint32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetGestureConfig(HWND hwnd, uint32 dwReserved, uint32 dwFlags, uint32* pcIDs, GESTURECONFIG* pGestureConfig, uint32 cbSize);

}
#endregion
