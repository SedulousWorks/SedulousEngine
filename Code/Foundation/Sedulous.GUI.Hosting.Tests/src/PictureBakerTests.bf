using System;
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
/// late learns the bakes, and one taken out forgets them.
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
}
