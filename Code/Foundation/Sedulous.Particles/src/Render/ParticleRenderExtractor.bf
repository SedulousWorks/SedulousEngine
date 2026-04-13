using System;
using Sedulous.Core.Mathematics;
namespace Sedulous.Particles.Render;

/// Extracts render data from a ParticleSystem into a ParticleRenderData.
/// Handles billboard vertex construction, sorting, and atlas UV computation.
/// All CPU work with no RHI dependency (RHI is only in the Renderer itself).
public static class ParticleRenderExtractor
{
	/// Extracts billboard vertices from a system into renderData.
	/// cameraPos is used for sorting (back-to-front) and stretched billboard projection.
	public static void Extract(
		ParticleSystem system,
		ParticleRenderData renderData,
		Vector3 cameraPos)
	{
		let streams = system.Streams;
		renderData.VertexCount = 0;
		renderData.BlendMode = system.BlendMode;
		renderData.RenderMode = system.RenderMode;
		renderData.Bounds = default;

		if (streams.AliveCount == 0)
			return;

		let positions = streams.Positions;
		let sizes = streams.Sizes;
		let colors = streams.Colors;
		let rotations = streams.Rotations;
		let velocities = streams.Velocities;
		if (positions == null) return;

		// Sort if needed (back-to-front for alpha blending)
		int32[] sortIndices = null;
		if (system.SortParticles && system.BlendMode == .Alpha)
		{
			sortIndices = scope :: int32[streams.AliveCount];
			SortBackToFront(positions, streams.AliveCount, cameraPos, sortIndices);
		}

		// Compute AABB from alive particle positions
		var boundsMin = positions[0];
		var boundsMax = positions[0];
		for (int32 i = 1; i < streams.AliveCount; i++)
		{
			let p = positions[i];
			boundsMin = Vector3.Min(boundsMin, p);
			boundsMax = Vector3.Max(boundsMax, p);
		}
		// Expand by max particle size to account for billboard extent
		float maxSize = 0.1f;
		if (sizes != null)
		{
			for (int32 i = 0; i < streams.AliveCount; i++)
			{
				let s = Math.Max(sizes[i].X, sizes[i].Y);
				if (s > maxSize) maxSize = s;
			}
		}
		let expand = Vector3(maxSize, maxSize, maxSize);
		renderData.Bounds = .(boundsMin - expand, boundsMax + expand);

		// Build vertex data
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let srcIdx = (sortIndices != null) ? sortIndices[i] : i;
			ref ParticleVertex v = ref renderData.Vertices[i];

			v.Position = positions[srcIdx];
			v.Size = (sizes != null) ? sizes[srcIdx] : .(0.1f, 0.1f);
			v.Rotation = (rotations != null) ? rotations[srcIdx] : 0;

			if (colors != null)
			{
				let c = colors[srcIdx];
				v.Color = Color(c.X, c.Y, c.Z, c.W);
			}
			else
			{
				v.Color = .(255, 255, 255, 255);
			}

			// Stretched billboard velocity projection
			if (system.RenderMode == .StretchedBillboard && velocities != null)
			{
				let toCamera = Vector3.Normalize(cameraPos - v.Position);
				var right = Vector3.Cross(.(0, 1, 0), toCamera);
				let rightLen = right.Length();
				if (rightLen > 0.001f)
					right = right / rightLen;
				else
					right = .(1, 0, 0);
				let up = Vector3.Cross(toCamera, right);
				v.Velocity2D = .(
					Vector3.Dot(velocities[srcIdx], right),
					Vector3.Dot(velocities[srcIdx], up)
				);
			}
			else
			{
				v.Velocity2D = .Zero;
			}

			// Default full-texture UV (no atlas)
			v.TexCoordOffset = .Zero;
			v.TexCoordScale = .(1, 1);
		}

