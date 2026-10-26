using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Render;
using Sedulous.Shell;

namespace Sedulous.Engine.GUI;

/// The input: the engine's active input source (the player's window, an editor Game tab's view)
/// into ONE root a frame, through GUI.Shell's bridge (one per root, each root its own
/// dispatcher). An occupied overlay layer is modal; else the root whose GUI is under the pointer
/// (the screen tier first, then a scene's, then a world panel's by a ray through its scene's
/// camera); else the screen tier while it holds a screen; else the first scene root with content.
/// A press stays with its root until every button is up. Which scenes input may reach follows the
/// input subsystem's binding, as Engine.UI's does. The action layer is told what the GUI took,
/// added to what Engine.UI claims; the input kind is tracked from the same source.
///
/// It reads the SAME device facades the action layer evaluates, so the player's window
/// coordinates and an editor viewport's content coordinates both arrive in the right space.
extension GuiSubsystem
{
	/// The window whose platform text input (IME) follows the GUI's focus (the player's main
	/// window); null leaves it alone (an editor, whose own bridge owns it). BORROWED.
	public void SetTextInputTarget(IWindow window)
	{
		mTextInputTarget = window;
		if (mScreen.Bridge != null)
			mScreen.Bridge.SetTextInputTarget(window);
		for (let tier in mRunTiers)
			tier.Bridge.SetTextInputTarget(window);
		for (let tier in mSceneTiers)
			tier.Bridge.SetTextInputTarget(window);
	}

	/// The root this frame's input went to; null before any input.
	public SceneRoot ActiveInputRoot => mActiveRoot;
	/// Whether the GUI took the pointer this frame (what the action layer was told).
	public bool PointerOverGui => mPointerTaken;
	/// The input kind, from the active source each frame (the pointer, the keys, a pad). The
	/// subsystem's.
	public Sedulous.Input.InputKindTracker InputKindTracker => mInputKind;

	/// A bridge into `root`'s dispatcher, passing the tracker's kind on and the platform's text
	/// input following its focus. The CALLER owns it.
	private GuiInputBridge MakeBridge(SceneRoot root)
	{
		let bridge = new GuiInputBridge(root.EventDispatcher);
		bridge.SetInputKindTracker(mInputKind); // the pointer, the keys or a pad (K2b)
		bridge.SetTextInputTarget(mTextInputTarget);
		return bridge;
	}

	/// `root` going: neither the root input went to nor the one a press began in is it any more
	/// (both are compared, and pumped into, after it is freed otherwise).
	private void ForgetInputRoot(SceneRoot root)
	{
		if (mActiveRoot === root)
			mActiveRoot = null;
		if (mPressRoot === root)
			mPressRoot = null;
	}

	/// The bridge into `root`: its screen tier's, its scene tier's or its texture root's; null for
	/// none.
	private GuiInputBridge BridgeOf(SceneRoot root)
	{
		if (root == null)
			return null;
		if (let tier = TierOfRoot(root))
			return tier.Bridge;
		for (let tier in mSceneTiers)
		{
			if (tier.Root === root)
				return tier.Bridge;
		}
		for (let texture in mTextureRoots)
		{
			if (texture.Root === root)
				return texture.Bridge;
		}
		return null;
	}

