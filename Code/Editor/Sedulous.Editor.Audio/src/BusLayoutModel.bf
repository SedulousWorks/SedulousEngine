using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio.Pipeline;

namespace Sedulous.Editor.Audio;

// The rules a bus layout's page edits by, apart from the page (Raptor's editor-gui spec, 5.4, layer
// 5): the four fixed buses (Master, and Effects, Music and UI under it), a custom bus a named slot
// under a fixed bus or another custom one, the tree they make, and the edits that keep it one: a bus
// added in the first empty slot, one taken out (its children moving to Master), one renamed (its
// children following the name), one moved under another (never under itself or its own children: a
// cycle fails the cook). Pure functions over the asset, which the page's tests and its edits share.

/// One bus of the layout: a fixed one by its index (0 Master, 1 Effects, 2 Music, 3 UI) or a custom
/// one by its slot.
struct BusRef : IEquatable<BusRef>
{
	public int32 Fixed = -1;
	public int32 Slot = -1;

	public this(int32 fixedIndex, int32 slot)
	{
		Fixed = fixedIndex;
		Slot = slot;
	}

	public static BusRef Master => .(0, -1);
	public static BusRef OfSlot(int32 slot) => .(-1, slot);

	public bool IsFixed => Fixed >= 0;
	public bool IsValid => (Fixed >= 0) || (Slot >= 0);

	public bool Equals(BusRef other) => (Fixed == other.Fixed) && (Slot == other.Slot);
	public static bool operator==(BusRef a, BusRef b) => a.Equals(b);
}

/// A row of the bus tree: which bus, how deep, in the order the tree shows them.
class BusRow
{
	public BusRef Bus;
	public int32 Depth = 0;
	public String Name = new .() ~ delete _;

	public this(BusRef bus, int32 depth, StringView name)
	{
		Bus = bus;
		Depth = depth;
		Name.Set(name);
	}
}

static class BusLayoutModel
{
	/// The fixed buses, in the tree's order: Master first, the others under it.
	public static readonly StringView[4] cFixedNames = .("Master", "Effects", "Music", "UI");

	/// Whether two bus names are one, ignoring case (the cook takes a fixed bus's name in any case:
	/// "music" is Music).
	public static bool NamesMatch(StringView a, StringView b) => StringView.Compare(a, b, true) == 0;

	public static bool IsFixedBusName(StringView name)
	{
		for (let fixedName in cFixedNames)
		{
			if (NamesMatch(name, fixedName))
				return true;
		}
		return false;
	}

