using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// Fitting shadow maps: the cascades for a directional light, and the atlas entries for the
/// local ones.
///
/// Pure maths, so all of it is testable without a device.
static class ShadowMath
{
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
	public static ShadowCascades ComputeCascades(ViewCamera camera, Float3 lightDir,
		float shadowDistance, uint32 resolution)
	{
		var cascades = ShadowCascades();
		cascades.Valid = true;

		const int cCount = ShadowCascades.Count;
		/// Nought is uniform and one is logarithmic; halfway is the practical split.
		const float cLambda = 0.5f;

		let nearZ = 0.1f;
		let farZ = Max(nearZ + 1.0f, shadowDistance);
		// The frustum corners below span the CAMERA's whole depth range, so a split depth
		// has to become a fraction of that rather than of the shorter shadow range.
		let cameraFar = Max(farZ, camera.FarZ);

		float[cCount + 1] splits = default;
		splits[0] = nearZ;
		for (int i = 1; i <= cCount; i++)
		{
			let fraction = (float)i / (float)cCount;
			let logarithmic = nearZ * Pow(farZ / nearZ, fraction);
			let uniform = nearZ + (farZ - nearZ) * fraction;
			splits[i] = cLambda * logarithmic + (1.0f - cLambda) * uniform;
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
			// Snapped, so the cascade's size steps rather than creeping frame to frame.
			radius = Ceil(radius * 16.0f) / 16.0f;

			cascades.TexelWorldSize[c] = (radius * 2.0f) / (float)resolution;
			cascades.SplitFar[c] = splits[c + 1];

			let depth = radius * 6.0f;
			let eye = center - direction * (radius * 3.0f);
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
		return shadow;
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
		return MakeLocalShadow(view, caster.Range, fov, tileIndex, atlasResolution, tileResolution);
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

		return MakeLocalShadow(view, caster.Range, 1.745f, tileIndex, atlasResolution,
			tileResolution);
	}

	private static uint32 Columns(uint32 atlasResolution, uint32 tileResolution)
	{
		let perRow = (tileResolution > 0) ? (atlasResolution / tileResolution) : 1;
		return (perRow > 0) ? perRow : 1;
	}
}
