using Sedulous.Core;

namespace Sedulous.Shell;

/// A rectangular slice of a window that presents the SAME device interfaces as the shell,
/// transformed into its own content space and gated by hover and focus.
///
/// Drop-in by design: anything written against IMouse works unchanged when handed a
/// surface's mouse. That is what lets a camera controller run in a full window game and in
/// an editor viewport without knowing which it is in.
///
/// The gate is not decided here. An InputRouter owns hover, focus and capture across every
/// surface and pushes each one's answer once a frame, because deciding it per surface is
/// how two viewports end up both thinking they are hovered.
class InputSurface
{
	/// Matches the number of gamepads a shell reports.
	public const int32 MaxGamepads = 8;

	private IInputManager mRaw;
	private uint32 mWindow;
	private ContentFit mFit;
	private Float2 mWindowSize;

	private bool mHovered;
	private bool mFocused;
	private bool mCaptured;
	private Float2 mContentMouse;
	private Float2 mContentDelta;

	private SurfaceMouse mMouse ~ delete _;
	private SurfaceKeyboard mKeyboard ~ delete _;
	private SurfaceTouch mTouch ~ delete _;
	private SurfaceGamepad[MaxGamepads] mGamepads;

	public this(IInputManager raw, uint32 window, ContentFit fit)
	{
		mRaw = raw;
		mWindow = window;
		mFit = fit;

		mMouse = new SurfaceMouse(this);
		mKeyboard = new SurfaceKeyboard(this);
		mTouch = new SurfaceTouch(this);

		for (int32 i < MaxGamepads)
		{
			mGamepads[i] = new SurfaceGamepad();
			mGamepads[i].Bind(this, i);
		}
	}

	public ~this()
	{
		for (int32 i < MaxGamepads)
			delete mGamepads[i];
	}

	// ---- configuration ----

	public ContentFit Fit
	{
		get => mFit;
		set => mFit = value;
	}

	public void SetFit(ContentFit fit) => mFit = fit;
	public void SetRegion(Rectangle region) => mFit.Region = region;
	public void SetContentSize(Float2 size) => mFit.ContentSize = size;
	public void SetFitMode(FitMode mode) => mFit.Mode = mode;
	public void SetWindowSize(Float2 size) => mWindowSize = size;
	public Float2 WindowSize => mWindowSize;

	/// Re-targets the surface at a different window, for a panel undocked into a floating
	/// one. The router hover tests by window id, so this is what follows it across.
	public void SetWindow(uint32 window) => mWindow = window;
	public uint32 Window => mWindow;

	// ---- gate state, read by anyone, written by the router ----

	public bool Hovered => mHovered;
	public bool Focused => mFocused;
	public bool Captured => mCaptured;

	/// Hovered OR captured. The mouse stays live through a drag that leaves the rect,
	/// because the press pinned it here.
	public bool MouseActive => mHovered || mCaptured;

	public Float2 ContentMouse => mContentMouse;
	public Float2 ContentDelta => mContentDelta;

	// ---- the transformed, gated devices ----

	public IMouse Mouse => mMouse;
	public IKeyboard Keyboard => mKeyboard;
	public ITouch Touch => mTouch;

	public IGamepad Gamepad(int32 index)
		=> ((index >= 0) && (index < MaxGamepads)) ? mGamepads[index] : null;

	public IInputManager Raw => mRaw;

	/// Called by the router once a frame with this surface's resolved gate.
	public void ApplyGate(bool hovered, bool focused, bool captured, Float2 contentMouse,
		Float2 contentDelta)
	{
		mHovered = hovered;
		mFocused = focused;
		mCaptured = captured;
		mContentMouse = contentMouse;
		mContentDelta = contentDelta;
	}
}
