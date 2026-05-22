namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Particles;
using Sedulous.Particles.Resources;
using Sedulous.Resources;
using Sedulous.Textures.Importer;
using Sedulous.Textures.Resources;
using Sedulous.VFS;
using Sedulous.Serialization;

/// Builds and persists the engine's default `builtin://` asset set. Lives
/// in its own file so EditorApplication doesn't accumulate every new
/// default. Pure static; takes a writable mount + serializer + asset
/// directory and produces files on disk. The editor still owns the gate
/// (skip when `builtin.registry` exists) and the index-loading flow.
///
/// Stable GUIDs are exposed as `public static readonly` so other code
/// (scene templates, default-scene factories, sample projects) can
/// reference defaults by ID. Once a GUID is shipped, treat it as a
/// public API - changing it breaks every reference downstream.
public static class BuiltinAssets
{
	// ==================== Primitives ====================

	public static readonly Guid PlaneMeshId         = Guid.Parse("afda3f71-a2d6-479b-8564-7e343f22d12f").GetValueOrDefault();
	public static readonly Guid CubeMeshId          = Guid.Parse("5763a2f1-580a-49bb-a439-9fbd25f82015").GetValueOrDefault();
	public static readonly Guid SphereMeshId        = Guid.Parse("dc1de03f-efd4-453e-8007-b2c66374cbb1").GetValueOrDefault();

	// ==================== Materials ====================

	public static readonly Guid DefaultMaterialId   = Guid.Parse("107f851e-6e86-4c3a-b5c8-bc75a0f1e25f").GetValueOrDefault();
	public static readonly Guid DefaultUnlitId      = Guid.Parse("54e50e89-eb97-4631-a1e2-ffb3b297b68a").GetValueOrDefault();

	// ==================== Skies ====================

	public static readonly Guid RealisticSkyId      = Guid.Parse("5653f8c1-87c0-4855-9498-504ac8e67832").GetValueOrDefault();
	public static readonly Guid StylizedSkyId       = Guid.Parse("705c0bd8-b8e3-451c-8a19-7cb033cb1e1c").GetValueOrDefault();

	// ==================== Particle textures ====================

	// Kenney particle-pack, "PNG (Transparent)" subdir. Referenced by the
	// default particle effects below.
	public static readonly Guid ParticleTexCircleId = Guid.Parse("6a9c8f4a-5b3e-4d8a-9c1f-2b7e8a3d1c4b").GetValueOrDefault();
	public static readonly Guid ParticleTexSmokeId  = Guid.Parse("7b1d5e2a-3f8c-4a9b-8d2e-1c4f9a5b6e3d").GetValueOrDefault();
	public static readonly Guid ParticleTexStarId   = Guid.Parse("8c2e6f3b-4a1d-4e9c-9d3f-2b5a8c4e7f1a").GetValueOrDefault();
	public static readonly Guid ParticleTexFlameId  = Guid.Parse("9d3f7a4c-5b2e-4f1d-ae4b-3c6d9b5f8a2e").GetValueOrDefault();
	public static readonly Guid ParticleTexTraceId  = Guid.Parse("ae4a8b5d-6c3f-4a2e-bf5c-4d7eac6a9b3f").GetValueOrDefault();
	public static readonly Guid ParticleTexSparkId  = Guid.Parse("bf5b9c6e-7d4a-4b3f-806d-5e8fbd7b0c4a").GetValueOrDefault();

	// ==================== Particle effects ====================

	// Construction copied from EngineSandbox so the canonical samples and
	// the builtin catalog stay visually consistent.
	public static readonly Guid ParticleSparksId    = Guid.Parse("c1d2e3f4-aa01-4b1a-9c01-110a220b330c").GetValueOrDefault();
	public static readonly Guid ParticleSmokeId     = Guid.Parse("c1d2e3f4-aa02-4b2b-9c02-220b330c440d").GetValueOrDefault();
	public static readonly Guid ParticleMagicId     = Guid.Parse("c1d2e3f4-aa03-4b3c-9c03-330c440d550e").GetValueOrDefault();
	public static readonly Guid ParticleFireId      = Guid.Parse("c1d2e3f4-aa04-4b4d-9c04-440d550e660f").GetValueOrDefault();
	public static readonly Guid ParticleCometId     = Guid.Parse("c1d2e3f4-aa05-4b5e-9c05-550e660faabb").GetValueOrDefault();
	public static readonly Guid ParticleFireworksId = Guid.Parse("c1d2e3f4-aa06-4b6f-9c06-660faabbccdd").GetValueOrDefault();

