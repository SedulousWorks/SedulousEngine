using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Texture;
using Sedulous.Texture.Resource;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Particles.Pipeline.Tests;

/// An AUTHORED effect through the cook and back.
///
/// Authored rather than imported: there is no source file, so what the builder does is clone a
/// graph of polymorphic modules and resolve its soft references, and both halves have to
/// survive for the effect to simulate on the other side.
class ParticleEffectCookTests
{
	private const String cRoot = "scratch_particles_pipeline";
	private const String cEffectType = "Sedulous.Particles.Resource.ParticleEffectResource";
	private const String cTextureType = "Sedulous.Texture.Resource.TextureResource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	private static void Register()
	{
		ParticlesPipeline.RegisterAll();
		ParticleResources.RegisterAll();
		ParticleModules.RegisterModules();
		TextureResources.RegisterAll();
	}

	[Test]
	public static void AnAuthoredEffectCooksLoadsBackAndSimulates()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		Register();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("smoke", cEffectType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope ParticleEffectAsset();
			let system = asset.Effect.AddSystem(1000, 777);
			system.Name.Set("smoke");
			system.BlendMode = .Alpha;
			system.Emitter.SpawnRate = 40.0f;
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(2.0f, 3.0f);
			system.AddInitializer<SizeInitializer>().Size = .Constant(.(1.0f, 1.0f));
			system.AddBehavior<DragBehavior>().Drag = 0.3f;
			system.AddBehavior<SizeOverLifetimeBehavior>().Size = .Ease(1, 3); // an eased size, both axes

			let builder = scope ParticleEffectAssetBuilder();
			Test.Assert(builder.AssetType == typeof(ParticleEffectAsset));

			let context = scope AssetBuildContext();
			context.Output = instance;
			context.Database = database;
			context.Serializers = serializers;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope ParticleEffectFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<ParticleEffectResource>(id);
		let resource = bound.Get;
		Test.Assert(resource != null);
		Test.Assert(resource.Effect.SystemCount == 1);

		let system = resource.Effect.GetSystem(0);
		Test.Assert(system != null);
		Test.Assert(system.MaxParticles == 1000);
		Test.Assert(system.Seed == 777);
		Test.Assert(system.BlendMode == .Alpha);
		Test.Assert(Near(system.Emitter.SpawnRate, 40.0f));
		Test.Assert(system.InitializerCount == 2);
		Test.Assert(system.BehaviorCount == 2);

		// And it RUNS: a clone whose modules came back as the wrong types spawns nothing.
		let instance = scope ParticleEffectInstance(resource.Effect);
		instance.Update(0.1f);
		Test.Assert(system.AliveCount > 0);
	}

	/// A system's texture is an edit time PATH, which the build resolves to the cooked
	/// texture's identity, and the factory then binds to a live proxy.
	[Test]
	public static void ATexturePathResolvesToAnIdentityAndBinds()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		Register();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid effectId;
		Guid textureId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");

			let textureInstance = database.RootGroup.CreateInstance("smoketex", cTextureType);
			Test.Assert(textureInstance != null);
			textureId = textureInstance.Id;

			let record = scope TextureResource();
			record.Width = 2;
			record.Height = 2;
			record.Format = .RGBA8Unorm;
			Test.Assert(textureInstance.WriteObject(record) case .Ok);
			let pixels = scope uint8[2 * 2 * 4];
			Test.Assert(textureInstance.WriteData("data", pixels) case .Ok);

			let effectInstance = database.RootGroup.CreateInstance("effect", cEffectType);
			Test.Assert(effectInstance != null);
			effectId = effectInstance.Id;

