using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.VG.SVG;

namespace Sedulous.GUI.Hosting.Tests;

/// The GPU picture baker on the Null RHI backend: a picture asked for is queued, baked when the
/// frame records, and registered with every target renderer under its key; asked again it is that
/// key; a size of its own is a bake of its own; one no draw asks for goes in time; a target added
/// late learns the bakes, and one taken out forgets them. Small pictures go into an atlas: queued,
/// drawn on their page when the frame records, then their region; one too large is not taken, one
/// no draw asks for goes, and a full atlas is packed anew from the pictures asked for lately.
class PictureBakerTests
{
	/// A Null device, the GUI's renderer, a baker on it, and an encoder a frame records on.
	private class Bed
	{
		public NullRhiBed Rhi = new .();
		public VGRenderer Target = new .();
		public GpuPictureBaker Baker;
		public SVGDocument Document;

		public this()
		{
			Test.Assert(Target.Initialize(Rhi.Device, Rhi.Vs, Rhi.Fs, .BGRA8UnormSrgb, 2) case .Ok);
			Baker = new .(Rhi.Device, null);
			var setup = PictureBakerSetup();
			setup.VertexShader = Rhi.Vs;
			setup.FragmentShader = Rhi.Fs;
			setup.Format = .BGRA8UnormSrgb;
			Test.Assert(Baker.Initialize(setup) case .Ok);
			Baker.AddTarget(Target);
			Document = HostingFixtures.LoadPicture(HostingFixtures.cRedPicture);
			Test.Assert(Document != null);
		}

		public ~this()
		{
			Baker.Dispose();
			Target.Dispose();
			delete Baker;
			delete Target;
			delete Document;
			delete Rhi;
		}

		/// One frame: the baker records on an encoder of its own.
		public bool Frame(int32 frameIndex)
		{
			let encoder = Rhi.Encoder();
			let baked = Baker.Record(encoder, frameIndex);
			Rhi.Done(encoder);
			return baked;
		}
	}

	[Test]
	public static void APictureAskedForIsBakedWhenTheFrameRecordsThenDrawnFromItsKey()
	{
		let bed = scope Bed();
		Test.Assert(bed.Baker.Baked(bed.Document, 48, 24) == null); // queued
		Test.Assert(bed.Baker.BakeCount == 1);
		Test.Assert(bed.Baker.Generation == 0);
		Test.Assert(bed.Frame(0));
		Test.Assert(bed.Baker.Generation == 1); // the GUI redraws
		let key = bed.Baker.Baked(bed.Document, 48, 24);
		Test.Assert(key != null);
		Test.Assert(key.Width == 48);
		Test.Assert(key.Height == 24);
		Test.Assert(bed.Target.IsExternalTextureRegistered(key));
		Test.Assert(!bed.Frame(1)); // nothing new
		Test.Assert(bed.Baker.Generation == 1);

		// Another size is a bake of its own.
		Test.Assert(bed.Baker.Baked(bed.Document, 24, 12) == null);
		Test.Assert(bed.Frame(0));
		Test.Assert(bed.Baker.Baked(bed.Document, 24, 12) != null);
		Test.Assert(bed.Baker.Baked(bed.Document, 24, 12) != key);
		Test.Assert(bed.Baker.BakeCount == 2);
	}

	[Test]
	public static void ABakeNoDrawAsksForGoesAndTheGuisRendererForgetsIt()
	{
		let bed = scope Bed();
		bed.Baker.Baked(bed.Document, 48, 24);
		bed.Frame(0);
		let key = bed.Baker.Baked(bed.Document, 48, 24);
		Test.Assert(key != null);
		for (uint64 frame = 0; frame < GpuPictureBaker.cKeepFrames; frame++)
		{
			if (frame % 100 == 0)
				Test.Assert(bed.Baker.Baked(bed.Document, 48, 24) == key); // still asked for: kept
			bed.Frame((int32)(frame % 2));
		}
		Test.Assert(bed.Baker.BakeCount == 1);
		for (uint64 frame = 0; frame <= GpuPictureBaker.cKeepFrames; frame++)
			bed.Frame((int32)(frame % 2));
		Test.Assert(bed.Baker.BakeCount == 0);
		Test.Assert(!bed.Target.IsExternalTextureRegistered(key));
	}

	[Test]
	public static void ARendererAddedLateLearnsTheBakesOneTakenOutForgetsThem()
	{
		let bed = scope Bed();
		let second = scope VGRenderer();
		Test.Assert(second.Initialize(bed.Rhi.Device, bed.Rhi.Vs, bed.Rhi.Fs, .BGRA8UnormSrgb, 2) case .Ok);
		bed.Baker.Baked(bed.Document, 48, 24);
		bed.Frame(0);
		let key = bed.Baker.Baked(bed.Document, 48, 24);
		Test.Assert(key != null);
		Test.Assert(!second.IsExternalTextureRegistered(key));
		bed.Baker.AddTarget(second); // a window opened after the bake
		Test.Assert(second.IsExternalTextureRegistered(key));
		bed.Baker.Baked(bed.Document, 24, 12);
		bed.Frame(1);
		Test.Assert(second.IsExternalTextureRegistered(bed.Baker.Baked(bed.Document, 24, 12)));
		bed.Baker.RemoveTarget(second); // its window goes
		Test.Assert(!second.IsExternalTextureRegistered(key));
		Test.Assert(bed.Target.IsExternalTextureRegistered(key));
		second.Dispose();
	}

