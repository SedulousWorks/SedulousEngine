using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield.Pipeline;

namespace Sedulous.Editor.Heightfield;

/// The heightfield page's undo snapshot, the whole asset as bytes.
static class HeightfieldAssetEdit
{
	public static void Snapshot(HeightfieldAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(HeightfieldAsset asset, Span<uint8> blob)
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
