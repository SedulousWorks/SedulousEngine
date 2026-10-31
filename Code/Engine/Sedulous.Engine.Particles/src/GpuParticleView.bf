using System;
using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// The particles' view block, mirroring particle.vs.hlsl's (and particletrail's) ParticleView:
/// the view's two matrices and the depth reconstruction terms.
[CRepr]
struct GpuParticleView
{
	public Float4x4 ViewProj;
	public Float4x4 View;
	/// The projection terms that turn a sampled NDC depth back into view depth (soft particles):
	/// M[2][2], M[3][2] and M[2][3], the last nought for an orthographic projection. The soft
	/// distance itself rides each instance (ParticleBillboardInstance.SoftDistance).
	public float ProjZScale;
	public float ProjZOffset;
	public float ProjWScale;
	public float Pad0;
}
