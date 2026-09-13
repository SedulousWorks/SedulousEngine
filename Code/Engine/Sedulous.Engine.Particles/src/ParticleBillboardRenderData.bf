using Sedulous.Particles;
using Sedulous.RHI;

namespace Sedulous.Engine.Particles;

/// A BATCH: one item per system, texture and blend, carrying a borrowed run of packed
/// instances.
///
/// This is the difference from the sprite path, which emits one item per sprite. A particle
/// count would flood the draw list's sort otherwise, so the renderer takes the batch and emits
/// one instanced draw from it.
///
/// The instances are BORROWED and valid for the frame; the component manager's scratch owns
/// them.
class ParticleBillboardRenderData : ParticleRenderDataBase
{
	public ParticleBillboardInstance* Instances = null;
	public uint32 Count = 0;
	public ITextureView Texture = null;
	/// Selects the renderer's blend pipeline.
	public ParticleBlendMode Blend = .Alpha;
}
