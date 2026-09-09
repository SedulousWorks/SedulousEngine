using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Render;

/// The scene rendering coordinator.
///
/// A LIGHT SEAM: it names only core, RHI and scene types, so a tool can drive scene rendering
/// without linking the renderer at all.
///
/// One bracket per frame, with any number of views inside it:
///
///     BeginRendering(encoder, frameIndex);
///     RenderScene(sceneA, targetA, ...);
///     RenderScene(sceneB, targetB, ...);
///     EndRendering();
///
/// Beginning resets the shared per frame state once; each render extracts a scene and
/// collects a view over it; ending composes every collected view into the frame. The CALLER
/// owns the encoder, the targets and the frame pacing. The bracket self guards when the
/// renderer is not ready, so it can be driven unconditionally.
interface ISceneRenderer
{
	/// `encoder` is the caller's and receives every command of the frame; `frameIndex` is the
	/// device's ring index.
	void BeginRendering(ICommandEncoder encoder, uint32 frameIndex);

	/// Collects a scene, seen from its primary camera or from the override, to be drawn into
	/// a target. Between the brackets.
	///
	/// The `viewport` is the sub rectangle to render into, and distinct viewports with their
	/// own camera overrides across several calls are what a split screen is.
	///
	/// The `viewportKey` is a STABLE per view identity. When it is given, this view's scene
	/// gizmos come from that key's own debug buffer rather than the scene's shared one, so an
	/// editor viewport can draw a grid that appears ONLY in it and not in a second view of
	/// the same scene. Null keeps the per scene buffer, drawn in every view, which is what a
	/// gameplay view wants.
	void RenderScene(Scene scene, ITextureView target, TextureFormat targetFormat, uint32 width,
		uint32 height, ViewportRect viewport = .(), CameraOverride* cameraOverride = null,
		TargetState targetState = .(), ViewPostOverride* postOverride = null,
		void* viewportKey = null, ViewDebugView debugView = null);

	/// Composes every collected view into the frame's encoder.
	void EndRendering();

	/// The PREVIOUS frame's graph inventory, for a debug view picker. THE CALLER OWNS the
	/// rows appended.
	///
	/// Empty by default, so a light stand in need not implement it.
	void GetDebugResources(List<DebugResourceInfo> outResources)
	{
		ClearAndDeleteItems!(outResources);
	}

	/// The scene tier registry. Idempotent and NON OWNING: unregister before destroying.
	void RegisterOverlay(ISceneOverlay overlay);
	void UnregisterOverlay(ISceneOverlay overlay);
}
