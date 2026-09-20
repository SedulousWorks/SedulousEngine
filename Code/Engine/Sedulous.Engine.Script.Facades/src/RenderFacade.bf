using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Render;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Render`: what an entity draws with, by asset id.
[Scriptable, SceneFacade("Render")]
class RenderFacade : SceneFacade
{
	private MeshComponentManager Meshes => Scene.GetSystem<MeshComponentManager>();

	[Scriptable]
	public bool SetMesh(EntityHandle entity, Guid mesh) => Meshes?.SetMesh(entity, mesh) ?? false;
	[Scriptable]
	public bool SetMaterial(EntityHandle entity, Guid material, int slot = 0) => Meshes?.SetMaterial(entity, material, slot) ?? false;
}

/// `scene.Debug`: lines, shapes and text drawn over the scene for a frame. The drawer is
/// the render subsystem's, per scene; with no renderer every call is a no-op.
[Scriptable, SceneFacade("Debug")]
class DebugFacade : SceneFacade
{
	/// BORROWED: the render subsystem, installed by the application; null draws nothing.
	public static RenderSubsystem Renderer = null;

	private DebugDraw Draw => (Renderer != null) ? Renderer.DebugScene(Scene) : null;

	[Scriptable]
	public void Line(Float3 from, Float3 to, Color color, bool overlay = false) => Draw?.DrawLine(from, to, color, overlay);
	[Scriptable]
	public void Ray(Float3 origin, Float3 direction, Color color, bool overlay = false) => Draw?.DrawRay(origin, direction, color, overlay);
	[Scriptable]
	public void WireBox(Float3 min, Float3 max, Color color, bool overlay = false) => Draw?.DrawWireBox(min, max, color, overlay);
	[Scriptable]
	public void WireSphere(Float3 center, float radius, Color color) => Draw?.DrawWireSphere(center, radius, color);
	[Scriptable]
	public void Cross(Float3 center, float size, Color color, bool overlay = false) => Draw?.DrawCross(center, size, color, overlay);
	[Scriptable]
	public void Arrow(Float3 start, Float3 end, Color color, float headSize = 0.1f) => Draw?.DrawArrow(start, end, color, headSize);
	[Scriptable]
	public void Text(Float3 worldPosition, StringView text, Color color) => Draw?.DrawText3D(worldPosition, text, color);
	[Scriptable]
	public void ScreenText(float x, float y, StringView text, Color color, float scale = 1.0f) => Draw?.DrawScreenText(x, y, text, color, scale);
}
