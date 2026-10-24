using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Shell.Tests;

/// A keyboard whose modifiers a test sets; no key is ever down.
class MockKeyboard : Sedulous.Shell.IKeyboard
{
	public Sedulous.Shell.KeyModifiers Mods = .None;

	public bool IsKeyDown(Sedulous.Shell.KeyCode key) => false;
	public bool IsKeyPressed(Sedulous.Shell.KeyCode key) => false;
	public bool IsKeyReleased(Sedulous.Shell.KeyCode key) => false;
	public Sedulous.Shell.KeyModifiers Modifiers => Mods;
}

/// A mouse at (0, 0) whose left press a test sets, recording the cursor and visibility it is told.
class MockMouse : Sedulous.Shell.IMouse
{
	public bool LeftPressed = false;
	public Sedulous.Shell.CursorType Cursor = .Default;
	public int CursorSets = 0;
	public bool Visible = true;
	public int VisibilitySets = 0;

	public float X => 0.0f;
	public float Y => 0.0f;
	public float GlobalX => 0.0f;
	public float GlobalY => 0.0f;
	public float DeltaX => 0.0f;
	public float DeltaY => 0.0f;
	public float ScrollX => 0.0f;
	public float ScrollY => 0.0f;

	public bool IsButtonDown(Sedulous.Shell.MouseButton button) => false;
	public bool IsButtonPressed(Sedulous.Shell.MouseButton button) => (button == .Left) && LeftPressed;
	public bool IsButtonReleased(Sedulous.Shell.MouseButton button) => false;

	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) { }
	public bool CursorVisible => Visible;

	public void SetCursorVisible(bool visible)
	{
		Visible = visible;
		VisibilitySets++;
	}

	public void SetCursor(Sedulous.Shell.CursorType cursor)
	{
		Cursor = cursor;
		CursorSets++;
	}

	public void SetGlobalCapture(bool enabled) { }
}

/// Fingers a test puts down and lifts.
class MockTouch : Sedulous.Shell.ITouch
{
	public List<Sedulous.Shell.TouchPoint> Points = new .() ~ delete _;

	public int32 TouchCount => (int32)Points.Count;

	public bool GetTouchPoint(int32 index, out Sedulous.Shell.TouchPoint point)
	{
		point = default;
		if ((index < 0) || (index >= TouchCount))
			return false;
		point = Points[index];
		return true;
	}

	public bool HasTouch => !Points.IsEmpty;
}

/// The devices a surface reads: the mock keyboard and mouse, and the mock touch when `withTouch`.
class MockInputManager : Sedulous.Shell.IInputManager
{
	public MockKeyboard KeyboardMock = new .() ~ delete _;
	public MockMouse MouseMock = new .() ~ delete _;
	public MockTouch TouchMock = new .() ~ delete _;
	private bool mWithTouch;

	public this(bool withTouch = false)
	{
		mWithTouch = withTouch;
	}

	public Sedulous.Shell.IKeyboard Keyboard => KeyboardMock;
	public Sedulous.Shell.IMouse Mouse => MouseMock;
	public Sedulous.Shell.ITouch Touch => mWithTouch ? TouchMock : null;
	public int32 GamepadCount => 0;
	public Sedulous.Shell.IGamepad GetGamepad(int32 index) => null;
	public Span<Sedulous.Shell.InputEvent> Events => .();
	public uint32 HoverWindow => 0;
	public uint32 FocusedWindow => 0;
	public void Update() { }
}

/// What the bridge tests share.
static class BridgeFixtures
{
	/// A root of a GUI of its own, `width` by `height`, held by the caller (it releases it).
	public static SceneRoot NewScene(float width, float height)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(width, height);
		return root;
	}

	/// A plain node at `pos`, `size`, held by the caller.
	public static Node NewPanel(Float2 pos, Float2 size)
	{
		let node = new Node();
		node.Size = size;
		node.Position = pos;
		return node;
	}

	public static Sedulous.Shell.InputEvent MouseMove(float x, float y)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = .MouseMove;
		e.X = x;
		e.Y = y;
		return e;
	}

	public static Sedulous.Shell.InputEvent ButtonEvent(Sedulous.Shell.InputEventKind kind, float x, float y,
		Sedulous.Shell.MouseButton button, Sedulous.Shell.KeyModifiers mods = .None)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = kind;
		e.X = x;
		e.Y = y;
		e.Button = button;
		e.Modifiers = mods;
		return e;
	}

	public static Sedulous.Shell.InputEvent Key(Sedulous.Shell.InputEventKind kind, Sedulous.Shell.KeyCode key,
		Sedulous.Shell.KeyModifiers mods = .None)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = kind;
		e.Key = key;
		e.Modifiers = mods;
		return e;
	}

	/// A TextInput (or `kind`) event carrying `text`.
	public static Sedulous.Shell.InputEvent TextEvent(String text, Sedulous.Shell.InputEventKind kind = .TextInput)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = kind;
		Sedulous.Shell.InputEvent.CopyEventText(ref e.Text, text.CStr());
		return e;
	}

	public static Sedulous.Shell.InputEvent Pad(Sedulous.Shell.InputEventKind kind, Sedulous.Shell.GamepadButton button)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = kind;
		e.PadButton = button;
		return e;
	}

	public static Sedulous.Shell.InputEvent Stick(Sedulous.Shell.GamepadAxis axis, float value)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = .GamepadAxis;
		e.PadAxis = axis;
		e.Value = value;
		return e;
	}

	/// A finger's event at (`nx`, `ny`), normalized over the window.
	public static Sedulous.Shell.InputEvent Finger(Sedulous.Shell.InputEventKind kind, uint64 id, float nx, float ny)
	{
		Sedulous.Shell.InputEvent e = default;
		e.Kind = kind;
		e.TouchId = id;
		e.X = nx;
		e.Y = ny;
		return e;
	}

	/// A dropped file the caller owns.
	public static Sedulous.Shell.DroppedFile Drop(uint32 window, float x, float y, StringView path)
	{
		let file = new Sedulous.Shell.DroppedFile();
		file.Window = window;
		file.X = x;
		file.Y = y;
		file.Path.Set(path);
		return file;
	}

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));
}
