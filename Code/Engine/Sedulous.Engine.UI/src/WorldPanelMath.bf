using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Engine.UI;

/// The world panel's pointer arithmetic, kept PURE so it can be measured on its own: a ray
/// from a pointer, and where that ray crosses a panel.
static class WorldPanelMath
{
	/// The world space ray for a pointer at `pointerPx` on a view of `viewSize`, through an
	/// UNJITTERED camera. Near maps to a depth of nought and far to one.
	public static void PointerRayFromCamera(ViewCamera camera, Float2 pointerPx, Float2 viewSize,
		out Float3 outOrigin, out Float3 outDirection)
	{
		let inverseViewProjection = Inverse(camera.ViewProjection);
		let ndcX = (pointerPx.X / viewSize.X) * 2.0f - 1.0f;
		let ndcY = 1.0f - (pointerPx.Y / viewSize.Y) * 2.0f;

		outOrigin = Unproject(inverseViewProjection, ndcX, ndcY, Projection.NdcDepthNear);
		let far = Unproject(inverseViewProjection, ndcX, ndcY, Projection.NdcDepthFar);
		outDirection = Normalized(far - outOrigin);
	}

	private static Float3 Unproject(Float4x4 inverseViewProjection, float ndcX, float ndcY,
		float z)
	{
		// Row vector, so the point goes on the left.
		let clip = Float4(ndcX, ndcY, z, 1.0f) * inverseViewProjection;
		let w = (clip.W != 0.0f) ? clip.W : 1.0f;
		return .(clip.X / w, clip.Y / w, clip.Z / w);
	}

	/// The ray against the panel's plane, whose quad is spanned by the entity's world right
	/// and up. BOTH faces hit: a panel read from behind is still a panel.
	public static WorldPanelHit RayHitWorldPanel(Float3 rayOrigin, Float3 rayDirection,
		Float4x4 panelWorld, Float2 sizeMeters)
	{
		var result = WorldPanelHit();

		let center = Float3(panelWorld.M[3][0], panelWorld.M[3][1], panelWorld.M[3][2]);
		let right = Normalized(Float3(panelWorld.M[0][0], panelWorld.M[0][1], panelWorld.M[0][2]));
		let up = Normalized(Float3(panelWorld.M[1][0], panelWorld.M[1][1], panelWorld.M[1][2]));
		let normal = Cross(right, up);

		let denominator = Dot(rayDirection, normal);
		// Parallel, so it never meets the plane at all.
		if (Math.Abs(denominator) < 1.0e-6f)
			return result;

		let t = Dot(center - rayOrigin, normal) / denominator;
		// Behind the pointer.
		if (t <= 0.0f)
			return result;

		let local = (rayOrigin + rayDirection * t) - center;
		let x = Dot(local, right);
		let y = Dot(local, up);
		if ((Math.Abs(x) > sizeMeters.X * 0.5f) || (Math.Abs(y) > sizeMeters.Y * 0.5f))
			return result;

		result.Hit = true;
		result.Distance = t;
		result.Uv = .(x / sizeMeters.X + 0.5f, 0.5f - y / sizeMeters.Y);
		return result;
	}
}
