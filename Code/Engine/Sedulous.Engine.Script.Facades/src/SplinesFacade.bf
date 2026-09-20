using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Spline;
using Sedulous.Engine.Spline;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Splines`: reading an entity's spline.
[Scriptable, SceneFacade("Splines")]
class SplinesFacade : SceneFacade
{
	private SplineComponentManager Splines => Scene.GetSystem<SplineComponentManager>();

	[Scriptable]
	public float Length(EntityHandle entity) => Splines?.Length(entity) ?? 0.0f;
	[Scriptable]
	public int32 PointCount(EntityHandle entity) => Splines?.PointCount(entity) ?? 0;
	[Scriptable]
	public bool IsClosed(EntityHandle entity) => Splines?.IsClosed(entity) ?? false;
	[Scriptable]
	public SplineHit SampleAt(EntityHandle entity, float t) => Splines?.SampleAt(entity, t) ?? .();
	[Scriptable]
	public SplineHit SampleAtDistance(EntityHandle entity, float distance) => Splines?.SampleAtDistance(entity, distance) ?? .();
	[Scriptable]
	public SplineHit ClosestPoint(EntityHandle entity, Float3 world) => Splines?.ClosestPoint(entity, world) ?? .();
}
