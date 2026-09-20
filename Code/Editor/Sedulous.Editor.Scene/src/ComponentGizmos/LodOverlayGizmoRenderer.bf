using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene;

/// The LOD overlay: every mesh with more than one level draws its bounds in the colour of
/// the level the view would pick. Draws unselected, gated by the overlay toggle.
class LodOverlayGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(MeshComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		if (!ctx.LodOverlay || (ctx.ViewCamera == null))
			return;
		let mc = (MeshComponent*)component;
		let mesh = mc.Mesh.Get;
		if ((mesh == null) || (mesh.LodCount <= 1))
			return;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let center = TransformPoint(mesh.Bounds.Center(), world);
		var minCorner = center;
		var maxCorner = center;
		let lo = mesh.Bounds.Min;
		let hi = mesh.Bounds.Max;
		for (uint32 corner < 8)
		{
			let local = Float3(((corner & 1) != 0) ? hi.X : lo.X, ((corner & 2) != 0) ? hi.Y : lo.Y,
				((corner & 4) != 0) ? hi.Z : lo.Z);
			let p = TransformPoint(local, world);
			minCorner = .(Min(minCorner.X, p.X), Min(minCorner.Y, p.Y), Min(minCorner.Z, p.Z));
			maxCorner = .(Max(maxCorner.X, p.X), Max(maxCorner.Y, p.Y), Max(maxCorner.Z, p.Z));
		}
		let radius = 0.5f * Length(maxCorner - minCorner);
		let coverage = MeshLod.LodCoverageFor(*ctx.ViewCamera, center, radius, mc.LodBias);
		let maxLod = (uint32)(mesh.LodCount - 1);
		var level = MeshLod.PickLodLevel(mesh, coverage);
		if (mc.ForceLod >= 0)
			level = ((uint32)mc.ForceLod < maxLod) ? (uint32)mc.ForceLod : maxLod;
		// Green is the finest, then yellow, orange, and red for three and beyond.
		Color color;
		switch (level)
		{
		case 0: color = .(0.3f, 0.9f, 0.3f, 1.0f);
		case 1: color = .(0.95f, 0.9f, 0.2f, 1.0f);
		case 2: color = .(1.0f, 0.6f, 0.15f, 1.0f);
		default: color = .(1.0f, 0.25f, 0.2f, 1.0f);
		}
		ctx.Debug.DrawTransformedBox(mesh.Bounds.Min, mesh.Bounds.Max, world, color);
	}
}
