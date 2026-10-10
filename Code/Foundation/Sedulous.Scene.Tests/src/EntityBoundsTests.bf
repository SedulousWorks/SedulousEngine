using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// Scene.EntityWorldBounds merges what every measuring system (ISceneEntityBounds) answers,
/// and says when none does.
class EntityBoundsTests
{
	/// Measures one entity as a fixed box: what a render or physics domain answers.
	private class MeshMeasure : SceneSystem, ISceneEntityBounds
	{
		public EntityHandle Entity = .Invalid;
		public AABB Box = .();
		public override ISceneEntityBounds AsEntityBounds => this;

		public bool EntityBounds(Scene scene, EntityHandle entity, out AABB outBounds)
		{
			outBounds = Box;
			return entity == Entity;
		}
	}

	/// A second domain, a collider reaching further.
	private class ColliderMeasure : MeshMeasure
	{
	}

	[Test]
	public static void EveryMeasuringSystemsAnswerMergesAndNoneIsFalse()
	{
		let scene = scope Scene();
		let crate = scene.CreateEntity("Crate");
		let marker = scene.CreateEntity("Marker");

		// No system measures anything yet.
		Test.Assert(!scene.EntityWorldBounds(crate, ?));

		// One system: its box.
		let mesh = scene.AddSystem<MeshMeasure>();
		mesh.Entity = crate;
		mesh.Box = .(.(0.0f, 0.0f, 0.0f), .(1.0f, 2.0f, 1.0f));
		Test.Assert(scene.EntityWorldBounds(crate, let one));
		Test.Assert(one.Max.Y == 2.0f);

		// A second one: the box holding both.
		let collider = scene.AddSystem<ColliderMeasure>();
		collider.Entity = crate;
		collider.Box = .(.(-1.0f, 0.0f, 0.0f), .(0.5f, 1.0f, 3.0f));
		Test.Assert(scene.EntityWorldBounds(crate, let both));
		Test.Assert((both.Min.X == -1.0f) && (both.Max.Y == 2.0f) && (both.Max.Z == 3.0f));

		// An entity neither measures.
		Test.Assert(!scene.EntityWorldBounds(marker, ?));
	}
}