	// ==================== Entry point ====================

	/// Generates the entire default-asset set into `mount`, registering
	/// each resource's GUID -> URI in `index`. Caller serializes the
	/// index to disk afterwards. `assetRoot` is the editor's source-asset
	/// directory; we read sky HDRs and particle PNGs from there.
	public static void GenerateAll(IWritableMount mount, IResourceIndex index,
		ISerializerProvider provider, StringView assetRoot, ILogger logger)
	{
		GeneratePrimitives(mount, index, provider, logger);
		GenerateMaterials(mount, index, provider, logger);
		GenerateSkies(mount, index, provider, assetRoot, logger);
		GenerateParticleTextures(mount, index, provider, assetRoot, logger);
		GenerateParticleEffects(mount, index, provider, logger);
	}

	// ==================== Per-category generators ====================

	private static void GeneratePrimitives(IWritableMount mount, IResourceIndex index, ISerializerProvider provider, ILogger logger)
	{
		// Plane
		{
			let res = StaticMeshResource.CreatePlane(10, 10, 1, 1);
			res.Id = PlaneMeshId;
			res.Name = "Plane";
			SaveResourceText(res, mount, "primitives/plane.mesh", provider, logger);
			index.Register(res.Id, "builtin://primitives/plane.mesh");
			delete res;
		}

		// Cube
		{
			let res = StaticMeshResource.CreateCube(1.0f);
			res.Id = CubeMeshId;
			res.Name = "Cube";
			SaveResourceText(res, mount, "primitives/cube.mesh", provider, logger);
			index.Register(res.Id, "builtin://primitives/cube.mesh");
			delete res;
		}

		// Sphere
		{
			let res = StaticMeshResource.CreateSphere(0.5f, 32, 16);
			res.Id = SphereMeshId;
			res.Name = "Sphere";
			SaveResourceText(res, mount, "primitives/sphere.mesh", provider, logger);
			index.Register(res.Id, "builtin://primitives/sphere.mesh");
			delete res;
		}
	}

	private static void GenerateMaterials(IWritableMount mount, IResourceIndex index, ISerializerProvider provider, ILogger logger)
	{
		// Default PBR material
		{
			let mat = Materials.CreatePBR("Default", "forward");
			let res = new MaterialResource(mat, true);
			res.Id = DefaultMaterialId;
			res.Name = "Default";
			SaveResourceText(res, mount, "materials/default.material", provider, logger);
			index.Register(res.Id, "builtin://materials/default.material");
			delete res;
		}

		// Default Unlit material
		{
			let mat = Materials.CreateUnlit("DefaultUnlit");
			let res = new MaterialResource(mat, true);
			res.Id = DefaultUnlitId;
			res.Name = "DefaultUnlit";
			SaveResourceText(res, mount, "materials/default_unlit.material", provider, logger);
			index.Register(res.Id, "builtin://materials/default_unlit.material");
			delete res;
		}
	}

	private static void GenerateSkies(IWritableMount mount, IResourceIndex index, ISerializerProvider provider, StringView assetRoot, ILogger logger)
	{
		// Realistic sky (equirectangular HDR)
		{
			let srcPath = scope String();
			JoinPath(assetRoot, "textures/environment/BlueSky.hdr", srcPath);

			if (TextureImporter.ImportEquirectangular(srcPath) case .Ok(let res))
			{
				res.Id = RealisticSkyId;
				res.Name.Set("realistic_sky");
				SaveTextureWithSidecar(res, mount, "skies/realistic_sky.texture", "realistic_sky.texture.bin", provider, logger);
				index.Register(res.Id, "builtin://skies/realistic_sky.texture");
				delete res;
			}
		}

		// Stylized sky (equirectangular PNG)
		{
			let srcPath = scope String();
			JoinPath(assetRoot, "textures/environment/sky_75_2k/sky_75_2k.png", srcPath);

			if (TextureImporter.ImportEquirectangular(srcPath) case .Ok(let res))
			{
				res.Id = StylizedSkyId;
				res.Name.Set("stylized_sky");
				SaveTextureWithSidecar(res, mount, "skies/stylized_sky.texture", "stylized_sky.texture.bin", provider, logger);
				index.Register(res.Id, "builtin://skies/stylized_sky.texture");
				delete res;
			}
		}
	}

