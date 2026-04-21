namespace Sedulous.Editor.Core;

using Sedulous.Core.Mathematics;
using Sedulous.Renderer;

/// Drawing context passed to gizmo renderers.
/// Provides access to DebugDraw for wire shapes and viewport info.
struct GizmoContext
{
	/// Debug draw API for wire shapes, lines, text.
	public Sedulous.Renderer.Debug.DebugDraw DebugDraw;

	/// View-projection matrix for the current viewport.
	public Matrix ViewProjectionMatrix;

	/// Camera position in world space.
	public Vector3 CameraPosition;

	/// Viewport width in pixels.
	public uint32 ViewportWidth;

	/// Viewport height in pixels.
	public uint32 ViewportHeight;
}
