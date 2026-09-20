using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The thumbnail service: icon first then one ready signal, negatives, the content hash disk
/// cache, RAM only on an unknown hash, a corrupt file self healing; and the GPU lane's one in
/// flight queue, its negatives, its disk round trip, Reset, and routing by type.
static class ThumbnailServiceTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	[Test]
	public static void IconFirstThenTheDrawableAndOneReadySignal()
	{
		Scratch("thumbs_happy", .. scope .());
		let f = scope ThumbnailFixture("thumbs_happy");
		int ready = 0;
		f.Service.OnThumbnailReady = new [&ready](id) => { ready++; };
		Test.Assert(f.Service.Get(f.Known) == null, "a miss schedules; the caller keeps its icon");
		f.PumpLight();
		let thumb = f.Service.Get(f.Known);
		Test.Assert(thumb != null);
		Test.Assert((ready == 1) && (f.Generates == 1));
		Test.Assert(f.Service.Get(f.Known) == thumb, "a stable instance, no rescheduling");
	}

	[Test]
	public static void NegativesNeverReschedule()
	{
		Scratch("thumbs_negative", .. scope .());
		Scratch("thumbs_fail", .. scope .());
		let f = scope ThumbnailFixture("thumbs_negative");
		let unknown = Guid.Parse("00000009-0000-0000-0000-000000000009").Get();
		Test.Assert(f.Service.Get(unknown) == null);
		Test.Assert(f.Service.Get(unknown) == null);
		Test.Assert((f.Service.CachedCount == 1) && (f.Prepares == 0), "an unknown id: a negative, no job");

		let g = scope ThumbnailFixture("thumbs_fail", 0x77, true);
		Test.Assert(g.Service.Get(g.Known) == null);
		g.PumpLight();
		Test.Assert(g.Service.Get(g.Known) == null);
		Test.Assert(g.Generates == 1);
		g.PumpLight();
		Test.Assert(g.Generates == 1, "the negative held");
		g.Service.Invalidate(g.Known);
		Test.Assert(g.Service.Get(g.Known) == null);
		g.PumpLight();
		Test.Assert(g.Generates == 2, "Invalidate re-arms");
	}

	[Test]
	public static void TheContentHashDiskCacheRoundTripsWithoutRegenerating()
	{
		Scratch("thumbs_disk", .. scope .());
		{
			let f = scope ThumbnailFixture("thumbs_disk", 0xabc);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert((f.Service.Get(f.Known) != null) && (f.Generates == 1));
		}
		{
			// A fresh service, a new session: the file serves; neither Generate nor Prepare.
			let f = scope ThumbnailFixture("thumbs_disk", 0xabc);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert((f.Service.Get(f.Known) != null) && (f.Generates == 0) && (f.Prepares == 0));
		}
		{
			// A DIFFERENT hash, the content changed: the old file mismatches; regenerate.
			let f = scope ThumbnailFixture("thumbs_disk", 0xdef);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert((f.Service.Get(f.Known) != null) && (f.Generates == 1));
		}
	}

	[Test]
	public static void AnUnknownContentHashIsRamOnly()
	{
		Scratch("thumbs_ram", .. scope .());
		{
			let f = scope ThumbnailFixture("thumbs_ram", 0);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert((f.Service.Get(f.Known) != null) && (f.Generates == 1));
		}
		{
			let f = scope ThumbnailFixture("thumbs_ram", 0);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert(f.Generates == 1, "nothing persisted: a fresh session regenerates");
		}
	}

	[Test]
	public static void ACorruptCacheFileSelfHeals()
	{
		Scratch("thumbs_corrupt", .. scope .());
		let path = scope String();
		{
			let f = scope ThumbnailFixture("thumbs_corrupt", 0x55);
			f.Service.Get(f.Known);
			f.PumpLight();
			Test.Assert(f.Service.Get(f.Known) != null);
			path.AppendF("{}/{}-{}.png", f.CacheDir, f.Known, (uint64)0x55);
			Test.Assert(FileExists(path));
		}
		// Corrupted: the load fails, and since the file existed Prepare was skipped, which
		// once cached a silent PERMANENT negative.
		let junk = "junk";
		Test.Assert(WriteFile(path, .((uint8*)junk.Ptr, junk.Length)) case .Ok);
		{
			let f = scope ThumbnailFixture("thumbs_corrupt", 0x55);
			Test.Assert(f.Service.Get(f.Known) == null);
			f.PumpLight();
			Test.Assert(!FileExists(path), "the stale file was deleted");
			Test.Assert(f.Service.CachedCount == 0, "and NOTHING was cached");
			Test.Assert(f.Service.Get(f.Known) == null);
			f.PumpLight();
			Test.Assert((f.Service.Get(f.Known) != null) && (f.Generates == 1));
			Test.Assert(FileExists(path), "rewritten");
		}
	}

	private static Image SolidTile(uint8 red)
	{
		let image = new Image();
		StubThumbnailGenerator.SolidTile(red, image);
		return image;
	}

	[Test]
	public static void ASceneGeneratedTypeQueuesOneGpuJobOnMiss()
	{
		Scratch("thumbs_gpu_queue", .. scope .());
		let fx = scope ThumbnailFixture("thumbs_gpu_queue", 0x99, false, true);
		Test.Assert(fx.Service.SceneGeneratorCount == 1);
		Test.Assert(fx.Service.Get(fx.Known) == null, "a miss: queued for the stage");
		Test.Assert(fx.Service.QueuedSceneJobs == 1);
		Test.Assert(fx.Service.Get(fx.Known) == null);
		Test.Assert(fx.Service.QueuedSceneJobs == 1, "a re-query does not duplicate");
		let job = fx.Service.TakeSceneJob();
		Test.Assert((job.Id == fx.Known) && (job.Generator != null));
		Test.Assert(fx.Service.TakeSceneJob().IsEmpty, "one job in flight at a time");
		Test.Assert(fx.Service.Get(fx.Known) == null);
		Test.Assert(fx.Service.QueuedSceneJobs == 1, "the taken job still counts, no re-queue");
		int ready = 0;
		fx.Service.OnThumbnailReady = new [&ready](id) => { ready++; };
		fx.Service.AcceptSceneResult(fx.Known, SolidTile(180), true);
		Test.Assert(ready == 1);
		Test.Assert(fx.Service.Get(fx.Known) != null, "published immediately");
		Test.Assert(fx.Service.QueuedSceneJobs == 0);
		fx.PumpLight();
		bool fileExists = false;
		ListDirectory(fx.CacheDir, scope [&](name, isDirectory) => { if (name.EndsWith(".png")) fileExists = true; });
		Test.Assert(fileExists, "the PNG persisted on the light lane");
	}

	[Test]
	public static void AFailedStageResultCachesANegativeAndNeverRequeues()
	{
		Scratch("thumbs_gpu_fail", .. scope .());
		let fx = scope ThumbnailFixture("thumbs_gpu_fail", 0x99, false, true);
		fx.Service.Get(fx.Known);
		let job = fx.Service.TakeSceneJob();
		Test.Assert(job.Id == fx.Known);
		fx.Service.AcceptSceneResult(fx.Known, new Image(), false);
		Test.Assert(fx.Service.Get(fx.Known) == null);
		Test.Assert(fx.Service.QueuedSceneJobs == 0, "the negative stopped rescheduling");
	}

	[Test]
	public static void TheSceneGeneratedDiskCacheRoundTripsThroughTheLightLane()
	{
		Scratch("thumbs_gpu_disk", .. scope .());
		{
			let fx = scope ThumbnailFixture("thumbs_gpu_disk", 0x99, false, true);
			fx.Service.Get(fx.Known);
			fx.Service.TakeSceneJob();
			fx.Service.AcceptSceneResult(fx.Known, SolidTile(90), true);
			fx.PumpLight();
		}
		// A fresh service, the same cache and hash: the file serves on the LIGHT lane and
		// the GPU queue is never touched.
		let fx = scope ThumbnailFixture("thumbs_gpu_disk", 0x99, false, true);
		Test.Assert(fx.Service.Get(fx.Known) == null, "scheduled, not yet loaded");
		Test.Assert(fx.Service.QueuedSceneJobs == 0);
		fx.PumpLight();
		Test.Assert(fx.Service.Get(fx.Known) != null);
		Test.Assert(fx.Service.QueuedSceneJobs == 0);
	}

	[Test]
	public static void ResetClearsTheGpuQueueAndDropsATakenJobsResult()
	{
		Scratch("thumbs_gpu_reset", .. scope .());
		let fx = scope ThumbnailFixture("thumbs_gpu_reset", 0x99, false, true);
		fx.Service.Get(fx.Known);
		let job = fx.Service.TakeSceneJob();
		Test.Assert(job.Id == fx.Known);
		fx.Service.Reset();
		Test.Assert(fx.Service.QueuedSceneJobs == 0);
		fx.Service.AcceptSceneResult(job.Id, SolidTile(50), true);
		Test.Assert(fx.Service.CachedCount == 0, "dropped, not published");
	}

	[Test]
	public static void JobsRouteToTheGeneratorCoveringTheAssetsType()
	{
		Scratch("thumbs_gpu_route", .. scope .());
		let fx = scope ThumbnailFixture("thumbs_gpu_route", 0x99, false, true);
		fx.Service.RegisterSceneGenerator(new StubSceneThumbnailGenerator("OtherGpuAsset", true));
		Test.Assert(fx.Service.SceneGeneratorCount == 2);
		Test.Assert(fx.Service.Get(fx.Known) == null);
		let job = fx.Service.TakeSceneJob();
		Test.Assert(job.Generator != null);
		let names = scope List<StringView>();
		job.Generator.AssetTypeNames(names);
		Test.Assert((names[0] == "StubGpuAsset") && !job.Generator.NeedsPrivateScene, "the stub, not the other");
		let framing = ThumbnailFraming();
		Test.Assert((framing.Radius == 1.0f) && !framing.PreferSceneCamera && (framing.PrewarmSteps == 0));
		fx.Service.Reset();
	}
}
