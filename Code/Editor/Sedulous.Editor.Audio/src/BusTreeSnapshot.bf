using System;
using System.Collections;
using Sedulous.Audio.Pipeline;

namespace Sedulous.Editor.Audio;

/// The bus layout as a tree: Master at the root with the three fixed buses under it, then
/// every named custom slot under the bus its parent names, Master when that is empty or
/// unknown (the cook's fallback).
class BusTreeSnapshot
{
	public List<BusNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> Roots = new .() ~ delete _;

	public bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < Nodes.Count);

	public void Rebuild(AudioBusLayoutAsset asset)
	{
		ClearAndDeleteItems!(Nodes);
		Roots.Clear();
		if (asset == null)
			return;
		for (int32 f < 4)
		{
			let node = new BusNode();
			node.Fixed = true;
			node.FixedIndex = f;
			node.Depth = (f == 0) ? 0 : 1;
			Nodes.Add(node);
		}
		Roots.Add(0);
		Nodes[0].Children.Add(1);
		Nodes[0].Children.Add(2);
		Nodes[0].Children.Add(3);

		let slotNode = scope int32[asset.Custom.Count];
		for (int32 i < (int32)asset.Custom.Count)
		{
			slotNode[i] = -1;
			if (asset.Custom[i].Name.IsEmpty)
				continue;
			let node = new BusNode();
			node.Fixed = false;
			node.SlotIndex = i;
			slotNode[i] = (int32)Nodes.Count;
			Nodes.Add(node);
		}
		for (int32 i < (int32)asset.Custom.Count)
		{
			if (slotNode[i] < 0)
				continue;
			let parent = asset.Custom[i].Parent;
			int32 parentNode = 0;
			if ((StringView.Compare(parent, "Effects", true) == 0))
				parentNode = 1;
			else if ((StringView.Compare(parent, "Music", true) == 0))
				parentNode = 2;
			else if ((StringView.Compare(parent, "UI", true) == 0))
				parentNode = 3;
			else
			{
				let slot = AudioBusLayoutEdit.FindSlotByName(asset, parent);
				if ((slot >= 0) && (slotNode[slot] >= 0) && (slot != i))
					parentNode = slotNode[slot];
			}
			Nodes[parentNode].Children.Add(slotNode[i]);
		}
		// Depths from the root down; the guard bounds a cycle the asset should never hold.
		let pending = scope List<int32>();
		pending.Add(0);
		for (int guard = 0; !pending.IsEmpty && (guard < Nodes.Count * 2 + 4); guard++)
		{
			let node = pending.PopBack();
			for (let child in Nodes[node].Children)
			{
				Nodes[child].Depth = Nodes[node].Depth + 1;
				pending.Add(child);
			}
		}
	}

	/// The row text: a fixed bus's name, or the slot's.
	public StringView Label(AudioBusLayoutAsset asset, int32 nodeId)
	{
		if (!InRange(nodeId))
			return "";
		let node = Nodes[nodeId];
		if (node.Fixed)
			return AudioBusLayoutEdit.FixedNames[node.FixedIndex];
		return ((asset != null) && (node.SlotIndex < asset.Custom.Count)) ? StringView(asset.Custom[node.SlotIndex].Name) : "";
	}

	/// The authoring record a node edits.
	public static AudioBusAuthoring BusOf(AudioBusLayoutAsset asset, BusNode node)
	{
		if ((asset == null) || (node == null))
			return null;
		if (node.Fixed)
		{
			switch (node.FixedIndex)
			{
			case 1: return asset.Effects;
			case 2: return asset.Music;
			case 3: return asset.UI;
			default: return asset.Master;
			}
		}
		return (node.SlotIndex < asset.Custom.Count) ? asset.Custom[node.SlotIndex].Bus : null;
	}
}
