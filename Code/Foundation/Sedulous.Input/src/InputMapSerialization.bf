using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Input;

/// Reading and writing an input map, one bidirectional pass.
///
/// ONE supported layout: the current one. Nothing has been written in an older layout, so
/// this writes the current version and REFUSES any other rather than gating fields on a
/// stored version and guessing which are present.
static class InputMapSerialization
{
	public const uint32 cVersion = 2;

	public static void SerializeBinding(ISerializer ar, ref Binding binding)
	{
		var source = (uint8)binding.Source;
		SerializeValue(ar, "source", ref source);
		binding.Source = (BindingSource)source;

		SerializeValue(ar, "code", ref binding.Code);
		SerializeValue(ar, "modifiers", ref binding.Modifiers);
		SerializeValue(ar, "device", ref binding.Device);
		SerializeValue(ar, "deadZone", ref binding.DeadZone);
		SerializeValue(ar, "scale", ref binding.Scale);
		SerializeValue(ar, "invert", ref binding.Invert);
		SerializeValue(ar, "normalize", ref binding.Normalize);
		SerializeValue(ar, "negX", ref binding.NegX);
		SerializeValue(ar, "posX", ref binding.PosX);
		SerializeValue(ar, "negY", ref binding.NegY);
		SerializeValue(ar, "posY", ref binding.PosY);
		SerializeValue(ar, "regionX", ref binding.RegionX);
		SerializeValue(ar, "regionY", ref binding.RegionY);
		SerializeValue(ar, "regionW", ref binding.RegionW);
		SerializeValue(ar, "regionH", ref binding.RegionH);
		SerializeValue(ar, "stickRadius", ref binding.StickRadius);
	}

	public static void SerializeInputMap(ISerializer ar, InputMap map)
	{
		let writing = ar.Mode == .Write;

		var version = cVersion;
		SerializeValue(ar, "version", ref version);
		if (!writing && (version != cVersion))
		{
			// The field list differs between versions, so reading on would decode the
			// wrong ones into plausible looking bindings.
			ar.FailPayload(.NotSupported);
			return;
		}

		uint32 setCount = writing ? (uint32)map.Sets.Count : 0;
		ar.Key("sets");
		ar.BeginArray(ref setCount);

		if (!writing)
		{
			ClearAndDeleteItems!(map.Sets);
			for (uint32 i < setCount)
				map.Sets.Add(new ActionSet());
		}

		for (uint32 s < setCount)
		{
			let set = map.Sets[(int)s];
			Sedulous.Core.Serialization.Serialize(ar, "name", set.Name);
			SerializeValue(ar, "priority", ref set.Priority);

			uint32 actionCount = writing ? (uint32)set.Actions.Count : 0;
			ar.Key("actions");
			ar.BeginArray(ref actionCount);

			if (!writing)
			{
				ClearAndDeleteItems!(set.Actions);
				for (uint32 i < actionCount)
					set.Actions.Add(new InputAction());
			}

			for (uint32 a < actionCount)
				SerializeAction(ar, set.Actions[(int)a], writing);

			ar.EndArray();
		}

		ar.EndArray();
	}

	private static void SerializeAction(ISerializer ar, InputAction action, bool writing)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", action.Name);

		var kind = (uint8)action.Kind;
		SerializeValue(ar, "kind", ref kind);
		action.Kind = (ActionKind)kind;

		SerializeValue(ar, "sensitivity", ref action.Processors.Sensitivity);
		SerializeValue(ar, "gravity", ref action.Processors.Gravity);
		SerializeValue(ar, "snap", ref action.Processors.Snap);
		SerializeValue(ar, "responseExponent", ref action.Processors.ResponseExponent);
		SerializeValue(ar, "timeScale", ref action.Processors.TimeScale);

		var interaction = (uint8)action.Interaction.Kind;
		SerializeValue(ar, "interaction", ref interaction);
		action.Interaction.Kind = (InteractionKind)interaction;
		SerializeValue(ar, "interactionSeconds", ref action.Interaction.Seconds);

		uint32 bindingCount = writing ? (uint32)action.Bindings.Count : 0;
		ar.Key("bindings");
		ar.BeginArray(ref bindingCount);

		if (!writing)
		{
			action.Bindings.Clear();
			action.Bindings.Resize((int)bindingCount);
		}

		for (uint32 b < bindingCount)
			SerializeBinding(ar, ref action.Bindings[(int)b]);

		ar.EndArray();
	}
}
