using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Fonts;
using Sedulous.Fonts.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Fonts.Resource.Tests;

/// A scratch mount, a content database over it, and a manager with the font factory
/// registered. The whole stack, so nothing here is measured against a stand-in.
class FontFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;
	public FontFactory Fonts = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView root, JobSystem jobs = null)
	{
		FontResources.RegisterAll();

		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset");
		Manager = new ResourceManager(Database, jobs);
		Manager.AddFactory(Fonts);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Authors a two entry record: one 'A' glyph with one kerning pair per entry, over 2x2
	/// atlases, baked at 12 and 24 pixels.
	///
	/// Two entries and two sizes because that is the least that makes "closest" mean
	/// anything, and 2x2 atlases because what is under test is the plumbing of the tables
	/// and the pixel slices, not the pixels.
	public static void Author(FontResource record, FontResourcePixels mode,
		float oversample = 1.0f)
	{
		record.Family.Set("TestFamily");
		record.Pixels = (uint32)mode;

		let bytesPerPixel = (mode == .DistanceField) ? 4 : 1;

		for (uint32 i < 2)
		{
			let pixelHeight = (i == 0) ? 12.0f : 24.0f;

			record.EntryPixelHeight.Add(pixelHeight);
			record.EntryAscent.Add(pixelHeight * 0.8f);
			record.EntryDescent.Add(-pixelHeight * 0.2f);
			record.EntryLineGap.Add(1.0f);
			record.EntryScale.Add(1.0f);

			record.EntryAtlasWidth.Add(2);
			record.EntryAtlasHeight.Add(2);
			record.EntryWhitePixelU.Add(0.25f);
			record.EntryWhitePixelV.Add(0.25f);
			record.EntryDistanceFieldRange.Add(3.0f);
			record.EntryOversampleX.Add(oversample);
			record.EntryOversampleY.Add(oversample);

			record.EntryPixelOffset.Add((uint64)i * 4 * (uint64)bytesPerPixel);
			record.EntryPixelBytes.Add(4 * (uint64)bytesPerPixel);

			let advance = pixelHeight * 0.5f;

			record.GlyphCodepoint.Add((int32)'A');
			record.GlyphIndex.Add(1);
			record.GlyphAdvanceWidth.Add(advance);
			record.GlyphLeftSideBearing.Add(0);
			record.GlyphBoundsX.Add(0);
			record.GlyphBoundsY.Add(0);
			record.GlyphBoundsWidth.Add(2);
			record.GlyphBoundsHeight.Add(2);
			record.GlyphHasBitmap.Add(true);
			record.EntryGlyphCount.Add(1);

			record.KerningFirst.Add((int32)'A');
			record.KerningSecond.Add((int32)'V');
			record.KerningAmount.Add(-1.5f);
			record.EntryKerningCount.Add(1);

			record.RegionCodepoint.Add((int32)'A');
			record.RegionX.Add(0);
			record.RegionY.Add(0);
			record.RegionWidth.Add(2);
			record.RegionHeight.Add(2);
			record.RegionOffsetX.Add(0);
			record.RegionOffsetY.Add(-pixelHeight * 0.8f);
			record.RegionAdvanceX.Add(advance);
			record.EntryRegionCount.Add(1);
		}
	}

	/// Writes an authored record plus its concatenated atlas payload, and returns the
	/// identity to bind by.
	public Guid Cook(StringView name, FontResourcePixels mode, Span<uint8> pixels,
		float oversample = 1.0f)
	{
		let instance = Database.RootGroup.CreateInstance(name, "Sedulous.Fonts.Resource.FontResource");

		let record = scope FontResource();
		Author(record, mode, oversample);
		instance.WriteObject(record).IgnoreError();
		instance.WriteData("data", pixels).IgnoreError();

		return instance.Id;
	}

	/// The default coverage payload: two entries of four alpha texels, each texel a
	/// distinct value so a slice landing at the wrong offset is visible.
	public static void CoveragePixels(List<uint8> outPixels)
	{
		outPixels.Clear();
		for (int i < 8)
			outPixels.Add((uint8)(0x10 * (i + 1)));
	}

	/// The default distance field payload: two entries of four RGBA texels, numbered so a
	/// slice landing at the wrong offset is visible.
	public static void DistanceFieldPixels(List<uint8> outPixels)
	{
		outPixels.Clear();
		for (int i < (2 * 4 * 4))
			outPixels.Add((uint8)i);
	}
}
