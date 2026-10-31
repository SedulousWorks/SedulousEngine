using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Engine.GUI;

/// The GUI's arithmetic in the world, kept PURE so each piece is measured on its own: a world
/// panel's texture size, a ray from a pointer and where it crosses a panel, and where a
/// billboard shows in a view.
static class GuiWorldMath
{
	/// A world panel's texture in pixels: its extent at its density, within 16 and 2044 on each
	/// axis: with the two pixel edge the subsystem pads each side with, never past 2048.
	public static Float2 WorldPanelPixels(GuiWorldPanelComponent panel)
	{
		let density = Math.Max(panel.PixelsPerMeter, 1.0f);
		let width = Math.Clamp((uint32)(panel.SizeMeters.X * density + 0.5f), 16, 2044);
		let height = Math.Clamp((uint32)(panel.SizeMeters.Y * density + 0.5f), 16, 2044);
		return .((float)width, (float)height);
	}

	/// The world ray under `pointer` (pixels) on a view of `viewSize` through an UNJITTERED
	/// camera, from the near plane, between the engine's NDC depths.
	public static void GuiPointerRay(ViewCamera camera, Float2 pointer, Float2 viewSize,
		out Float3 origin, out Float3 direction)
	{
		let inverse = Inverse(camera.ViewProjection);
		let ndcX = (pointer.X / viewSize.X) * 2.0f - 1.0f;
		let ndcY = 1.0f - (pointer.Y / viewSize.Y) * 2.0f;

		origin = Unproject(inverse, ndcX, ndcY, Projection.NdcDepthNear);
		let far = Unproject(inverse, ndcX, ndcY, Projection.NdcDepthFar);
		direction = Normalized(far - origin);
	}

	private static Float3 Unproject(Float4x4 inverse, float ndcX, float ndcY, float z)
	{
		// Row vectors, so the point goes on the left.
		let clip = Float4(ndcX, ndcY, z, 1.0f) * inverse;
		let w = (clip.W != 0.0f) ? clip.W : 1.0f;
		return .(clip.X / w, clip.Y / w, clip.Z / w);
	}

	/// The ray against a panel of `sizeMeters` in the plane of `panelWorld`, which its world
	/// right and up span. EITHER face is hit: a panel read from behind is still a panel.
	public static GuiPanelHit RayHitGuiPanel(Float3 origin, Float3 direction, Float4x4 panelWorld,
		Float2 sizeMeters)
	{
		var result = GuiPanelHit();
		let centre = Float3(panelWorld.M[3][0], panelWorld.M[3][1], panelWorld.M[3][2]);
		let right = Normalized(Float3(panelWorld.M[0][0], panelWorld.M[0][1], panelWorld.M[0][2]));
		let up = Normalized(Float3(panelWorld.M[1][0], panelWorld.M[1][1], panelWorld.M[1][2]));
		let normal = Cross(right, up);

		let facing = Dot(direction, normal);
		// Along the plane, so it never meets it.
		if (Math.Abs(facing) < 1.0e-6f)
			return result;

		let t = Dot(centre - origin, normal) / facing;
		// Behind the pointer.
		if (t <= 0.0f)
			return result;

		let local = (origin + direction * t) - centre;
		let x = Dot(local, right);
		let y = Dot(local, up);
		if ((Math.Abs(x) > sizeMeters.X * 0.5f) || (Math.Abs(y) > sizeMeters.Y * 0.5f))
			return result;

		result.Hit = true;
		result.Distance = t;
		result.Uv = .(x / sizeMeters.X + 0.5f, 0.5f - y / sizeMeters.Y);
		return result;
	}

	/// `billboard` on an entity at `entityWorld`, seen through an UNJITTERED `viewProjection`
	/// from `cameraPosition`, in a view of `viewport` pixels.
	public static GuiBillboardPlacement PlaceBillboard(GuiBillboardComponent billboard,
		Float4x4 entityWorld, Float4x4 viewProjection, Float3 cameraPosition, Float2 viewport)
	{
		var placement = GuiBillboardPlacement();
		Float3 point;
		if (billboard.Orientation == .Cylindrical)
		{
			// A fixed lift in world space above the entity's origin, however it turns.
			let anchor = TransformPoint(Float3(0.0f, 0.0f, 0.0f), entityWorld);
			point = anchor + billboard.Offset;
		}
		else
		{
			// The entity's own space, so the offset turns with it.
			point = TransformPoint(billboard.Offset, entityWorld);
		}

		let clip = Float4(point.X, point.Y, point.Z, 1.0f) * viewProjection;
		// Behind the camera.
		if (clip.W <= 0.0f)
			return placement;

		placement.Shown = true;
		placement.Anchor = .((clip.X / clip.W * 0.5f + 0.5f) * viewport.X, (0.5f - clip.Y / clip.W * 0.5f) * viewport.Y);
		if (billboard.ScaleMode == .Distance)
		{
			let distance = Math.Max(Length(point - cameraPosition), 0.001f);
			placement.Scale = Math.Clamp(billboard.ReferenceDistance / distance, billboard.MinScale, billboard.MaxScale);
		}
		return placement;
	}
}
