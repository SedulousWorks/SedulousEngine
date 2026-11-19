using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// Fitting shadow maps: the cascades for a directional light, and the atlas entries for the
/// local ones.
///
/// Pure maths, so all of it is testable without a device.
static class ShadowMath
{
	/// How far a view's directional shadows reach from its draw eye: the scene's `distance` past
	/// the eye (at least a metre), clamped to the camera's far plane. A view drawn from behind its
	/// eye (ViewCamera.PullBack) reaches that much further, so its shadows cover the same ground.
	public static float ShadowReach(ViewCamera camera, float distance) =>
		Math.Min(camera.FarZ, Math.Max(distance, 1.0f) + camera.PullBack);

	/// Unprojects a clip space corner back into the world.
	public static Float3 UnprojectNDC(Float4x4 inverseViewProj, float ndcX, float ndcY, float ndcZ)
	{
		let clip = Float4(ndcX, ndcY, ndcZ, 1.0f) * inverseViewProj;
		let inverseW = (Abs(clip.W) > 1e-6f) ? (1.0f / clip.W) : 1.0f;
		return .(clip.X * inverseW, clip.Y * inverseW, clip.Z * inverseW);
	}

	/// Fits the cascades to a camera's frustum.
	///
	/// The splits blend a logarithmic distribution with a uniform one, which is what keeps
	/// the near cascade tight without leaving the far one starved. Each cascade is fitted to
	/// the BOUNDING SPHERE of its slice rather than to the slice's box: a sphere is
	/// invariant under rotation, so turning the camera does not resize the cascade and make
	/// the shadows swim.
	///
	/// Two snaps hold the rest of the shimmer down. The radius snaps to a fraction, so it
	/// steps rather than creeping; and the whole cascade snaps to WHOLE TEXELS in light clip
	/// space, so its texels advance in integer steps as the camera moves rather than sliding
	/// under the geometry and crawling along every edge.
	///
	/// `lambda` blends the splits: nought is uniform and one logarithmic, more of the map near
	/// the camera; halfway is the practical split.
	public static ShadowCascades ComputeCascades(ViewCamera camera, Float3 lightDir,
		float shadowDistance, uint32 resolution, float lambda = 0.5f, AABB* receivers = null)
	{
		var cascades = ShadowCascades();
		cascades.Valid = true;

		const int cCount = ShadowCascades.Count;

		let nearZ = camera.NearPlane; // the camera's own near plane, read from its projection
		let farZ = Max(nearZ + 1.0f, shadowDistance);
		// The frustum corners below span the CAMERA's whole depth range, so a split depth
		// has to become a fraction of that rather than of the shorter shadow range.
		let cameraFar = Max(farZ, camera.FarPlane);
		// The log split needs a near plane in front of the eye.
		let logNear = Max(nearZ, 0.01f);

		float[cCount + 1] splits = default;
		splits[0] = nearZ;
		for (int i = 1; i <= cCount; i++)
		{
			let fraction = (float)i / (float)cCount;
			let logarithmic = logNear * Pow(farZ / logNear, fraction);
			let uniform = nearZ + (farZ - nearZ) * fraction;
			splits[i] = lambda * logarithmic + (1.0f - lambda) * uniform;
		}

		let inverseViewProj = Inverse(camera.ViewProjection);
		Float3[4] nearCorners = default;
		Float3[4] farCorners = default;
		let xs = float[4](-1.0f, 1.0f, 1.0f, -1.0f);
		let ys = float[4](-1.0f, -1.0f, 1.0f, 1.0f);
		for (int i < 4)
		{
			nearCorners[i] = UnprojectNDC(inverseViewProj, xs[i], ys[i], Projection.NdcDepthNear);
			farCorners[i] = UnprojectNDC(inverseViewProj, xs[i], ys[i], Projection.NdcDepthFar);
		}

		let direction = Normalized(lightDir);
		// Straight down or straight up leaves no sideways up vector to look with.
		let up = (Abs(direction.Y) > 0.95f) ? Float3(0.0f, 0.0f, 1.0f) : Float3(0.0f, 1.0f, 0.0f);

		for (int c < cCount)
		{
			let fromNear = (splits[c] - nearZ) / (cameraFar - nearZ);
			let toFar = (splits[c + 1] - nearZ) / (cameraFar - nearZ);

			Float3[8] corners = default;
			for (int i < 4)
			{
				let edge = farCorners[i] - nearCorners[i];
				corners[i] = nearCorners[i] + edge * fromNear;
				corners[i + 4] = nearCorners[i] + edge * toFar;
			}

			var center = Float3(0.0f, 0.0f, 0.0f);
			for (int i < 8)
				center = center + corners[i];
			center = center * (1.0f / 8.0f);

			var radius = 0.0f;
			for (int i < 8)
				radius = Max(radius, Length(corners[i] - center));
			// How far toward the light the box reaches past its centre: the slice's own three radii.
			let towardLight = (Ceil(radius * 16.0f) / 16.0f) * 3.0f;

			if ((receivers != null) && receivers.IsValid())
			{
				var slice = AABB.Empty();
				for (int i < 8)
					slice.Expand(corners[i]);
				let overlap = AABB(Max(slice.Min, receivers.Min), Min(slice.Max, receivers.Max));
				if (!overlap.IsValid())
				{
					cascades.HasReceivers[c] = false; // nothing here to shadow: keep the slice's box
				}
				else
				{
					// In eighths of the slice's radius, which depends only on the projection, so
					// the box does not swim as the camera turns.
					let step = radius / 8.0f;
					let fitted = Ceil(Length(overlap.Extents()) / step) * step;
					if (fitted < radius)
					{
						radius = fitted;
						center = overlap.Center();
					}
				}
			}
			// Snapped, so the cascade's size steps rather than creeping frame to frame.
			radius = Ceil(radius * 16.0f) / 16.0f;

			cascades.TexelWorldSize[c] = (radius * 2.0f) / (float)resolution;
			cascades.SplitFar[c] = splits[c + 1];

			// A fitted box keeps the slice's reach toward the light, so every caster the slice's
			// box would have drawn still lands in it, and its depth never grows.
			let depth = towardLight + radius * 3.0f;
			// A caster in the box shadows a receiver in it no further along the light than this.
			cascades.CasterReach = Max(cascades.CasterReach, depth);
			let eye = center - direction * towardLight;
			let view = Float4x4.LookAtRH(eye, center, up);
			let projection = Float4x4.OrthographicRH(radius * 2.0f, radius * 2.0f, 0.0f, depth);
			var viewProj = view * projection;

			// The texel snap: shift the cascade so the world origin lands on a whole texel.
			let originClip = TransformPoint(.(0.0f, 0.0f, 0.0f), viewProj);
			let half = (float)resolution * 0.5f;
			let offsetX = (Floor(originClip.X * half + 0.5f) - originClip.X * half) / half;
			let offsetY = (Floor(originClip.Y * half + 0.5f) - originClip.Y * half) / half;
			viewProj[3, 0] += offsetX;
			viewProj[3, 1] += offsetY;

			cascades.ViewProjection[c] = viewProj;
		}

		return cascades;
	}

