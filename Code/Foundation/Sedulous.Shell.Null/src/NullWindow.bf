using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Null;

/// A window with no operating system behind it.
///
/// Every property is recorded rather than applied, which is exactly what makes multi
/// window logic testable: create, move, resize and close all behave, and nothing needs a
/// display.
class NullWindow : IWindow
{
	private uint32 mId;
	private uint32 mWidth;
	private uint32 mHeight;
	private int32 mX;
	private int32 mY;
	private bool mOpen = true;
	private bool mMinimized;
	private bool mTextInput;
	private TextInputKind mTextInputKind = .Text;
	private (int32 x, int32 y, int32 width, int32 height, int32 caretX) mTextInputArea;
	private uint32 mRaised;
	private String mTitle = new .() ~ delete _;

	public this(uint32 id, WindowSettings settings)
	{
		mId = id;
		mWidth = settings.Width;
		mHeight = settings.Height;
		mX = settings.Positioned ? settings.X : 0;
		mY = settings.Positioned ? settings.Y : 0;
		mTitle.Set(settings.Title);
	}

	public uint32 Id => mId;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public int32 X => mX;
	public int32 Y => mY;

	public void SetPosition(int32 x, int32 y) { mX = x; mY = y; }
	public void SetSize(uint32 width, uint32 height) { mWidth = width; mHeight = height; }

	public float ContentScale => 1.0f;
	/// No handles, since there is nothing for a graphics backend to draw into.
	public NativeWindow Native => .();

	public bool IsOpen => mOpen;
	public bool IsMinimized => mMinimized;
	public void Close() => mOpen = false;
	/// Headless: just counted.
	public void Raise() => mRaised++;
	/// Headless: just recorded.
	public void SetTitle(StringView title) => mTitle.Set(title);

	public void StartTextInput(TextInputKind kind = .Text)
	{
		mTextInput = true;
		mTextInputKind = kind;
	}
	public void StopTextInput() => mTextInput = false;
	public bool IsTextInputActive => mTextInput;
	public TextInputKind ActiveTextInputKind => mTextInputKind;
	/// Headless: just recorded.
	public void SetTextInputArea(int32 x, int32 y, int32 width, int32 height, int32 caretX) =>
		mTextInputArea = (x, y, width, height, caretX);

	// ---- what a test drives, since there is no OS to drive it ----

	/// What SetTextInputArea was last told.
	public (int32 x, int32 y, int32 width, int32 height, int32 caretX) LastTextInputArea => mTextInputArea;

	public void Resize(uint32 width, uint32 height) { mWidth = width; mHeight = height; }
	public void SetMinimized(bool minimized) => mMinimized = minimized;
	/// What SetTitle was last told (the settings' title until then).
	public StringView Title => mTitle;
	/// How many times Raise was called.
	public uint32 RaiseCount => mRaised;
}
