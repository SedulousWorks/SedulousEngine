using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Input.Tests;

/// The input map editor's registration and its headless edits.
class InputMapEditTests
{
	[Test]
	public static void RegisteringRoutesInputMapAssetToTheFactory()
	{
		let context = scope EditorContext();
		InputEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(InputMapAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(InputMapAsset)));
	}

	[Test]
	public static void LookupsAreGuardedAndFreshBindingsFollowTheKind()
	{
		let asset = scope InputMapAsset();
		asset.SeedDefaultContent();
		let map = asset.Map;
		Test.Assert(InputMapEdit.SetAt(map, 0) != null);
		Test.Assert(InputMapEdit.SetAt(map, 1) == null);
		Test.Assert(InputMapEdit.ActionAt(map, 0, 3).Name == "Fire");
		Test.Assert(InputMapEdit.ActionAt(map, 0, 4) == null);
		Test.Assert(!InputMapEdit.HasBinding(map, 0, 0, 0));
		let move = InputMapEdit.ActionAt(map, 0, 0);
		move.Bindings.Add(InputMapEdit.FreshBinding(move.Kind));
		Test.Assert(InputMapEdit.HasBinding(map, 0, 0, 0));
		Test.Assert(move.Bindings[0].Source == .GamepadStick);
		Test.Assert(InputMapEdit.FreshBinding(.Button).Source == .Key);
	}

	[Test]
	public static void CyclingTheSourceWalksTheValidListOnAFreshBinding()
	{
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(.Button, valid);
		Test.Assert(valid.Count >= 2);
		var binding = Binding();
		binding.Source = valid[0];
		binding.Scale = 7.0f;
		let next = InputMapEdit.CycleSource(.Button, binding);
		Test.Assert(next.Source == valid[1]);
		Test.Assert(next.Scale == 1.0f); // the source specifics reset
		// The last wraps to the first.
		var last = Binding();
		last.Source = valid[valid.Count - 1];
		Test.Assert(InputMapEdit.CycleSource(.Button, last).Source == valid[0]);
	}

	[Test]
	public static void TheListenFilterFollowsTheActionKind()
	{
		let button = InputMapEdit.FilterFor(.Button, false);
		Test.Assert(button.Keys && button.MouseButtons && button.GamepadButtons && !button.GamepadAxes && !button.GamepadSticks);
		let axis = InputMapEdit.FilterFor(.Axis1D, false);
		Test.Assert(axis.Keys && axis.GamepadAxes && !axis.GamepadSticks);
		let stick = InputMapEdit.FilterFor(.Axis2D, false);
		Test.Assert(!stick.Keys && !stick.MouseButtons && !stick.GamepadButtons && stick.GamepadSticks);
		let direction = InputMapEdit.FilterFor(.Axis2D, true);
		Test.Assert(direction.Keys && !direction.MouseButtons && !direction.GamepadButtons);
	}

	[Test]
	public static void ACaptureLandsInTheBindingOrOneCompositeDirection()
	{
		let asset = scope InputMapAsset();
		asset.SeedDefaultContent();
		let map = asset.Map;
		let jump = InputMapEdit.ActionAt(map, 0, 2);
		jump.Bindings.Add(InputMapEdit.FreshBinding(.Button));
		var captured = Binding();
		captured.Source = .MouseButton;
		captured.Code = 3;
		InputMapEdit.ApplyCapture(map, 0, 2, 0, -1, captured);
		Test.Assert((jump.Bindings[0].Source == .MouseButton) && (jump.Bindings[0].Code == 3));

		let move = InputMapEdit.ActionAt(map, 0, 0);
		var composite = Binding();
		composite.Source = .Composite2D;
		move.Bindings.Add(composite);
		var key = Binding();
		key.Code = 42;
		InputMapEdit.ApplyCapture(map, 0, 0, 0, 3, key);
		Test.Assert((move.Bindings[0].Source == .Composite2D) && (move.Bindings[0].PosY == 42) && (move.Bindings[0].NegX == 0));
		// Out of range slots are ignored.
		InputMapEdit.ApplyCapture(map, 0, 0, 5, -1, key);
		InputMapEdit.ApplyCapture(map, 9, 0, 0, -1, key);
		Test.Assert(move.Bindings.Count == 1);
	}
}
