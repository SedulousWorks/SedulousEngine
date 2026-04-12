namespace Sedulous.Renderer.Shadows;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;

/// Maximum cascades per directional light. Matches the size of GPUShadowData.CascadeSplits.
public static class ShadowConstants
{
	public const int32 MaxCascades = 4;
	/// Number of cube-map faces for a point light shadow (always 6).
	public const int32 PointFaceCount = 6;
}

/// Output of DirectionalCascades — per-cascade view-projection matrices,
/// view-space far split distances, and world-space texel sizes.
public struct DirectionalCascadeData
{
	public Matrix[ShadowConstants.MaxCascades] ViewProjs;
	public Vector4 Splits;           // view-space far depths per cascade
	public Vector4 WorldTexelSizes;  // world units per shadow map texel per cascade
}

/// Utilities for computing per-light shadow view-projection matrices.
///
/// Phase 7.2: spot light support.
/// Phase 7.3: cascaded directional support.
public static class ShadowMatrices
{
	/// Computes the world → light-clip view-projection matrix for one face of a
	/// point light's cube shadow. Face indices follow the standard +X, -X, +Y,
	/// -Y, +Z, -Z order (matches the shader's face selection).
	public static Matrix PointLightFaceViewProj(LightRenderData light, int32 faceIdx)
	{
		let position = light.Position;

		Vector3 forward = .Zero;
		Vector3 up = .Zero;
		switch (faceIdx)
		{
		case 0: forward = .(1, 0, 0);  up = .(0, 1, 0);  // +X
		case 1: forward = .(-1, 0, 0); up = .(0, 1, 0);  // -X
		case 2: forward = .(0, 1, 0);  up = .(0, 0, -1); // +Y — up must be non-parallel
		case 3: forward = .(0, -1, 0); up = .(0, 0, 1);  // -Y
		case 4: forward = .(0, 0, 1);  up = .(0, 1, 0);  // +Z
		case 5: forward = .(0, 0, -1); up = .(0, 1, 0);  // -Z
		}

		let target = position + forward;
		let view = Matrix.CreateLookAt(position, target, up);

		// Slightly wider than 90° so adjacent cube faces overlap at the boundary.
		// This eliminates the seam artifact where fragments at exactly 45° between
		// two axes can flip face index and hit an unlit edge of the other face's map.
		let fov = Math.PI_f * 0.5f + 0.04f; // ~92.3°
		let nearPlane = 0.1f;
		let farPlane = Math.Max(light.Range, nearPlane + 0.1f);
		let proj = Matrix.CreatePerspectiveFieldOfView(fov, 1.0f, nearPlane, farPlane);

		return view * proj;
	}

	/// Computes the world → light-clip view-projection matrix for a spot light.
	///
	///   - Light position is the matrix's eye point.
	///   - Light direction is the look-at forward vector.
	///   - FOV equals twice the outer cone angle (full angular extent).
	///   - Range provides the far plane; near plane is a small constant.
	public static Matrix SpotLightViewProj(LightRenderData light)
	{
		let position = light.Position;
		let forward = Vector3.Normalize(light.Direction);
		let target = position + forward;

		// Pick an up vector that isn't parallel to forward.
		let upGuess = Math.Abs(forward.Y) < 0.99f ? Vector3.Up : Vector3.Forward;
		let view = Matrix.CreateLookAt(position, target, upGuess);

		// FOV is the full angular extent (outer cone is half-angle).
		let fov = light.OuterConeAngle * 2.0f;
		let nearPlane = 0.1f;
		let farPlane = Math.Max(light.Range, nearPlane + 0.1f);

		let proj = Matrix.CreatePerspectiveFieldOfView(fov, 1.0f, nearPlane, farPlane);

		return view * proj;
	}

