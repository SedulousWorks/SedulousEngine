using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// Maps the runtime tests are measured against. THE CALLER OWNS what comes back.
static class InputTestMaps
{
	/// One action, one binding, in one set. The shape most behaviours only need.
	public static InputMap Single(StringView actionName, ActionKind kind, Binding binding,
		StringView setName = "S")
	{
		let map = new InputMap();
		let set = new ActionSet();
		set.Name.Set(setName);
		map.Sets.Add(set);

		let action = new InputAction();
		action.Name.Set(actionName);
		action.Kind = kind;
		action.Bindings.Add(binding);
		set.Actions.Add(action);
		return map;
	}

	public static Binding Key(KeyCode key, uint32 modifiers = 0)
	{
		var binding = Binding();
		binding.Source = .Key;
		binding.Code = (.)key;
		binding.Modifiers = modifiers;
		return binding;
	}

	/// Gameplay and Menu, sharing Space between Jump and Confirm on purpose: that overlap
	/// is what the priority and exclusivity rules exist to settle.
	public static InputMap Gameplay()
	{
		let map = new InputMap();

		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");
		gameplay.Priority = 0;
		map.Sets.Add(gameplay);

		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Kind = .Button;
		jump.Bindings.Add(Key(.Space));
		var padButton = Binding();
		padButton.Source = .GamepadButton;
		padButton.Code = (.)GamepadButton.South;
		jump.Bindings.Add(padButton);
		gameplay.Actions.Add(jump);

		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		var wasd = Binding();
		wasd.Source = .Composite2D;
		wasd.NegX = (.)KeyCode.A;
		wasd.PosX = (.)KeyCode.D;
		wasd.NegY = (.)KeyCode.S;
		wasd.PosY = (.)KeyCode.W;
		move.Bindings.Add(wasd);
		var stick = Binding();
		stick.Source = .GamepadStick;
		stick.Code = (.)StickCode.Left;
		stick.DeadZone = 0.2f;
		move.Bindings.Add(stick);
		gameplay.Actions.Add(move);

		let menu = new ActionSet();
		menu.Name.Set("Menu");
		menu.Priority = 10;
		map.Sets.Add(menu);

		let confirm = new InputAction();
		confirm.Name.Set("Confirm");
		confirm.Kind = .Button;
		confirm.Bindings.Add(Key(.Space));
		menu.Actions.Add(confirm);

		return map;
	}
}
