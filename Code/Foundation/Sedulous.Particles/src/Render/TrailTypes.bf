namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// A single recorded point in a particle trail.
[CRepr]
public struct TrailPoint
{
	/// World-space position.
	public Vector3 Position;

	/// Width at this point.
	public float Width;

	/// Color at this point.
	public Color Color;

	/// Time this point was recorded (elapsed emitter time).
	public float RecordTime;

	/// Size in bytes.
	public static int SizeInBytes => 28;
}

/// Vertex data for trail ribbon rendering.
/// Two vertices per trail point (left and right edges of the ribbon).
[CRepr]
public struct TrailVertex
{
	/// World-space position (ribbon edge).
	public Vector3 Position;

	/// Texture coordinate (U=[0,1] across width, V=[0,1] along length).
	public Vector2 TexCoord;

	/// Vertex color.
	public Color Color;

	/// Size in bytes.
	public static int SizeInBytes => 24;
}

/// Per-particle trail state (ring buffer metadata).
/// Trail points are stored in a shared flat array indexed by particle index.
public struct ParticleTrailState
{
	/// Current write head (wraps around).
	public int32 Head;

	/// Number of active points (up to max).
	public int32 Count;

	/// Time of last recorded point.
	public float LastRecordTime;

	/// Last recorded position (for distance check).
	public Vector3 LastPosition;

	/// Clears all trail points.
	public void Clear() mut
	{
		Head = 0;
		Count = 0;
		LastRecordTime = 0;
		LastPosition = .Zero;
	}
}

/// Trail configuration settings for a particle emitter.
[CRepr]
public struct TrailSettings
{
	/// Whether trails are enabled.
	public bool Enabled;

	/// Maximum trail points per particle.
	public int32 MaxPoints;

	/// Minimum time between recording trail points (seconds).
	public float RecordInterval;

	/// Trail point lifetime (seconds). Points older than this fade out.
	public float Lifetime;

	/// Width at the newest point (near particle).
	public float WidthStart;

	/// Width at the oldest point (trail tip).
	public float WidthEnd;

	/// Minimum distance between adjacent trail points.
	public float MinVertexDistance;

	/// Whether the trail uses the particle's color or a fixed color.
	public bool UseParticleColor;

	/// Fixed trail color (used when UseParticleColor is false).
	public Vector4 TrailColor;

	/// Creates default trail settings.
	public static Self Default()
	{
		return .()
		{
			Enabled = false,
			MaxPoints = 16,
			RecordInterval = 0.033f,
			Lifetime = 1.0f,
			WidthStart = 0.05f,
			WidthEnd = 0.0f,
			MinVertexDistance = 0.02f,
			UseParticleColor = true,
			TrailColor = .(1, 1, 1, 1)
		};
	}

	/// Whether these settings have trails active.
	public bool IsActive => Enabled && MaxPoints >= 2;
}
