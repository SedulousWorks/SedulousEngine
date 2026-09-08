using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Input;
using Sedulous.Input.Resource;
using Sedulous.Shell;

namespace Sedulous.Input.Resource.Tests;

/// The cooked wrapper around a map: the envelope the resource adds, and the registration
/// without which an instance reads its primary back as null.
class InputMapResourceTests
{
	private static InputMapResource Authored()
	{
		let resource = new InputMapResource();

		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");
		gameplay.Priority = 3;
		resource.Map.Sets.Add(gameplay);

		let jump = new InputAction();
		jump.Name.Set("Jump");
		jump.Kind = .Button;
		jump.Interaction.Kind = .Hold;
		jump.Interaction.Seconds = 0.4f;

		var key = Binding();
		key.Source = .Key;
		key.Code = 44;
		key.Modifiers = 4;
		jump.Bindings.Add(key);

		var stick = Binding();
		stick.Source = .GamepadStick;
		stick.DeadZone = 0.25f;
		stick.Invert = true;
		jump.Bindings.Add(stick);

		jump.Processors.Sensitivity = 5.0f;
		jump.Processors.ResponseExponent = 2.0f;
		gameplay.Actions.Add(jump);

		return resource;
	}

	[Test]
	public static void ACookedMapRoundTripsThroughTheResourceEnvelope()
	{
		let authored = Authored();
		defer delete authored;

		// Through the interface: [Serializable] emits the body as an EXPLICIT
		// implementation, so the interface is where the method is.
		ISerializable writable = authored;
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);

		let loaded = scope InputMapResource();
		ISerializable readable = loaded;
		let reader = scope BinarySerializer(buffer, .Read);
		readable.Serialize(reader);
		Test.Assert(reader.IsOk);

		Test.Assert(loaded.Map.Sets.Count == 1);
		let set = loaded.Map.Sets[0];
		Test.Assert(set.Name == "Gameplay");
		Test.Assert(set.Priority == 3);
		Test.Assert(set.Actions.Count == 1);

		let action = set.Actions[0];
		Test.Assert(action.Name == "Jump");
		Test.Assert(action.Kind == .Button);
		Test.Assert(action.Interaction.Kind == .Hold);
		Test.Assert(action.Interaction.Seconds == 0.4f);
		Test.Assert(action.Processors.Sensitivity == 5.0f);
		Test.Assert(action.Processors.ResponseExponent == 2.0f);

		Test.Assert(action.Bindings.Count == 2);
		Test.Assert(action.Bindings[0].Source == .Key);
		Test.Assert(action.Bindings[0].Code == 44);
		Test.Assert(action.Bindings[0].Modifiers == 4);
		Test.Assert(action.Bindings[1].Source == .GamepadStick);
		Test.Assert(action.Bindings[1].DeadZone == 0.25f);
		Test.Assert(action.Bindings[1].Invert);
	}

	/// The registration is what makes a stored primary decodable. Without it an instance
	/// writes fine and reads back null, which looks like a missing asset rather than a
	/// missing call.
	[Test]
	public static void TheResourceTypeRegisters()
	{
		let registry = scope SerializableRegistry();
		InputResources.RegisterAll(registry);

		Test.Assert(registry.IsRegistered(InputMapResource.TypeId));
		Test.Assert(registry.IsRegistered(TypeIdOf("Sedulous.Input.Resource.InputMapResource")),
			"registered under the name an instance stores");

		let created = registry.Create(InputMapResource.TypeId);
		defer delete created;
		Test.Assert(created is InputMapResource);
	}
}
