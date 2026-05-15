namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Initializes the per-particle Axis stream used by mesh particles to
/// build an axis-angle quaternion. Without this initializer, mesh
/// particles keep `Axis = (0, 0, 0)` and the resulting quaternion is
/// the identity (rotation has no visible effect) - useful when authoring
/// world-aligned meshes; add this initializer when you want each particle
/// to tumble around its own random axis.
///
/// The rotation magnitude itself comes from the existing Rotation /
/// RotationSpeed streams (set by RotationInitializer +
/// RotationOverLifetimeBehavior). This initializer only picks the axis.
public class MeshOrientationInitializer : ParticleInitializer
{
	/// When true, every particle gets a uniformly random unit-vector axis
	/// on spawn. When false, the FixedAxis is used for every particle.
	[Property]
	public bool RandomAxis = true;

	/// Used when `RandomAxis == false`. Defaults to world Y so particles
	/// spin around the vertical axis (typical falling-debris look).
	[Property]
	public Vector3 FixedAxis = .(0, 1, 0);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Axis, .Float3);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		let axes = streams.Axes;
		if (axes == null) return;

		if (RandomAxis)
		{
			// Uniform random unit vector via the standard "two-angles" sampling:
			// cosTheta in [-1, 1], phi in [0, 2pi).
			let cosTheta = (float)(rng.NextDouble() * 2.0 - 1.0);
			let sinTheta = Math.Sqrt(Math.Max(0.0f, 1.0f - cosTheta * cosTheta));
			let phi = (float)(rng.NextDouble() * Math.PI_d * 2.0);
			axes[index] = .(sinTheta * Math.Cos(phi), cosTheta, sinTheta * Math.Sin(phi));
		}
		else
		{
			// Use the configured fixed axis. Normalize defensively in case
			// the author entered a non-unit vector.
			var a = FixedAxis;
			let lenSq = a.X * a.X + a.Y * a.Y + a.Z * a.Z;
			if (lenSq > 0.0001f)
			{
				let inv = 1.0f / Math.Sqrt(lenSq);
				a = .(a.X * inv, a.Y * inv, a.Z * inv);
			}
			else
			{
				a = .(0, 1, 0);
			}
			axes[index] = a;
		}
	}
}
