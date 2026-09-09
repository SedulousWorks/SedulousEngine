using Sedulous.RHI;

namespace Sedulous.Render;

/// One entry of the sprite renderer's pipeline cache, which is keyed by target format AND
/// blend mode: an in scene sprite draws into the scene while a post tone mapping one draws
/// into the final image, both within a single frame.
struct SpritePipelineEntry
{
	public IRenderPipeline Pipeline = null;
	public TextureFormat Format = .Undefined;
	public bool Additive = false;
	/// What the shader's version was when this was built, so a hot reload rebuilds it.
	public uint64 ShaderVersion = 0;

	public this() {}
}
