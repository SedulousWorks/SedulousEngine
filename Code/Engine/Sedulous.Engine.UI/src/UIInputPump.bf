using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Engine.Input;
using Sedulous.Engine.Render;
using Sedulous.Input;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// Driving the platform's input into the UI, and telling the action layer what the UI took.
///
/// It reads the SAME device facades the action layer evaluates, so the player's window
/// coordinates and an editor viewport's content coordinates both arrive already in the right
/// space.
extension UISubsystem
{
	/// How far a stick has to go before it counts as a direction.
	private const float cNavThreshold = 0.6f;
	/// How long a held direction waits before it starts repeating, and then between repeats.
	private const float cNavInitialDelay = 0.4f;
	private const float cNavRepeatDelay = 0.12f;

	private void PumpInput()
	{
		// The global overlay layer eats input only while it holds something INTERACTIVE. A
		// modal menu keeps the modal while occupied contract, but a passive badge pushed
		// with hit testing off must not turn the full window layer into a click shield over
		// every scene's heads up display.
		let overlayActive = OverlayLayerWantsInput;
		if (mScreen.Overlay != null)
			mScreen.Overlay.IsHitTestVisible = overlayActive;

		if (mInput == null)
			return;

		let devices = mInput.ActiveSource;
		// The pointer: the mouse, or the first finger while one is down (a phone has no mouse:
		// a tap presses, a drag drags, so a scroll view scrolls).
		let pointer = ReadPointer(devices);
		let inputManager = mContext.GetInputManager();

		// Where the pointer lands when a world panel took it: the active root IS that
		// panel's own root, so the coordinates have to be its texture's pixels.
		var panelPointer = false;
		var panelPointerPx = Float2(0.0f, 0.0f);

		PickActiveInputRoot(pointer, overlayActive, ref panelPointer, ref panelPointerPx);
		PumpPointer(pointer, inputManager, panelPointer, panelPointerPx);
		PumpKeyboard(devices);
		PumpGamepad(devices, inputManager);
		ShowNavigationFocus();
		PublishConsumption(pointer, panelPointer, inputManager);
		// The touch guide: from the first touch on, the controls of the sets in effect.
		if ((devices.Touch != null) && devices.Touch.HasTouch)
			mTouchSeen = true;
		if (mTouchGuide != null)
			mTouchGuide.Update(mInput, mTouchSeen);
		TraceUi(devices.Mouse);
	}

	/// Whether this frame's input may reach a scene's root.
	///
	/// A BOUND source, which an editor's play surface is, confines routing and consumption
	/// to ITS scene, so two interactive scenes on screen at once cannot cross route on
	/// overlapping coordinates. An UNBOUND one follows the input subsystem's policy. The
	/// scene LESS screen tier is never confined: a global overlay sits above every scene.
	private bool SceneRootEligible(UISceneUI ui)
	{
		let boundKey = mInput.BoundSceneKey;
		if (boundKey != null)
			return (void*)Internal.UnsafeCastToPtr(ui.Scene) == boundKey;

		return mInput.UnboundScenePolicy == .AllScenes;
	}

