using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;

namespace Sedulous.Editor.Scene;

/// The clip page's edits on an AnimationClipSource, kept off the page so they run headless:
/// the event table, kept as parallel arrays of equal length, and the whole asset's binary
/// snapshot the undo step carries.
static class ClipSourceEdit
{
	/// Pads whichever of the two event arrays is shorter, so every event has a time and a
	/// name; a hand edited or older source can have them uneven.
	public static void NormalizeEvents(AnimationClipSource source)
	{
		while (source.EventName.Count < source.EventTime.Count)
			source.EventName.Add(new String());
		while (source.EventTime.Count < source.EventName.Count)
			source.EventTime.Add(0.0f);
	}

	public static int EventCount(AnimationClipSource source)
	{
		NormalizeEvents(source);
		return source.EventTime.Count;
	}

	public static void AddEvent(AnimationClipSource source, float time, StringView name)
	{
		NormalizeEvents(source);
		source.EventTime.Add(time);
		source.EventName.Add(new String(name));
	}

	/// False when `index` is out of range.
	public static bool RemoveEvent(AnimationClipSource source, int index)
	{
		NormalizeEvents(source);
		if ((index < 0) || (index >= source.EventTime.Count))
			return false;
		source.EventTime.RemoveAt(index);
		delete source.EventName[index];
		source.EventName.RemoveAt(index);
		return true;
	}

	/// The whole asset as its binary form, what an undo step keeps.
	public static void Snapshot(AnimationClipAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(AnimationClipAsset asset, Span<uint8> blob)
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
