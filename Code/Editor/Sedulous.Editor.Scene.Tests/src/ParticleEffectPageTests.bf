using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Particles;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The particle page's headless halves: the seed, the module catalogue, the tree snapshot,
/// the undo snapshot and the creator.
class ParticleEffectPageTests
{
	[Test]
	public static void TheDefaultSeedIsAOneSystemFountainWithTheCoreModules()
	{
		let fx = scope ParticleEffect();
		ParticleEffectEdit.SeedDefault(fx);
		Test.Assert(fx.SystemCount == 1);
		let sys = fx.GetSystem(0);
		Test.Assert(sys != null);
		Test.Assert(sys.Emitter.Mode == .Continuous);
		Test.Assert(Math.Abs(sys.Emitter.SpawnRate - 120.0f) < 1e-4f);

		LifetimeInitializer life = null;
		VelocityInitializer vel = null;
		SizeInitializer size = null;
		ColorInitializer color = null;
		for (int32 i < sys.InitializerCount)
		{
			if (let p = sys.GetInitializer(i) as LifetimeInitializer) life = p;
			if (let p = sys.GetInitializer(i) as VelocityInitializer) vel = p;
			if (let p = sys.GetInitializer(i) as SizeInitializer) size = p;
			if (let p = sys.GetInitializer(i) as ColorInitializer) color = p;
		}
		Test.Assert((life != null) && (vel != null) && (size != null) && (color != null));
		Test.Assert(Math.Abs(life.Lifetime.Min - 1.5f) < 1e-4f);
		Test.Assert(Math.Abs(life.Lifetime.Max - 2.5f) < 1e-4f);
		Test.Assert(vel.BaseVelocity.Y == 5.0f);

		GravityBehavior grav = null;
		for (int32 i < sys.BehaviorCount)
		{
			if (let p = sys.GetBehavior(i) as GravityBehavior)
				grav = p;
		}
		Test.Assert(grav != null);
	}

	[Test]
	public static void TheCatalogueAddsEveryModuleKindInMenuOrder()
	{
		let fx = scope ParticleEffect();
		let sys = fx.AddSystem(64);
		for (int k < ParticleEffectEdit.InitializerNames.Count)
			Test.Assert(ParticleEffectEdit.AddInitializer(sys, k) != null);
		Test.Assert(ParticleEffectEdit.AddInitializer(sys, 99) == null);
		Test.Assert(sys.InitializerCount == ParticleEffectEdit.InitializerNames.Count);
		Test.Assert(sys.GetInitializer(0) is PositionInitializer);
		Test.Assert(sys.GetInitializer(6) is MeshOrientationInitializer);

		for (int k < ParticleEffectEdit.BehaviorNames.Count)
			Test.Assert(ParticleEffectEdit.AddBehavior(sys, k) != null);
		Test.Assert(ParticleEffectEdit.AddBehavior(sys, -1) == null);
		Test.Assert(sys.BehaviorCount == ParticleEffectEdit.BehaviorNames.Count);
		Test.Assert(sys.GetBehavior(0) is GravityBehavior);
		Test.Assert(sys.GetBehavior(7) is CollisionBehavior);
		Test.Assert(sys.GetBehavior(12) is SpeedOverLifetimeBehavior);

		// The label is the type's short name; the gizmo shape is the first position initializer's.
		Test.Assert(ParticleEffectEdit.ModuleLabel(sys.GetBehavior(0), .. scope .()) == "GravityBehavior");
		let shape = ParticleEffectEdit.EmissionShapeOf(sys);
		Test.Assert((shape != null) && (shape == &((PositionInitializer)sys.GetInitializer(0)).Shape));
		let bare = fx.AddSystem(8);
		Test.Assert(ParticleEffectEdit.EmissionShapeOf(bare) == null);
	}