	/// The context dispatches through ONE active root, so one is picked per frame.
	///
	/// The screen tier is this frame's input tier: the bound run's (its Game tab) or the shared
	/// one. An OCCUPIED global overlay layer is modal and always wins; failing that the eligible root under
	/// the pointer; failing that the nearest interactive world panel the camera ray crosses;
	/// and failing all of those the first eligible scene root that HAS canvas content, so a
	/// gamepad still reaches a pause menu no pointer ever hovered.
	private void PickActiveInputRoot(UIPointerFrame pointer, bool overlayActive, ref bool panelPointer,
		ref Float2 panelPointerPx)
	{
		RootView target = null;
		let tier = InputTier();

		if (overlayActive)
			target = mScreen.Root; // the global overlays live on the shared tier

		if ((target == null) && pointer.Present)
		{
			let point = Float2(pointer.X, pointer.Y);

			if (tier.Root != null)
			{
				let hit = tier.Root.HitTest(tier.LayoutPoint(point));
				if ((hit != null) && (hit !== tier.Root))
					target = tier.Root;
			}

			for (let ui in mSceneUIs)
			{
				if (target != null)
					break;
				if (!SceneRootEligible(ui) || (ui.Root == null))
					continue;

				let hit = ui.Root.HitTest(point);
				if ((hit != null) && (hit !== ui.Root))
					target = ui.Root;
			}

			// The world tier: the pointer missed every overlay, so cast the scene camera's
			// ray and take the NEAREST interactive panel it crosses.
			if (target == null)
				target = RayPickPanel(pointer.Relative, point, ref panelPointer, ref panelPointerPx);

			if (target == null)
				panelPointer = false;
		}

		if (target == null)
		{
			for (let ui in mSceneUIs)
			{
				if (!SceneRootEligible(ui))
					continue;

				// Beyond the billboard layer means at least one canvas was instantiated.
				if ((ui.Root != null) && (ui.Root.ChildCount > 1))
				{
					target = ui.Root;
					break;
				}
			}
		}

		if (target == null)
			target = tier.Root;

		if (target != null)
			mContext.SetActiveInputRoot(target);
	}

	/// `centreAim`: a captured look mode, where the cursor is parked wherever it was grabbed, so
	/// the crosshair IS the pointer and the ray goes through the centre of the view instead.
	private RootView RayPickPanel(bool centreAim, Float2 point, ref bool panelPointer,
		ref Float2 panelPointerPx)
	{

		RootView target = null;
		var bestDistance = 0.0f;

		for (let sceneUI in mSceneUIs)
		{
			if (!SceneRootEligible(sceneUI))
				continue;

			let panels = sceneUI.Scene.GetSystem<UIWorldPanelComponentManager>();
			if (panels == null)
				continue;

			// The surface's content size is the scene root's last drawn viewport, which is
			// nothing at all before the first frame renders, and then there is no ray yet.
			let viewSize = (sceneUI.Root != null) ? sceneUI.Root.ViewportSize : Float2(0, 0);
			if ((viewSize.X <= 0.0f) || (viewSize.Y <= 0.0f))
				continue;

			var camera = ViewCamera();
			// The projection the scene was drawn with: the shape of its view.
			if (!RenderExtract.ExtractPrimaryCamera(sceneUI.Scene, ref camera, null, viewSize.X / viewSize.Y))
				continue;

			let rayPoint = centreAim ? Float2(viewSize.X * 0.5f, viewSize.Y * 0.5f) : point;
			WorldPanelMath.PointerRayFromCamera(camera, rayPoint, viewSize, let rayOrigin,
				let rayDirection);

			panels.ForEach(scope [&] (component, owner) =>
				{
					if (!component.Interactive || !component.Visible
						|| !sceneUI.Scene.IsEffectivelyActive(owner))
						return;
					if (component.RenderRoot == null)
						return;

					let hit = WorldPanelMath.RayHitWorldPanel(rayOrigin, rayDirection,
						sceneUI.Scene.GetWorldMatrix(owner), component.SizeMeters);
					if (!hit.Hit)
						return;
					if ((target != null) && (hit.Distance >= bestDistance))
						return;

					target = component.RenderRoot;
					bestDistance = hit.Distance;

					let rootSize = component.RenderRoot.ViewportSize;
					panelPointerPx = .(hit.Uv.X * rootSize.X, hit.Uv.Y * rootSize.Y);
					panelPointer = true;
				});
		}

		return target;
	}

