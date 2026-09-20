using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Spline;
using Sedulous.Engine.Spline;

namespace Sedulous.Editor.Scene;

/// The curve, sampled per segment, and a sphere at every control point.
class SplineGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(SplineComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let spline = (SplineComponent*)component;
		let curve = spline.Curve;
		if (curve == null)
			return;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let curveColor = Color(0.35f, 0.85f, 1.0f, 1.0f);
		let segments = curve.SegmentCount;
		if (segments > 0)
		{
			let steps = segments * SplineCurve.SamplesPerSegment;
			var previous = TransformPoint(curve.Evaluate(0.0f), world);
			for (uint32 i = 1; i <= steps; i++)
			{
				let t = curve.MaxT * (float)i / (float)steps;
				let position = TransformPoint(curve.Evaluate(t), world);
				ctx.Debug.DrawLine(previous, position, curveColor);
				previous = position;
			}
		}
		for (let point in curve.Points)
			ctx.Debug.DrawWireSphere(TransformPoint(point.Position, world), 0.1f, .(1.0f, 0.85f, 0.2f, 1.0f), 12);
	}
}