	/// The share of a cascade's depth range, at its far end, over which the shader blends toward
	/// the next cascade: a receiver there samples both. Matches SampleCSM in lighting.hlsli.
	public const float CascadeBlendBand = 0.15f;

	/// The view depths cascade `c` of `cascades` shades, as SampleCSM picks it: its own slice,
	/// and the blend band at the far end of the slice before (a receiver there samples this one
	/// too). `cameraNear` is the view's near plane, where the first slice starts.
	public static void CascadeReceiverDepths(ShadowCascades cascades, float cameraNear, int c, out float outNear, out float outFar)
	{
		outFar = cascades.SplitFar[c];
		if (c == 0)
		{
			outNear = cameraNear;
			return;
		}
		let prevFar = cascades.SplitFar[c - 1];
		let prevNear = (c == 1) ? 0.0f : cascades.SplitFar[c - 2];
		outNear = Max(cameraNear, prevFar - (prevFar - prevNear) * CascadeBlendBand);
	}

	/// The part of a view between two of its view depths (the depth the shader compares with
	/// the cascades' splits): its frustum with the near and far planes moved there, planes
	/// pointing outward, the depths kept to what the view sees. The cuts are taken along the
	/// view's own axis, between its projection's near and far planes, rather than from the
	/// planes themselves, which an endless projection does not have.
	public static BoundingFrustum ShadowSliceFrustum(ViewCamera camera, float nearDepth, float farDepth)
	{
		var frustum = BoundingFrustum(camera.ViewProjection);
		let nearZ = camera.NearPlane;
		let projectionFar = Max(camera.FarPlane, nearZ + 1e-3f);
		let inverseViewProj = Inverse(camera.ViewProjection);
		let nearCentre = UnprojectNDC(inverseViewProj, 0.0f, 0.0f, Projection.NdcDepthNear);
		let farCentre = UnprojectNDC(inverseViewProj, 0.0f, 0.0f, Projection.NdcDepthFar);
		let axis = Normalized(farCentre - nearCentre);
		Float3 At(float depth) => nearCentre + (farCentre - nearCentre) * ((Math.Clamp(depth, nearZ, projectionFar) - nearZ) / (projectionFar - nearZ));
		frustum.Planes[1] = Plane.FromPointNormal(At(farDepth), axis);
		if (nearDepth > nearZ)
			frustum.Planes[0] = Plane.FromPointNormal(At(Min(nearDepth, farDepth)), -axis);
		return frustum;
	}

