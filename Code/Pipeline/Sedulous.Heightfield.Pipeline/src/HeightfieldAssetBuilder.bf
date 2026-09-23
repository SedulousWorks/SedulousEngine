using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;

namespace Sedulous.Heightfield.Pipeline;

/// Cooks a heightfield into its metadata object plus a heights stream.
class HeightfieldAssetBuilder : IAssetBuilder
{
	/// The smallest span anything here is allowed to have.
	private const float cMinSpan = 0.001f;

	public Type AssetType => typeof(HeightfieldAsset);

	/// The SERIALIZED cooked form rather than the runtime product, because the cook stamps this
	/// onto the instance and the runtime reconstructs by that name. The factory's product type
	/// is the runtime grid a bind matches, and the two differ on purpose, as they do for
	/// textures.
	public Type ProductType => typeof(HeightfieldSource);

	/// Two, since the cooked form changed from the runtime grid to its source; three since
	/// 2026-09-23, when the holes stream joined the heights, so every heightfield re-cooks.
	public int32 Version => 3;

	/// An EMBEDDED heightfield, meaning one with no file name, reads its authored heights
	/// sidecar, so the recipe hash has to chain those bytes: the envelope hash does not cover a
	/// sidecar, and a sculpt save has to re-cook. An IMPORTED one chains the heightmap file
	/// instead, which the implicit file name already covers.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let field = (HeightfieldAsset)asset;
		if (field.FileName.IsEmpty)
		{
			outDeps.AddSourceStream(HeightfieldSource.HeightStream);
			outDeps.AddSourceStream(HeightfieldSource.HoleStream);
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (HeightfieldAsset)asset;

		// The fields should already be valid, but they are snapped defensively so a malformed
		// asset still cooks a LEGAL grid rather than breaking the runtime's contracts further
		// down: the size onto the valid ladder, the footprint away from zero, since a zero span
		// turns the world to grid arithmetic into NaN and hands the physics engine a zero
		// scale, and the height range open, since a closed one quantises every sample to one
		// height and divides by zero on the way back.
		let size = Heightfield.IsValidSize(authored.Size)
			? authored.Size
			: Heightfield.NextValidSize(authored.Size);
		let worldSize = Float2((authored.WorldSize.X > cMinSpan) ? authored.WorldSize.X : cMinSpan,
			(authored.WorldSize.Y > cMinSpan) ? authored.WorldSize.Y : cMinSpan);
		let minY = authored.MinY;
		let maxY = (authored.MaxY > authored.MinY + cMinSpan) ? authored.MaxY
			: (authored.MinY + cMinSpan);

		let field = scope Heightfield(size, worldSize, minY, maxY);

		if (!authored.FileName.IsEmpty)
		{
			let bytes = scope List<uint8>();
			if (AssetSource.ReadBytes(context, authored.FileName.Value, bytes)
				case .Err(let readError))
			{
				return .Err(readError);
			}

			let image = scope Image();
			if (ImageIO.LoadImage16FromMemory(bytes, image) case .Err(let decodeError))
				return .Err(decodeError);

			HeightmapResample.ResampleR16((uint16*)image.PixelData.Ptr, image.Width, image.Height,
				field);
		}
		else if (context.Source != null)
		{
			// EMBEDDED: the authored sidecar is the truth, an empty file name being what marks
			// it authoritative. A missing or mismatched blob leaves the grid flat, which is a
			// heightfield created on a page and never sculpted.
			let stream = context.Source.ReadData(HeightfieldSource.HeightStream);
			if (stream != null)
			{
				defer delete stream;
				let streamSize = stream.Size();
				let expected = (int64)size * (int64)size * (int64)sizeof(uint16);
				if (streamSize == expected)
				{
					let samples = field.Samples;
					if (stream.Read(.((uint8*)samples.Ptr, (int)streamSize)) != (int)streamSize)
					{
						// A partial read: flat beats half a terrain.
						for (int i < samples.Length)
							samples[i] = 0;
					}
				}
			}

			// The authored HOLES sidecar, which the hole brush persists. Absent, meaning a
			// heightfield painted before holes existed, or mismatched, leaves the plane solid.
			let holeStream = context.Source.ReadData(HeightfieldSource.HoleStream);
			if (holeStream != null)
			{
				defer delete holeStream;
				let streamSize = holeStream.Size();
				if (streamSize == ((int64)size * (int64)size))
				{
					let plane = scope List<uint8>();
					plane.Resize((int)streamSize);
					if (holeStream.Read(.(plane.Ptr, (int)streamSize)) == (int)streamSize)
						field.SetHoles(plane);
				}
			}
		}

		let cooked = scope HeightfieldSource();
		HeightfieldSource.FromHeightfield(field, cooked);
		if (context.Output.WriteObject(cooked) case .Err(let writeError))
			return .Err(writeError);

		if (context.Output.WriteData(HeightfieldSource.HeightStream,
			HeightfieldSource.HeightBlob(field)) case .Err(let heightError))
		{
			return .Err(heightError);
		}

		// ALWAYS, which is the one layout rule: a solid plane is bytes too.
		return context.Output.WriteData(HeightfieldSource.HoleStream,
			HeightfieldSource.HoleBlob(field));
	}
}