	[Test]
	public static void TheTreeSnapshotListsSystemsEmittersAndModuleFolders()
	{
		let fx = scope ParticleEffect();
		ParticleEffectEdit.SeedDefault(fx);
		fx.GetSystem(0).Name.Set("Sparks");
		fx.AddSystem(16); // unnamed: labelled by index

		let snapshot = scope ParticleTreeSnapshot();
		snapshot.Rebuild(fx);
		// Root + per system: the system, its emitter, two folders; plus 4 initializers and 1 behavior.
		Test.Assert(snapshot.Roots.Count == 1);
		Test.Assert(snapshot.Nodes.Count == 1 + 4 + 4 + 5);
		let root = snapshot.Nodes[snapshot.Roots[0]];
		Test.Assert((root.Kind == .Effect) && (root.Children.Count == 2));
		let sparks = snapshot.Nodes[root.Children[0]];
		Test.Assert((sparks.Kind == .System) && (sparks.Label == "Sparks") && (sparks.Depth == 1));
		Test.Assert(snapshot.Nodes[root.Children[1]].Label == "System 1");
		Test.Assert(sparks.Children.Count == 3);
		Test.Assert(snapshot.Nodes[sparks.Children[0]].Kind == .Emitter);
		let inits = snapshot.Nodes[sparks.Children[1]];
		Test.Assert((inits.Kind == .InitializersFolder) && (inits.Label == "Initializers (4)") && (inits.Children.Count == 4));
		let behs = snapshot.Nodes[sparks.Children[2]];
		Test.Assert((behs.Kind == .BehaviorsFolder) && (behs.Children.Count == 1));
		let grav = snapshot.Nodes[behs.Children[0]];
		Test.Assert((grav.Kind == .Behavior) && (grav.SystemIndex == 0) && (grav.ModuleIndex == 0) && (grav.Depth == 3));
		Test.Assert(grav.Label == "GravityBehavior");

		// Lookup by ref survives a rebuild; an absent ref is -1.
		Test.Assert(snapshot.NodeIdForRef(.(.Behavior, 0, 0)) == behs.Children[0]);
		Test.Assert(snapshot.NodeIdForRef(.Root) == snapshot.Roots[0]);
		Test.Assert(snapshot.NodeIdForRef(.(.Initializer, 1, 0)) == -1);
		snapshot.Rebuild(null);
		Test.Assert(snapshot.Nodes.IsEmpty);
	}

	[Test]
	public static void SnapshotRestoresTheSystemSetAndModuleFields()
	{
		ParticleModules.RegisterModules();
		let fx = scope ParticleEffect();
		ParticleEffectEdit.SeedDefault(fx);
		let before = scope List<uint8>();
		ParticleEffectEdit.Snapshot(fx, before);
		Test.Assert(before.Count > 0);
		Test.Assert(!ParticleEffectEdit.Apply(fx, before));

		// A field edit, a module added, a second system.
		((GravityBehavior)fx.GetSystem(0).GetBehavior(0)).Multiplier = 3.0f;
		fx.GetSystem(0).AddBehavior<DragBehavior>();
		fx.AddSystem(32);
		let after = scope List<uint8>();
		ParticleEffectEdit.Snapshot(fx, after);

		Test.Assert(ParticleEffectEdit.Apply(fx, before));
		Test.Assert(fx.SystemCount == 1);
		Test.Assert(fx.GetSystem(0).BehaviorCount == 1);
		Test.Assert(((GravityBehavior)fx.GetSystem(0).GetBehavior(0)).Multiplier == 1.0f);

		Test.Assert(ParticleEffectEdit.Apply(fx, after));
		Test.Assert(fx.SystemCount == 2);
		Test.Assert(fx.GetSystem(0).BehaviorCount == 2);
		Test.Assert(fx.GetSystem(0).GetBehavior(1) is DragBehavior);
		Test.Assert(((GravityBehavior)fx.GetSystem(0).GetBehavior(0)).Multiplier == 3.0f);
	}

	[Test]
	public static void TheCreatorSeedsAnEffectUnderParticleEffects()
	{
		ParticleModules.RegisterModules();
		ParticlesPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_particle_creator_test", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let ctx = scope EditorContext();
		ctx.SetProject(project);

		let empty = scope EditorContext();
		Test.Assert(ParticleAssetCreators.CreateParticleEffectInstance(empty, null) == null);

		let first = ParticleAssetCreators.CreateParticleEffectInstance(ctx, null);
		Test.Assert(first != null);
		Test.Assert(first.GetPath(.. scope .()) == "ParticleEffects/ParticleEffect");
		Test.Assert(AssetTypeNames.Matches(first.TypeName, "ParticleEffectAsset"));
		let object = first.ReadObject();
		defer delete object;
		let asset = object as ParticleEffectAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.Effect.SystemCount == 1);
		Test.Assert(asset.Effect.GetSystem(0).InitializerCount == 4);

		let second = ParticleAssetCreators.CreateParticleEffectInstance(ctx, null);
		Test.Assert((second != null) && (second.GetPath(.. scope .()) == "ParticleEffects/ParticleEffect.2"));
	}
}
