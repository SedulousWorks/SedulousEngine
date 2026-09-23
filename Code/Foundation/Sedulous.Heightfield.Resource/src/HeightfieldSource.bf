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
/// A payload written under any other version is refused rather than guessed at.
///
/// Version two, 2026-09-23, added the holes stream beside the heights. Every cooked
/// heightfield carries BOTH, which is the one layout rule: a version one product is refused
/// and re-cooked rather than migrated, an absent plane being indistinguishable from a solid
/// one only until someone cuts a hole.
[Serializable(2)]
class HeightfieldSource
{
	/// The sidecar stream carrying the raw samples.
	public const String HeightStream = "heights";
	/// The per sample hole plane, one byte per sample with nought solid and 255 cut, ALWAYS
	/// written beside the heights: an all zero plane is the common file, and one layout is
	/// cheaper to reason about than an optional one.
	public const String HoleStream = "holes";

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

	/// A grid's hole plane as raw bytes, to be written to its own sidecar stream. BORROWED
	/// from the grid, which has to outlive the write.
	public static Span<uint8> HoleBlob(Heightfield field) => field.Holes;

	/// Builds the runtime grid from this metadata and the two sidecar streams.
	///
	/// An inconsistent cook, meaning an illegal size, a height blob whose length does not
	/// match it, or a hole blob that does not, produces an EMPTY grid rather than a malformed
	/// one: an empty grid answers every query inertly, while a half filled one looks like
	/// terrain and is not.
	public Heightfield Build(Span<uint8> heightBlob, Span<uint8> holeBlob)
	{
		if (!Heightfield.IsValidSize(Size))
			return new Heightfield();

		let samples = (int)Size * (int)Size;
		if ((heightBlob.Length != (samples * sizeof(uint16))) || (holeBlob.Length != samples))
			return new Heightfield();

		let field = new Heightfield(Size, WorldSize, MinY, MaxY);
		Internal.MemCpy(field.Samples.Ptr, heightBlob.Ptr, samples * sizeof(uint16));
		field.SetHoles(holeBlob);
		return field;
	}
}