	/// Imports particle sprites from the Kenney particle pack PNGs and
	/// publishes them as builtin `.texture` resources. These back the
	/// default particle effects; each effect references one of these
	/// textures by stable GUID.
	private static void GenerateParticleTextures(IWritableMount mount, IResourceIndex index, ISerializerProvider provider, StringView assetRoot, ILogger logger)
	{
		ImportParticleSprite(mount, index, provider, assetRoot, "circle_05", ParticleTexCircleId, logger);
		ImportParticleSprite(mount, index, provider, assetRoot, "smoke_07",  ParticleTexSmokeId,  logger);
		ImportParticleSprite(mount, index, provider, assetRoot, "star_04",   ParticleTexStarId,   logger);
		ImportParticleSprite(mount, index, provider, assetRoot, "flame_06",  ParticleTexFlameId,  logger);
		ImportParticleSprite(mount, index, provider, assetRoot, "trace_05",  ParticleTexTraceId,  logger);
		ImportParticleSprite(mount, index, provider, assetRoot, "spark_07",  ParticleTexSparkId,  logger);
	}

	private static void ImportParticleSprite(IWritableMount mount, IResourceIndex index, ISerializerProvider provider,
		StringView assetRoot, StringView spriteName, Guid stableId, ILogger logger)
	{
		let srcPath = scope String();
		JoinPath(assetRoot, scope $"textures/kenney_particle-pack/PNG (Transparent)/{spriteName}.png", srcPath);

		if (TextureImporter.Import2D(srcPath) case .Ok(let res))
		{
			res.Id = stableId;
			res.Name.Set(spriteName);
			let locator = scope $"particles/textures/{spriteName}.texture";
			let sidecar = scope $"{spriteName}.texture.bin";
			SaveTextureWithSidecar(res, mount, locator, sidecar, provider, logger);
			index.Register(res.Id, scope $"builtin://particles/textures/{spriteName}.texture");
			delete res;
		}
		else
		{
			logger?.Log(.Error, scope $"Builtin asset: particle sprite import failed for {srcPath}");
		}
	}

	private static void GenerateParticleEffects(IWritableMount mount, IResourceIndex index, ISerializerProvider provider, ILogger logger)
	{
		SaveParticleEffect(mount, index, provider, "sparks",    ParticleSparksId,    BuildSparksEffect(),    logger);
		SaveParticleEffect(mount, index, provider, "smoke",     ParticleSmokeId,     BuildSmokeEffect(),     logger);
		SaveParticleEffect(mount, index, provider, "magic",     ParticleMagicId,     BuildMagicEffect(),     logger);
		SaveParticleEffect(mount, index, provider, "fire",      ParticleFireId,      BuildFireEffect(),      logger);
		SaveParticleEffect(mount, index, provider, "comet",     ParticleCometId,     BuildCometEffect(),     logger);
		SaveParticleEffect(mount, index, provider, "fireworks", ParticleFireworksId, BuildFireworksEffect(), logger);
	}

	private static void SaveParticleEffect(IWritableMount mount, IResourceIndex index, ISerializerProvider provider,
		StringView effectName, Guid stableId, ParticleEffect effect, ILogger logger)
	{
		let res = new ParticleEffectResource(effect);
		res.Id = stableId;
		res.Name.Set(effectName);
		let locator = scope $"particles/{effectName}.particlefx";
		SaveResourceText(res, mount, locator, provider, logger);
		index.Register(res.Id, scope $"builtin://particles/{effectName}.particlefx");
		delete res;
	}