	/// The nearest interactive world panel the pointer's ray crosses, through each reachable
	/// scene's camera at the shape its GUI last drew (through the view's centre when the mouse is
	/// captured: the crosshair is the pointer), and the point in its pixels; none: no root.
	private GuiInputTarget PanelUnderPointer(Float2 point, bool centreAim)
	{
		var found = GuiInputTarget();
		var nearest = 0.0f;
		for (let tier in mSceneTiers)
		{
			let panels = tier.Scene.GetSystem<GuiWorldPanelComponentManager>();
			if ((panels == null) || !InputReaches(tier))
				continue;
			let viewSize = tier.Root.ViewportSize;
			if ((viewSize.X <= 0.0f) || (viewSize.Y <= 0.0f))
				continue; // not drawn yet: no shape to cast through
			var camera = ViewCamera();
			if (!RenderExtract.ExtractPrimaryCamera(tier.Scene, ref camera, null, viewSize.X / viewSize.Y))
				continue;
			let aim = centreAim ? Float2(viewSize.X * 0.5f, viewSize.Y * 0.5f) : point;
			GuiWorldMath.GuiPointerRay(camera, aim, viewSize, let origin, let direction);
			panels.ForEach(scope [&] (c, entity) =>
				{
					if (!c.Interactive || !c.Visible || (c.RenderRoot == null) || !tier.Scene.IsEffectivelyActive(entity))
						return;
					let hit = GuiWorldMath.RayHitGuiPanel(origin, direction, tier.Scene.GetWorldMatrix(entity), c.SizeMeters);
					if (!hit.Hit || ((found.Root != null) && (hit.Distance >= nearest)))
						return;
					let pixels = GuiWorldMath.WorldPanelPixels(*c);
					found = .(c.RenderRoot, .(hit.Uv.X * pixels.X, hit.Uv.Y * pixels.Y), true, true);
					nearest = hit.Distance;
				});
		}
		return found;
	}

	/// Whether this frame's input may reach `tier`'s scene: the source's own scene when it is
	/// bound to one (an editor Game tab), else every scene or none, as the input subsystem's
	/// policy says.
	private bool InputReaches(GuiSceneTier tier)
	{
		if (mInput == null)
			return false;
		let bound = mInput.BoundSceneKey;
		if (bound != null)
			return (void*)Internal.UnsafeCastToPtr(tier.Scene) == bound;
		return mInput.UnboundScenePolicy == .AllScenes;
	}

	/// The tier input reaches: the run of the scene the input is bound to, when run screens are on
	/// and that run has a tier; the shared tier otherwise.
	private GuiScreenTier InputTier()
	{
		let bound = (mRunScreens && (mInput != null)) ? mInput.BoundSceneKey : null;
		if (bound == null)
			return mScreen;
		for (let scene in mSceneTiers)
		{
			if ((void*)Internal.UnsafeCastToPtr(scene.Scene) != bound)
				continue;
			if (let tier = FindRunTier(scene.Scene.Run))
				return tier;
			break;
		}
		return mScreen;
	}

	/// The root this frame's input goes to, and where the pointer falls in it.
	private GuiInputTarget PickInputRoot(bool pointer, Float2 point, bool centreAim)
	{
		if (mScreen.Root == null)
			return .();
		// The shared tier's overlay layer, occupied (a system menu, a loading screen), is modal; a
		// passive one (a watermark, `pointer-events: none`) draws over everything and takes nothing.
		if (mOverlay != null)
		{
			for (int i < mOverlay.ChildCount)
			{
				let overlay = mOverlay.GetChildAt(i);
				if (overlay.Displayed && overlay.HitTestVisible)
					return .(mScreen.Root, ScreenPointerPoint(mScreen, point), mScreen.HasResolution, false);
			}
		}
		// The screen tier input reaches (the bound run's), its pointer in its own pixels.
		let tier = InputTier();
		let screen = GuiInputTarget(tier.Root, ScreenPointerPoint(tier, point), tier.HasResolution, false);
		// The GUI under the pointer, the screen tier's over a scene's, then a world panel's.
		if (pointer)
		{
			if (tier.Root.EventDispatcher.IsPointerOver(screen.Point))
				return screen;
			for (let scene in mSceneTiers)
			{
				if (InputReaches(scene) && scene.Root.EventDispatcher.IsPointerOver(point))
					return .(scene.Root, point, false, false);
			}
			let panel = PanelUnderPointer(point, centreAim);
			if (panel.Root != null)
				return panel;
		}
		// The keys and a pad: the screens a game pushed, else a scene's GUI.
		if (tier.Screens.Count > 0)
			return screen;
		for (let scene in mSceneTiers)
		{
			if (InputReaches(scene) && HasContent(scene))
				return .(scene.Root, point, false, false);
		}
		return screen;
	}

