namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Renders the 3D scene to caller-provided output targets.
/// Implemented by RenderSubsystem. Application queries via
/// Context.GetSubsystemByInterface<ISceneRenderer>().
interface ISceneRenderer
{
	/// Renders the scene to the provided output targets.
	/// The application owns the encoder, output textures, and frame pacing.
	/// After this call, the color target is transitioned to ShaderRead for blit sampling.
	void RenderScene(ICommandEncoder encoder, ITexture colorTexture, ITextureView colorTarget,
		uint32 w, uint32 h, int32 frameIndex);

	/// The render pipeline (for pass registration, output dimensions, etc.).
	Pipeline Pipeline { get; }

	/// Shared rendering infrastructure (DebugDraw, GPU resources, materials, etc.).
	RenderContext RenderContext { get; }
}
