using System;
using System.Collections;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// Bindings and the enums around them, rendered as labels.
class BindingNamesTests
{
	private static void Name(uint32 code, String outName) => BindingNames.KeyName(code, outName);

	[Test]
	public static void KeysRenderAsLettersDigitsFunctionKeysAndNames()
	{
		Test.Assert(Name((.)KeyCode.A, .. scope String()) == "A");
		Test.Assert(Name((.)KeyCode.Z, .. scope String()) == "Z");
		Test.Assert(Name((.)KeyCode.Num0, .. scope String()) == "0");
		Test.Assert(Name((.)KeyCode.Num9, .. scope String()) == "9");
		Test.Assert(Name((.)KeyCode.F1, .. scope String()) == "F1");
		Test.Assert(Name((.)KeyCode.F24, .. scope String()) == "F24");
		Test.Assert(Name((.)KeyCode.Return, .. scope String()) == "Return");
		Test.Assert(Name((.)KeyCode.Space, .. scope String()) == "Space");
		Test.Assert(Name((.)KeyCode.LeftShift, .. scope String()) == "LShift");
		Test.Assert(Name((.)KeyCode.RightAlt, .. scope String()) == "RAlt");
	}

	/// A key with no name still renders something a person can report, rather than an
	/// empty prompt that looks like a missing binding.
	[Test]
	public static void AnUnnamedKeyFallsBackToItsCode()
	{
		Test.Assert(Name((.)KeyCode.Semicolon, .. scope String()) == scope $"Key#{(uint32)KeyCode.Semicolon}");
		Test.Assert(Name(9999, .. scope String()) == "Key#9999");
	}