	/// This frame's pointer: the first finger while one is down, else the mouse.
	private UIPointerFrame ReadPointer(IInputSourceProvider devices)
	{
		var frame = UIPointerFrame();
		// A finger first: while the one driving is down it is the pointer, its left button held.
		if (let touch = devices.Touch)
		{
			var point = TouchPoint();
			var down = false;
			let count = touch.TouchCount;
			for (int32 i = 0; (i < count) && !down; i++)
			{
				if (touch.GetTouchPoint(i, out point) && (!mTouchHeld || (point.Id == mTouchId)))
					down = true;
			}
			if (down)
			{
				frame.TouchBegan = !mTouchHeld;
				mTouchHeld = true;
				mTouchId = point.Id;
				mTouchLast = .(point.PointerX, point.PointerY);
				mMouseWaits = true;
				frame.Present = true;
				frame.Touch = true;
				frame.X = point.PointerX;
				frame.Y = point.PointerY;
				frame.Buttons[0] = true;
				frame.Used = true;
				return frame;
			}
		}
		if (mTouchHeld)
		{
			// It lifted: a release where it last was (a tap's click lands there).
			mTouchHeld = false;
			frame.Present = true;
			frame.X = mTouchLast.X;
			frame.Y = mTouchLast.Y;
			frame.Used = true;
			frame.Touch = true;
			frame.TouchLifted = true;
			return frame;
		}
		let mouse = devices.Mouse;
		if (mouse == null)
			return frame;
		if (mMouseWaits)
		{
			if ((mouse.DeltaX == 0.0f) && (mouse.DeltaY == 0.0f) && (mouse.ScrollX == 0.0f) && (mouse.ScrollY == 0.0f))
				return frame; // no pointer until the mouse moves
			// It moved: it drives again, from the buttons as they are now (no edge from a stale one).
			mMouseWaits = false;
			mPrevButtons[0] = mouse.IsButtonDown(.Left);
			mPrevButtons[1] = mouse.IsButtonDown(.Right);
			mPrevButtons[2] = mouse.IsButtonDown(.Middle);
		}
		frame.Present = true;
		frame.X = mouse.X;
		frame.Y = mouse.Y;
		frame.Buttons[0] = mouse.IsButtonDown(.Left);
		frame.Buttons[1] = mouse.IsButtonDown(.Right);
		frame.Buttons[2] = mouse.IsButtonDown(.Middle);
		frame.ScrollX = mouse.ScrollX;
		frame.ScrollY = mouse.ScrollY;
		frame.Relative = mouse.RelativeMode;
		// Moved by its MOTION, not its position: the platform's first report of where the cursor
		// rests, and a warp, change the position with no motion at all.
		frame.Used = (mouse.DeltaX != 0.0f) || (mouse.DeltaY != 0.0f) || (frame.ScrollX != 0.0f)
			|| (frame.ScrollY != 0.0f) || frame.Buttons[0] || frame.Buttons[1] || frame.Buttons[2];
		return frame;
	}

	private void PumpPointer(UIPointerFrame pointer, InputManager inputManager, bool panelPointer,
		Float2 panelPointerPx)
	{
		// A pointer only counts once it is used: moved, clicked or scrolled. A cursor that sits
		// still, hidden on a handheld say, hovers nothing while keys or a pad drive.
		if (pointer.Present)
		{
			if (pointer.Used)
				mPointerLive = true;
			if (!mPointerLive)
				inputManager.ClearHover();
		}
		if (pointer.Present && mPointerLive)
		{
			var x = panelPointer ? panelPointerPx.X : pointer.X;
			var y = panelPointer ? panelPointerPx.Y : pointer.Y;
			// A screen tier drawn fitted takes its pointer in its own pixels.
			let activeTier = TierOfRoot(mContext.ActiveInputRoot);
			if (!panelPointer && (activeTier != null))
			{
				let screen = activeTier.PointerPoint(.(x, y));
				x = screen.X;
				y = screen.Y;
			}
			inputManager.ProcessMouseMove(x, y);

			let uiButtons = scope Sedulous.UI.MouseButton[3](.Left, .Right, .Middle);
			if (pointer.Touch)
			{
				// A finger's own edges: it came down, or it lifted (whatever the mouse reports).
				if (pointer.TouchBegan)
					inputManager.ProcessMouseDown(.Left, x, y, mContext.TotalTime);
				else if (pointer.TouchLifted)
					inputManager.ProcessMouseUp(.Left, x, y);
				if (InputTracing && (pointer.TouchBegan || pointer.TouchLifted))
				{
					GlobalLog(.Information, scope $"UiTouch: finger {(pointer.TouchBegan ? "down" : "up")} at ({x},{y}) on {DescribeView(mContext.GetViewById(inputManager.HoveredId), .. scope .())}, pressed {DescribeView(mContext.GetViewById(inputManager.PressedId), .. scope .())}");
				}
			}
			for (int i = 0; (i < 3) && !pointer.Touch; i++)
			{
				let down = pointer.Buttons[i];
				if (down && !mPrevButtons[i])
					inputManager.ProcessMouseDown(uiButtons[i], x, y, mContext.TotalTime);
				else if (!down && mPrevButtons[i])
					inputManager.ProcessMouseUp(uiButtons[i], x, y);
				if (InputTracing && (down != mPrevButtons[i]))
				{
					GlobalLog(.Information, scope $"UiMouse: button {i} {(down ? "down" : "up")} at ({x},{y}) on {DescribeView(mContext.GetViewById(inputManager.HoveredId), .. scope .())}");
				}
				mPrevButtons[i] = down;
			}

			// Already a per frame delta.
			if (pointer.ScrollY != 0.0f)
				inputManager.ProcessMouseWheel(x, y, pointer.ScrollX, pointer.ScrollY);
		}
		// A lifted finger leaves no cursor behind: nothing stays hovered, and the mouse counts
		// again only once it is used.
		if (pointer.TouchLifted)
		{
			mPointerLive = false;
			inputManager.ClearHover();
		}
	}