	/// The custom slot named `name`, or -1 (a fixed name, an unknown one, an empty one).
	public static int32 FindBusSlot(AudioBusLayoutAsset asset, StringView name)
	{
		if (name.IsEmpty || IsFixedBusName(name))
			return -1;
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (!asset.Custom[i].Name.IsEmpty && (asset.Custom[i].Name == name))
				return i;
		}
		return -1;
	}

	/// True when moving custom slot `slot` under `parent` would make a cycle among the custom buses
	/// (a fixed parent never can).
	public static bool WouldCycle(AudioBusLayoutAsset asset, int32 slot, StringView parent)
	{
		if ((slot < 0) || (slot >= asset.Custom.Count))
			return false;
		var walk = FindBusSlot(asset, parent);
		for (int guard = 0; (walk >= 0) && (guard <= asset.Custom.Count); guard++)
		{
			if (walk == slot)
				return true;
			walk = FindBusSlot(asset, asset.Custom[walk].Parent);
		}
		return false;
	}

	/// A bus's name as the tree and the parents show it.
	public static StringView BusName(AudioBusLayoutAsset asset, BusRef bus)
	{
		if (bus.IsFixed)
			return (bus.Fixed < cFixedNames.Count) ? cFixedNames[bus.Fixed] : default;
		return ((bus.Slot >= 0) && (bus.Slot < asset.Custom.Count)) ? (StringView)asset.Custom[bus.Slot].Name : default;
	}

	/// The layout's settings of `bus` (null: no such bus).
	public static AudioBusAuthoring BusSettings(AudioBusLayoutAsset asset, BusRef bus)
	{
		switch (bus.Fixed)
		{
		case 0: return asset.Master;
		case 1: return asset.Effects;
		case 2: return asset.Music;
		case 3: return asset.UI;
		default:
		}
		if ((bus.Slot >= 0) && (bus.Slot < asset.Custom.Count) && !asset.Custom[bus.Slot].Name.IsEmpty)
			return asset.Custom[bus.Slot].Bus;
		return null;
	}

	/// The bus tree in order, into `outRows` (the caller deletes them): Master, the fixed buses under
	/// it, each bus's custom children under it (an empty or unknown parent is Master, as the cook
	/// takes it).
	public static void BusTree(AudioBusLayoutAsset asset, List<BusRow> outRows)
	{
		outRows.Add(new .(BusRef.Master, 0, cFixedNames[0]));
		for (int32 f = 1; f < cFixedNames.Count; f++)
		{
			outRows.Add(new .(BusRef(f, -1), 1, cFixedNames[f]));
			Children(asset, cFixedNames[f], 2, outRows);
		}
		Children(asset, cFixedNames[0], 1, outRows);
		// Buses in a cycle (each under another of them) are reached from no fixed bus: shown under
		// Master all the same, to be moved out of it (the cook fails until they are).
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (asset.Custom[i].Name.IsEmpty)
				continue;
			bool shown = false;
			for (let row in outRows)
				shown = shown || (row.Bus.Slot == i);
			if (!shown)
				outRows.Add(new .(BusRef.OfSlot(i), 1, asset.Custom[i].Name));
		}
	}

	/// Whether some custom buses are under each other in a cycle (the cook fails on it).
	public static bool HasBusCycle(AudioBusLayoutAsset asset)
	{
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (!asset.Custom[i].Name.IsEmpty && WouldCycle(asset, i, asset.Custom[i].Parent))
				return true;
		}
		return false;
	}

	/// The parents custom slot `slot` may move under, into `outChoices` (the caller deletes them):
	/// the fixed buses, then the other custom ones that would not make a cycle.
	public static void BusParentChoices(AudioBusLayoutAsset asset, int32 slot, List<String> outChoices)
	{
		for (let fixedName in cFixedNames)
			outChoices.Add(new String(fixedName));
		for (int32 i < (int32)asset.Custom.Count)
		{
			if ((i != slot) && !asset.Custom[i].Name.IsEmpty && !WouldCycle(asset, slot, asset.Custom[i].Name))
				outChoices.Add(new String(asset.Custom[i].Name));
		}
	}

	/// A custom bus in the first empty slot, named "Bus N" (the first N free) under Master; its slot,
	/// or -1 when every slot is in use.
	public static int32 AddBus(AudioBusLayoutAsset asset)
	{
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (!asset.Custom[i].Name.IsEmpty)
				continue;
			let name = scope String();
			for (int n = 1;; n++)
			{
				name.Clear();
				name.AppendF("Bus {}", n);
				if (FindBusSlot(asset, name) < 0)
					break;
			}
			asset.Custom[i].Name.Set(name);
			asset.Custom[i].Parent.Set(cFixedNames[0]);
			ResetBus(asset.Custom[i].Bus);
			return i;
		}
		return -1;
	}

	/// Takes custom slot `slot` out; its children move to Master.
	public static void RemoveBus(AudioBusLayoutAsset asset, int32 slot)
	{
		if ((slot < 0) || (slot >= asset.Custom.Count) || asset.Custom[slot].Name.IsEmpty)
			return;
		let name = scope String(asset.Custom[slot].Name);
		for (let other in asset.Custom)
		{
			if (!other.Name.IsEmpty && (other.Parent == name))
				other.Parent.Set(cFixedNames[0]);
		}
		asset.Custom[slot].Name.Clear();
		asset.Custom[slot].Parent.Clear();
		ResetBus(asset.Custom[slot].Bus);
	}

	/// Renames custom slot `slot`, its children following the name; false (nothing changed) for an
	/// empty name, a fixed bus's or another bus's.
	public static bool RenameBus(AudioBusLayoutAsset asset, int32 slot, StringView name)
	{
		if ((slot < 0) || (slot >= asset.Custom.Count) || asset.Custom[slot].Name.IsEmpty)
			return false;
		if (name.IsEmpty || IsFixedBusName(name))
			return false;
		let owner = FindBusSlot(asset, name);
		if ((owner >= 0) && (owner != slot))
			return false;
		let old = scope String(asset.Custom[slot].Name);
		for (let other in asset.Custom)
		{
			if (!other.Name.IsEmpty && (other.Parent == old))
				other.Parent.Set(name);
		}
		asset.Custom[slot].Name.Set(name);
		return true;
	}

	/// Moves custom slot `slot` under `parent`; false (nothing changed) when that would make a cycle
	/// or names no bus.
	public static bool ReparentBus(AudioBusLayoutAsset asset, int32 slot, StringView parent)
	{
		if ((slot < 0) || (slot >= asset.Custom.Count) || asset.Custom[slot].Name.IsEmpty)
			return false;
		if (!IsFixedBusName(parent))
		{
			let found = FindBusSlot(asset, parent);
			if ((found < 0) || (found == slot))
				return false;
		}
		if (WouldCycle(asset, slot, parent))
			return false;
		asset.Custom[slot].Parent.Set(parent);
		return true;
	}

	/// A bus's settings back to a new bus's.
	public static void ResetBus(AudioBusAuthoring bus)
	{
		let fresh = scope AudioBusAuthoring();
		bus.Volume = fresh.Volume;
		bus.Muted = fresh.Muted;
		bus.LowpassHz = fresh.LowpassHz;
		bus.HighpassHz = fresh.HighpassHz;
		bus.DelaySeconds = fresh.DelaySeconds;
		bus.DelayDecay = fresh.DelayDecay;
		bus.ReverbWet = fresh.ReverbWet;
		bus.ReverbRoomSize = fresh.ReverbRoomSize;
		bus.ReverbDamping = fresh.ReverbDamping;
	}

	// The custom slots whose parent is `parent` (by name), under it at `depth`, each followed by its
	// own children.
	private static void Children(AudioBusLayoutAsset asset, StringView parent, int32 depth, List<BusRow> outRows)
	{
		for (int32 i < (int32)asset.Custom.Count)
		{
			let slot = asset.Custom[i];
			if (slot.Name.IsEmpty)
				continue;
			let underMaster = slot.Parent.IsEmpty || (!IsFixedBusName(slot.Parent) && (FindBusSlot(asset, slot.Parent) < 0));
			bool under;
			if (NamesMatch(parent, cFixedNames[0]))
				under = underMaster || NamesMatch(slot.Parent, parent);
			else if (IsFixedBusName(parent))
				under = NamesMatch(slot.Parent, parent);
			else
				under = slot.Parent == parent;
			if (!under)
				continue;
			outRows.Add(new .(BusRef.OfSlot(i), depth, slot.Name));
			Children(asset, slot.Name, depth + 1, outRows);
		}
	}
}
