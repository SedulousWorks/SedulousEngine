namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Messaging;
using Sedulous.Particles;
using Sedulous.Images;
using Sedulous.Textures.Resources;

/// Manages one-shot particle effects for tower fire, enemy death, and projectile impacts.
/// Creates burst particle entities that self-clean after their lifetime expires.
class ParticleEffects
{
	private Scene mScene;
	private MessageBus mBus;
	private ResourceSystem mResources;

	// Shared particle texture
	private TextureResource mParticleTexture ~ _?.ReleaseRef();

	// Active effect entities, their effects, and remaining lifetimes
	private List<ActiveEffect> mActiveEffects = new .() ~ delete _;

	struct ActiveEffect
	{
		public EntityHandle Entity;
		public ParticleEffect Effect; // owned, one per spawn
		public float RemainingTime;
	}

	// Message subscriptions
	private SubscriptionHandle mTowerShotSub;
	private SubscriptionHandle mEnemyKilledSub;
	private SubscriptionHandle mProjectileHitSub;

	public void Initialize(Scene scene, MessageBus bus, ResourceSystem resources, StringView assetDir)
	{
		mScene = scene;
		mBus = bus;
		mResources = resources;

		// Load the particle texture once and keep it across play/stop cycles.
		// Re-loading per cycle adds a new TextureResource (under a fresh Guid)
		// to the resource cache every time, and the cache holds a ref the
		// caller can't easily reclaim - reload-per-cycle leaks one texture
		// (+ Image + sample buffer) per cycle. The field destructor
		// (~_?.ReleaseRef()) handles final cleanup at module destruction.
		if (mParticleTexture == null)
		{
			let texPath = scope String();
			texPath.AppendF("{}/textures/kenney_particle-pack/PNG (Transparent)/circle_05.png", assetDir);
			if (ImageLoaderFactory.LoadImage(texPath) case .Ok(var image))
			{
				mParticleTexture = new TextureResource(image, true);
				resources.AddResource<TextureResource>(mParticleTexture);
			}
		}

		// Subscribe to game events
		if (mBus != null)
		{
			mTowerShotSub = mBus.Subscribe<TowerShotMsg>(new (msg) =>
				{
					SpawnEffect(CreateTowerFireEffect(), msg.Origin, 0.4f);
				});

			mEnemyKilledSub = mBus.Subscribe<EnemyKilledMsg>(new (msg) =>
				{
					SpawnEffect(CreateEnemyDeathEffect(), msg.Position, 0.8f);
				});

			mProjectileHitSub = mBus.Subscribe<ProjectileHitMsg>(new (msg) =>
				{
					SpawnEffect(CreateProjectileHitEffect(), msg.HitPosition, 0.5f);
				});
		}
	}

	/// Call each frame to clean up expired effects.
	public void Update(float deltaTime)
	{
		if (mScene == null) return;

		for (int i = mActiveEffects.Count - 1; i >= 0; i--)
		{
			mActiveEffects[i].RemainingTime -= deltaTime;
			if (mActiveEffects[i].RemainingTime <= 0)
			{
				if (mScene.IsValid(mActiveEffects[i].Entity))
					mScene.DestroyEntity(mActiveEffects[i].Entity);
				delete mActiveEffects[i].Effect;
				mActiveEffects.RemoveAtFast(i);
			}
		}
	}

	public void Shutdown()
	{
		// Clean up active effects
		if (mScene != null)
		{
			for (let effect in mActiveEffects)
			{
				if (mScene.IsValid(effect.Entity))
					mScene.DestroyEntity(effect.Entity);
				delete effect.Effect;
			}
		}
		mActiveEffects.Clear();

		if (mBus != null)
		{
			mBus.Unsubscribe(mTowerShotSub);
			mBus.Unsubscribe(mEnemyKilledSub);
			mBus.Unsubscribe(mProjectileHitSub);
		}

		// mParticleTexture intentionally NOT released here - it's loaded
		// once in Initialize and reused across all play/stop cycles. The
		// field destructor (~_?.ReleaseRef()) releases it when the module
		// itself is destroyed at editor shutdown.
	}