		renderData.VertexCount = streams.AliveCount;
	}

	/// Extracts trail ribbon vertices from a system into renderData.
	/// Generates camera-facing ribbon quads between adjacent trail points.
	public static void ExtractTrails(
		ParticleSystem system,
		ParticleRenderData renderData,
		Vector3 cameraPos)
	{
		renderData.TrailVertexCount = 0;

		if (!system.Trail.IsActive) return;
		if (system.TrailStates == null || system.TrailPoints == null) return;
		if (system.AliveCount == 0) return;

		let trailSettings = system.Trail;
		let maxPoints = Math.Max(trailSettings.MaxPoints, 2);
		let totalTime = system.TotalTime;

		// Estimate max trail vertices needed: each segment = 6 vertices (2 triangles)
		let maxTrailVertices = system.AliveCount * (maxPoints - 1) * 6;
		renderData.EnsureTrailVertices(maxTrailVertices);

		int32 vertexIdx = 0;

		for (int32 i = 0; i < system.AliveCount; i++)
		{
			let state = ref system.TrailStates[i];
			if (state.Count < 2) continue;

			let baseOffset = i * maxPoints;

			// Walk from newest to oldest point, generating ribbon quads
			for (int32 seg = 0; seg < state.Count - 1; seg++)
			{
				if (vertexIdx + 6 > maxTrailVertices) break;

				// Ring buffer indices: newest first
				let currRingIdx = ((state.Head - 1 - seg) % maxPoints + maxPoints) % maxPoints;
				let nextRingIdx = ((state.Head - 2 - seg) % maxPoints + maxPoints) % maxPoints;

				let currPoint = system.TrailPoints[baseOffset + currRingIdx];
				let nextPoint = system.TrailPoints[baseOffset + nextRingIdx];

				// Fade out old points
				let currAge = totalTime - currPoint.RecordTime;
				let nextAge = totalTime - nextPoint.RecordTime;

				if (currAge > trailSettings.Lifetime || nextAge > trailSettings.Lifetime)
					break;

				let currFade = 1.0f - (currAge / trailSettings.Lifetime);
				let nextFade = 1.0f - (nextAge / trailSettings.Lifetime);

				// Direction along the ribbon
				var dir = currPoint.Position - nextPoint.Position;
				let dirLen = dir.Length();
				if (dirLen < 0.0001f) continue;
				dir = dir / dirLen;

				// Width direction: perpendicular to ribbon and camera-to-point
				let toCamera = Vector3.Normalize(cameraPos - currPoint.Position);
				var widthDir = Vector3.Cross(dir, toCamera);
				let widthLen = widthDir.Length();
				if (widthLen < 0.0001f) continue;
				widthDir = widthDir / widthLen;

				let currWidth = currPoint.Width * currFade * 0.5f;
				let nextWidth = nextPoint.Width * nextFade * 0.5f;

				// V coordinate: normalized position along trail
				let vCurr = (float)seg / (float)(state.Count - 1);
				let vNext = (float)(seg + 1) / (float)(state.Count - 1);

				// Colors with fade applied to alpha
				let currColor = Color(
					(float)currPoint.Color.R / 255.0f,
					(float)currPoint.Color.G / 255.0f,
					(float)currPoint.Color.B / 255.0f,
					(float)currPoint.Color.A / 255.0f * currFade
				);
				let nextColor = Color(
					(float)nextPoint.Color.R / 255.0f,
					(float)nextPoint.Color.G / 255.0f,
					(float)nextPoint.Color.B / 255.0f,
					(float)nextPoint.Color.A / 255.0f * nextFade
				);

				// Four corners of the quad
				let p0 = currPoint.Position - widthDir * currWidth;
				let p1 = currPoint.Position + widthDir * currWidth;
				let p2 = nextPoint.Position - widthDir * nextWidth;
				let p3 = nextPoint.Position + widthDir * nextWidth;

				// Triangle 1: p0, p1, p2
				renderData.TrailVertices[vertexIdx]     = .() { Position = p0, TexCoord = .(0, vCurr), Color = currColor };
				renderData.TrailVertices[vertexIdx + 1] = .() { Position = p1, TexCoord = .(1, vCurr), Color = currColor };
				renderData.TrailVertices[vertexIdx + 2] = .() { Position = p2, TexCoord = .(0, vNext), Color = nextColor };

				// Triangle 2: p2, p1, p3
				renderData.TrailVertices[vertexIdx + 3] = .() { Position = p2, TexCoord = .(0, vNext), Color = nextColor };
				renderData.TrailVertices[vertexIdx + 4] = .() { Position = p1, TexCoord = .(1, vCurr), Color = currColor };
				renderData.TrailVertices[vertexIdx + 5] = .() { Position = p3, TexCoord = .(1, vNext), Color = nextColor };

				vertexIdx += 6;
			}
		}

		renderData.TrailVertexCount = vertexIdx;
	}

	/// Sorts particles back-to-front by squared distance to camera.
	private static void SortBackToFront(
		CPUStream<Vector3> positions,
		int32 count,
		Vector3 cameraPos,
		int32[] outIndices)
	{
		float[] distances = scope float[count];
		for (int32 i = 0; i < count; i++)
		{
			outIndices[i] = i;
			let diff = positions[i] - cameraPos;
			distances[i] = Vector3.Dot(diff, diff);
		}

		// Insertion sort (back-to-front: farthest first)
		for (int32 i = 1; i < count; i++)
		{
			let key = outIndices[i];
			let keyDist = distances[key];
			var j = i - 1;

			while (j >= 0 && distances[outIndices[j]] < keyDist)
			{
				outIndices[j + 1] = outIndices[j];
				j--;
			}
			outIndices[j + 1] = key;
		}
	}
}