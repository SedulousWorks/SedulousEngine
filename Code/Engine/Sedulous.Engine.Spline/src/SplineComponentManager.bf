using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Spline;

namespace Sedulous.Engine.Spline;

/// The pool of authored curves.
///
/// It creates and frees the curve each component points at: a component is a struct in a
/// packed pool, so it cannot own one itself. Raptor holds the curve BY VALUE and lets the
/// vector's destructor deal with it.
class SplineComponentManager : SerializableComponentManager<SplineComponent>
{
	/// BORROWED: the scene owns this manager. Needed because every query answers in WORLD
	/// space, and the entity transform is what places the curve.
	private Scene mScene = null;

	public override void OnSceneCreate(Scene scene) => mScene = scene;

	protected override void OnComponentCreated(SplineComponent* component, EntityHandle entity)
	{
		component.Curve = new SplineCurve();
	}

	/// A component that reaches its first Initialize phase with NO points was added bare (the
	/// editor's Add Component, a script): it is seeded. A loaded or spawned one has its
	/// points by then and is left alone.
	protected override void OnComponentInitialized(SplineComponent* component, EntityHandle entity)
	{
		if (component.Curve.Points.IsEmpty)
			SplineComponent.SeedDefault(component.Curve);
	}

	protected override void OnComponentDestroyed(SplineComponent* component, EntityHandle entity)
	{
		delete component.Curve;
		component.Curve = null;
	}

	// ---- queries -------------------------------------------------------------------------
	//
	// Raptor exposes these on a free SceneSplines facade bound to a scene, because a script
	// needs a value it can hold. They live on the manager here: it already owns the
	// components and knows the scene, so the facade's scene argument and its "is this my
	// scene" guard have nothing left to do.
	//
	// Points are stored ENTITY LOCAL and every answer is world space: the entity transform is
	// what places the curve.

	/// The curve length, or nought when the entity carries no spline.
	public float Length(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) ? component.Curve.Length : 0.0f;
	}

	public int32 PointCount(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) ? (int32)component.Curve.Points.Count : 0;
	}

	public bool IsClosed(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) && component.Curve.Closed;
	}

	/// Samples at the curve PARAMETER, which runs to the segment count and wraps on a closed
	/// curve.
	public SplineHit SampleAt(EntityHandle entity, float t)
	{
		let component = Get(entity);
		if ((component == null) || (mScene == null))
			return .();

		return MakeHit(component.Curve, t, mScene.GetWorldMatrix(entity));
	}

	/// Samples at a DISTANCE along the curve, which is evenly spaced where the parameter is
	/// not: the arc length table is what makes the difference.
	public SplineHit SampleAtDistance(EntityHandle entity, float distance)
	{
		let component = Get(entity);
		if ((component == null) || (mScene == null))
			return .();

		return MakeHit(component.Curve, component.Curve.DistanceToT(distance),
			mScene.GetWorldMatrix(entity));
	}

	/// The point on the curve nearest a WORLD position.
	///
	/// Takes a Float3 where Raptor takes three floats, which is a script signature rather
	/// than a choice about the query.
	public SplineHit ClosestPoint(EntityHandle entity, Float3 world)
	{
		let component = Get(entity);
		if ((component == null) || (mScene == null))
			return .();

		let toWorld = mScene.GetWorldMatrix(entity);
		// The query point goes INTO curve space, and the sample comes back out of it.
		let local = TransformPoint(world, Inverse(toWorld));
		let sample = component.Curve.ClosestPoint(local);
		return MakeHit(component.Curve, sample.T, toWorld);
	}

	private static SplineHit MakeHit(SplineCurve curve, float t, Float4x4 toWorld)
	{
		var hit = SplineHit();
		hit.Valid = true;
		hit.T = t;
		hit.Position = TransformPoint(curve.Evaluate(t), toWorld);
		hit.Tangent = Normalized(TransformDirection(curve.Tangent(t), toWorld));
		return hit;
	}
}
