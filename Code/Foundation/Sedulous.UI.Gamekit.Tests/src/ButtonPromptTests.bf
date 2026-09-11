using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// A button prompt shows "[binding] text". These cover the raw Set, resolving an action's first
/// binding through the input module's own describer, and the unbound fallback.
class ButtonPromptTests
{
	private static ButtonPrompt Attach(WidgetBed bed)
	{
		let prompt = new ButtonPrompt();
		bed.Root.AddView(prompt);
		return prompt;
	}

	/// OWNERSHIP transfers.
	private static InputMap MapWith(StringView actionName, BindingSource source, uint32 code)
	{
		let map = new InputMap();
		let set = new ActionSet();
		set.Name.Set("Gameplay");

		let action = new InputAction();
		action.Name.Set(actionName);
		Binding binding = .();
		binding.Source = source;
		binding.Code = code;
		action.Bindings.Add(binding);

		set.Actions.Add(action);
		map.Sets.Add(set);
		return map;
	}

	[Test]
	public static void SetShowsTheLabelAndTheText()
	{
		let bed = scope WidgetBed();
		let prompt = Attach(bed);

		prompt.Set("E", "Deliver");
		Test.Assert(prompt.Keycap.Text.Value == "[E]");
		Test.Assert(prompt.TextLabel.Text.Value == "Deliver");
	}

	[Test]
	public static void SetFromActionResolvesAKeyboardBinding()
	{
		let bed = scope WidgetBed();
		let prompt = Attach(bed);

		// QUALIFIED: the UI names a KeyCode of its own, and a binding carries the shell's.
		let map = MapWith("Deliver", .Key, (uint32)Sedulous.Shell.KeyCode.E);
		defer delete map;

		prompt.SetFromAction(map, "Deliver", "Deliver");
		Test.Assert(prompt.Keycap.Text.Value == "[E]");
		Test.Assert(prompt.TextLabel.Text.Value == "Deliver");
	}

	[Test]
	public static void SetFromActionResolvesAGamepadBinding()
	{
		let bed = scope WidgetBed();
		let prompt = Attach(bed);

		let map = MapWith("Jump", .GamepadButton, (uint32)GamepadButton.South);
		defer delete map;

		prompt.SetFromAction(map, "Jump", "Jump");
		Test.Assert(prompt.Keycap.Text.Value == "[Pad South]");
	}

	/// An unbound action shows a dash rather than an empty chip, so the prompt still reads as a
	/// prompt instead of looking like a layout fault.
	[Test]
	public static void AMissingOrUnboundActionShowsADash()
	{
		let bed = scope WidgetBed();
		let prompt = Attach(bed);

		let map = scope InputMap();
		prompt.SetFromAction(map, "Nope", "Nope");
		Test.Assert(prompt.Keycap.Text.Value == "[-]");
		Test.Assert(prompt.TextLabel.Text.Value == "Nope");
	}
}
