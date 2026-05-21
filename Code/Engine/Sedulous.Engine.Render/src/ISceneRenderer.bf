namespace Sedulous.Engine.Render;

using Sedulous.RHI;
using Sedulous.Engine.Core;
using Sedulous.Renderer;

/// Renders the 3D scene to caller-provided output targets.
/// Implemented by RenderSubsystem. Application queries via
/// Context.GetSubsystemByInterface<ISceneRenderer>().
///
/// Usage:
///   BeginRendering(encoder, frameIndex);
///   RenderScene(scene1, encoder, ...);
///   RenderScene(scene2, encoder, ...);
///   EndRendering();
///
/// BeginRendering resets shared per-frame state (frame allocator, shadow
/// atlas, view pool). RenderScene handles per-scene extraction, shadow
/// rendering, and forward pass. Multiple scenes share the shadow atlas
/// and frame allocator without clobbering each other.
interface ISceneRenderer
{
	/// Begins a rendering frame. Resets shared per-frame state (frame allocator,
	/// shadow atlas, view pool, shadow pipeline ring buffers). Must be called
	/// once per frame before any RenderScene calls.
	void BeginRendering(ICommandEncoder encoder, int32 frameIndex);

	/// Renders a specific scene to the provided output targets.
	/// Each (scene, viewportKey) pair has its own Pipeline. The default
	/// scene-wide pipeline (key = null) is created in OnSceneCreated;
	/// additional pipelines for secondary viewports (camera previews,
	/// reflection probes, ortho sub-viewports) are created on demand via
	/// AcquirePipeline.
	/// The application owns the encoder, output textures, and frame pacing.
	/// After this call, the color target is transitioned to ShaderRead for blit sampling.
	/// Pass a CameraOverride to use external camera matrices instead of the scene's active camera.
	/// Must be called between BeginRendering/EndRendering.
	void RenderScene(Scene scene, ICommandEncoder encoder, ITexture colorTexture, ITextureView colorTarget,
		uint32 w, uint32 h, int32 frameIndex, CameraOverride? camera = null,
		void* viewportKey = null);

	/// Ends a rendering frame. Called after all RenderScene calls for the frame.
	void EndRendering();

	/// Get the pipeline for a (scene, viewportKey) pair. Returns null if no
	/// such pipeline exists. Pass key = null for the scene's default pipeline.
	Pipeline GetPipeline(Scene scene, void* viewportKey = null);

	/// Lazily create and return a secondary pipeline for the given key. The
	/// caller owns the lifecycle: pair every Acquire with a Release. Acquiring
	/// the same key twice returns the same instance. Pass key = null to get
	/// the scene-default pipeline (already created by OnSceneCreated).
	Pipeline AcquirePipeline(Scene scene, void* viewportKey);

	/// Tear down a secondary pipeline previously acquired via AcquirePipeline.
	/// No-op if the key was never acquired or has already been released. The
	/// scene-default pipeline (key = null) is owned by OnSceneCreated/
	/// OnSceneDestroyed and cannot be released through this method.
	void ReleasePipeline(Scene scene, void* viewportKey);

	/// Shared rendering infrastructure (DebugDraw, GPU resources, materials, etc.).
	RenderContext RenderContext { get; }
}
