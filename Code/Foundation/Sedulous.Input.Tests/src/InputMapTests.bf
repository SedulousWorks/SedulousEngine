using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// The binding data model: what it stores, and that it survives a round trip.
class InputMapTests
{
	/// A map with one set, one action of each kind, and bindings that exercise the fields
	/// different sources actually read.
	private static void Populate(InputMap map)
	{
		let set = new ActionSet();
		set.Name.Set("Gameplay");
		set.Priority = 10;

		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Kind = .Button;
		jump.Interaction = .() { Kind = .Hold, Seconds = 0.5f };
		jump.Bindings.Add(.() { Source = .Key, Code = 44, Modifiers = 2 });
		set.Actions.Add(jump);

		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		move.Processors = .() { Sensitivity = 3.0f, Gravity = 6.0f, Snap = true,
			ResponseExponent = 2.0f, TimeScale = true };
		move.Bindings.Add(.() { Source = .Composite2D, NegX = 1, PosX = 2, NegY = 3, PosY = 4,
			Normalize = false });
		move.Bindings.Add(.() { Source = .GamepadStick, Code = (uint32)StickCode.Left,
			DeadZone = 0.25f, Invert = true, Device = 1 });
		set.Actions.Add(move);

		let look = new InputAction();
		look.Name.Set("Look");
		look.Kind = .Axis1D;
		look.Bindings.Add(.() { Source = .MouseAxis, Code = (uint32)MouseAxisCode.DeltaX,
			Scale = -1.0f });
		look.Bindings.Add(.() { Source = .TouchStick, RegionX = 0.5f, RegionY = 0.25f,
			RegionW = 0.5f, RegionH = 0.75f, StickRadius = 0.2f });
		set.Actions.Add(look);

		map.Sets.Add(set);
	}

	private static void RoundTrip(InputMap source, InputMap target)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			InputMapSerialization.SerializeInputMap(writer, source);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		InputMapSerialization.SerializeInputMap(reader, target);
		Test.Assert(reader.IsOk);
	}

	[Test]
	public static void AMapSurvivesARoundTrip()
	{
		let source = scope InputMap();
		Populate(source);

		let target = scope InputMap();
		RoundTrip(source, target);

		Test.Assert(target.Sets.Count == 1);
		let set = target.Sets[0];
		Test.Assert(set.Name == "Gameplay");
		Test.Assert(set.Priority == 10);
		Test.Assert(set.Actions.Count == 3);

		let jump = set.Actions[0];
		Test.Assert(jump.Name == "Jump");
		Test.Assert(jump.Kind == .Button);
		Test.Assert(jump.Interaction.Kind == .Hold);
		Test.Assert(jump.Interaction.Seconds == 0.5f);
		Test.Assert(jump.Bindings.Count == 1);
		Test.Assert(jump.Bindings[0].Source == .Key);
		Test.Assert(jump.Bindings[0].Code == 44);
		Test.Assert(jump.Bindings[0].Modifiers == 2);

		let move = set.Actions[1];
		Test.Assert(move.Kind == .Axis2D);
		Test.Assert(move.Processors.Sensitivity == 3.0f);
		Test.Assert(move.Processors.Gravity == 6.0f);
		Test.Assert(move.Processors.Snap);
		Test.Assert(move.Processors.ResponseExponent == 2.0f);
		Test.Assert(move.Processors.TimeScale);
		Test.Assert(move.Bindings.Count == 2, "several sources fold into one action");
		Test.Assert(move.Bindings[0].Source == .Composite2D);
		Test.Assert(move.Bindings[0].PosY == 4);
		Test.Assert(!move.Bindings[0].Normalize);
		Test.Assert(move.Bindings[1].Source == .GamepadStick);
		Test.Assert(move.Bindings[1].DeadZone == 0.25f);
		Test.Assert(move.Bindings[1].Invert);
		Test.Assert(move.Bindings[1].Device == 1);

		// The touch region, which is the half a v1 stream would not have carried.
		let look = set.Actions[2];
		Test.Assert(look.Bindings[0].Scale == -1.0f);
		Test.Assert(look.Bindings[1].Source == .TouchStick);
		Test.Assert(look.Bindings[1].RegionX == 0.5f);
		Test.Assert(look.Bindings[1].RegionH == 0.75f);
		Test.Assert(look.Bindings[1].StickRadius == 0.2f);
	}

	/// A stream stamped with any other version is REFUSED. The field list differs between
	/// versions, so reading on would decode the wrong ones into bindings that look
	/// perfectly plausible and are silently wrong.
	[Test]
	public static void AnotherVersionIsRefused()
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			uint32 notOurVersion = 1;
			SerializeValue(writer, "version", ref notOurVersion);
		}
		buffer.Seek(0, .Begin);

		let target = scope InputMap();
		let reader = scope BinarySerializer(buffer, .Read);
		InputMapSerialization.SerializeInputMap(reader, target);

		Test.Assert(target.Sets.IsEmpty, "nothing was invented from it");
		Test.Assert(!reader.IsOk);
		Test.Assert(reader.Status case .Err(.NotSupported));
	}

	/// Copying is DEEP: the copy is what overrides are applied to, so the asset it came
	/// from has to be untouched by anything done to it.
	[Test]
	public static void CopyingIsDeep()
	{
		let source = scope InputMap();
		Populate(source);

		let copy = scope InputMap();
		source.CopyTo(copy);

		copy.Sets[0].Name.Set("Changed");
		copy.Sets[0].Actions[0].Bindings.Clear();

		Test.Assert(source.Sets[0].Name == "Gameplay", "the original kept its name");
		Test.Assert(source.Sets[0].Actions[0].Bindings.Count == 1, "and its bindings");
	}
}
