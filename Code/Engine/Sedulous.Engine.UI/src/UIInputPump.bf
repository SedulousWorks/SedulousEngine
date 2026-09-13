using System;
using Sedulous.Core;
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
		if (mOverlayLayer != null)
			mOverlayLayer.IsHitTestVisible = overlayActive;

		if (mInput == null)
			return;

		let devices = mInput.ActiveSource;
		let mouse = devices.Mouse;
		let inputManager = mContext.GetInputManager();

		// Where the pointer lands when a world panel took it: the active root IS that
		// panel's own root, so the coordinates have to be its texture's pixels.
		var panelPointer = false;
		var panelPointerPx = Float2(0.0f, 0.0f);

		PickActiveInputRoot(mouse, overlayActive, ref panelPointer, ref panelPointerPx);
		PumpMouse(mouse, inputManager, panelPointer, panelPointerPx);
		PumpKeyboard(devices);
		PumpGamepad(devices, inputManager);
		PublishConsumption(mouse, panelPointer, inputManager);
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
	/// An OCCUPIED screen tier is modal and always wins; failing that the eligible root under
	/// the pointer; failing that the nearest interactive world panel the camera ray crosses;
	/// and failing all of those the first eligible scene root that HAS canvas content, so a
	/// gamepad still reaches a pause menu no pointer ever hovered.
	private void PickActiveInputRoot(IMouse mouse, bool overlayActive, ref bool panelPointer,
		ref Float2 panelPointerPx)
	{
		RootView target = null;

		if (overlayActive)
			target = mScreenRoot;

		if ((target == null) && (mouse != null))
		{
			let point = Float2(mouse.X, mouse.Y);

			if (mScreenRoot != null)
			{
				let hit = mScreenRoot.HitTest(point);
				if ((hit != null) && (hit !== mScreenRoot))
					target = mScreenRoot;
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
				target = RayPickPanel(mouse, point, ref panelPointer, ref panelPointerPx);

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
			target = mScreenRoot;

		if (target != null)
			mContext.SetActiveInputRoot(target);
	}

	private RootView RayPickPanel(IMouse mouse, Float2 point, ref bool panelPointer,
		ref Float2 panelPointerPx)
	{
		// In a captured look mode the cursor is parked wherever it was grabbed, so the
		// crosshair IS the pointer and the ray goes through the centre of the view instead.
		let centreAim = mouse.RelativeMode;

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
			if (!RenderExtract.ExtractPrimaryCamera(sceneUI.Scene, ref camera))
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

	private void PumpMouse(IMouse mouse, InputManager inputManager, bool panelPointer,
		Float2 panelPointerPx)
	{
		if (mouse == null)
			return;

		let x = panelPointer ? panelPointerPx.X : mouse.X;
		let y = panelPointer ? panelPointerPx.Y : mouse.Y;
		inputManager.ProcessMouseMove(x, y);

		let shellButtons = scope Sedulous.Shell.MouseButton[3](.Left, .Right, .Middle);
		let uiButtons = scope Sedulous.UI.MouseButton[3](.Left, .Right, .Middle);

		for (int i < 3)
		{
			let down = mouse.IsButtonDown(shellButtons[i]);
			if (down && !mPrevButtons[i])
				inputManager.ProcessMouseDown(uiButtons[i], x, y, mContext.TotalTime);
			else if (!down && mPrevButtons[i])
				inputManager.ProcessMouseUp(uiButtons[i], x, y);

			mPrevButtons[i] = down;
		}

		// Already a per frame delta.
		let wheel = mouse.ScrollY;
		if (wheel != 0.0f)
			inputManager.ProcessMouseWheel(x, y, mouse.ScrollX, wheel);
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
			case .KeyDown, .KeyUp, .TextInput:
				mBridge.Dispatch(event);
			default:
			}
		}

		// Reconciled even on a frame with no events at all: focus moves without a key or a
		// click when a gamepad navigates onto or off a text field.
		mBridge.SyncTextInput();
	}

	/// The directions move focus through the framework's own geometric search, the south
	/// button submits and the east one cancels, both as the synthesised keys the existing
	/// activation path already understands.
	///
	/// The pad is deliberately NOT a consumption class: gameplay pad actions keep working,
	/// and a menu wanting exclusivity pushes an input set, which is the mechanism that
	/// already exists for it.
	private void PumpGamepad(IInputSourceProvider devices, InputManager inputManager)
	{
		let pad = devices.GetGamepad(0);
		if ((pad == null) || !pad.Connected || (mScreenRoot == null))
			return;

		let stickX = pad.Axis(.LeftX);
		let stickY = pad.Axis(.LeftY);

		let wants = scope bool[4](
			pad.IsButtonDown(.DPadUp) || (stickY < -cNavThreshold),
			pad.IsButtonDown(.DPadDown) || (stickY > cNavThreshold),
			pad.IsButtonDown(.DPadLeft) || (stickX < -cNavThreshold),
			pad.IsButtonDown(.DPadRight) || (stickX > cNavThreshold));

		let directions = scope FocusDirection[4](.Up, .Down, .Left, .Right);
		let focus = mContext.GetFocusManager();

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
				focus.FocusNext();
			else
				focus.MoveFocus(directions[i]);
		}

		if (pad.IsButtonPressed(.South))
		{
			inputManager.ProcessKeyDown(.Return, .None, false, mContext.TotalTime);
			inputManager.ProcessKeyUp(.Return, .None, mContext.TotalTime);
		}
		if (pad.IsButtonPressed(.East))
		{
			inputManager.ProcessKeyDown(.Escape, .None, false, mContext.TotalTime);
			inputManager.ProcessKeyUp(.Escape, .None, mContext.TotalTime);
		}
	}

	/// What the UI took, published to the action layer so a click on a menu never also fires
	/// a gameplay action.
	///
	/// The pointer probes the screen tier first, being topmost, then the ELIGIBLE scene
	/// roots, under the same binding rule as the routing: an unbound editor context never
	/// publishes a mask from heads up displays it cannot interact with anyway.
	private void PublishConsumption(IMouse mouse, bool panelPointer, InputManager inputManager)
	{
		var pointer = false;

		if (mouse != null)
		{
			let point = Float2(mouse.X, mouse.Y);

			if (mScreenRoot != null)
			{
				let hit = mScreenRoot.HitTest(point);
				pointer = (hit != null) && (hit !== mScreenRoot);
			}

			for (let ui in mSceneUIs)
			{
				if (pointer)
					break;
				if (!SceneRootEligible(ui) || (ui.Root == null))
					continue;

				let hit = ui.Root.HitTest(point);
				pointer = (hit != null) && (hit !== ui.Root);
			}
		}

		// A panel the ray hit consumes the pointer like any hovered canvas would, and so
		// does a pressed view, but NOT a pressed ROOT: a press over empty space parks on the
		// root so the release still routes, and that is not an interaction. Without the root
		// exclusion, ANY held click published a consumed mask and gated gameplay input for
		// as long as the button was down.
		let pressedView = mContext.GetViewById(inputManager.PressedId);
		let pressedOnUI = (pressedView != null) && (pressedView.Parent != null);
		pointer = pointer || panelPointer || pressedOnUI;

		let keyboard = mContext.WantsTextInput();
		mPointerConsumed = pointer;

		var mask = ConsumptionMask();
		mask.Pointer = pointer;
		mask.Keyboard = keyboard;
		mInput.Runtime.SetConsumptionMask(mask);
	}
}