			let asset = scope ParticleEffectAsset();
			let system = asset.Effect.AddSystem(500);
			system.RenderMode = .Billboard;
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f);
			asset.SetSystemTexturePath(0, "smoketex");

			let context = scope AssetBuildContext();
			context.Output = effectInstance;
			context.Database = database;
			context.Serializers = serializers;
			Test.Assert(scope ParticleEffectAssetBuilder().Build(asset, context) case .Ok);
		}

		// Headless GPU: the null device gives the texture factory a device to build through.
		//
		// DECLARED FIRST so it is freed LAST: the manager's cached products release their GPU
		// objects THROUGH this device when they go.
		let device = scope NullDevice();
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let effects = scope ParticleEffectFactory();
		let textures = scope TextureFactory(device);
		manager.AddFactory(effects);
		manager.AddFactory(textures);

		let bound = manager.Bind<ParticleEffectResource>(effectId);
		let resource = bound.Get;
		Test.Assert(resource != null);

		// The path became the texture's cooked identity during the build...
		Test.Assert(resource.Effect.GetSystem(0).TextureRef == textureId);
		// ...and the factory bound it to a live proxy that a hot reload would follow.
		let texture = resource.SystemTexture(0);
		Test.Assert(texture.Get != null);
		Test.Assert(texture.Get.GpuTexture != null);
	}

	/// Its builder's version moved with the product's (each system its sub-emitters), which is what
	/// cooks the old products again: the recipe folds the version in.
	[Test]
	public static void TheBuildersVersionMovedWithTheProducts()
	{
		Test.Assert(scope ParticleEffectAssetBuilder().Version == 6);
		Test.Assert(ParticleEffectResource.DataVersion == 2);
		Test.Assert(ParticleEffectAsset.DataVersion == 1);
	}

	// A fixture beside this project's sources, found up from where the tests run.
	private static bool Fixture(StringView name, String outText)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			for (let under in StringView[2]("Code/Pipeline/Sedulous.Particles.Pipeline.Tests", "Pipeline/Sedulous.Particles.Pipeline.Tests"))
			{
				let file = PathJoin(PathJoin(dir, under, .. scope .()), name, .. scope .());
				if (FileExists(file))
					return System.IO.File.ReadAllText(file, outText) case .Ok;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	// The fixture read through an instance's envelope as an editor reads an authored one, its guid
	// the instance's (OWNED by the caller), or null with the reason.
	private static ParticleEffectAsset ReadFixture(StringView name, String outReason)
	{
		let text = scope String();
		Test.Assert(Fixture(name, text), scope String(name));
		RemoveDirectoryRecursive("scratch_pfx_v0_db");
		CreateDirectory("scratch_pfx_v0_db");
		defer { RemoveDirectoryRecursive("scratch_pfx_v0_db"); }
		let mount = scope NativeFileSystem("scratch_pfx_v0_db");
		SerializerFactory serializers = scope (stream, mode) => new XmlSerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "xasset");
		let instance = database.RootGroup.CreateInstance("Sparkle", typeof(ParticleEffectAsset).GetFullName(.. scope .()));
		Test.Assert(instance != null);
		// The fixture's own id is another's: the instance's in its place.
		text.Replace("c0314b33-c9fc-1248-9a29-b93e8f2dff8a", instance.Id.ToString(.. scope .()));
		let stream = scope MemoryStream();
		stream.Write(.((uint8*)text.Ptr, text.Length));
		stream.Seek(0, .Begin);
		let object = instance.ReadObjectFrom(stream, outReason);
		let asset = object as ParticleEffectAsset;
		if ((object != null) && (asset == null))
			delete object;
		return asset;
	}

	/// PaperKid's Sparkle as git had it before the asset had an envelope of its own (its data version
	/// 0: two systems, the effect's empty links list) reads as the editor reads it, nothing lost; and
	/// the same asset with effect-level links (written in that layout: one into Flash, one into
	/// nothing) has them on its systems, as they behaved.
	[Test]
	public static void AVersionZeroAssetReadsItsEffectLinksOntoItsSystems()
	{
		Register();
		{
			let reason = scope String();
			let asset = ReadFixture("SparkleV0.xasset", reason);
			defer delete asset;
			Test.Assert(asset != null, reason);
			Test.Assert(asset.Effect.SystemCount == 2);
			Test.Assert(asset.Effect.GetSystem(0).Name == "Glints");
			Test.Assert(asset.Effect.GetSystem(1).Name == "Flash");
			Test.Assert(asset.Effect.GetSystem(0).SubEmitters.IsEmpty && asset.Effect.GetSystem(1).SubEmitters.IsEmpty);
			Test.Assert(asset.SystemTexturePath(1) == "Textures/SoftDot", "what follows the links still reads");
		}
		{
			let reason = scope String();
			let asset = ReadFixture("SparkleV0Links.xasset", reason);
			defer delete asset;
			Test.Assert(asset != null, reason);
			let fx = asset.Effect;
			Test.Assert(fx.SystemCount == 2);
			Test.Assert(fx.GetSystem(0).SubEmitters.Count == 1, "the link into Flash is the glints' own");
			Test.Assert(fx.GetSystem(0).SubEmitters[0].ChildSystemIndex == 1);
			Test.Assert(fx.GetSystem(0).SubEmitters[0].SpawnCount == 40);
			Test.Assert(fx.GetSystem(1).SubEmitters.IsEmpty, "never into itself; the link into nothing dropped");
		}
	}

	/// Written now, the asset carries its own envelope at version 1 and reads back as itself.
	[Test]
	public static void AnAssetWrittenNowCarriesItsVersionAndReadsBack()
	{
		Register();
		let buffer = scope MemoryStream();
		{
			let context = scope XmlSerializerContext(buffer, .Write);
			let asset = scope ParticleEffectAsset();
			let shells = asset.Effect.AddSystem(16);
			asset.Effect.AddSystem(16);
			var link = SubEmitterLink.Default();
			link.ChildSystemIndex = 1;
			shells.SubEmitters.Add(link);
			asset.Serialize(context.Serializer);
			context.Flush(buffer);
		}
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		Test.Assert(text.Contains("dataVersions") && text.Contains("subEmitters") && !text.Contains("\"links\""), text);
		buffer.Seek(0, .Begin);
		let context = scope XmlSerializerContext(buffer, .Read);
		let read = scope ParticleEffectAsset();
		read.Serialize(context.Serializer);
		Test.Assert(context.Serializer.IsPayloadOk);
		Test.Assert((read.Effect.SystemCount == 2) && (read.Effect.GetSystem(0).SubEmitters.Count == 1));
		Test.Assert(read.Effect.GetSystem(0).SubEmitters[0].ChildSystemIndex == 1);
	}
}