	/// Added in the port: a baker without the two shaders every draw needs refuses to start, and
	/// what is asked of it stays queued, never baked.
	[Test]
	public static void ABakerWithoutItsShadersRefusesToStartAndBakesNothing()
	{
		let rhi = scope NullRhiBed();
		let baker = scope GpuPictureBaker(rhi.Device, null);
		let started = baker.Initialize(PictureBakerSetup());
		Test.Assert(started case .Err);
		if (started case .Err(let error))
			Test.Assert(error == .InvalidArgument);
		let document = HostingFixtures.LoadPicture(HostingFixtures.cSquarePicture);
		defer delete document;
		Test.Assert(baker.Baked(document, 16, 16) == null); // queued
		let encoder = rhi.Encoder();
		Test.Assert(!baker.Record(encoder, 0));
		rhi.Done(encoder);
		Test.Assert(baker.Generation == 0);
		Test.Assert(baker.BakeCount == 1);
		Test.Assert(baker.Baked(document, 16, 16) == null); // still waiting
	}

	[Test]
	public static void AnIconAskedForInTheAtlasIsQueuedBakedOnItsPageWhenTheFrameRecordsThenItsRegion()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Baker.AtlasRegion(bed.Document, 24, 12, true).HasValue); // queued
		Test.Assert(bed.Baker.AtlasPictureCount == 1);
		Test.Assert(bed.Frame(0));
		Test.Assert(bed.Baker.Generation == 1);
		let region = bed.Baker.AtlasRegion(bed.Document, 24, 12, true);
		Test.Assert(region.HasValue);
		Test.Assert(region.Value.Page != null);
		Test.Assert(region.Value.Page.Width == GpuPictureBaker.cAtlasPageSize);
		Test.Assert(HostingFixtures.Near(region.Value.Source.Width, 24.0f));
		Test.Assert(HostingFixtures.Near(region.Value.Source.Height, 12.0f));
		Test.Assert(region.Value.Source.X >= (float)GpuPictureBaker.cAtlasGutter); // inside its gutter
		Test.Assert(bed.Target.IsExternalTextureRegistered(region.Value.Page));

		// The same picture as authored is a bake of its own, on the same page, beside it.
		Test.Assert(!bed.Baker.AtlasRegion(bed.Document, 24, 12, false).HasValue);
		Test.Assert(bed.Frame(1));
		let coloured = bed.Baker.AtlasRegion(bed.Document, 24, 12, false);
		Test.Assert(coloured.HasValue);
		Test.Assert(coloured.Value.Page == region.Value.Page);
		Test.Assert(!HostingFixtures.Near(coloured.Value.Source.X, region.Value.Source.X));
		Test.Assert(bed.Baker.AtlasPageCount == 1);
		Test.Assert(!bed.Frame(0)); // nothing new
	}

	[Test]
	public static void APictureLargerThanAnAtlasKeepsIsNotTakenOneNoDrawAsksForGoes()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Baker.AtlasRegion(bed.Document, PictureRegion.cLargestAtlasPicture + 1, 12, true).HasValue);
		Test.Assert(bed.Baker.AtlasPictureCount == 0);
		bed.Baker.AtlasRegion(bed.Document, 24, 12, true);
		bed.Frame(0);
		for (uint64 frame = 0; frame <= GpuPictureBaker.cKeepFrames + 1; frame++)
			bed.Frame((int32)(frame % 2));
		Test.Assert(bed.Baker.AtlasPictureCount == 0);
	}

	[Test]
	public static void AFullAtlasIsPackedAnewFromThePicturesAskedForLately()
	{
		let bed = scope Bed();
		// Pictures of the largest size an atlas keeps, each its own document: every page full.
		let side = PictureRegion.cLargestAtlasPicture;
		let perRow = (int)(GpuPictureBaker.cAtlasPageSize / (side + 2 * GpuPictureBaker.cAtlasGutter));
		let fit = perRow * perRow * GpuPictureBaker.cMostAtlasPages;
		let documents = scope List<SVGDocument>();
		defer { ClearAndDeleteItems!(documents); }
		for (int i = 0; i <= fit; i++)
		{
			let document = HostingFixtures.LoadPicture(HostingFixtures.cSquarePicture);
			Test.Assert(document != null);
			documents.Add(document);
		}
		for (int i = 0; i < fit; i++)
			bed.Baker.AtlasRegion(documents[i], side, side, true);
		Test.Assert(bed.Baker.AtlasPictureCount == fit);
		Test.Assert(bed.Baker.AtlasPageCount == GpuPictureBaker.cMostAtlasPages);
		// Long after, only the first asked for still; then one more than fits: packed anew round it.
		for (uint64 frame = 0; frame <= GpuPictureBaker.cRecentFrames + 1; frame++)
		{
			bed.Baker.AtlasRegion(documents[0], side, side, true);
			bed.Frame((int32)(frame % 2));
		}
		bed.Baker.AtlasRegion(documents[fit], side, side, true);
		Test.Assert(bed.Baker.AtlasPictureCount == 2);
		bed.Frame(0);
		Test.Assert(bed.Baker.AtlasRegion(documents[0], side, side, true).HasValue); // drawn again
		Test.Assert(bed.Baker.AtlasRegion(documents[fit], side, side, true).HasValue);
	}
}