	/// The frame's input into one root, before the GUI's clock: the pointer polled, the keys, text
	/// and the pad through their events, then what the GUI took told to the action layer.
	private void PumpInput()
	{
		mPointerTaken = false;
		if ((mInput == null) || (mScreen.Root == null))
			return;
		let devices = mInput.ActiveSource;
		mInputKind.Update(devices);
		let mouse = devices.Mouse;
		let touch = devices.Touch;
		let fingers = (touch != null) && (touch.TouchCount > 0);
		var point = Float2(0.0f, 0.0f);
		if (fingers)
		{
			if (touch.GetTouchPoint(0, let finger))
				point = .(finger.PointerX, finger.PointerY);
		}
		else if (mouse != null)
			point = .(mouse.X, mouse.Y);
		let pointer = fingers || (mouse != null);
		let held = fingers || ((mouse != null) && (mouse.IsButtonDown(.Left) || mouse.IsButtonDown(.Right) || mouse.IsButtonDown(.Middle)));

		// One root a frame; a held press stays with the root it began in, so its release lands (on
		// a panel, where the ray crosses it still, else where it last did).
		let centreAim = (mouse != null) && mouse.RelativeMode;
		var target = PickInputRoot(pointer, point, centreAim);
		if (held && (mPressRoot != null) && (target.Root !== mPressRoot))
		{
			bool panel = false;
			for (let texture in mTextureRoots)
				panel = panel || (texture.Root === mPressRoot);
			if (panel)
				target = .(mPressRoot, mPanelPoint, true, true);
			else if (let tier = TierOfRoot(mPressRoot))
				target = .(mPressRoot, ScreenPointerPoint(tier, point), tier.HasResolution, false);
			else
				target = .(mPressRoot, point, false, false);
		}
		if (target.Panel)
			mPanelPoint = target.Point;
		let root = target.Root;
		if ((root !== mActiveRoot) && (mActiveRoot != null) && pointer)
		{
			// The root input leaves: nothing in it stays hovered.
			mActiveRoot.EventDispatcher.InjectMouseMove(.(-1.0e6f, -1.0e6f));
		}
		mActiveRoot = root;
		let bridge = BridgeOf(root);
		if (bridge == null)
			return;
		if (held && (mPressRoot == null))
		{
			mPressRoot = root; // the press begins: where it began says whether the GUI took it
			mPressTaken = target.Panel || root.EventDispatcher.IsPointerOver(target.Point);
		}
		if (target.Mapped)
		{
			// A panel's pointer is where the ray crosses it, a fitted screen tier's where the
			// render-space pointer falls in its pixels (fingers come as the mouse SDL copies them to).
			if (mouse != null)
			{
				let mapped = scope GuiPanelMouse(mouse, target.Point);
				bridge.PumpDevices(mapped, null, devices.Keyboard);
			}
			else
				bridge.PumpDevices(null, null, devices.Keyboard);
		}
		else
			bridge.PumpDevices(mouse, touch, devices.Keyboard);
		// Keys, text and the pad through their events, in order; the pointer was polled above.
		for (let event in devices.Events)
		{
			switch (event.Kind)
			{
			case .KeyDown, .KeyUp, .TextInput, .TextEditing, .GamepadButtonDown, .GamepadButtonUp, .GamepadAxis:
				bridge.Dispatch(event);
			default:
			}
		}
		bridge.SyncInputKind(); // a pad or keys with no event this frame still count

		// What the action layer is told the GUI took: the pointer over GUI that takes it, or a
		// press that began there while it is held; the keys while text is edited. Added to
		// Engine.UI's claim (its pump runs first in this lane); EndFrame clears them after the
		// frame read them.
		mPointerTaken = pointer && (held ? mPressTaken : (target.Panel || root.EventDispatcher.IsPointerOver(target.Point)));
		let keys = root.EventDispatcher.WantsTextInput;
		if (!held)
		{
			mPressRoot = null;
			mPressTaken = false;
		}
		let pointerTaken = mPointerTaken;
		mInput.ForEachActionRuntime(scope [&] (runtime) =>
			{
				var mask = runtime.GetConsumptionMask();
				mask.Pointer = mask.Pointer || pointerTaken;
				mask.Keyboard = mask.Keyboard || keys;
				runtime.SetConsumptionMask(mask);
			});
	}
}
