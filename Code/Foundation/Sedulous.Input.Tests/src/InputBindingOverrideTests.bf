using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// The user rebind overlay.
///
/// The point of keeping it separate from the asset: restoring a default is DROPPING an
/// override, not remembering what the default was.
class InputBindingOverrideTests
{
	private static void Populate(InputMap map)
	{
		let set = new ActionSet();
		set.Name.Set("Gameplay");

		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Bindings.Add(.() { Source = .Key, Code = 44 });
		set.Actions.Add(jump);

		let fire = new InputAction();
		fire.Name.Set("Fire");
		fire.Bindings.Add(.() { Source = .MouseButton, Code = 1 });
		set.Actions.Add(fire);

		map.Sets.Add(set);
	}

	[Test]
	public static void AnOverrideReplacesAnActionsBindingsAndLeavesTheRest()
	{
		let asset = scope InputMap();
		Populate(asset);

		let overrides = scope InputBindingOverrides();
		var rebind = Binding() { Source = .Key, Code = 99 };
		overrides.Set("Gameplay", "Jump", .(&rebind, 1));

		// Applied to a COPY, so the asset stays as authored.
		let live = scope InputMap();
		asset.CopyTo(live);
		overrides.ApplyTo(live);

		let set = live.FindSet("Gameplay");
		Test.Assert(set.Actions[0].Bindings.Count == 1);
		Test.Assert(set.Actions[0].Bindings[0].Code == 99, "the rebind took");
		Test.Assert(set.Actions[1].Bindings[0].Code == 1, "the other action is untouched");
		Test.Assert(asset.FindSet("Gameplay").Actions[0].Bindings[0].Code == 44,
			"and the asset itself never changed");
	}

	/// Clearing an override restores the asset's bindings EXACTLY, because it never had to
	/// remember them: they were always still there.
	[Test]
	public static void ClearingAnOverrideRestoresTheDefault()
	{
		let asset = scope InputMap();
		Populate(asset);

		let overrides = scope InputBindingOverrides();
		var rebind = Binding() { Source = .Key, Code = 99 };
		overrides.Set("Gameplay", "Jump", .(&rebind, 1));
		overrides.Clear("Gameplay", "Jump");

		let live = scope InputMap();
		asset.CopyTo(live);
		overrides.ApplyTo(live);

		Test.Assert(overrides.Overrides.IsEmpty);
		Test.Assert(live.FindSet("Gameplay").Actions[0].Bindings[0].Code == 44);
	}

	/// Setting the same action twice REPLACES rather than accumulating: rebinding is "these
	/// are the keys now", and a merge would leave a player guessing which old ones still work.
	[Test]
	public static void SettingTheSameActionTwiceReplaces()
	{
		let overrides = scope InputBindingOverrides();
		var first = Binding() { Source = .Key, Code = 10 };
		overrides.Set("Gameplay", "Jump", .(&first, 1));
		var second = Binding() { Source = .Key, Code = 20 };
		overrides.Set("Gameplay", "Jump", .(&second, 1));

		Test.Assert(overrides.Overrides.Count == 1);
		Test.Assert(overrides.Overrides[0].Bindings.Count == 1);
		Test.Assert(overrides.Overrides[0].Bindings[0].Code == 20);
	}

	/// An override naming something the map no longer has is IGNORED. A map edit is allowed
	/// to invalidate a rebind, and resurrecting a deleted action would be worse.
	[Test]
	public static void AnOverrideForSomethingGoneIsIgnored()
	{
		let asset = scope InputMap();
		Populate(asset);

		let overrides = scope InputBindingOverrides();
		var rebind = Binding() { Source = .Key, Code = 99 };
		overrides.Set("Vehicle", "Handbrake", .(&rebind, 1));
		overrides.Set("Gameplay", "Crouch", .(&rebind, 1));

		let live = scope InputMap();
		asset.CopyTo(live);
		overrides.ApplyTo(live);

		Test.Assert(live.Sets.Count == 1, "no set was invented");
		Test.Assert(live.FindSet("Gameplay").Actions.Count == 2, "and no action was");
	}

	[Test]
	public static void TheOverlaySurvivesARoundTrip()
	{
		let overrides = scope InputBindingOverrides();
		var rebind = Binding() { Source = .GamepadButton, Code = 3, Device = 2, DeadZone = 0.4f };
		overrides.Set("Gameplay", "Jump", .(&rebind, 1));

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			overrides.Serialize(writer);
		}
		buffer.Seek(0, .Begin);

		let restored = scope InputBindingOverrides();
		let reader = scope BinarySerializer(buffer, .Read);
		restored.Serialize(reader);

		Test.Assert(restored.Overrides.Count == 1);
		Test.Assert(restored.Overrides[0].SetName == "Gameplay");
		Test.Assert(restored.Overrides[0].ActionName == "Jump");
		Test.Assert(restored.Overrides[0].Bindings[0].Source == .GamepadButton);
		Test.Assert(restored.Overrides[0].Bindings[0].Device == 2);
		Test.Assert(restored.Overrides[0].Bindings[0].DeadZone == 0.4f);
	}
}
