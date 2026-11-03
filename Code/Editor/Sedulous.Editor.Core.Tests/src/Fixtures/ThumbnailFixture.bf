using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// A service over one known instance, a stub generator counting its calls, and a job
/// service to pump. An EMPTY mount: the database scans it, and a null serializer factory
/// stays uninvoked only when the scan finds no envelopes.
class ThumbnailFixture
{
	public String CacheDir = new .() ~ delete _;
	public String MountDir = new .() ~ delete _;
	public NativeFileSystem Mount ~ delete _;
	public ContentDatabase Db ~ delete _;
	public Instance Instance ~ delete _;
	public TaskPool Tasks = new .(1) ~ delete _;
	public TaskLane Light = Tasks.CreateLane("Light");
	public ThumbnailService Service = new .() ~ delete _;
	public Guid Known;
	public int Prepares = 0;
	public int Generates = 0;
	/// The content hash the service sees (0: not cooked yet).
	public uint64 Hash;

	/// `generatorHash` is what a GPU generator names the asset's content by (a document no builder
	/// cooks); nought leaves it to `hash`.
	public this(StringView cacheDir, uint64 hash = 0x77, bool failGenerate = false, bool gpu = false, uint64 generatorHash = 0)
	{
		Hash = hash;
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), cacheDir, CacheDir);
		CreateDirectory(CacheDir);
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), "thumbs_empty_mount", MountDir);
		CreateDirectory(MountDir);
		Mount = new NativeFileSystem(MountDir);
		Db = new ContentDatabase(Mount, null, "asset");
		Known = gpu ? Guid.Parse("00003333-0000-0000-0000-000000004444").Get() : Guid.Parse("00001111-0000-0000-0000-000000002222").Get();
		Instance = new Instance(Db, Db.RootGroup, Known, gpu ? "StubGpu" : "Stub", gpu ? "StubGpuAsset" : "StubAsset");
		if (gpu)
		{
			Service.RegisterSceneGenerator(new StubSceneThumbnailGenerator("StubGpuAsset", false, generatorHash));
		}
		else
		{
			let generator = new StubThumbnailGenerator();
			generator.PrepareCount = &Prepares;
			generator.GenerateCount = &Generates;
			generator.FailGenerate = failGenerate;
			Service.RegisterGenerator(generator);
		}
		Service.Configure(CacheDir, new (id) => (id == Known) ? Instance : null, Tasks, Light, new (id) => Hash, MountDir);
	}

	/// Pumps the light lane to completion; bounded so a hang fails.
	public void PumpLight()
	{
		for (int guard < 8)
		{
			Tasks.Finish(); // waits for the lane's tasks, then hands them back
			if (Tasks.InFlight == 0)
				break;
		}
	}
}
