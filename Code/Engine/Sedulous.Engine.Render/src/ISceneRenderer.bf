namespace Sedulous.Engine.Render;

using Sedulous.RHI;
using Sedulous.Engine.Core;
using Sedulous.Renderer;

/// Renders the 3D scene to caller-provided output targets.
/// Implemented by RenderSubsystem. Application queries via
/// Context.GetSubsystemByInterface<ISceneRenderer>().
interface ISceneRenderer
{
	/// Renders a specific scene to the provided output targets.
	/// Each scene has its own Pipeline (created in OnSceneCreated).
	/// The application owns the encoder, output textures, and frame pacing.
	/// After this call, the color target is transitioned to ShaderRead for blit sampling.
	/// Pass a CameraOverride to use external camera matrices instead of the scene's active camera.
	void RenderScene(Scene scene, ICommandEncoder encoder, ITexture colorTexture, ITextureView colorTarget,
		uint32 w, uint32 h, int32 frameIndex, CameraOverride? camera = null);

	/// Get the pipeline for a specific scene. Returns null if scene has no pipeline.
	Pipeline GetPipeline(Scene scene);

	/// Shared rendering infrastructure (DebugDraw, GPU resources, materials, etc.).
	RenderContext RenderContext { get; }
}
