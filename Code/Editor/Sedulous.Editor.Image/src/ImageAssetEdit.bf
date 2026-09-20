using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.Pipeline;

namespace Sedulous.Editor.Image;

/// The image page's headless halves: the source format label and the whole asset's binary
/// snapshot the undo step carries.
static class ImageAssetEdit
{
	public static StringView PixelFormatLabel(PixelFormat format)
	{
		switch (format)
		{
		case .R8: return "R8";
		case .RG8: return "RG8";
		case .RGB8: return "RGB8";
		case .RGBA8: return "RGBA8";
		case .RGBA32F: return "RGBA32F (HDR)";
		default: return "?";
		}
	}

	public static void Snapshot(ImageAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(ImageAsset asset, Span<uint8> blob)
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
