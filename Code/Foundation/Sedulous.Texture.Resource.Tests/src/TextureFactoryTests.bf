using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Resource.Tests;

/// The whole runtime load: a cooked record and its pixel stream in a content database,
/// through the manager, onto a device.
class TextureFactoryTests
{
	[Test]
	public static void ACookedRecordBecomesALiveTexture()
	{
		let fixture = scope TextureFixture("scratch_texture_factory");
		let id = fixture.AuthorSimple("tex");

		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let texture = manager.Bind<Texture>(id);
		Test.Assert(texture.State == .Ready);
		Test.Assert(texture.Get != null);

		Test.Assert(texture.Get.Width == 2);
		Test.Assert(texture.Get.Height == 2);
		Test.Assert(texture.Get.Format == .RGBA8UnormSrgb);
		Test.Assert(texture.Get.GpuTexture != null);
		Test.Assert(texture.Get.View != null, "the default sampled view a material binds");
		Test.Assert(texture.Get.Sampler != null);
		Test.Assert(!texture.Get.IsCube);
		Test.Assert(texture.Get.Uid != 0, "adopted, so it has an identity");
	}

	/// Binding the same identity twice shares one product, so the GPU texture is created
	/// once rather than per caller.
	[Test]
	public static void BindingTwiceSharesOneProduct()
	{
		let fixture = scope TextureFixture("scratch_texture_shared");
		let id = fixture.AuthorSimple("tex");

		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let first = manager.Bind<Texture>(id);
		let second = manager.Bind<Texture>(id);
		Test.Assert(first.Get == second.Get);
		Test.Assert(first.Get.Uid == second.Get.Uid);
	}

	/// A cube asset gets a real cube VIEW, so a skybox can be sampled as one rather than
	/// as six unrelated layers.
	[Test]
	public static void ACubeRecordBuildsACubeView()
	{
		let fixture = scope TextureFixture("scratch_texture_cube");

		let record = scope TextureResource();
		record.Width = 4;
		record.Height = 4;
		record.Shape = .Cubemap;
		record.Format = .RGBA8Unorm;

		let pixels = scope List<uint8>();
		pixels.Resize(4 * 4 * 4 * 6);
		let id = fixture.Author("sky", record, pixels);

		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let texture = manager.Bind<Texture>(id);
		Test.Assert(texture.Get != null);
		Test.Assert(texture.Get.IsCube);
		Test.Assert(texture.Get.View != null);
		Test.Assert(texture.Get.Width == 4);
	}

	/// A record with no pixel stream still builds. The record describes a texture, and an
	/// empty payload uploads nothing rather than failing the whole load.
	[Test]
	public static void ARecordWithNoPixelsStillBuilds()
	{
		let fixture = scope TextureFixture("scratch_texture_nopixels");

		let record = scope TextureResource();
		record.Width = 8;
		record.Height = 8;
		let id = fixture.Author("blank", record, .());

		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let texture = manager.Bind<Texture>(id);
		Test.Assert(texture.Get != null);
		Test.Assert(texture.Get.GpuTexture != null);
		Test.Assert(texture.Get.Width == 8);
	}

	/// Something else stored under a texture's type name is not a texture. The build fails
	/// rather than handing back a product that would fault later, somewhere less obvious.
	[Test]
	public static void AnInstanceHoldingSomethingElseFailsToBuild()
	{
		let fixture = scope TextureFixture("scratch_texture_wrongtype");

		// An instance whose stored type name resolves to nothing this registry knows.
		let instance = fixture.Database.RootGroup.CreateInstance("stranger", "demo.NotATexture");
		let record = scope TextureResource();
		record.Width = 2;
		record.Height = 2;
		instance.WriteObject(record).IgnoreError();

		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let texture = manager.Bind<Texture>(instance.Id);
		Test.Assert(texture.Get == null, "no product came back");
		Test.Assert(texture.State == .Failed, "tried and failed, which is not never tried");
		Test.Assert(!texture.IsNull, "but the handle stays, so a recook can fill it in");
	}

	/// An identity nothing was authored under fails rather than building an empty texture.
	[Test]
	public static void AMissingInstanceFails()
	{
		let fixture = scope TextureFixture("scratch_texture_missing");
		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(fixture.Textures);

		let texture = manager.Bind<Texture>(.Create());
		Test.Assert(texture.Get == null);
		Test.Assert(texture.State == .Failed, "no instance is a failure, not an empty texture");
	}

	/// The async path decodes on a worker and uploads on the main thread, and must land on
	/// the same product the synchronous path does.
	[Test]
	public static void TheAsyncLoadMatchesTheSynchronousOne()
	{
		let jobs = scope JobSystem(2);
		let fixture = scope TextureFixture("scratch_texture_async");
		let id = fixture.AuthorSimple("tex", 4, 2);

		let syncManager = scope ResourceManager(fixture.Database);
		syncManager.AddFactory(fixture.Textures);
		let reference = syncManager.Bind<Texture>(id);
		Test.Assert(reference.Get != null);

		let asyncManager = scope ResourceManager(fixture.Database, jobs);
		asyncManager.AddFactory(fixture.Textures);
		let loaded = asyncManager.BindAsync<Texture>(id);
		asyncManager.WaitAll();

		Test.Assert(loaded.Get != null);
		Test.Assert(loaded.State == .Ready);

		// The null backend has no readback, so the equivalence check is the descriptor and
		// live GPU objects: the record and the upload path are the same code either way.
		Test.Assert(loaded.Get.Width == reference.Get.Width);
		Test.Assert(loaded.Get.Height == reference.Get.Height);
		Test.Assert(loaded.Get.Format == reference.Get.Format);
		Test.Assert(loaded.Get.GpuTexture != null);
		Test.Assert(loaded.Get.Sampler != null);
		Test.Assert(loaded.Get.Uid != reference.Get.Uid, "two products, two identities");
	}

	/// Many at once, which is what a level load looks like: every decode reads the content
	/// database and the registries concurrently.
	[Test]
	public static void ManyConcurrentAsyncLoadsAllArrive()
	{
		let jobs = scope JobSystem(4);
		let fixture = scope TextureFixture("scratch_texture_concurrent");

		let ids = scope List<Guid>();
		for (int i = 0; i < 12; i++)
			ids.Add(fixture.AuthorSimple(scope $"tex{i:00}"));

		let manager = scope ResourceManager(fixture.Database, jobs);
		manager.AddFactory(fixture.Textures);

		let textures = scope List<Proxy<Texture>>();
		for (let id in ids)
			textures.Add(manager.BindAsync<Texture>(id));
		manager.WaitAll();

		for (let texture in textures)
		{
			Test.Assert(texture.Get != null);
			Test.Assert(texture.State == .Ready);
			Test.Assert(texture.Get.Width == 2);
			Test.Assert(texture.Get.GpuTexture != null);
		}
	}
}
