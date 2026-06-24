namespace Sedulous.Editor;

using System;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Renderer.Debug;
using Sedulous.Core.Mathematics;

/// Draws a wireframe sphere showing the reflection probe's influence radius.
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

		let worldMatrix = scene.GetWorldMatrix(probe.Owner);
		let position = worldMatrix.Translation;

		// Influence sphere
		let color = Color(100, 200, 255);
		dbg.DrawWireSphere(position, probe.InfluenceRadius, color, 32);

		// Small diamond at center for visibility when sphere is large
		let r = 0.2f;
		dbg.DrawLine(position - Vector3(r, 0, 0), position + Vector3(r, 0, 0), color);
		dbg.DrawLine(position - Vector3(0, r, 0), position + Vector3(0, r, 0), color);
		dbg.DrawLine(position - Vector3(0, 0, r), position + Vector3(0, 0, r), color);
	}

	public void Dispose() { }
}
