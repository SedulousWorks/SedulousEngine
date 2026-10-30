using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The effect and its instance: systems, sub emitter routing, and local space.
class ParticleEffectTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void SystemsCanBeAddedAndRemoved()
	{
		let effect = scope ParticleEffect();
		effect.AddSystem(100);
		effect.AddSystem(100);
		Test.Assert(effect.SystemCount == 2);
		effect.RemoveSystem(0);
		Test.Assert(effect.SystemCount == 1);
		effect.Clear();
		Test.Assert(effect.SystemCount == 0);
	}

	[Test]
	public static void ASystemRemovedTheSubEmittersFollowIt()
	{
		let effect = scope ParticleEffect("shells");
		let first = effect.AddSystem(16);
		effect.AddSystem(16);
		effect.AddSystem(16);
		var intoSecond = SubEmitterLink.Default();
		intoSecond.ChildSystemIndex = 1;
		var intoThird = SubEmitterLink.Default();
		intoThird.ChildSystemIndex = 2;
		first.SubEmitters.Add(intoSecond);
		first.SubEmitters.Add(intoThird);

		effect.RemoveSystem(1);
		Test.Assert(first.SubEmitters.Count == 2);
		Test.Assert(first.SubEmitters[0].ChildSystemIndex == -1, "into the one removed: does nothing");
		Test.Assert(first.SubEmitters[1].ChildSystemIndex == 1, "the third is the second now");
	}

	// A field's attribute of type T, by the field's name.
	private static Result<T> FieldAttribute<T>(Type type, StringView field) where T : Attribute
	{
		if (!(type.GetField(scope String(field)) case .Ok(let info)))
			return .Err;
		return info.GetCustomAttribute<T>();
	}

	[Test]
	public static void EveryAuthoredFieldOfASystemIsReflectedItsModesNamedEachRowWhereItActs()
	{
		// The modes are reflected enums, so a row can offer them.
		int cases = 0;
		for (var (name, value) in Enum.GetEnumerator(typeof(ParticleRenderMode)))
			cases++;
		Test.Assert(cases == 7);
		cases = 0;
		for (var (name, value) in Enum.GetEnumerator(typeof(ParticleBlendMode)))
			cases++;
		Test.Assert(cases == 4);

		// The references name what they bind; each shows where its render mode uses it.
		Test.Assert(FieldAttribute<ReferencesAttribute>(typeof(ParticleSystem), "TextureRef") case .Ok(let texture));
		Test.Assert(texture.TargetName == "Sedulous.Texture.Resource.Texture");
		Test.Assert(FieldAttribute<VisibleWhenAttribute>(typeof(ParticleSystem), "TextureRef") case .Ok(let textureShown));
		Test.Assert(textureShown.Condition == "RenderMode=0,1,2,3,5");
		Test.Assert(FieldAttribute<ReferencesAttribute>(typeof(ParticleSystem), "MaterialRefs") case .Ok(let materials));
		Test.Assert(materials.TargetName == "Sedulous.Materials.Material");
		Test.Assert(FieldAttribute<VisibleWhenAttribute>(typeof(ParticleSystem), "Trail") case .Ok(let trail));
		Test.Assert(trail.Condition == "RenderMode=5");
		Test.Assert(FieldAttribute<VisibleWhenAttribute>(typeof(ParticleSystem), "Flipbook") case .Ok(let flipbook));
		Test.Assert(flipbook.Condition == "RenderMode=0,1,2,3");
		Test.Assert(FieldAttribute<HiddenAttribute>(typeof(ParticleSystem), "Position") case .Ok, "runtime state, no row");

		// A trail's colour and a colour range are colours; a shape's measures show for its shapes.
		Test.Assert(FieldAttribute<AsColorAttribute>(typeof(TrailSettings), "TrailColor") case .Ok);
		Test.Assert(FieldAttribute<AsColorAttribute>(typeof(RangeColor), "Min") case .Ok);
		Test.Assert(FieldAttribute<VisibleWhenAttribute>(typeof(EmissionShape), "Extents") case .Ok(let extents));
		Test.Assert(extents.Condition == "Type=3");
		Test.Assert(FieldAttribute<VisibleWhenAttribute>(typeof(ParticleEmitter), "SpawnRate") case .Ok(let rate));
		Test.Assert(rate.Condition == "Mode=0,2");

		// A sub-emitter link is reflected field by field.
		Test.Assert(FieldAttribute<DisplayNameAttribute>(typeof(SubEmitterLink), "ChildSystemIndex") case .Ok(let into));
		Test.Assert(into.Name == "Into");
		cases = 0;
		for (var (name, value) in Enum.GetEnumerator(typeof(ParticleEventType)))
			cases++;
		Test.Assert(cases == 2);
	}

	[Test]
	public static void ParentDeathSpawnsIntoTheChild()
	{
		let effect = scope ParticleEffect("fireworks");

		// Short lived rockets, which die and so produce death events.
		let rockets = effect.AddSystem(100);
		rockets.AddInitializer<LifetimeInitializer>().Lifetime = .(0.05f, 0.05f);
		rockets.Emitter.Mode = .Burst;
		rockets.Emitter.BurstCount = 4;
		rockets.Emitter.BurstInterval = 0.0f;

		// Sparks, which emit nothing of their own.
		let sparks = effect.AddSystem(1000);
		sparks.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.0f);
		sparks.Emitter.IsEmitting = false;

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = 1;
		link.SpawnCount = 10;
		link.Probability = 1.0f;
		rockets.SubEmitters.Add(link); // the rockets' sub-emitter

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.016f);
		Test.Assert(rockets.AliveCount == 4);
		Test.Assert(sparks.AliveCount == 0);

		// The rockets age out, and each death spawns ten sparks.
		instance.Update(0.1f);
		Test.Assert(rockets.AliveCount == 0);
		Test.Assert(sparks.AliveCount == 40);
	}

	[Test]
	public static void SpawnAtAddsVelocityAndModulatesColour()
	{
		let effect = scope ParticleEffect("inherit");
		let child = effect.AddSystem(100);
		child.AddInitializer<VelocityInitializer>().BaseVelocity = .(1, 0, 0);
		child.AddInitializer<ColorInitializer>().Color = .Constant(.(1, 1, 1, 1));
		child.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);

		child.SpawnAt(1, .(0, 0, 0), .(0, 5, 0), .(1, 0, 0, 1));
		Test.Assert(child.AliveCount == 1);

		let velocity = child.Streams.Velocities[0];
		// The base is kept and the inherited part is ADDED to it.
		Test.Assert(Near(velocity.X, 1.0f));
		Test.Assert(Near(velocity.Y, 5.0f));

		let color = child.Streams.Colors[0];
		// White MODULATED by red.
		Test.Assert(Near(color.X, 1.0f));
		Test.Assert(Near(color.Y, 0.0f));
		Test.Assert(Near(color.Z, 0.0f));
	}

	[Test]
	public static void ALocalSpaceSystemSpawnsAtItsOwnOrigin()
	{
		let effect = scope ParticleEffect("local");
		let system = effect.AddSystem(100);
		system.SimulationSpace = .Local;
		system.AddInitializer<PositionInitializer>();
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 8;

		let instance = scope ParticleEffectInstance(effect);
		// A long way from the origin, which a world space system would spawn at.
		instance.Position = .(100, 0, 0);
		instance.Update(0.016f);

		Test.Assert(system.AliveCount == 8);
		Test.Assert(Length(system.Streams.Positions[0]) < 1.0f);
	}

	/// A world space system with nothing to place its particles bears them at the emitter,
	/// not at the origin or where a dead particle last was.
	[Test]
	public static void WithNoPositionInitializerParticlesAreBornAtTheEmitter()
	{
		let effect = scope ParticleEffect("unplaced");
		let system = effect.AddSystem(16);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(5.0f, 5.0f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 4;

		let instance = scope ParticleEffectInstance(effect);
		instance.Position = .(100, 2, -7);
		instance.Update(0.016f);
		Test.Assert(system.AliveCount == 4);
		for (int32 i < 4)
			Test.Assert(Length(system.Streams.Positions[i] - Float3(100, 2, -7)) < 0.01f, "at the emitter");

		// Reset clears the particles but not their slots: the next burst is born where the
		// emitter is NOW, not where the old ones were.
		instance.Reset();
		instance.Position = .(-50, 0, 3);
		instance.Update(0.016f);
		Test.Assert(system.AliveCount == 4);
		for (int32 i < 4)
			Test.Assert(Length(system.Streams.Positions[i] - Float3(-50, 0, 3)) < 0.01f, "not a dead particle's spot");
	}

	[Test]
	public static void StopDrainsAndPlayResumes()
	{
		let effect = scope ParticleEffect("drain");
		let system = effect.AddSystem(1000);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.1f, 0.1f);
		system.Emitter.SpawnRate = 200.0f;

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.05f);
		Test.Assert(system.AliveCount > 0);
		Test.Assert(!instance.IsFinished);

		instance.Stop();
		for (int i = 0; i < 30; i++)
			instance.Update(0.02f);
		// Emission stopped AND the live particles finished their lives.
		Test.Assert(instance.IsFinished);

		instance.Play();
		instance.Update(0.05f);
		Test.Assert(system.AliveCount > 0);
	}

	[Test]
	public static void ALinkNeverRoutesASystemIntoItself()
	{
		let effect = scope ParticleEffect("selfloop");
		let system = effect.AddSystem(1000);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.05f, 0.05f);
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 4;
		system.Emitter.BurstInterval = 0.0f;

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		// Pointed at the only system there is, which is its own parent.
		link.ChildSystemIndex = 0;
		link.SpawnCount = 10;
		system.SubEmitters.Add(link);

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.016f);
		instance.Update(0.1f);
		// The deaths route nowhere, so the system drains instead of feeding itself forever.
		Test.Assert(system.AliveCount == 0);
	}

	/// A sub-emitter spawns from its own system's events alone: two systems die at once (shells and
	/// smoke), one is spawned (sparks), and only the shells burst; a link into itself does nothing.
	[Test]
	public static void ASubEmitterSpawnsFromItsOwnSystemsDeathsOnly()
	{
		let effect = scope ParticleEffect("shells");
		let shells = effect.AddSystem(16);
		let smoke = effect.AddSystem(16);
		for (let dying in ParticleSystem[2](shells, smoke))
		{
			dying.AddInitializer<LifetimeInitializer>().Lifetime = .(0.05f, 0.05f);
			dying.Emitter.Mode = .Burst;
			dying.Emitter.BurstCount = 2;
			dying.Emitter.BurstInterval = 0.0f;
		}
		let sparks = effect.AddSystem(1000);
		sparks.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.0f);
		sparks.Emitter.IsEmitting = false;
		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = 2;
		link.SpawnCount = 5;
		shells.SubEmitters.Add(link);
		var self = SubEmitterLink.Default();
		self.Trigger = .OnDeath;
		self.ChildSystemIndex = 0; // into itself: does nothing
		shells.SubEmitters.Add(self);

		let instance = scope ParticleEffectInstance(effect);
		instance.Update(0.016f);
		instance.Update(0.1f); // both die: only the shells' deaths spawn sparks
		Test.Assert(sparks.AliveCount == 10, scope $"{sparks.AliveCount}");
		Test.Assert(shells.AliveCount == 0);
	}
}
