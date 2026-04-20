namespace Sedulous.Renderer;

/// Interface for scene modules that produce render data.
/// Implemented by component managers (MeshComponentManager, LightComponentManager,
/// ParticleComponentManager, etc.) in the engine layer.
///
/// The RenderSubsystem discovers all scene modules that implement this interface
/// and calls ExtractRenderData after scene updates complete. Providers iterate
/// their active components and add render data to the context's output.
///
/// Providers are responsible for:
///   - Skipping inactive/invisible components
///   - Layer mask filtering (via context.LayerMask)
///   - Frustum culling (when context provides visibility data, future)
///   - LOD selection (via context.CameraPosition + context.LODBias)
///
/// The Renderer knows nothing about entities or scenes - this interface is
/// the boundary between scene-aware code and scene-independent rendering.
interface IRenderDataProvider
{
	/// Extracts render data from this provider's components into the context.
	/// Called once per frame per view by the RenderSubsystem.
	void ExtractRenderData(in RenderExtractionContext context);
}
