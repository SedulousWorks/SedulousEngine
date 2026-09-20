using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Audio.Pipeline;

namespace Sedulous.Editor.Audio;

/// The sound cue page's undo snapshot, the whole asset as bytes, and a deep copy.
static class SoundCueAssetEdit
{
	public static void Snapshot(SoundCueAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(SoundCueAsset asset, Span<uint8> blob)
	{
		if (blob.IsEmpty)
			return false;
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

	public static void CopyTo(SoundCueAsset source, SoundCueAsset target)
	{
		let blob = scope List<uint8>();
		Snapshot(source, blob);
		Apply(target, blob);
	}

	/// The label the mode button shows.
	public static StringView ModeLabel(uint8 mode)
	{
		switch (mode % 3)
		{
		case 0: return "Mode: Random (no repeat)";
		case 1: return "Mode: Random";
		default: return "Mode: Sequential";
		}
	}

	public static bool HasAnyClip(SoundCueAsset asset)
	{
		for (let slot in asset.Slots)
		{
			if (!slot.ClipId.IsNil)
				return true;
		}
		return false;
	}
}
