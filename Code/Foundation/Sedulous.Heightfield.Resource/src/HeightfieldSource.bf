using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;

namespace Sedulous.Heightfield.Resource;

/// The cooked heightfield METADATA: the grid's parameters, and nothing else.
///
/// The samples are NOT here. They ride the sidecar stream this names, the way an image's
/// pixels do: a database browsing a hundred terrains wants a hundred headers, not a hundred
/// megabytes of grid.
[Serializable]
class HeightfieldSource
{
	/// The sidecar stream carrying the raw samples.
	public const String HeightStream = "heights";

	public int32 Size = 0;
	public Float2 WorldSize = .(0.0f, 0.0f);
	public float MinY = 0.0f;
	public float MaxY = 0.0f;

	/// Captures a runtime grid's METADATA, which is the cooking half. The samples are
	/// written separately, from HeightBlob.
	public static void FromHeightfield(Heightfield field, HeightfieldSource outSource)
	{
		outSource.Size = field.Size;
		outSource.WorldSize = field.WorldSize;
		outSource.MinY = field.MinY;
		outSource.MaxY = field.MaxY;
	}

	/// A grid's samples as raw bytes, to be written to the sidecar stream. BORROWED from the
	/// grid, which has to outlive the write.
	public static Span<uint8> HeightBlob(Heightfield field)
	{
		let samples = field.Samples;
		return .((uint8*)samples.Ptr, samples.Length * sizeof(uint16));
	}

	/// Builds the runtime grid from this metadata and the sidecar bytes.
	///
	/// An inconsistent cook, meaning an illegal size or a blob whose length does not match
	/// it, produces an EMPTY grid rather than a malformed one: an empty grid answers every
	/// query inertly, while a half filled one looks like terrain and is not.
	public Heightfield Build(Span<uint8> blob)
	{
		if (!Heightfield.IsValidSize(Size))
			return new Heightfield();

		let expected = (int)Size * (int)Size * sizeof(uint16);
		if (blob.Length != expected)
			return new Heightfield();

		let field = new Heightfield(Size, WorldSize, MinY, MaxY);
		Internal.MemCpy(field.Samples.Ptr, blob.Ptr, expected);
		return field;
	}
}
