namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Extracted render data for a single particle system.
/// Produced by ParticleRenderExtractor each frame for the renderer to consume.
/// Contains the vertex array ready for GPU upload plus rendering configuration.
public class ParticleRenderData
{
	/// Billboard particle vertices (one per alive particle, sorted if needed).
	public ParticleVertex[] Vertices ~ delete _;

	/// Number of valid vertices in the array.
	public int32 VertexCount;

	/// Trail vertices (if trails are active).
	public TrailVertex[] TrailVertices ~ delete _;

	/// Number of valid trail vertices.
	public int32 TrailVertexCount;

	/// Computed AABB from alive particle positions (for frustum culling).
	public BoundingBox Bounds;

	/// Blend mode for rendering.
	public ParticleBlendMode BlendMode;

	/// Render mode (billboard type, mesh, trail).
	public ParticleRenderMode RenderMode;

	/// Maximum particle capacity (array sizes).
	public int32 Capacity { get; private set; }

	public this(int32 capacity)
	{
		Capacity = capacity;
		Vertices = new ParticleVertex[capacity];
	}

	/// Allocates trail vertex storage if not already present.
	public void EnsureTrailVertices(int32 maxTrailVertices)
	{
		if (TrailVertices == null || TrailVertices.Count < maxTrailVertices)
		{
			delete TrailVertices;
			TrailVertices = new TrailVertex[maxTrailVertices];
		}
	}
}