	/// The TAGGED event stream off the same provider: ordered key events and text payloads
	/// that polling cannot carry.
	///
	/// The bridge applies the shell to UI key mapping and reconciles the platform's text
	/// input after every event. The mouse kinds are skipped, being polled above, since
	/// dispatching both would fire everything twice.
	private void PumpKeyboard(IInputSourceProvider devices)
	{
		for (let event in devices.Events)
		{
			switch (event.Kind)
			{
			case .KeyDown:
				mPointerLive = false;
				mNavigating = true;
				// An arrow with nothing focused lands on the menu first, as the pad does,
				// rather than going nowhere; that press does not also move on.
				if (IsArrow(event.Key) && (mContext.GetFocusManager().FocusedView == null) && LandFocus())
					continue;
				mBridge.Dispatch(event);
			case .KeyUp, .TextInput:
				mBridge.Dispatch(event);
			default:
			}
		}

		// Reconciled even on a frame with no events at all: focus moves without a key or a
		// click when a gamepad navigates onto or off a text field.
		mBridge.SyncTextInput();
	}

	/// The directions arrive as the arrow keys, so the focused control sees them first and an
	/// unhandled one moves focus through the framework's own geometric search; the south
	/// button submits and the east one cancels, also as the keys the activation path knows.
	///
	/// The pad is deliberately NOT a consumption class: gameplay pad actions keep working,
	/// and a menu wanting exclusivity pushes an input set, which is the mechanism that
	/// already exists for it.
	private static bool IsArrow(Sedulous.Shell.KeyCode key) =>
		(key == .Up) || (key == .Down) || (key == .Left) || (key == .Right);

	/// Nothing is focused and a navigation input came: the top screen's default focus, or
	/// failing a screen the first focusable anywhere. False when there is nothing to focus.
	private bool LandFocus()
	{
		if (InputTier().Stack.FocusDefault(.Keyboard))
			return true;
		let focus = mContext.GetFocusManager();
		focus.FocusNext();
		return focus.FocusedView != null;
	}

