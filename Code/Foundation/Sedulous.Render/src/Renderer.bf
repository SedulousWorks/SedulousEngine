using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Render;

/// A per category drawer, which a mesh, sprite or particle subsystem implements and registers.
///
/// TWO PHASES. Resolving turns a sorted run of draw items into resolved draws, and is where
/// the uploads, the pipeline builds and the ring allocations happen, so it runs on one thread.
/// Emitting then replays those, serially or in parallel, mutating nothing.
///
/// The frame bracket exists so a renderer sizes its transient buffers ONCE: growing one mid
/// frame would invalidate the draws already resolved against it.
abstract class Renderer
{
	/// This renderer's dispatch id, which is its index in the registry.
	///
	/// A producer stamps it onto its render data, so a draw is routed back to the renderer
	/// that understands it: several renderers can share a category, and the category alone
	/// would not say which.
	public uint16 RendererId = 0;

	/// The categories this renderer draws, which are its registration keys.
	public abstract Span<uint16> SupportedCategories { get; }

	/// Opens the frame. `maxDraws` is an upper bound across every view, so the per object
	/// transients are sized once and never reallocated mid frame.
	public virtual void PrepareFrame(uint32 maxDraws, uint32 frameIndex) {}

	/// Turns a sorted run of this renderer's draws into resolved ones, appending them.
	public abstract void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws);

	/// The same draws as DEPTH ONLY casters for a shadow pass, where the context's matrix is
	/// the light's.
	///
	/// Nothing by default, so a renderer OPTS IN to casting shadows: a mesh does, a sprite
	/// need not.
	public virtual void ResolveDepthOnly(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws) {}

	/// This frame's directional shadow map, with the generation the shadow system bumps when
	/// it recreates the texture, so a bind group cache invalidates rather than holding a view
	/// whose address came back around.
	public virtual void SetShadowMap(ITextureView shadowMap, uint64 generation) {}

	/// This frame's local light atlas, under the same contract. The pass count is how many
	/// atlas passes will re-emit this renderer's casters, so it can size its rings for them.
	public virtual void SetShadowAtlas(ITextureView atlas, uint64 generation, uint32 passCount) {}

	/// How many probe capture faces will re-emit this renderer's draws, each being a forward
	/// pass of its own.
	public virtual void SetCaptureFacePasses(uint32 passes) {}

	/// Re-emits these items as PICK ID writers: the context's matrix is the pick view's cropped
	/// world to clip, its colour format the RG32Uint id target and its depth format that
	/// target's depth. Each draw's fragment writes its RenderData tag as (entity index plus
	/// one, generation); the pass's own depth keeps the nearest. Nothing by default, so a
	/// renderer whose draws are not pickable, sprites and particles, costs nothing; the
	/// editor's CPU pick covers their entities.
	public virtual void ResolvePickIds(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws) {}

	/// How many pick passes will re-emit this renderer's draws this frame, for the per object
	/// ring sizing, like the capture faces. Called before PrepareFrame.
	public virtual void SetPickPasses(uint32 passes) {}

	/// This frame's probes: the prefiltered cube array, the metadata, and how many are active.
	public virtual void SetProbes(ITextureView cubeArray, IBuffer probeBuffer, uint32 count) {}

	/// This frame's local shadow entries, for a renderer that binds them.
	public virtual void UploadLocalShadows(Span<GpuLocalShadow> shadows, uint32 frameIndex) {}

	/// Writes this frame's skinning matrices into the renderer's pool ONCE and copies them to
	/// the device.
	///
	/// Before the graph executes, so the forward pass and every shadow pass share one device
	/// local bone buffer: uploading per pass would stream the same matrices across the bus
	/// once per cascade.
	public virtual void UploadSkinning(ExtractedScene scene, ICommandEncoder encoder) {}

	public virtual void FinishFrame() {}
}