	// ==================== Effect Spawning ====================

	/// Spawns a one-shot particle effect. Takes ownership of the effect.
	private void SpawnEffect(ParticleEffect effect, Vector3 position, float lifetime)
	{
		if (mScene == null || effect == null) { delete effect; return; }

		// Texture lives on each ParticleSystem in the asset, not on the
		// component. Apply the shared sprite to every system in this
		// programmatically-built effect before spawning.
		if (mParticleTexture != null)
		{
			var texRef = ResourceRef(mParticleTexture.Id, "");
			defer texRef.Dispose();
			for (let sys in effect.Systems)
				sys.SetTextureRef(texRef);
		}

		let entity = mScene.CreateEntity("FX");
		mScene.SetLocalTransform(entity, .() { Position = position, Rotation = .Identity, Scale = .One });

		let particleMgr = mScene.GetModule<ParticleComponentManager>();
		if (particleMgr != null)
		{
			let handle = particleMgr.CreateComponent(entity);
			if (let comp = particleMgr.Get(handle))
				comp.SetEffect(effect);
		}

		mActiveEffects.Add(.() { Entity = entity, Effect = effect, RemainingTime = lifetime });
	}

	// ==================== Effect Definitions ====================

	private static ParticleEffect CreateTowerFireEffect()
	{
		let effect = new ParticleEffect("TowerFire");
		let sys = new ParticleSystem(30);
		sys.Emitter.Mode = .Burst;
		sys.Emitter.BurstCount = 15;
		sys.Emitter.BurstCycles = 1;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.1f, 0.8f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.1f) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 1.5f, 0), Randomness = .(1.0f, 0.5f, 1.0f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.1f, 0.1f), .(0.2f, 0.2f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Constant(.(1.0f, 0.78f, 0.31f, 1.0f)) });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .Linear(1.0f, 0.0f) });
		sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.2f, 0.2f), .(0.06f, 0.06f)) });
		effect.AddSystem(sys);
		return effect;
	}

	private static ParticleEffect CreateEnemyDeathEffect()
	{
		let effect = new ParticleEffect("EnemyDeath");
		let sys = new ParticleSystem(50);
		sys.Emitter.Mode = .Burst;
		sys.Emitter.BurstCount = 30;
		sys.Emitter.BurstCycles = 1;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.3f, 0.7f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.2f) });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 2.0f, 0), Randomness = .(2.0f, 1.5f, 2.0f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.1f, 0.1f), .(0.25f, 0.25f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Constant(.(1.0f, 0.63f, 0.24f, 1.0f)) });
		sys.AddBehavior(new GravityBehavior() { Multiplier = 0.5f });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .Linear(1.0f, 0.0f) });
		sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.25f, 0.25f), .(0.025f, 0.025f)) });
		effect.AddSystem(sys);
		return effect;
	}

	private static ParticleEffect CreateProjectileHitEffect()
	{
		let effect = new ParticleEffect("ProjectileHit");
		let sys = new ParticleSystem(20);
		sys.Emitter.Mode = .Burst;
		sys.Emitter.BurstCount = 10;
		sys.Emitter.BurstCycles = 1;
		sys.BlendMode = .Additive;
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.1f, 0.8f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Point() });
		sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 0.5f, 0), Randomness = .(1.5f, 1.0f, 1.5f) });
		sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.05f, 0.05f), .(0.12f, 0.12f)) });
		sys.AddInitializer(new ColorInitializer() { Color = .Constant(.(1.0f, 0.86f, 0.39f, 1.0f)) });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .Linear(1.0f, 0.0f) });
		effect.AddSystem(sys);
		return effect;
	}

}
