using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Particles.Resource.Tests;

/// The authoring path end to end: an effect built in code, cooked into a database, and bound
/// back through the manager with every polymorphic module rebuilt.
class ParticleEffectResourceTests
{
	private const String cEffectTypeName = "Sedulous.Particles.Resource.ParticleEffectResource";

	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A scratch database with the effect factory wired in.
	///
	/// The registry is its own for the RECORD, which is what the database resolves. The
	/// MODULES also land in the global table, because that is the only one an effect's
	/// Serialize can reach.
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;
		public ParticleEffectFactory Effects = new .() ~ delete _;

		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			ParticleResources.RegisterAll(Serializables);

			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
			Manager = new ResourceManager(Database, null);

			ParticleResources.AddFactories(Manager, Effects);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}

		public Guid Cook(StringView name, ParticleEffectResource resource)
		{
			let instance = Database.RootGroup.CreateInstance(name, cEffectTypeName);
			instance.WriteObject(resource).IgnoreError();
			return instance.Id;
		}
	}

	/// A fountain and a spark burst, linked so the fountain's deaths feed the sparks.
	private static void BuildEffect(ParticleEffect effect)
	{
		let fountain = effect.AddSystem(5000, 0xABCDEF01UL);
		fountain.Name.Set("fountain");
		fountain.BlendMode = .Additive;
		fountain.RenderMode = .Billboard;
		fountain.SortParticles = true;
		fountain.SoftDistance = 1.25f;
		fountain.Emitter.Mode = .Continuous;
		fountain.Emitter.SpawnRate = 250.0f;
		fountain.AddInitializer<PositionInitializer>().Shape = .Cone(0.4f, 0.35f);
		fountain.AddInitializer<LifetimeInitializer>().Lifetime = .(1.5f, 2.5f);
		fountain.AddInitializer<VelocityInitializer>().BaseVelocity = .(0, 9, 0);
		fountain.AddInitializer<ColorInitializer>().Color = .(.(1, 0.5f, 0.1f, 1),
			.(1, 0.9f, 0.3f, 1));
		fountain.AddBehavior<GravityBehavior>().Multiplier = 1.4f;
		fountain.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.4f);

		let sparks = effect.AddSystem(2000);
		sparks.Name.Set("sparks");
		sparks.Emitter.IsEmitting = false;
		sparks.AddInitializer<LifetimeInitializer>().Lifetime = .(0.5f, 1.0f);
		sparks.AddBehavior<CollisionBehavior>().Bounce = 0.6f;

		var link = SubEmitterLink.Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = 1;
		link.SpawnCount = 12;
		effect.AddSubEmitterLink(link);
	}

	[Test]
	public static void ACookedEffectBindsBackWithItsModulesRebuilt()
	{
		let fixture = scope Fixture("scratch_particle_resource");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null);
		let effect = bound.Get.Effect;

		Test.Assert(effect.SystemCount == 2);
		Test.Assert(effect.SubEmitterLinks.Length == 1);

		let fountain = effect.GetSystem(0);
		Test.Assert(fountain.Name == "fountain");
		Test.Assert(fountain.MaxParticles == 5000);
		Test.Assert(fountain.Seed == 0xABCDEF01UL);
		Test.Assert(fountain.BlendMode == .Additive);
		Test.Assert(fountain.SortParticles);
		Test.Assert(Near(fountain.SoftDistance, 1.25f));
		Test.Assert(Near(fountain.Emitter.SpawnRate, 250.0f));
		Test.Assert(fountain.InitializerCount == 4);
		Test.Assert(fountain.BehaviorCount == 2);

		// Rebuilt as the right CONCRETE type, in the authored order.
		Test.Assert(fountain.GetInitializer(0) is PositionInitializer);
		Test.Assert(fountain.GetBehavior(1) is AlphaOverLifetimeBehavior);

		let sparks = effect.GetSystem(1);
		Test.Assert(!sparks.Emitter.IsEmitting);
		Test.Assert(sparks.BehaviorCount == 1);
	}

	[Test]
	public static void ARebuiltEffectStillSimulates()
	{
		let fixture = scope Fixture("scratch_particle_resource_sim");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null);

		// The modules declared their streams as they were added back, so the reconstructed
		// effect runs rather than reading channels nothing allocated.
		let instance = scope ParticleEffectInstance(bound.Get.Effect);
		instance.Update(0.1f);
		Test.Assert(bound.Get.Effect.GetSystem(0).AliveCount > 0);
	}

	[Test]
	public static void AModulesParametersSurviveTheRoundTrip()
	{
		let fixture = scope Fixture("scratch_particle_resource_params");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null);
		let fountain = bound.Get.Effect.GetSystem(0);

		let gravity = fountain.GetBehavior(0) as GravityBehavior;
		Test.Assert(gravity != null);
		Test.Assert(Near(gravity.Multiplier, 1.4f));

		let lifetime = fountain.GetInitializer(1) as LifetimeInitializer;
		Test.Assert(lifetime != null);
		Test.Assert(Near(lifetime.Lifetime.Min, 1.5f));
		Test.Assert(Near(lifetime.Lifetime.Max, 2.5f));

		let shape = (fountain.GetInitializer(0) as PositionInitializer).Shape;
		Test.Assert(shape.Type == .Cone);
		Test.Assert(Near(shape.Radius, 0.4f));
		Test.Assert(Near(shape.Angle, 0.35f));

		// The hand written body: its counts and its shapes.
		let collision = bound.Get.Effect.GetSystem(1).GetBehavior(0) as CollisionBehavior;
		Test.Assert(collision != null);
		Test.Assert(Near(collision.Bounce, 0.6f));
		Test.Assert(collision.PlaneCount == 1);
	}

	[Test]
	public static void MeshAndMaterialReferencesSurviveAClone()
	{
		var rng = Sedulous.Core.Random(0x1234);
		let meshId = Guid.Generate(ref rng);
		let firstMaterial = Guid.Generate(ref rng);
		let secondMaterial = Guid.Generate(ref rng);

		let source = scope ParticleEffect();
		let system = source.AddSystem(100);
		system.RenderMode = .Mesh;
		system.MeshRef = meshId;
		system.MeshScale = 2.5f;
		// Two submesh slots, whose ORDER is what indexes them.
		system.MaterialRefs.Add(firstMaterial);
		system.MaterialRefs.Add(secondMaterial);

		let registry = scope SerializableRegistry();
		ParticleResources.RegisterAll(registry);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		// The clone the cook bakes an authored effect with.
		let destination = scope ParticleEffect();
		Test.Assert(ParticleEffectSerialization.CloneEffect(source, destination, serializers)
			case .Ok);

		let copy = destination.GetSystem(0);
		Test.Assert(copy != null);
		Test.Assert(copy.RenderMode == .Mesh);
		Test.Assert(copy.MeshRef == meshId);
		Test.Assert(Near(copy.MeshScale, 2.5f));
		Test.Assert(copy.MaterialRefs.Count == 2);
		Test.Assert(copy.MaterialRefs[0] == firstMaterial);
		Test.Assert(copy.MaterialRefs[1] == secondMaterial);
	}

	[Test]
	public static void AnUnknownModuleTypeIsSkippedRatherThanFailingTheEffect()
	{
		let fixture = scope Fixture("scratch_particle_resource_unknown");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		// A build that no longer knows what a gravity behaviour is. Put back at the end, since
		// the module table is process wide.
		let gravityId = TypeIdOf("Sedulous.Particles.GravityBehavior");
		GlobalSerializableRegistry.Unregister(gravityId);
		defer GlobalSerializableRegistry.Register(gravityId, () => new GravityBehavior());

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null);
		let fountain = bound.Get.Effect.GetSystem(0);

		// The unknown module is dropped and the rest of the effect still loads.
		Test.Assert(fountain.BehaviorCount == 1);
		Test.Assert(fountain.GetBehavior(0) is AlphaOverLifetimeBehavior);
		Test.Assert(fountain.InitializerCount == 4);
	}

	/// Skipping a module must not shift the SYSTEM after it.
	///
	/// This is what the framing is for. Unframed, an unknown module's parameters stay in the
	/// positional stream and everything behind them slides: the next system's particle budget
	/// is then read out of the middle of a curve, and a budget read as garbage is a runaway
	/// allocation rather than a wrong-looking effect. Raptor cannot skip at all for exactly
	/// this reason; the frame is what buys the choice.
	[Test]
	public static void ASkippedModuleDoesNotShiftTheNextSystem()
	{
		let fixture = scope Fixture("scratch_particle_resource_shift");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		// The dropped module sits in system ZERO, so system one is downstream of the hole.
		let gravityId = TypeIdOf("Sedulous.Particles.GravityBehavior");
		GlobalSerializableRegistry.Unregister(gravityId);
		defer GlobalSerializableRegistry.Register(gravityId, () => new GravityBehavior());

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null);
		Test.Assert(bound.Get.Effect.SystemCount == 2, "both systems still arrived");

		let sparks = bound.Get.Effect.GetSystem(1);
		Test.Assert(sparks != null);
		Test.Assert(sparks.Name == "sparks", "the name after the hole is not garbage");
		Test.Assert(sparks.MaxParticles == 2000, scope $"budget read as {sparks.MaxParticles}");
		Test.Assert(!sparks.Emitter.IsEmitting, "and its emitter flag survived");
		Test.Assert(sparks.InitializerCount == 1);
		Test.Assert(sparks.BehaviorCount == 1);
	}

	/// A type id that still constructs, but into the WRONG KIND, is skipped like an unknown
	/// one rather than misread as the kind the slot expected.
	///
	/// Constructible but wrong is the nastier half: the object exists, so a build that only
	/// checked for null would hand it the next module's parameters to parse.
	[Test]
	public static void ATypeOfTheWrongKindInAModuleSlotIsSkipped()
	{
		let fixture = scope Fixture("scratch_particle_resource_wrongkind");

		let record = scope ParticleEffectResource();
		BuildEffect(record.Effect);
		let id = fixture.Cook("effect", record);

		// The lifetime slot now constructs a BEHAVIOUR: registered, constructible, and not an
		// initializer.
		let lifetimeId = TypeIdOf("Sedulous.Particles.LifetimeInitializer");
		GlobalSerializableRegistry.Unregister(lifetimeId);
		GlobalSerializableRegistry.Register(lifetimeId, () => new GravityBehavior());
		defer
		{
			GlobalSerializableRegistry.Unregister(lifetimeId);
			GlobalSerializableRegistry.Register(lifetimeId, () => new LifetimeInitializer());
		}

		let bound = fixture.Manager.Bind<ParticleEffectResource>(id);
		Test.Assert(bound.Get != null, "the effect still loads");

		let fountain = bound.Get.Effect.GetSystem(0);
		Test.Assert(fountain.InitializerCount == 3, "the wrong-kind slot was dropped, not kept");
		Test.Assert(fountain.BehaviorCount == 2, "and nothing after it was misread");

		// The system behind the hole is intact, which is the alignment claim again.
		let sparks = bound.Get.Effect.GetSystem(1);
		Test.Assert(sparks.MaxParticles == 2000, scope $"budget read as {sparks.MaxParticles}");
	}
}
