namespace Sedulous.UI.Runtime;

using Sedulous.Shell.Input;
using Sedulous.UI;

/// Bridges Sedulous.Shell input (polling-based) to UI InputManager events.
/// Called each frame by UISubsystem before UI update.
public class UIInputHelper
{
	private IInputManager mShellInput;
	private UIContext mContext;
	private float mTotalTime;

	// Previous frame button states for edge detection.
	private bool mPrevLeftDown;
	private bool mPrevRightDown;
	private bool mPrevMiddleDown;

	// Previous frame key states for edge detection.
	private bool[256] mPrevKeyDown;

	public this(IInputManager shellInput, UIContext context)
	{
		mShellInput = shellInput;
		mContext = context;
	}

	/// Poll shell input and generate UI events. Call once per frame.
	public void Update(float deltaTime)
	{
		mTotalTime += deltaTime;

		let mouse = mShellInput.Mouse;
		let kb = mShellInput.Keyboard;
		if (mouse == null) return;

		let mx = mouse.X;
		let my = mouse.Y;

		// Mouse move — always process so hover tracks.
		mContext.InputManager.ProcessMouseMove(mx, my);

		// Mouse button edges.
		ProcessMouseButton(mouse, .Left, ref mPrevLeftDown, mx, my);
		ProcessMouseButton(mouse, .Right, ref mPrevRightDown, mx, my);
		ProcessMouseButton(mouse, .Middle, ref mPrevMiddleDown, mx, my);

		// Mouse wheel.
		if (mouse.ScrollX != 0 || mouse.ScrollY != 0)
			mContext.InputManager.ProcessMouseWheel(mx, my, mouse.ScrollX, mouse.ScrollY);

		// Keyboard events.
		if (kb != null)
			ProcessKeyboard(kb);
	}

	private void ProcessKeyboard(IKeyboard kb)
	{
		let modifiers = MapModifiers(kb.Modifiers);

		// Scan common keys for edge detection. We check a subset of keys
		// rather than all 256 to keep the per-frame cost low.
		Sedulous.UI.KeyCode[?] keysToScan = .(
			.Tab, .Return, .Escape, .Space, .Backspace, .Delete,
			.Left, .Right, .Up, .Down,
			.Home, .End, .PageUp, .PageDown,
			.A, .C, .V, .X, .Z, .Y,
			.F1, .F2, .F3, .F4, .F5, .F6, .F7, .F8, .F9, .F10, .F11, .F12
		);

		for (let uiKey in keysToScan)
		{
			let shellKey = (Sedulous.Shell.Input.KeyCode)(int)uiKey;
			let idx = (int)uiKey;
			if (idx >= 256) continue;

			let down = kb.IsKeyDown(shellKey);
			let wasDown = mPrevKeyDown[idx];

			if (down && !wasDown)
			{
				// Key pressed this frame.
				if (uiKey == .Tab && !modifiers.HasFlag(.Ctrl))
				{
					// Plain Tab / Shift+Tab → focus navigation (not routed as key event).
					if (modifiers.HasFlag(.Shift))
						mContext.FocusManager.FocusPrev();
					else
						mContext.FocusManager.FocusNext();
				}
				else
				{
					mContext.InputManager.ProcessKeyDown(uiKey, modifiers, false);
				}
			}
			else if (down && wasDown)
			{
				// Key repeat.
				mContext.InputManager.ProcessKeyDown(uiKey, modifiers, true);
			}
			else if (!down && wasDown)
			{
				// Key released.
				mContext.InputManager.ProcessKeyUp(uiKey, modifiers);
			}

			mPrevKeyDown[idx] = down;
		}
	}

	private void ProcessMouseButton(IMouse mouse, Sedulous.Shell.Input.MouseButton shellBtn,
		ref bool prevDown, float mx, float my)
	{
		let down = mouse.IsButtonDown(shellBtn);
		let uiBtn = MapMouseButton(shellBtn);

		if (down && !prevDown)
			mContext.InputManager.ProcessMouseDown(uiBtn, mx, my, mTotalTime);
		else if (!down && prevDown)
			mContext.InputManager.ProcessMouseUp(uiBtn, mx, my);

		prevDown = down;
	}

	private static Sedulous.UI.MouseButton MapMouseButton(Sedulous.Shell.Input.MouseButton shellBtn)
	{
		switch (shellBtn)
		{
		case .Left:   return .Left;
		case .Right:  return .Right;
		case .Middle: return .Middle;
		case .X1:     return .X1;
		case .X2:     return .X2;
		}
	}

	private static Sedulous.UI.KeyModifiers MapModifiers(Sedulous.Shell.Input.KeyModifiers shellMods)
	{
		Sedulous.UI.KeyModifiers result = .None;
		if (shellMods.HasFlag(.Shift)) result |= .Shift;
		if (shellMods.HasFlag(.Ctrl))  result |= .Ctrl;
		if (shellMods.HasFlag(.Alt))   result |= .Alt;
		if (shellMods.HasFlag(.Gui))   result |= .Gui;
		return result;
	}
}
