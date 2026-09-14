using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Samples.InputActions;

/// The pristine defaults, which stand in for the map asset a real game would ship.
///
/// In code rather than loaded, because what this sample is about is the layer ABOVE the map:
/// the overlay, the capture, and the runtime. Where the defaults come from is beside the point.
static class DefaultInputMap
{
	/// A fresh map. THE CALLER OWNS it.
	public static InputMap Create()
	{
		let map = new InputMap();

		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");
		gameplay.Actions.Add(CreateMove());
		gameplay.Actions.Add(CreateJump());
		map.Sets.Add(gameplay);

		// A HIGHER priority set, so pushing it exclusively suppresses gameplay rather than
		// merely adding to it.
		let menu = new ActionSet();
		menu.Name.Set("Menu");
		menu.Priority = 10;

		let confirm = new InputAction();
		confirm.Name.Set("Confirm");
		confirm.Kind = .Button;
		Binding space = .();
		space.Source = .Key;
		space.Code = (uint32)KeyCode.Space;
		confirm.Bindings.Add(space);
		menu.Actions.Add(confirm);

		map.Sets.Add(menu);
		return map;
	}

	/// Three bindings for ONE action: the keyboard composite, a stick, and a touch region.
	/// Whichever device is present drives it, and none of them knows about the others.
	private static InputAction CreateMove()
	{
		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;

		Binding wasd = .();
		wasd.Source = .Composite2D;
		wasd.NegX = (uint32)KeyCode.A;
		wasd.PosX = (uint32)KeyCode.D;
		wasd.NegY = (uint32)KeyCode.S;
		wasd.PosY = (uint32)KeyCode.W;
		move.Bindings.Add(wasd);

		Binding stick = .();
		stick.Source = .GamepadStick;
		stick.Code = (uint32)StickCode.Left;
		stick.Invert = true; // stick plus Y is down; the square's plus Y is up
		move.Bindings.Add(stick);

		Binding touch = .();
		touch.Source = .TouchStick;
		touch.RegionX = 0.0f;
		touch.RegionY = 0.3f; // the left side, below the debug panel
		touch.RegionW = 0.45f;
		touch.RegionH = 0.7f;
		touch.StickRadius = 0.12f;
		touch.Invert = true;
		move.Bindings.Add(touch);

		move.Processors.Sensitivity = 6.0f;
		move.Processors.Gravity = 10.0f;
		move.Processors.Snap = true;
		move.Processors.TimeScale = true; // slow motion slows the movement
		return move;
	}

	private static InputAction CreateJump()
	{
		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Kind = .Button;

		Binding space = .();
		space.Source = .Key;
		space.Code = (uint32)KeyCode.Space;
		jump.Bindings.Add(space);

		Binding pad = .();
		pad.Source = .GamepadButton;
		pad.Code = 0;
		jump.Bindings.Add(pad);

		Binding touch = .();
		touch.Source = .TouchButton;
		touch.RegionX = 0.55f;
		touch.RegionY = 0.55f; // the bottom right quadrant
		touch.RegionW = 0.45f;
		touch.RegionH = 0.45f;
		jump.Bindings.Add(touch);
		return jump;
	}
}
