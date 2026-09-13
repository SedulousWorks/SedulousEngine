using Sedulous.Particles;
using Sedulous.RHI;

namespace Sedulous.Engine.Particles;

/// A batched ribbon for one system: a borrowed triangle list the manager's scratch owns for
/// the frame.
class ParticleTrailRenderData : ParticleRenderDataBase
{
	public TrailVertex* Vertices = null;
	public uint32 VertexCount = 0;
	public ITextureView Texture = null;
	public ParticleBlendMode Blend = .Alpha;

	public this()
	{
		ParticleKind = 1;
	}
}