	/// What of a view receives its directional shadows: its frustum from the near plane to
	/// `shadowDistance`, the depth the cascades cover.
	public static BoundingFrustum ShadowReceiverFrustum(ViewCamera camera, float shadowDistance)
	{
		return ShadowSliceFrustum(camera, camera.NearPlane, shadowDistance);
	}

	/// How far along the light a caster's shadow can still land on something: `reach` (the
	/// furthest a cascade carries a shadow), cut short where the sweep of its sphere (xyz
	/// centre, w radius) along `lightDir` (unit) leaves `receivers`, the bounds of everything the
	/// scene draws. Past them there is nothing for the shadow to fall on: a tree's shadow ends at
	/// the ground, not hundreds of metres beyond it. Invalid bounds (nothing drawn) leave
	/// `reach` as it is.
	public static float ShadowSweepLength(Float4 sphere, Float3 lightDir, float reach, AABB receivers)
	{
		if (!receivers.IsValid())
			return reach;
		let r = sphere.W;
		float[3] centre = .(sphere.X, sphere.Y, sphere.Z);
		float[3] direction = .(lightDir.X, lightDir.Y, lightDir.Z);
		float[3] lo = .(receivers.Min.X - r, receivers.Min.Y - r, receivers.Min.Z - r);
		float[3] hi = .(receivers.Max.X + r, receivers.Max.Y + r, receivers.Max.Z + r);
		var exit = reach;
		for (int a < 3)
		{
			if (direction[a] > 1e-6f)
				exit = Min(exit, (hi[a] - centre[a]) / direction[a]);
			else if (direction[a] < -1e-6f)
				exit = Min(exit, (lo[a] - centre[a]) / direction[a]);
		}
		return Math.Clamp(exit, 0.0f, reach);
	}

	/// Whether a directional light's caster can shadow what the view receives shadows on. A
	/// shadow falls from its caster along the light. A cascade draws a caster whose sphere
	/// touches its box, and the shadow pass clamps depth, so the part of it that sticks out
	/// toward the light (up to its diameter) still casts: its shadow lands at most `reach`
	/// (ShadowCascades.CasterReach) plus that diameter from its centre. The caster matters only
	/// when its bounding sphere (xyz centre, w radius), swept that far along `lightDir` (unit,
	/// the direction light travels), touches `receivers`. Conservative: a caster it rejects
	/// writes no shadow the view samples. A caster beside or behind the view whose shadow falls
	/// away from it, or every caster of a view turned to the sky, is rejected.
	public static bool CasterShadowReachesView(BoundingFrustum receivers, Float3 lightDir, float reach, Float4 sphere)
	{
		let centre = Float3(sphere.X, sphere.Y, sphere.Z);
		let sweep = reach + 2.0f * sphere.W;
		for (let plane in receivers.Planes)
		{
			// The capsule is outside the plane when both its ends are further out than its radius.
			let start = Dot(plane.Normal, centre) + plane.D;
			let end = start + Dot(plane.Normal, lightDir) * sweep;
			if (Min(start, end) > sphere.W)
				return false;
		}
		return true;
	}

	/// Whether a cached (static) atlas tile must be redrawn for a moving caster (a figure, a
	/// door) touching its light's volume: one there now, or one there last frame, which has
	/// just left and whose shadow the cache still holds.
	public static bool MovingCasterTouchesTile(Float3 tileCenter, float tileRadius,
		Span<BoundingSphere> now, Span<BoundingSphere> before)
	{
		for (let sphere in now)
		{
			if (Length(sphere.Center - tileCenter) <= (tileRadius + sphere.Radius))
				return true;
		}
		for (let sphere in before)
		{
			if (Length(sphere.Center - tileCenter) <= (tileRadius + sphere.Radius))
				return true;
		}
		return false;
	}

