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
	private CameraComponentManager Cameras => Scene.GetSystem<CameraComponentManager>();

	[Scriptable]
	public bool SetMesh(EntityHandle entity, Guid mesh) => Meshes?.SetMesh(entity, mesh) ?? false;
	[Scriptable]
	public bool SetMaterial(EntityHandle entity, Guid material, int slot = 0) => Meshes?.SetMaterial(entity, material, slot) ?? false;
	/// Sets one of the entity's material properties for it alone: the material in `slot` draws
	/// with `value` for the property `name` (as the material editor shows it: Roughness), every
	/// other mesh using that material unchanged. A name the material does not have, or a value
	/// wider than the property, changes nothing. Runtime only: not saved with the scene. False
	/// for an entity without a mesh or a negative slot.
	[Scriptable]
	public bool SetMaterialFloat(EntityHandle entity, int slot, StringView name, float value) => Meshes?.SetMaterialProperty(entity, slot, name, .(value, 0, 0, 0), sizeof(float)) ?? false;
	/// The same for a colour or a vector: a colour as authored, sRGB rgba, and an HDR colour
	/// (EmissiveColor) sRGB rgb with its intensity in w.
	[Scriptable]
	public bool SetMaterialFloat4(EntityHandle entity, int slot, StringView name, Float4 value) => Meshes?.SetMaterialProperty(entity, slot, name, value, sizeof(Float4)) ?? false;
	/// Puts a property set by SetMaterialFloat or SetMaterialFloat4 back to the material's own
	/// value; false if it was not set.
	[Scriptable]
	public bool ClearMaterialProperty(EntityHandle entity, int slot, StringView name) => Meshes?.ClearMaterialProperty(entity, slot, name) ?? false;
	/// Points the entity's camera at a render texture asset, which it then draws into instead
	/// of the screen; a nil id gives the camera back to the screen. False for an entity
	/// without a camera.
	[Scriptable]
	public bool SetCameraTarget(EntityHandle entity, Guid texture) => Cameras?.SetTarget(entity, texture) ?? false;
	/// How much light reaches `position`, linear RGB: every enabled light by the renderer's own
	/// falloff and cone, a shadow casting one stopped by what stands between (a ray among the
	/// collision groups in `groupMask`), plus the ambient. A CPU estimate of the shading for a
	/// light meter or a guard's eye, not a read of the frame; ask from a point off any surface.
	[Scriptable]
	public Float3 LightAt(Float3 position, uint32 groupMask = 0xFFFFFFFF) => RenderExtract.LightAt(Scene, position, groupMask);
}

/// `scene.Debug`: lines, shapes and text drawn over the scene for a frame. The drawer is
/// the render subsystem's, per scene; with no renderer every call is a no-op. Colours are sRGB,
/// as entered everywhere.
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
