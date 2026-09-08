using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// The data errors a map can carry. Every one is something an editor must refuse to save,
/// because the alternative is a binding that reads zero at runtime with nothing to say why.
class InputMapValidationTests
{
	/// A map with one set holding one action of `kind` bound to `source`.
	private static InputMap Build(ActionKind kind, BindingSource source,
		InteractionKind interaction = .None, StringView setName = "gameplay",
		StringView actionName = "fire")
	{
		let map = new InputMap();
		let set = new ActionSet();
		set.Name.Set(setName);
		map.Sets.Add(set);

		let action = new InputAction();
		action.Name.Set(actionName);
		action.Kind = kind;
		action.Interaction.Kind = interaction;

		var binding = Binding();
		binding.Source = source;
		binding.Code = (.)KeyCode.Space;
		action.Bindings.Add(binding);
		set.Actions.Add(action);
		return map;
	}

	[Test]
	public static void AWellFormedMapValidates()
	{
		let map = Build(.Button, .Key, .Hold);
		defer delete map;
		let error = scope String();
		Test.Assert(InputMapValidation.Validate(map, error));
		Test.Assert(error.IsEmpty, "a pass leaves the error untouched");
	}

	/// An empty map is coherent. Nothing to check is not the same as something wrong, and
	/// a new project starts here.
	[Test]
	public static void AnEmptyMapValidates()
	{
		let map = scope InputMap();
		Test.Assert(InputMapValidation.Validate(map));
	}

	[Test]
	public static void AnUnnamedSetOrActionIsRefused()
	{
		let unnamedSet = Build(.Button, .Key, .None, "");
		defer delete unnamedSet;
		let setError = scope String();
		Test.Assert(!InputMapValidation.Validate(unnamedSet, setError));
		Test.Assert(setError == "action set with an empty name");

		let unnamedAction = Build(.Button, .Key, .None, "gameplay", "");
		defer delete unnamedAction;
		let actionError = scope String();
		Test.Assert(!InputMapValidation.Validate(unnamedAction, actionError));
		Test.Assert(actionError == "action with an empty name");
	}

	/// An interaction is a press state machine, so on an axis it is a setting that would
	/// silently do nothing.
	[Test]
	public static void AnInteractionOnANonButtonIsRefused()
	{
		let map = Build(.Axis1D, .GamepadAxis, .Tap);
		defer delete map;
		let error = scope String();
		Test.Assert(!InputMapValidation.Validate(map, error));
		Test.Assert(error == "interaction on a non-Button action");
	}

	[Test]
	public static void AKindMismatchIsRefusedInBothDirections()
	{
		let analogOnButton = Build(.Button, .GamepadAxis);
		defer delete analogOnButton;
		let buttonError = scope String();
		Test.Assert(!InputMapValidation.Validate(analogOnButton, buttonError));
		Test.Assert(buttonError == "analog binding on a Button action");

		let twoDOnButton = Build(.Button, .GamepadStick);
		defer delete twoDOnButton;
		Test.Assert(!InputMapValidation.Validate(twoDOnButton));

		let twoDOnAxis1D = Build(.Axis1D, .MouseDelta);
		defer delete twoDOnAxis1D;
		let axisError = scope String();
		Test.Assert(!InputMapValidation.Validate(twoDOnAxis1D, axisError));
		Test.Assert(axisError == "2D binding on an Axis1D action");

		let keyOnAxis2D = Build(.Axis2D, .Key);
		defer delete keyOnAxis2D;
		let vectorError = scope String();
		Test.Assert(!InputMapValidation.Validate(keyOnAxis2D, vectorError));
		Test.Assert(vectorError == "non-2D binding on an Axis2D action");
	}

	/// A digital source on an Axis1D is FINE: a key with Scale -1 is how one axis is built
	/// out of two keys, which is the whole point of the scale field.
	[Test]
	public static void ADigitalSourceOnAnAxis1DIsAccepted()
	{
		let key = Build(.Axis1D, .Key);
		defer delete key;
		Test.Assert(InputMapValidation.Validate(key));

		let padButton = Build(.Axis1D, .GamepadButton);
		defer delete padButton;
		Test.Assert(InputMapValidation.Validate(padButton));
	}

	/// The caller may not want the message, and asking for no message must not change the
	/// verdict.
	[Test]
	public static void TheErrorStringIsOptional()
	{
		let map = Build(.Axis2D, .Key);
		defer delete map;
		Test.Assert(!InputMapValidation.Validate(map));
	}

	/// The FIRST problem is the one reported: the rest are usually the same mistake again,
	/// and a save dialog has room for one line.
	[Test]
	public static void OnlyTheFirstProblemIsReported()
	{
		let map = scope InputMap();
		let set = new ActionSet();
		set.Name.Set("gameplay");
		map.Sets.Add(set);

		let first = new InputAction();
		first.Name.Set("aim");
		first.Kind = .Axis2D;
		var key = Binding();
		key.Source = .Key;
		first.Bindings.Add(key);
		set.Actions.Add(first);

		let second = new InputAction();
		second.Name.Set("");
		second.Kind = .Button;
		set.Actions.Add(second);

		let error = scope String();
		Test.Assert(!InputMapValidation.Validate(map, error));
		Test.Assert(error == "non-2D binding on an Axis2D action", "the action walked first");
	}
}
