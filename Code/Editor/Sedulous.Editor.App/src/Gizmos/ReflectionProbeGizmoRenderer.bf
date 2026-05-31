namespace Sedulous.Editor.App;

using System;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Renderer.Debug;
using Sedulous.Core.Mathematics;

/// Draws debug wireframes for reflection probe components:
/// - Wireframe box for the local influence bounds (full-weight region)
/// - Wireframe sphere for the influence radius (full-to-zero falloff)
/// - Small cross at the probe's capture origin
class ReflectionProbeGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(ReflectionProbeComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(Component component, GizmoContext ctx)
	{
		let probe = component as ReflectionProbeComponent;
		if (probe == null || probe.Owner == .Invalid) return;

		let scene = ctx.Scene;
		if (scene == null) return;

		let dbg = ctx.DebugDraw;
		if (dbg == null) return;

		let position = scene.GetWorldMatrix(probe.Owner).Translation;

		// Cool blue for probe gizmos so they read as distinct from light gizmos.
		let boxColor = Color(0.4f, 0.7f, 1.0f);
		let sphereColor = Color(0.3f, 0.5f, 0.9f);

		// Influence box: full-weight region. Translate local-space bounds to world.
		BoundingBox worldBox = .(position + probe.LocalBoxMin, position + probe.LocalBoxMax);
		dbg.DrawWireBox(worldBox, boxColor);

		// Influence sphere: outer falloff radius.
		dbg.DrawWireSphere(position, probe.InfluenceRadius, sphereColor, 24);

		// Small cross at capture origin for visibility when bounds are large.
		let r = 0.2f;
		dbg.DrawLine(position - Vector3(r, 0, 0), position + Vector3(r, 0, 0), boxColor);
		dbg.DrawLine(position - Vector3(0, r, 0), position + Vector3(0, r, 0), boxColor);
		dbg.DrawLine(position - Vector3(0, 0, r), position + Vector3(0, 0, r), boxColor);
	}

	public void Dispose() { }
}
