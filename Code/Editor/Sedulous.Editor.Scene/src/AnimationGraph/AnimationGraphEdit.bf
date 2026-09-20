using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Animation.Pipeline;

namespace Sedulous.Editor.Scene;

/// The graph page's headless edits: the default seed, the canvas layout kept in step with
/// the model, and the whole asset's binary snapshot the undo step carries.
static class AnimationGraphEdit
{
	/// One "Base" layer with an "Idle" clip state as its default, and a float "Speed"
	/// parameter, laid out on the canvas.
	public static void SeedDefault(AnimationGraphAsset asset)
	{
		let doc = scope GraphDocument();
		doc.AddParam("Speed", 0);
		let layer = doc.AddLayer("Base");
		layer.AddState("Idle", 0); // a clip, unassigned: pick in the inspector
		layer.DefaultState = 0;
		doc.Store(asset.Source);

		ClearAndDeleteItems!(asset.LayerLayouts);
		let layout = new AnimationGraphLayerLayout();
		layout.StatePositions.Add(.(280.0f, 120.0f));
		layout.AnyStatePosition = .(60.0f, 40.0f);
		asset.LayerLayouts.Add(layout);
	}

	/// Pads or trims the asset's per layer layouts to the model: one per layer, one position
	/// per state, a new state placed on a loose grid so it never lands on another.
	public static void SyncLayouts(AnimationGraphAsset asset, GraphDocument doc)
	{
		let layouts = asset.LayerLayouts;
		while (layouts.Count < doc.Layers.Count)
		{
			let layout = new AnimationGraphLayerLayout();
			layout.AnyStatePosition = .(40.0f, 40.0f);
			layouts.Add(layout);
		}
		while (layouts.Count > doc.Layers.Count)
		{
			delete layouts[layouts.Count - 1];
			layouts.RemoveAt(layouts.Count - 1);
		}
		for (int l < doc.Layers.Count)
		{
			let positions = layouts[l].StatePositions;
			let stateCount = doc.Layers[l].States.Count;
			while (positions.Count < stateCount)
			{
				let x = 240.0f + 60.0f * (float)(positions.Count % 5);
				let y = 90.0f + 70.0f * (float)(positions.Count / 5);
				positions.Add(.(x, y));
			}
			while (positions.Count > stateCount)
				positions.RemoveAt(positions.Count - 1);
		}
	}

	/// The label a state's node kind shows under its title.
	public static StringView NodeKindLabel(uint8 kind)
	{
		switch (kind)
		{
		case 1: return "Blend Tree 1D";
		case 2: return "Blend Tree 2D";
		default: return "Clip";
		}
	}

	/// The whole asset, source and layouts, as its binary form.
	public static void Snapshot(AnimationGraphAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(AnimationGraphAsset asset, Span<uint8> blob)
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