	private void PumpGamepad(IInputSourceProvider devices, InputManager inputManager)
	{
		let pad = devices.GetGamepad(0);
		if ((pad == null) || !pad.Connected || (InputTier().Root == null))
			return;

		let stickX = pad.Axis(.LeftX);
		let stickY = pad.Axis(.LeftY);

		let wants = scope bool[4](
			pad.IsButtonDown(.DPadUp) || (stickY < -cNavThreshold),
			pad.IsButtonDown(.DPadDown) || (stickY > cNavThreshold),
			pad.IsButtonDown(.DPadLeft) || (stickX < -cNavThreshold),
			pad.IsButtonDown(.DPadRight) || (stickX > cNavThreshold));

		// As the arrow keys, through the same dispatch: the focused control sees the direction
		// first (a slider steps), and only an unhandled one moves focus.
		let arrows = scope Sedulous.UI.KeyCode[4](.Up, .Down, .Left, .Right);
		let focus = mContext.GetFocusManager();

		// A connected pad is how the player navigates, so focus shows; any pad input takes
		// over from the pointer.
		mNavigating = true;
		if (wants[0] || wants[1] || wants[2] || wants[3] || pad.IsButtonPressed(.South) || pad.IsButtonPressed(.East))
			mPointerLive = false;

		for (int i < 4)
		{
			if (!wants[i])
			{
				mNavHeld[i] = false;
				continue;
			}

			var fire = false;
			if (!mNavHeld[i])
			{
				fire = true;
				mNavHeld[i] = true;
				mNavRepeat[i] = cNavInitialDelay;
			}
			else
			{
				mNavRepeat[i] -= mNavDeltaTime;
				if (mNavRepeat[i] <= 0.0f)
				{
					fire = true;
					mNavRepeat[i] = cNavRepeatDelay;
				}
			}

			if (!fire || (focus == null))
				continue;

			// Nothing focused yet, so land somewhere first.
			if (focus.FocusedView == null)
			{
				LandFocus();
			}
			else
			{
				inputManager.ProcessKeyDown(arrows[i], .None, false, mContext.TotalTime);
				inputManager.ProcessKeyUp(arrows[i], .None, mContext.TotalTime);
			}
		}

		// Confirm and back act on the RELEASE. On the press, a button that resumes play would
		// unfreeze the game while the pad still held the button, and gameplay would read
		// that same press as its own (the confirm button is a jump). And the release counts
		// only on the view the press went down on: a jump held into a pause menu must not
		// let go on its default button and click it.
		if (pad.IsButtonPressed(.South))
			mConfirmPressedOn = ((focus != null) && (focus.FocusedView != null)) ? focus.FocusedId : .Invalid;
		if (pad.IsButtonReleased(.South))
		{
			let pressedOn = mConfirmPressedOn;
			mConfirmPressedOn = .Invalid;
			if (pressedOn.IsValid && (focus != null) && (focus.FocusedId == pressedOn))
			{
				inputManager.ProcessKeyDown(.Return, .None, false, mContext.TotalTime);
				inputManager.ProcessKeyUp(.Return, .None, mContext.TotalTime);
			}
		}
		if (pad.IsButtonPressed(.East))
			mBackPressed = true;
		if (pad.IsButtonReleased(.East) && mBackPressed)
		{
			mBackPressed = false;
			inputManager.ProcessKeyDown(.Escape, .None, false, mContext.TotalTime);
			inputManager.ProcessKeyUp(.Escape, .None, mContext.TotalTime);
		}
	}

	/// SEDULOUS_INPUT_TRACE set (on the web: the page's address has ?trace): the input path
	/// explains itself in the log.
	private bool InputTracing
	{
		get
		{
			if (mTraceUi == 0)
			{
				let value = scope String();
				mTraceUi = ((Environment.GetEnvironmentVariable("SEDULOUS_INPUT_TRACE", value) case .Ok) && !value.IsEmpty) ? 1 : -1;
			}
			return mTraceUi > 0;
		}
	}

	/// `view` for the trace: its name and type, or "none".
	private static void DescribeView(View view, String outText)
	{
		if (view == null)
		{
			outText.Append("none");
			return;
		}
		outText.AppendF("'{}' ", view.Name);
		view.GetType().GetName(outText);
	}

	/// Whether the UI takes a pointer over `view`: it, or a view it sits in, answers pointers
	/// (View.TakesPointer). A layout box alone, or the root, does not.
	private static bool TakesPointerAt(View view)
	{
		for (var v = view; v != null; v = v.Parent)
		{
			if (v.TakesPointer)
				return true;
		}
		return false;
	}

