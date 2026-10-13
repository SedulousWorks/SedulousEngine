using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The view-projection the sky draws its rays through.
static class SkyProjection
{
	/// From an UNJITTERED camera: the view's own for a perspective camera; for an orthographic
	/// one, whose rays are parallel (the whole background one colour), a 60 degree perspective with
	/// the same view and aspect, so the sky still reads as sky and turns with the camera.
	public static Float4x4 SkyViewProjection(ViewCamera camera)
	{
		if (!camera.IsOrthographic)
			return camera.ViewProjection;
		let p = camera.Projection;
		let aspect = (p.M[0][0] != 0.0f) ? (p.M[1][1] / p.M[0][0]) : 1.0f;
		let farZ = Math.Max(camera.FarPlane, 1.0f);
		return camera.View * Float4x4.PerspectiveFovRH(1.0471976f, aspect, Math.Min(0.1f, farZ * 0.5f), farZ);
	}
}
