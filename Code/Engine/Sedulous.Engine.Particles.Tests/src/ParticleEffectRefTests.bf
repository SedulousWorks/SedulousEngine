using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Particles;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Particles.Tests;

/// A particle component's effect reference: it round trips by id, resolves through the
/// manager's proxies, and the manager then CLONES the cooked effect into a live instance.
class ParticleEffectRefTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static ParticleEffectComponent* Sole(Scene scene)
	{
		ParticleEffectComponent* found = null;
		scene.GetSystem<ParticleEffectComponentManager>().ForEach(scope [&] (component, owner) =>
			{
				found = component;
			});
		return found;
	}

	[Test]
	public static void ASceneRoundTripResolvesTheEffectAndTheManagerAttachesIt()
	{
		let fixture = scope ParticleResourceFixture("scratch_engine_pfxref_db");
		let effectId = fixture.CookEffect("Puff", 64);

		// Author a scene referencing the effect BY ID only.
		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let manager = scene.AddSystem<ParticleEffectComponentManager>();
			let entity = scene.CreateEntity("Emitter");
			let component = manager.Add(entity);
			component.EffectAsset.SetId(effectId);
			component.LightRange = 7.0f;

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		let manager = loaded.AddSystem<ParticleEffectComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(manager.ComponentCount == 1);
		let component = Sole(loaded);
		Test.Assert(component != null);

		// The identity and the tunable survived, and nothing is bound until the resolve.
		Test.Assert(component.EffectAsset.Id == effectId);
		Test.Assert(component.EffectAsset.Get == null);
		Test.Assert(Near(component.LightRange, 7.0f));

		SceneResolve.ResolveSceneResources(loaded, fixture.Manager);
		let live = component.EffectAsset.Get;
		Test.Assert(live != null);
		Test.Assert(live.Effect.SystemCount == 1);

		// The manager attaches on the NEXT tick, and what it attaches is this component's own
		// CLONE rather than the shared cooked template: two entities running one effect must
		// not share live particle state.
		Test.Assert(component.Instance == null);
		loaded.Update(1.0f / 60.0f);
		Test.Assert(component.Instance != null);
		Test.Assert(component.OwnedEffect != null);
		Test.Assert(component.OwnedEffect !== live.Effect);
		Test.Assert(component.OwnedEffect.SystemCount == 1);
		Test.Assert(component.AttachedResource === live);
	}

	/// Attaching a bound resource by hand takes effect IMMEDIATELY rather than waiting for a
	/// tick, which is the path a sample or a spawn takes.
	[Test]
	public static void AttachingAResourceByHandTakesEffectImmediately()
	{
		let fixture = scope ParticleResourceFixture("scratch_engine_pfxref_db2");
		let effectId = fixture.CookEffect("Spark", 16, false);

		let scene = scope Scene();
		let manager = scene.AddSystem<ParticleEffectComponentManager>();
		let entity = scene.CreateEntity("Emitter");
		let component = manager.Add(entity);

		var reference = component.EffectAsset;
		reference.SetId(effectId);
		reference.Bind(fixture.Manager);
		component.EffectAsset = reference;

		let resource = component.EffectAsset.Get;
		Test.Assert(resource != null);

		manager.AttachResource(component, resource);
		Test.Assert(component.Instance != null);
		Test.Assert(component.AttachedResource === resource);
	}

	/// An inactive entity never attaches and never emits, and deactivating FREEZES what is
	/// already alive rather than letting it decay.
	[Test]
	public static void AnInactiveEntityNeverAttachesAndFreezesWhatIsAlive()
	{
		ParticleResources.RegisterAll();

		let scene = scope Scene();
		let manager = scene.AddSystem<ParticleEffectComponentManager>();
		let entity = scene.CreateEntity("Emitter");
		let component = manager.Add(entity);

		let resource = scope ParticleEffectResource();
		let system = resource.Effect.AddSystem(64);
		system.Emitter.IsEmitting = true;
		system.Emitter.SpawnRate = 100.0f;
		// Long lived, so the alive count is stable across the ticks below.
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(10.0f, 10.0f);

		component.EffectAsset.SetDirect(resource);

		// Starts inactive: the manager never attaches, and nothing emits.
		scene.SetActive(entity, false);
		scene.Update(0.1f);
		scene.Update(0.1f);
		Test.Assert(component.Instance == null);

		// The activation edge attaches and simulates.
		scene.SetActive(entity, true);
		scene.Update(0.1f);
		Test.Assert(component.Instance != null);
		scene.Update(0.2f);

		let alive = component.Instance.Effect.GetSystem(0).AliveCount;
		Test.Assert(alive > 0);

		// Deactivating FREEZES the live particles: no simulation, no emission and no decay.
		scene.SetActive(entity, false);
		scene.Update(0.5f);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount == alive);
	}

	/// An effect on an entity made and placed this frame, the way a spawned prefab is, fires
	/// its one-shot burst where the entity IS: the simulation runs once the transforms are
	/// final, not before, when a new entity's world position still reads the origin.
	[Test]
	public static void ASpawnedOneShotBurstsWhereItsEntityIs()
	{
		ParticleResources.RegisterAll();

		let scene = scope Scene();
		let manager = scene.AddSystem<ParticleEffectComponentManager>();

		let resource = scope ParticleEffectResource();
		let system = resource.Effect.AddSystem(32);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 6;

		scene.Update(0.016f); // a scene already running
		let entity = scene.CreateEntity("Burst");
		scene.SetLocalPosition(entity, .(12, 3, -40));
		let component = manager.Add(entity);
		component.EffectAsset.SetDirect(resource);
		scene.Update(0.016f);

		let live = component.Instance.Effect.GetSystem(0);
		Test.Assert(live.AliveCount == 6, "the one burst, on the first step");
		for (int32 i < 6)
			Test.Assert(Length(live.Streams.Positions[i] - Float3(12, 3, -40)) < 0.1f, scope $"particle {i} at the entity, not the origin");
	}

	/// The manager's playback controls. Stop lets what is alive run out; SetPaused freezes it
	/// where it stands.
	[Test]
	public static void TheManagerDrivesPlaybackPerEntity()
	{
		ParticleResources.RegisterAll();

		let scene = scope Scene();
		let manager = scene.AddSystem<ParticleEffectComponentManager>();
		let entity = scene.CreateEntity("Emitter");
		let component = manager.Add(entity);

		let resource = scope ParticleEffectResource();
		let system = resource.Effect.AddSystem(64);
		system.Emitter.IsEmitting = true;
		system.Emitter.SpawnRate = 100.0f;
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(10.0f, 10.0f);

		// An entity with no effect yet takes every control as a clean no-op.
		Test.Assert(!manager.IsPlaying(entity));
		manager.Play(entity);
		manager.Restart(entity);

		component.EffectAsset.SetDirect(resource);
		scene.Update(0.1f);
		scene.Update(0.2f);
		Test.Assert(manager.IsPlaying(entity));

		let alive = component.Instance.Effect.GetSystem(0).AliveCount;
		Test.Assert(alive > 0);

		// Paused freezes the simulation outright, live particles included.
		manager.SetPaused(entity, true);
		scene.Update(0.5f);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount == alive);

		manager.SetPaused(entity, false);
		scene.Update(0.1f);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount > alive, "resumed emitting");

		// Restart empties it and begins again, so the count drops back toward one tick's worth.
		let beforeRestart = component.Instance.Effect.GetSystem(0).AliveCount;
		manager.Restart(entity);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount == 0);
		scene.Update(0.1f);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount < beforeRestart);

		// Stop ends emission; what is already alive is long lived and stays.
		let atStop = component.Instance.Effect.GetSystem(0).AliveCount;
		manager.Stop(entity);
		scene.Update(0.3f);
		Test.Assert(component.Instance.Effect.GetSystem(0).AliveCount == atStop);
	}

	/// An effect's colours are authored sRGB like every colour: simulated as entered, and
	/// decoded where they leave the simulation for the renderer.
	[Test]
	public static void TheSimulatedColourReachesBillboardsAndLightsDecodedToLinear()
	{
		ParticleResources.RegisterAll();

		let scene = scope Scene();
		let manager = scene.AddSystem<ParticleEffectComponentManager>();

		let resource = scope ParticleEffectResource();
		let system = resource.Effect.AddSystem(8);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(0.5f, 0.25f, 1.0f, 1.0f));
		system.RenderMode = .Light; // a light per particle, and its glow
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 2;

		let component = manager.Add(scene.CreateEntity("Glow"));
		component.EffectAsset.SetDirect(resource);
		scene.Update(0.016f);
		Test.Assert(component.Instance != null);

		let snapshot = scope ExtractedScene();
		manager.ExtractRenderData(snapshot);
		Test.Assert(snapshot.Lights.Length == 2);
		Test.Assert(Math.Abs(snapshot.Lights[0].Color.X - SrgbToLinear(0.5f)) < 1e-5f);
		Test.Assert(Math.Abs(snapshot.Lights[0].Color.Y - SrgbToLinear(0.25f)) < 1e-5f);
		Test.Assert(Math.Abs(snapshot.Lights[0].Color.Z - 1.0f) < 1e-5f);

		Test.Assert(snapshot.Size == 1, "the billboard batch");
		let batch = (ParticleBillboardRenderData)snapshot.Items[0];
		Test.Assert(batch.Count == 2);
		Test.Assert(Math.Abs(batch.Instances[0].Color.X - SrgbToLinear(0.5f)) < 1e-5f);
		Test.Assert(batch.Instances[0].Color.W == 1.0f, "alpha is not decoded");

		// The helper the four upload points share.
		let linear = ParticleBillboardInstance.ColorToLinear(.(0.5f, 0.0f, 1.0f, 0.25f));
		Test.Assert(Math.Abs(linear.X - SrgbToLinear(0.5f)) < 1e-5f);
		Test.Assert(linear.W == 0.25f);
	}
}