	/// Applies the same texture ref to every system in an effect. The
	/// default effects use a single sprite for every system; if a future
	/// effect needs per-system textures we'd inline the assignment.
	private static void SetEffectTexture(ParticleEffect effect, Guid textureId, StringView texturePath)
	{
		var texRef = ResourceRef(textureId, texturePath);
		for (let sys in effect.Systems)
			sys.SetTextureRef(texRef);
		texRef.Dispose();
	}

	// ==================== Effect builders ====================

	private static ParticleEffect BuildSparksEffect()
	{
		let effect = new ParticleEffect("Sparks");
		let sys = new ParticleSystem(500);
		sys.Emitter.SpawnRate = 40;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.5f, 1.5f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.3f) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 3, 0), Randomness = .(1.5f, 1, 1.5f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.08f, 0.08f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Range(.(1, 0.4f, 0, 1), .(1, 0.9f, 0.2f, 1)) });
		sys.AddInitializer(new RotationInitializer());
		sys.AddBehavior(new GravityBehavior() { Multiplier = 0.3f });
		sys.AddBehavior(new DragBehavior() { Drag = 0.8f });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f) });
		sys.AddBehavior(new RotationOverLifetimeBehavior());
		effect.AddSystem(sys);
		SetEffectTexture(effect, ParticleTexCircleId, "builtin://particles/textures/circle_05.texture");
		return effect;
	}

	private static ParticleEffect BuildSmokeEffect()
	{
		let effect = new ParticleEffect("Smoke");
		let sys = new ParticleSystem(300);
		sys.Emitter.SpawnRate = 15;
		sys.BlendMode = .Alpha;
		sys.SortParticles = true;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(2.0f, 4.0f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Circle(0.4f) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 1.5f, 0), Randomness = .(0.3f, 0.2f, 0.3f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.3f, 0.3f), .(0.5f, 0.5f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.4f, 0.4f, 0.4f, 0.6f), .(0.6f, 0.6f, 0.6f, 0.4f)) });
		sys.AddInitializer(new RotationInitializer() { RotationSpeed = .(-0.5f, 0.5f) });
		sys.AddBehavior(new GravityBehavior() { Multiplier = -0.05f, Direction = .(0, -1, 0) });
		sys.AddBehavior(new DragBehavior() { Drag = 0.3f });
		sys.AddBehavior(new WindBehavior() { Force = .(0.3f, 0, 0.1f) });
		sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.3f, 0.3f), .(1.2f, 1.2f)) });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.5f) });
		sys.AddBehavior(new RotationOverLifetimeBehavior());
		effect.AddSystem(sys);
		SetEffectTexture(effect, ParticleTexSmokeId, "builtin://particles/textures/smoke_07.texture");
		return effect;
	}

	private static ParticleEffect BuildMagicEffect()
	{
		let effect = new ParticleEffect("Magic");
		let sys = new ParticleSystem(400);
		sys.Emitter.SpawnRate = 60;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(1.0f, 2.0f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.8f, true) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 0.5f, 0), Randomness = .(0.2f, 0.3f, 0.2f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.15f, 0.15f), .(0.3f, 0.3f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.5f, 0.7f, 1.5f, 1), .(1.2f, 0.5f, 1.5f, 1)) });
		sys.AddBehavior(new VortexBehavior() { Strength = 3.0f, Axis = .(0, 1, 0) });
		sys.AddBehavior(new DragBehavior() { Drag = 0.5f });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.6f) });
		sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.3f, 0.3f), .(0.05f, 0.05f)) });
		effect.AddSystem(sys);
		SetEffectTexture(effect, ParticleTexStarId, "builtin://particles/textures/star_04.texture");
		return effect;
	}

	private static ParticleEffect BuildFireEffect()
	{
		let effect = new ParticleEffect("Fire");
		let sys = new ParticleSystem(800);
		sys.Emitter.SpawnRate = 120;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.3f, 0.8f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Circle(0.15f) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 2.0f, 0), Randomness = .(0.15f, 0.5f, 0.15f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.2f, 0.2f), .(0.35f, 0.35f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Constant(.(1, 0.9f, 0.5f, 1)) });
		sys.AddInitializer(new RotationInitializer());
		sys.AddBehavior(new GravityBehavior() { Multiplier = -0.3f, Direction = .(0, -1, 0) });
		sys.AddBehavior(new DragBehavior() { Drag = 2.0f });
		sys.AddBehavior(new TurbulenceBehavior() { Strength = 0.8f, Frequency = 3.0f, Speed = 4.0f });

		var fireColor = ParticleCurveColor();
		fireColor.AddKey(0.0f, .(1.5f, 1.2f, 0.5f, 1));
		fireColor.AddKey(0.25f, .(1.2f, 0.5f, 0.05f, 1));
		fireColor.AddKey(0.6f, .(0.6f, 0.1f, 0.0f, 0.7f));
		fireColor.AddKey(1.0f, .(0.2f, 0.02f, 0.0f, 0.0f));
		sys.AddBehavior(new ColorOverLifetimeBehavior() { Curve = fireColor });

		var fireSize = ParticleCurveVector2();
		fireSize.AddKey(0.0f, .(0.2f, 0.2f));
		fireSize.AddKey(0.15f, .(0.35f, 0.35f));
		fireSize.AddKey(1.0f, .(0.02f, 0.02f));
		sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = fireSize });

		sys.AddBehavior(new RotationOverLifetimeBehavior());
		effect.AddSystem(sys);
		SetEffectTexture(effect, ParticleTexFlameId, "builtin://particles/textures/flame_06.texture");
		return effect;
	}

	private static ParticleEffect BuildCometEffect()
	{
		let effect = new ParticleEffect("Comet");
		let sys = new ParticleSystem(50);
		sys.Emitter.SpawnRate = 8;
		sys.BlendMode = .Additive;
		sys.RenderMode = .Trail;
		sys.Trail = .()
		{
			Enabled = true,
			MaxPoints = 32,
			RecordInterval = 0.016f,
			Lifetime = 1.5f,
			WidthStart = 0.15f,
			WidthEnd = 0.0f,
			MinVertexDistance = 0.01f,
			UseParticleColor = true,
			TrailColor = .(1, 1, 1, 1)
		};
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(2.0f, 3.0f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Point() });
		sys.AddInitializer(new VelocityInitializer()
		{
			BaseVelocity = .Zero,
			ShapeDirectionSpeed = 3.0f,
			Shape = .Sphere(0.1f)
		});
		sys.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.12f, 0.12f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.5f, 0.8f, 1.5f, 1), .(1.5f, 0.5f, 1.0f, 1)) });
		sys.AddBehavior(new GravityBehavior() { Multiplier = 0.15f });
		sys.AddBehavior(new DragBehavior() { Drag = 0.3f });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.4f) });
		effect.AddSystem(sys);
		SetEffectTexture(effect, ParticleTexTraceId, "builtin://particles/textures/trace_05.texture");
		return effect;
	}

	private static ParticleEffect BuildFireworksEffect()
	{
		let effect = new ParticleEffect("Fireworks");

		// System 0: rockets rising upward, short lifetime, trail trail.
		let rockets = new ParticleSystem(10);
		rockets.Emitter.Mode = .Burst;
		rockets.Emitter.BurstCount = 3;
		rockets.Emitter.BurstInterval = 2.0f;
		rockets.Emitter.BurstCycles = 0; // infinite
		rockets.BlendMode = .Additive;
		rockets.RenderMode = .Trail;
		rockets.Trail = .()
		{
			Enabled = true,
			MaxPoints = 24,
			RecordInterval = 0.02f,
			Lifetime = 0.8f,
			WidthStart = 0.06f,
			WidthEnd = 0.0f,
			MinVertexDistance = 0.01f,
			UseParticleColor = true,
			TrailColor = .(1, 1, 1, 1)
		};
		rockets.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.8f, 1.2f) });
		rockets.AddInitializer(new PositionInitializer() { Shape = .Circle(0.5f) });
		rockets.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 8, 0), Randomness = .(1.5f, 2, 1.5f) });
		rockets.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.06f, 0.06f)) });
		rockets.AddInitializer(new ColorInitializer() { Color = .Constant(.(1.5f, 1.2f, 0.5f, 1)) });
		rockets.AddBehavior(new GravityBehavior() { Multiplier = 0.4f });
		effect.AddSystem(rockets);

		// System 1: burst sparks - sub-emitted from each rocket on death.
		let burst = new ParticleSystem(500);
		burst.Emitter.IsEmitting = false; // sub-emitter only
		burst.BlendMode = .Additive;
		burst.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.5f, 1.5f) });
		burst.AddInitializer(new PositionInitializer() { Shape = .Point() });
		burst.AddInitializer(new VelocityInitializer()
		{
			BaseVelocity = .Zero,
			ShapeDirectionSpeed = 5.0f,
			Shape = .Sphere(0.1f)
		});
		burst.AddInitializer(new SizeInitializer() { Size = .Range(.(0.06f, 0.06f), .(0.12f, 0.12f)) });
		burst.AddInitializer(new ColorInitializer() { Color = .Range(.(1.5f, 0.3f, 0.1f, 1), .(0.3f, 1.5f, 0.3f, 1)) });
		burst.AddBehavior(new GravityBehavior() { Multiplier = 0.5f });
		burst.AddBehavior(new DragBehavior() { Drag = 1.0f });
		burst.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.3f) });
		let burstIdx = effect.AddSystem(burst);

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = burstIdx;
		link.SpawnCount = 30;
		link.Probability = 1.0f;
		link.InheritPosition = true;
		effect.AddSubEmitterLink(link);

		SetEffectTexture(effect, ParticleTexSparkId, "builtin://particles/textures/spark_07.texture");
		return effect;
	}

	// ==================== Helpers ====================

	/// Serializes a Resource's text representation into memory and writes
	/// it to `mount` at `locator`. Logs failures so builtin generation
	/// problems surface in the LogView panel.
	private static Result<void> SaveResourceText(Resource resource, IWritableMount mount, StringView locator, ISerializerProvider provider, ILogger logger)
	{
		let memStream = scope MemoryStream();
		if (resource.WriteToStream(memStream, provider) case .Err)
		{
			logger?.Log(.Error, scope $"Builtin asset save: serialization failed for {locator}");
			return .Err;
		}
		memStream.Position = 0;
		if (mount.Save(locator, memStream) case .Err(let err))
		{
			logger?.Log(.Error, scope $"Builtin asset save: mount save failed for {locator}: {err}");
			return .Err;
		}
		return .Ok;
	}

	/// Saves a TextureResource as a text metadata file plus a pixel sidecar
	/// in the same directory. `sidecarName` is the filename portion only
	/// (conventionally "<assetFileName>.bin"); the texture manager derives
	/// the same "<locator>.bin" on load.
	private static Result<void> SaveTextureWithSidecar(TextureResource resource, IWritableMount mount, StringView locator, StringView sidecarName, ISerializerProvider provider, ILogger logger)
	{
		Try!(SaveResourceText(resource, mount, locator, provider, logger));

		// Sidecar locator = main locator's directory + sidecar name.
		let sidecarLocator = scope String();
		let slash = locator.LastIndexOf('/');
		if (slash >= 0)
			sidecarLocator.Append(locator.Substring(0, slash + 1));
		sidecarLocator.Append(sidecarName);

		let pcmStream = scope MemoryStream();
		if (resource.WritePixelsToStream(pcmStream) case .Err)
		{
			logger?.Log(.Error, scope $"Builtin texture save: pixel sidecar serialization failed for {sidecarLocator}");
			return .Err;
		}
		pcmStream.Position = 0;
		if (mount.Save(sidecarLocator, pcmStream) case .Err(let err))
		{
			logger?.Log(.Error, scope $"Builtin texture save: sidecar mount save failed for {sidecarLocator}: {err}");
			return .Err;
		}
		return .Ok;
	}

	/// Combines `root` with `relative` into `outPath`. Matches the
	/// behavior of Application.GetAssetPath so paths resolve identically
	/// to the previous in-class implementation.
	private static void JoinPath(StringView root, StringView relative, String outPath)
	{
		outPath.Clear();
		System.IO.Path.InternalCombine(outPath, root, relative);
	}
}
