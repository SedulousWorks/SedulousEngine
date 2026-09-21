using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Spline;
using Sedulous.Engine.Spline;

namespace Sedulous.Engine.Spline.Tests;

/// The authored curve as scene data, and the follower that walks it.
class SplineComponentTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// What was authored comes back, and the DERIVED caches are rebuilt rather than stored.
	[Test]
	public static void SerializationRoundTripsThePointsAndRebuildsTheCaches()
	{
		// The manager owns the curve in a live scene; standing one up by hand here keeps the
		// case about the payload.
		let authoredCurve = scope SplineCurve();
		authoredCurve.Points.Add(SplinePoint(.(0, 0, 0)));
		var middle = SplinePoint(.(5, 1, 0), .Broken);
		middle.InHandle = .(-1, 0, 0);
		middle.OutHandle = .(1, 0, 0);
		authoredCurve.Points.Add(middle);
		authoredCurve.Points.Add(SplinePoint(.(10, 0, 4)));
		authoredCurve.Closed = true;
		authoredCurve.UpdateAutoHandles();
		authoredCurve.RebuildArcLength();

		var authored = SplineComponent();
		authored.Curve = authoredCurve;

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			authored.Serialize(writer);
			Test.Assert(writer.IsOk);
		}

		buffer.Seek(0, .Begin);
		let loadedCurve = scope SplineCurve();
		var loaded = SplineComponent();
		loaded.Curve = loadedCurve;
		{
			let reader = scope BinarySerializer(buffer, .Read);
			loaded.Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(loadedCurve.Points.Count == 3);
		Test.Assert(loadedCurve.Closed);
		Test.Assert(Near(loadedCurve.Points[1].Position.X, 5.0f));
		Test.Assert(Near(loadedCurve.Points[1].Position.Y, 1.0f));
		Test.Assert(Near(loadedCurve.Points[1].InHandle.X, -1.0f));
		Test.Assert(loadedCurve.Points[1].Mode == .Broken);

		// Rebuilt on read, so the loaded curve evaluates identically.
		Test.Assert(Near(loadedCurve.Length, authoredCurve.Length));
		let sampled = loadedCurve.Evaluate(1.5f);
		let expected = authoredCurve.Evaluate(1.5f);
		Test.Assert(Near(sampled.X, expected.X) && Near(sampled.Y, expected.Y)
			&& Near(sampled.Z, expected.Z));
	}

	/// Add Component in the editor, or a script: no points until the Initialize phase runs,
	/// which seeds a segment; a component that already has its points is left alone.
	[Test]
	public static void AddedBareItIsSeededAtItsFirstInitializeAndLoadedPointsAreKept()
	{
		let scene = scope Scene();
		let splines = scene.AddSystem<SplineComponentManager>();

		let bare = scene.CreateEntity("bare");
		let added = splines.Add(bare);
		Test.Assert(added.PointCount() == 0);
		let loaded = scene.CreateEntity("loaded");
		let kept = splines.Add(loaded);
		for (let x in scope float[](0.0f, 1.0f, 2.0f))
			kept.Curve.Points.Add(SplinePoint(.(x, 0.0f, 0.0f)));

		scene.InitializePendingComponents();
		Test.Assert(splines.Get(bare).PointCount() == 2, "the seed: a segment along local X");
		Test.Assert(splines.Get(bare).Curve.Points[0].Position.X == -1.0f);
		Test.Assert(splines.Get(bare).Curve.Points[1].Position.X == 1.0f);
		Test.Assert(splines.Get(bare).Curve.Length > 1.9f, "caches rebuilt with the seed");
		Test.Assert(splines.Get(loaded).PointCount() == 3);
		Test.Assert(splines.Get(loaded).Curve.Points[0].Position.X == 0.0f);

		// The inspector's rows: the loop flag goes through the curve and rebuilds its arc
		// length.
		let three = splines.Get(loaded);
		three.Curve.UpdateAutoHandles();
		three.Curve.RebuildArcLength();
		let open = three.Curve.Length;
		Test.Assert(!three.IsClosed());
		three.SetClosed(true);
		Test.Assert(three.IsClosed());
		Test.Assert(three.Curve.Length > open, "the closing segment is in the table now");
		three.SetClosed(false);
		Test.Assert(Near(three.Curve.Length, open));
	}

	/// Every query answers in WORLD space: the points are stored entity local, and the
	/// entity transform is what places them.
	[Test]
	public static void TheQueriesAnswerInWorldSpace()
	{
		let scene = scope Scene("splines");
		SplineScene.AddSplineSceneManagers(scene);
		let manager = scene.GetSystem<SplineComponentManager>();
		Test.Assert(manager != null);

		let entity = scene.CreateEntity("path");
		let component = manager.Add(entity);
		component.Curve.Points.Add(SplinePoint(.(0, 0, 0)));
		component.Curve.Points.Add(SplinePoint(.(10, 0, 0)));
		component.Curve.UpdateAutoHandles();
		component.Curve.RebuildArcLength();

		// Lifted five units, so a local answer and a world one cannot be confused.
		var placed = Transform();
		placed.Position = .(0, 5, 0);
		scene.SetLocalTransform(entity, placed);
		scene.UpdateTransforms();

		Test.Assert(manager.PointCount(entity) == 2);
		Test.Assert(!manager.IsClosed(entity));
		Test.Assert(Near(manager.Length(entity), 10.0f));

		let mid = manager.SampleAtDistance(entity, 5.0f);
		Test.Assert(mid.Valid);
		Test.Assert(Near(mid.Position.X, 5.0f, 0.05f) && Near(mid.Position.Y, 5.0f, 0.05f));
		Test.Assert(Near(mid.Tangent.X, 1.0f) && Near(mid.Tangent.Y, 0.0f));

		let nearest = manager.ClosestPoint(entity, .(3, 9, 0));
		Test.Assert(nearest.Valid);
		Test.Assert(Near(nearest.Position.X, 3.0f, 0.05f) && Near(nearest.Position.Y, 5.0f, 0.05f));

		// No spline on the entity gives the INVALID hit, zeroed, rather than an error.
		let bare = scene.CreateEntity("bare");
		Test.Assert(!manager.SampleAt(bare, 0.5f).Valid);
		Test.Assert(manager.Length(bare) == 0.0f);
	}

	/// Builds a scene with a straight ten unit path and a follower on it.
	private static void MakePath(Scene scene, out EntityHandle path, out EntityHandle mover)
	{
		SplineScene.AddSplineSceneManagers(scene);
		scene.SetSimulationEnabled(true);

		path = scene.CreateEntity("path");
		let spline = scene.GetSystem<SplineComponentManager>().Add(path);
		spline.Curve.Points.Add(SplinePoint(.(0, 0, 0)));
		spline.Curve.Points.Add(SplinePoint(.(10, 0, 0)));
		spline.Curve.UpdateAutoHandles();
		spline.Curve.RebuildArcLength();

		mover = scene.CreateEntity("mover");
	}

	[Test]
	public static void TheFollowerAdvancesAlignsAndStopsAtAnOpenEnd()
	{
		let scene = scope Scene("follow");
		MakePath(scene, let path, let mover);

		let follow = scene.GetSystem<PathFollowComponentManager>().Add(mover);
		follow.Spline = .(scene.GetEntityId(path));
		follow.Speed = 2.0f;
		follow.Loop = false;
		scene.UpdateTransforms();

		scene.Update(1.0f); // two units along +X
		let afterOne = scene.GetWorldPosition(mover);
		Test.Assert(Near(afterOne.X, 2.0f, 0.05f));
		Test.Assert(Near(afterOne.Y, 0.0f));

		// Aligned: the follower's -Z points along the tangent.
		let transform = scene.GetLocalTransform(mover);
		let forward = RotateVector(transform.Rotation, Float3(0, 0, -1));
		Test.Assert(Near(forward.X, 1.0f) && Near(forward.Y, 0.0f) && Near(forward.Z, 0.0f));

		// Past the end it clamps and stops rather than running on.
		for (int i < 10)
			scene.Update(1.0f);

		Test.Assert(Near(scene.GetWorldPosition(mover).X, 10.0f));
		Test.Assert(!scene.GetSystem<PathFollowComponentManager>().Get(mover).Playing);
	}

	[Test]
	public static void ALoopingFollowerWrapsInsteadOfStopping()
	{
		let scene = scope Scene("follow_loop");
		MakePath(scene, let path, let mover);

		let follow = scene.GetSystem<PathFollowComponentManager>().Add(mover);
		follow.Spline = .(scene.GetEntityId(path));
		follow.Speed = 4.0f;
		follow.Loop = true;
		scene.UpdateTransforms();

		scene.Update(3.0f); // twelve units, which wraps to two
		Test.Assert(Near(scene.GetWorldPosition(mover).X, 2.0f, 0.05f));
		Test.Assert(scene.GetSystem<PathFollowComponentManager>().Get(mover).Playing);
	}
}