	/// SEDULOUS_INPUT_TRACE set: twice a second, what the UI holds - the focused view and how
	/// focus got there, the hovered one, and where the pointer is in layout space - beside
	/// the input path's own trace.
	private void TraceUi(IMouse mouse)
	{
		if (!InputTracing || ((++mTraceFrame % 30) != 0))
			return;
		let line = scope String("UiTrace:");
		let focus = mContext.GetFocusManager();
		let focused = (focus != null) ? focus.FocusedView : null;
		if (focused != null)
			line.AppendF(" focused '{}' {} by {}", focused.Name, focused.GetType().GetName(.. scope .()), focus.Source);
		else
			line.Append(" focused none");
		let hovered = mContext.GetViewById(mContext.GetInputManager().HoveredId);
		if (hovered != null)
			line.AppendF(" | hovered '{}' {}", hovered.Name, hovered.GetType().GetName(.. scope .()));
		else
			line.Append(" | hovered none");
		if (mouse != null)
		{
			let point = InputTier().LayoutPoint(.(mouse.X, mouse.Y));
			line.AppendF(" | pointer ({:0},{:0}) layout ({:0},{:0})", mouse.X, mouse.Y, point.X, point.Y);
		}
		GlobalLog(.Information, line);
	}

	/// While keys or a pad drive and the pointer is idle, focus a screen set by itself (its
	/// default button) shows its ring: the player has to see where the confirm button goes
	/// before the first direction press. A pointer in use keeps the quiet look.
	private void ShowNavigationFocus()
	{
		if (!mNavigating || mPointerLive)
			return;
		let focus = mContext.GetFocusManager();
		if ((focus != null) && (focus.FocusedView != null) && (focus.Source == .Programmatic))
			focus.SetFocus(focus.FocusedView, .Keyboard);
	}

	/// What the UI took, published to the action layer so a click on a menu never also fires
	/// a gameplay action.
	///
	/// The pointer probes the screen tier first, being topmost, then the ELIGIBLE scene
	/// roots, under the same binding rule as the routing: an unbound editor context never
	/// publishes a mask from heads up displays it cannot interact with anyway.
	private void PublishConsumption(UIPointerFrame frame, bool panelPointer, InputManager inputManager)
	{
		var pointer = false;

		// Only what takes a pointer counts (TakesPointerAt): a pass-through HUD's layout boxes are
		// hits, but a tap between its controls is the game's.
		if (frame.Present)
		{
			let point = Float2(frame.X, frame.Y);

			let tier = InputTier();
			if (tier.Root != null)
				pointer = TakesPointerAt(tier.Root.HitTest(tier.LayoutPoint(point)));
			// The global overlays sit on the shared tier, above a run's own.
			if (!pointer && OverlayLayerWantsInput && (tier !== mScreen))
				pointer = TakesPointerAt(mScreen.Root.HitTest(mScreen.LayoutPoint(point)));

			for (let ui in mSceneUIs)
			{
				if (pointer)
					break;
				if (!SceneRootEligible(ui) || (ui.Root == null))
					continue;

				pointer = TakesPointerAt(ui.Root.HitTest(point));
			}
		}

		// A panel the ray hit consumes the pointer like any hovered canvas would, and so
		// does a pressed view that takes the pointer, but NOT a pressed ROOT or layout box: a
		// press over empty space parks on the root so the release still routes, and that is
		// not an interaction. Without that, ANY held click published a consumed mask and gated
		// gameplay input for as long as the button was down.
		let pressedView = mContext.GetViewById(inputManager.PressedId);
		let pressedOnUI = TakesPointerAt(pressedView);
		pointer = pointer || panelPointer || pressedOnUI;

		let keyboard = mContext.WantsTextInput();
		mPointerConsumed = pointer;

		var mask = ConsumptionMask();
		mask.Pointer = pointer;
		mask.Keyboard = keyboard;
		// On every runtime in play: a game's own reads its actions there.
		mInput.ForEachActionRuntime(scope [&] (runtime) => runtime.SetConsumptionMask(mask));
	}
}