	/// Computes 4 cascade view-projections using the Sedulous legacy "sphere-fit"
	/// approach: each cascade is a square ortho covering a bounding SPHERE around
	/// the camera frustum slice. Stable against camera rotation, resolution-
	/// independent shading, simpler math than AABB fitting.
	///
	/// Splits use a logarithmic + uniform blend (Practical Stable CSM, lambda=0.5).
	public static DirectionalCascadeData DirectionalCascades(
		LightRenderData light,
		RenderView mainView,
		uint32 shadowMapResolution,
		float shadowDistance = 0.0f)
	{
		DirectionalCascadeData result = default;

		let cascadeCount = ShadowConstants.MaxCascades;
		let nearPlane = mainView.NearPlane;
		let farPlane = (shadowDistance > 0.0f) ? Math.Min(shadowDistance, mainView.FarPlane) : mainView.FarPlane;

		// 1. Compute cascade split distances (view-space).
		float[ShadowConstants.MaxCascades + 1] splits = ?;
		splits[0] = nearPlane;
		let lambda = 0.5f;
		let range = farPlane - nearPlane;
		let ratio = farPlane / nearPlane;
		for (int i = 1; i < cascadeCount; i++)
		{
			let p = (float)i / (float)cascadeCount;
			let logSplit = nearPlane * Math.Pow(ratio, p);
			let uniSplit = nearPlane + p * range;
			splits[i] = lambda * logSplit + (1.0f - lambda) * uniSplit;
		}
		splits[cascadeCount] = farPlane;

		result.Splits.X = splits[1];
		result.Splits.Y = splits[2];
		result.Splits.Z = splits[3];
		result.Splits.W = splits[4];

		// 2. Build a stable orthonormal basis for the light view.
		// Using an orthonormal-basis construction (instead of Vector3.Up) avoids
		// up-vector flips when the light points straight down.
		let lightDir = Vector3.Normalize(light.Direction);
		let refVec = Math.Abs(lightDir.Y) < 0.9f ? Vector3.Up : Vector3(1, 0, 0);
		let lightRight = Vector3.Normalize(Vector3.Cross(refVec, lightDir));
		let lightUp = Vector3.Cross(lightDir, lightRight);

		// 3. For each cascade, compute a bounding SPHERE around the frustum slice
		// and build a square ortho that contains the sphere.
		Matrix invView = .Identity;
		Matrix.Invert(mainView.ViewMatrix, out invView);

		Matrix invProj = .Identity;
		Matrix.Invert(mainView.ProjectionMatrix, out invProj);

		// View-space near-plane corner rays (used to scale out to any cascade depth).
		Vector3[4] nearViewCorners = ?;
		int idx = 0;
		for (int xi = 0; xi < 2; xi++)
		for (int yi = 0; yi < 2; yi++)
		{
			let ndc = Vector4(xi == 0 ? -1.0f : 1.0f, yi == 0 ? -1.0f : 1.0f, 0.0f, 1.0f);
			let viewVec = Vector4.Transform(ndc, invProj);
			nearViewCorners[idx++] = .(viewVec.X / viewVec.W, viewVec.Y / viewVec.W, viewVec.Z / viewVec.W);
		}
		let nearDist = -nearViewCorners[0].Z;

		float[4] texelSizes = ?;

		for (int c = 0; c < cascadeCount; c++)
		{
			let splitNear = splits[c];
			let splitFar = splits[c + 1];

			// 8 frustum corners in WORLD space.
			Vector3[8] worldCorners = ?;
			int wi = 0;
			for (int corner = 0; corner < 4; corner++)
			{
				let nv = nearViewCorners[corner];
				let scaleNear = splitNear / nearDist;
				let scaleFar = splitFar / nearDist;
				let nearVS = Vector3(nv.X * scaleNear, nv.Y * scaleNear, -splitNear);
				let farVS  = Vector3(nv.X * scaleFar,  nv.Y * scaleFar,  -splitFar);
				worldCorners[wi++] = Vector3.Transform(nearVS, invView);
				worldCorners[wi++] = Vector3.Transform(farVS,  invView);
			}

			// Centroid of the slice.
			Vector3 center = .Zero;
			for (int i = 0; i < 8; i++)
				center += worldCorners[i];
			center /= 8.0f;

			// Bounding sphere radius = distance from centroid to farthest corner.
			float radius = 0;
			for (int i = 0; i < 8; i++)
			{
				let d = Vector3.Distance(worldCorners[i], center);
				if (d > radius) radius = d;
			}
			// Snap radius to a discrete step to reduce shadow edge swimming.
			radius = Math.Ceiling(radius * 16.0f) / 16.0f;

			// World-space texel size for this cascade.
			texelSizes[c] = (radius * 2.0f) / (float)shadowMapResolution;

			// Light view: square look-at from (center - lightDir * 2r) toward center.
			let shadowDist = radius * 2.0f;
			let lightPos = center - lightDir * shadowDist;
			let lightView = Matrix.CreateLookAt(lightPos, center, lightUp);

			// Square orthographic projection of side 2r.
			let lightProj = Matrix.CreateOrthographic(radius * 2.0f, radius * 2.0f, 0.01f, shadowDist * 2.0f);

			result.ViewProjs[c] = lightView * lightProj;
		}

		result.WorldTexelSizes.X = texelSizes[0];
		result.WorldTexelSizes.Y = texelSizes[1];
		result.WorldTexelSizes.Z = texelSizes[2];
		result.WorldTexelSizes.W = texelSizes[3];

		return result;
	}
}