	/// Which part of the atlas a tile occupies.
	public static AtlasTile AtlasTileRect(uint32 tileIndex, uint32 atlasResolution,
		uint32 tileResolution)
	{
		let columns = Columns(atlasResolution, tileResolution);
		return .((tileIndex % columns) * tileResolution, (tileIndex / columns) * tileResolution,
			tileResolution, tileResolution);
	}

	/// Finishes a local shadow entry from a light's view, its cone and its assigned tile.
	///
	/// The near plane is scaled TO THE RANGE rather than fixed: a tiny near plane wrecks the
	/// depth precision, so everything past a few units crams into the last thousandth of the
	/// depth buffer, the separation between occluder and receiver falls under the bias, and
	/// nothing casts a shadow at all.
	public static GpuLocalShadow MakeLocalShadow(Float4x4 view, float range, float fov,
		uint32 tileIndex, uint32 atlasResolution, uint32 tileResolution)
	{
		var shadow = GpuLocalShadow();

		let farZ = Max(0.2f, range);
		let nearZ = Max(0.2f, farZ * 0.05f);
		shadow.ViewProjection = view * Float4x4.PerspectiveFovRH(fov, 1.0f, nearZ, farZ);

		let columns = Columns(atlasResolution, tileResolution);
		let scale = (float)tileResolution / (float)atlasResolution;
		shadow.AtlasScaleBias = .(scale, scale, (float)(tileIndex % columns) * scale,
			(float)(tileIndex / columns) * scale);
		// One tile texel at distance one from the light spans 2 tan(fov / 2) / tileResolution
		// world units.
		shadow.NormalBiasPerDistance = (tileResolution > 0) ? (2.0f * Math.Tan(fov * 0.5f) / (float)tileResolution) : 0.0f;
		return shadow;
	}

	/// The caster light's own biases on a built entry: the texel to world scale MakeLocalShadow
	/// put in NormalBiasPerDistance, times the light's texels.
	public static GpuLocalShadow WithLightBiases(GpuLocalShadow shadow, LocalShadowCaster caster)
	{
		var result = shadow;
		result.NormalBiasPerDistance *= caster.NormalBias;
		result.DepthBias = caster.DepthBias;
		return result;
	}

	/// A spot light's entry: one perspective view looking down its cone.
	public static GpuLocalShadow BuildSpotShadow(LocalShadowCaster caster, uint32 tileIndex,
		uint32 atlasResolution, uint32 tileResolution)
	{
		let direction = Normalized(caster.DirectionWS);
		let up = (Abs(direction.Y) > 0.95f) ? Float3(0.0f, 0.0f, 1.0f) : Float3(0.0f, 1.0f, 0.0f);
		// The cone is padded a touch, and kept under half a turn.
		let fov = Min(caster.OuterAngle * 2.0f + 0.05f, 3.0f);

		let view = Float4x4.LookAtRH(caster.PositionWS, caster.PositionWS + direction, up);
		return WithLightBiases(MakeLocalShadow(view, caster.Range, fov, tileIndex, atlasResolution, tileResolution), caster);
	}

	/// One cube face of a point light's shadow.
	///
	/// The field of view is deliberately WIDER than a right angle. The shader picks a face by
	/// the dominant axis of the direction to the fragment, so a fragment exactly on the
	/// boundary lands at the tile's very edge, where the filter taps fall off it or into the
	/// neighbouring tile: a seam along every face boundary. The padding pulls those fragments
	/// inward.
	public static GpuLocalShadow BuildPointShadowFace(LocalShadowCaster caster, uint32 face,
		uint32 tileIndex, uint32 atlasResolution, uint32 tileResolution)
	{
		let faceDirections = Float3[6](.(1, 0, 0), .(-1, 0, 0), .(0, 1, 0), .(0, -1, 0),
			.(0, 0, 1), .(0, 0, -1));
		let index = (face < 6) ? face : 0;
		let direction = faceDirections[index];

		// The vertical faces cannot use an up axis of Y, since it is the axis they look along.
		let up = (index == 2) ? Float3(0, 0, -1) : ((index == 3) ? Float3(0, 0, 1) : Float3(0, 1, 0));
		let view = Float4x4.LookAtRH(caster.PositionWS, caster.PositionWS + direction, up);

		return WithLightBiases(MakeLocalShadow(view, caster.Range, 1.745f, tileIndex, atlasResolution,
			tileResolution), caster);
	}

	private static uint32 Columns(uint32 atlasResolution, uint32 tileResolution)
	{
		let perRow = (tileResolution > 0) ? (atlasResolution / tileResolution) : 1;
		return (perRow > 0) ? perRow : 1;
	}
}
