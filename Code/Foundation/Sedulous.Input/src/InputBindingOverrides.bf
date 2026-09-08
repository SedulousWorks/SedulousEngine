using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Input;

/// The user's rebinds, as an overlay.
///
/// NOT part of the asset. It is a section of the user's own settings, applied over a COPY
/// of the asset at load and after each rebind, so resetting to default is simply removing
/// an override and the asset itself never changes. That is what makes "restore defaults"
/// exact rather than an attempt to remember what the defaults were.
class InputBindingOverrides : ISerializable
{
	public List<InputBindingOverride> Overrides = new .() ~ DeleteContainerAndItems!(_);

	/// Sets, or replaces, the bindings for one action.
	public void Set(StringView setName, StringView actionName, Span<Binding> bindings)
	{
		for (let existing in Overrides)
		{
			if ((existing.SetName == setName) && (existing.ActionName == actionName))
			{
				existing.Bindings.Clear();
				existing.Bindings.AddRange(bindings);
				return;
			}
		}

		let fresh = new InputBindingOverride();
		fresh.SetName.Set(setName);
		fresh.ActionName.Set(actionName);
		fresh.Bindings.AddRange(bindings);
		Overrides.Add(fresh);
	}

	/// Drops one action's override, which puts it back to what the asset says.
	public void Clear(StringView setName, StringView actionName)
	{
		for (int i = 0; i < Overrides.Count; i++)
		{
			if ((Overrides[i].SetName == setName) && (Overrides[i].ActionName == actionName))
			{
				delete Overrides[i];
				Overrides.RemoveAt(i);
				return;
			}
		}
	}

	public void Serialize(ISerializer ar)
	{
		let writing = ar.Mode == .Write;

		uint32 count = writing ? (uint32)Overrides.Count : 0;
		ar.Key("overrides");
		ar.BeginArray(ref count);

		if (!writing)
		{
			ClearAndDeleteItems!(Overrides);
			for (uint32 i < count)
				Overrides.Add(new InputBindingOverride());
		}

		for (uint32 i < count)
		{
			let entry = Overrides[(int)i];
			Sedulous.Core.Serialization.Serialize(ar, "set", entry.SetName);
			Sedulous.Core.Serialization.Serialize(ar, "action", entry.ActionName);

			uint32 bindingCount = writing ? (uint32)entry.Bindings.Count : 0;
			ar.Key("bindings");
			ar.BeginArray(ref bindingCount);

			if (!writing)
			{
				entry.Bindings.Clear();
				entry.Bindings.Resize((int)bindingCount);
			}

			for (uint32 b < bindingCount)
				InputMapSerialization.SerializeBinding(ar, ref entry.Bindings[(int)b]);

			ar.EndArray();
		}

		ar.EndArray();
	}

	/// Applies the overlay onto `map`, which must be a COPY: the caller keeps the asset
	/// pristine, and an override naming a set or action that no longer exists is ignored
	/// rather than resurrecting it, since a map edit is allowed to invalidate a rebind.
	public void ApplyTo(InputMap map)
	{
		for (let entry in Overrides)
		{
			let set = map.FindSet(entry.SetName);
			if (set == null)
				continue;

			for (let action in set.Actions)
			{
				if (action.Name != entry.ActionName)
					continue;
				action.Bindings.Clear();
				action.Bindings.AddRange(entry.Bindings);
				break;
			}
		}
	}
}
