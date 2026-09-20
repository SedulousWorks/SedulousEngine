using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Audio.Pipeline;

namespace Sedulous.Editor.Audio;

/// The bus layout page's headless halves: the fixed bus names, slot lookup by name, the
/// cycle check a parent pick must pass, the structural edits, and the undo snapshot.
static class AudioBusLayoutEdit
{
	public static readonly StringView[4] FixedNames = .("Master", "Effects", "Music", "UI");

	public static bool IsFixedBusName(StringView name)
	{
		for (let fixedName in FixedNames)
		{
			if ((StringView.Compare(name, fixedName, true) == 0))
				return true;
		}
		return false;
	}

	/// The custom slot named `name`, or -1 for empty, fixed or unknown.
	public static int32 FindSlotByName(AudioBusLayoutAsset asset, StringView name)
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

	/// True when parenting `slotIndex` under `newParent` would loop back to itself,
	/// directly or through the chain.
	public static bool WouldCycle(AudioBusLayoutAsset asset, int32 slotIndex, StringView newParent)
	{
		if ((slotIndex < 0) || (slotIndex >= asset.Custom.Count))
			return false;
		var walk = FindSlotByName(asset, newParent);
		for (int guard = 0; (walk >= 0) && (guard < asset.Custom.Count + 1); guard++)
		{
			if (walk == slotIndex)
				return true;
			walk = FindSlotByName(asset, asset.Custom[walk].Parent);
		}
		return false;
	}

	/// The first free slot, named BusN under Master; -1 when every slot is in use.
	public static int32 AddBus(AudioBusLayoutAsset asset)
	{
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (!asset.Custom[i].Name.IsEmpty)
				continue;
			asset.Custom[i].Name.Set(scope $"Bus{i + 1}");
			asset.Custom[i].Parent.Set("Master");
			ResetBus(asset.Custom[i].Bus);
			return i;
		}
		return -1;
	}

	/// Renames a slot and every child that named it as parent; false for an empty, fixed
	/// or taken name.
	public static bool RenameBus(AudioBusLayoutAsset asset, int32 slotIndex, StringView name)
	{
		if ((slotIndex < 0) || (slotIndex >= asset.Custom.Count))
			return false;
		if (name.IsEmpty || IsFixedBusName(name) || (FindSlotByName(asset, name) >= 0))
			return false;
		let slot = asset.Custom[slotIndex];
		let oldName = scope String(slot.Name);
		slot.Name.Set(name);
		for (let other in asset.Custom)
		{
			if (other.Parent == oldName)
				other.Parent.Set(name);
		}
		return true;
	}

	/// Empties a slot, re-parenting its children to Master.
	public static bool RemoveBus(AudioBusLayoutAsset asset, int32 slotIndex)
	{
		if ((slotIndex < 0) || (slotIndex >= asset.Custom.Count))
			return false;
		let slot = asset.Custom[slotIndex];
		for (let other in asset.Custom)
		{
			if (!slot.Name.IsEmpty && (other.Parent == slot.Name))
				other.Parent.Set("Master");
		}
		slot.Name.Clear();
		slot.Parent.Clear();
		ResetBus(slot.Bus);
		return true;
	}

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

	public static void Snapshot(AudioBusLayoutAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(AudioBusLayoutAsset asset, Span<uint8> blob)
	{
		let current = scope List<uint8>();
		Snapshot(asset, current);
		if ((current.Count == blob.Length) && (Internal.MemCmp(current.Ptr, blob.Ptr, blob.Length) == 0))
			return false;
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		return true;
	}
}
