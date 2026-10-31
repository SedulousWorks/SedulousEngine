using System;
using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// The particles' view block, mirroring particle.vs.hlsl's (and particletrail's) ParticleView:
/// the view's two matrices and the depth reconstruction coefficients.
[CRepr]
struct GpuParticleView
{
	public Float4x4 ViewProj;
	public Float4x4 View;
	/// The projection terms that turn a sampled depth back into a view space one. The fourth lane
	/// is unused: the soft fade distance rides each instance.
	public Float4 DepthParams;
}
