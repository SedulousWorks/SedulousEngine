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
			system.AddBehavior<SizeOverLifetimeBehavior>().Curve = .Linear(.(1, 1), .(3, 3));

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
}
