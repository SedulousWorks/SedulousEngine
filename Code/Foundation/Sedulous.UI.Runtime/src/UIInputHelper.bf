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

	// Previous frame key state for Tab.
	private bool mPrevTabDown;

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
		ProcessButton(mouse, .Left, ref mPrevLeftDown, mx, my);
		ProcessButton(mouse, .Right, ref mPrevRightDown, mx, my);
		ProcessButton(mouse, .Middle, ref mPrevMiddleDown, mx, my);

		// Mouse wheel.
		if (mouse.ScrollX != 0 || mouse.ScrollY != 0)
			mContext.InputManager.ProcessMouseWheel(mx, my, mouse.ScrollX, mouse.ScrollY);

		// Tab navigation.
		if (kb != null)
		{
			let tabDown = kb.IsKeyDown(.Tab);
			if (tabDown && !mPrevTabDown)
			{
				if (kb.Modifiers.HasFlag(.Shift))
					mContext.FocusManager.FocusPrev();
				else
					mContext.FocusManager.FocusNext();
			}
			mPrevTabDown = tabDown;
		}
	}

	private void ProcessButton(IMouse mouse, Sedulous.Shell.Input.MouseButton shellBtn,
		ref bool prevDown, float mx, float my)
	{
		let down = mouse.IsButtonDown(shellBtn);
		let uiBtn = MapButton(shellBtn);

		if (down && !prevDown)
			mContext.InputManager.ProcessMouseDown(uiBtn, mx, my, mTotalTime);
		else if (!down && prevDown)
			mContext.InputManager.ProcessMouseUp(uiBtn, mx, my);

		prevDown = down;
	}

	private static Sedulous.UI.MouseButton MapButton(Sedulous.Shell.Input.MouseButton shellBtn)
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
}
