namespace Sedulous.Particles;

using System;

/// Particle simulation backend.
public enum SimulationMode : uint8
{
	/// CPU simulation - SoA arrays updated per-frame on CPU, uploaded to GPU for rendering.
	/// Supports all behaviors including CPU-only ones (raycasting, scene queries).
	CPU,

	/// GPU compute shader simulation - data stays on GPU, rendered directly (zero copy).
	/// Only behaviors that declare GPU support can be used.
	GPU,

	/// Automatic selection - GPU if all attached behaviors support it and particle
	/// count exceeds a threshold; CPU otherwise.
	Auto
}

/// Particle simulation space.
public enum ParticleSpace : uint8
{
	/// Particles simulate in world space. Moving the emitter doesn't affect
	/// already-spawned particles.
	World,

	/// Particles simulate relative to the emitter transform. Moving the emitter
	/// moves all particles with it.
	Local
}

/// Particle blend mode for rendering.
public enum ParticleBlendMode : uint8
{
	/// Standard alpha blending (src × srcAlpha + dst × (1 − srcAlpha)).
	Alpha,

	/// Additive blending (src + dst). Good for fire, sparks, magic.
	Additive,

	/// Premultiplied alpha.
	Premultiplied,

	/// Multiply blending (src × dst). Darkens.
	Multiply
}

/// How particles are rendered.
public enum ParticleRenderMode : uint8
{
	/// Camera-facing billboards.
	Billboard,

	/// Velocity-aligned stretched billboards.
	StretchedBillboard,

	/// Horizontal billboards (facing up, Y-axis normal).
	HorizontalBillboard,

	/// Vertical billboards (face camera horizontally, locked Y-up).
	VerticalBillboard,

	/// Mesh particles (instanced mesh per particle).
	Mesh,

	/// Trail particles (connected strip following particle trajectory).
	Trail
}

/// Simulation mode that a behavior supports.
public enum BehaviorSupport : uint8
{
	/// CPU simulation only.
	CPUOnly,

	/// GPU compute only.
	GPUOnly,

	/// Supports both CPU and GPU simulation.
	Both
}
