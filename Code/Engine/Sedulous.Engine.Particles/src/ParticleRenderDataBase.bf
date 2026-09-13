using Sedulous.Render;

namespace Sedulous.Engine.Particles;

/// What both particle render data kinds share.
///
/// They ride ONE renderer id, so the kind is what tells them apart when the renderer resolves
/// a draw. A second renderer would be the alternative, and it would duplicate the whole
/// pipeline set for what is one branch.
class ParticleRenderDataBase : RenderData
{
	/// Nought is a billboard batch and one is a trail ribbon.
	public uint8 ParticleKind = 0;
}