	[Test]
	public static void PadButtonsRenderByPositionNotByLabel()
	{
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.South) == "Pad South");
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.North) == "Pad North");
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.DPadUp) == "DPad Up");
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.LeftShoulder) == "Pad LB");
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.Start) == "Pad Start");
		// A button with no prompt of its own still names its family.
		Test.Assert(BindingNames.PadButtonName((.)GamepadButton.Touchpad) == "Pad Button");
	}

	private static void Describe(BindingSource source, uint32 code, String outName)
	{
		var binding = Binding();
		binding.Source = source;
		binding.Code = code;
		BindingNames.DescribeBinding(binding, outName);
	}

	[Test]
	public static void DescribeBindingDispatchesOnTheSource()
	{
		Test.Assert(Describe(.Key, (.)KeyCode.E, .. scope String()) == "E");
		Test.Assert(Describe(.GamepadButton, (.)GamepadButton.South, .. scope String()) == "Pad South");
		Test.Assert(Describe(.MouseButton, (.)MouseButton.Left, .. scope String()) == "Mouse Left");
		Test.Assert(Describe(.MouseButton, (.)MouseButton.Right, .. scope String()) == "Mouse Right");
		Test.Assert(Describe(.MouseButton, (.)MouseButton.Middle, .. scope String()) == "Mouse Middle");
		Test.Assert(Describe(.MouseButton, (.)MouseButton.X1, .. scope String()) == "Mouse Button");
		Test.Assert(Describe(.MouseAxis, (.)MouseAxisCode.DeltaX, .. scope String()) == "Mouse dX");
		Test.Assert(Describe(.MouseAxis, (.)MouseAxisCode.DeltaY, .. scope String()) == "Mouse dY");
		Test.Assert(Describe(.MouseAxis, (.)MouseAxisCode.Wheel, .. scope String()) == "Mouse Wheel");
		Test.Assert(Describe(.MouseDelta, 0, .. scope String()) == "Mouse Delta (2D)");
		Test.Assert(Describe(.GamepadAxis, (.)GamepadAxis.LeftX, .. scope String()) == "Pad Left X");
		Test.Assert(Describe(.GamepadAxis, (.)GamepadAxis.RightTrigger, .. scope String()) == "Pad RT");
		Test.Assert(Describe(.GamepadStick, (.)StickCode.Left, .. scope String()) == "Left Stick");
		Test.Assert(Describe(.GamepadStick, (.)StickCode.Right, .. scope String()) == "Right Stick");
		Test.Assert(Describe(.TouchButton, 0, .. scope String()) == "Touch Region");
		Test.Assert(Describe(.TouchStick, 0, .. scope String()) == "Touch Stick");
	}

	/// A composite names all four keys, in the order the fields are declared, so a prompt
	/// reads as the shape the player's hand makes.
	[Test]
	public static void ACompositeNamesItsFourKeys()
	{
		var wasd = Binding();
		wasd.Source = .Composite2D;
		wasd.NegX = (.)KeyCode.A;
		wasd.PosX = (.)KeyCode.D;
		wasd.NegY = (.)KeyCode.S;
		wasd.PosY = (.)KeyCode.W;

		let label = scope String();
		BindingNames.DescribeBinding(wasd, label);
		Test.Assert(label == "Keys A/D/S/W");
	}

	[Test]
	public static void TheEnumsNameThemselves()
	{
		Test.Assert(BindingNames.SourceName(.Key) == "Key");
		Test.Assert(BindingNames.SourceName(.GamepadButton) == "PadBtn");
		Test.Assert(BindingNames.SourceName(.Composite2D) == "Keys4");
		Test.Assert(BindingNames.SourceName(.TouchStick) == "TouchStick");

		Test.Assert(BindingNames.KindName(.Button) == "Button");
		Test.Assert(BindingNames.KindName(.Axis1D) == "Axis1D");
		Test.Assert(BindingNames.KindName(.Axis2D) == "Axis2D");

		Test.Assert(BindingNames.InteractionName(.None) == "On Press");
		Test.Assert(BindingNames.InteractionName(.Hold) == "Hold");
		Test.Assert(BindingNames.InteractionName(.Tap) == "Tap");
		Test.Assert(BindingNames.InteractionName(.DoubleTap) == "Double Tap");
	}

	[Test]
	public static void ValidSourcesListsWhatEachKindAccepts()
	{
		let buttons = scope List<BindingSource>();
		BindingNames.ValidSources(.Button, buttons);
		Test.Assert(buttons.Count == 4);
		Test.Assert(buttons[0] == .Key);
		Test.Assert(buttons[2] == .GamepadButton);

		let axis1D = scope List<BindingSource>();
		BindingNames.ValidSources(.Axis1D, axis1D);
		Test.Assert(axis1D.Count == 5);
		Test.Assert(axis1D[4] == .GamepadAxis);

		let axis2D = scope List<BindingSource>();
		BindingNames.ValidSources(.Axis2D, axis2D);
		Test.Assert(axis2D.Count == 4);
		Test.Assert(axis2D[0] == .GamepadStick);
		Test.Assert(axis2D[1] == .Composite2D);
	}

	/// The list an editor cycles through and the rule a save enforces are the SAME rule.
	/// If they drift, the editor offers a source that then refuses to save, which reads to
	/// the user as the editor being broken.
	[Test]
	public static void EveryOfferedSourceActuallyValidates()
	{
		for (let kind in scope ActionKind[](.Button, .Axis1D, .Axis2D))
		{
			let sources = scope List<BindingSource>();
			BindingNames.ValidSources(kind, sources);

			for (let source in sources)
			{
				let map = scope InputMap();
				let set = new ActionSet();
				set.Name.Set("gameplay");
				map.Sets.Add(set);

				let action = new InputAction();
				action.Name.Set("act");
				action.Kind = kind;
				var binding = Binding();
				binding.Source = source;
				action.Bindings.Add(binding);
				set.Actions.Add(action);

				let error = scope String();
				Test.Assert(InputMapValidation.Validate(map, error),
					scope $"{BindingNames.KindName(kind)} offers {BindingNames.SourceName(source)}: {error}");
			}
		}
	}
}
