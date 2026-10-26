using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// A GUI document shown in its scene's GUI: a menu, a HUD. Spawned it opens, despawned it
/// closes, so a menu riding in a scene or a prefab has no lifetime of its own to keep in step.
///
/// The tree, its host and a render texture's root are the SUBSYSTEM's to build: a component is
/// a struct in a packed pool, and building needs the GUI's context, which a headless scene
/// consumer never has. The component holds its own reference to each, which its manager lets
/// go when the component is removed.
[SerializableComponent("gui.Canvas")]
[DisplayName("GUI Canvas")]
[Category("GUI")]
[Scriptable]
[Description("Shows a GUI document in its scene, as a menu or a HUD, or draws it into a texture.")]
struct GuiCanvasComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<GuiDocument> Document = .(Guid());
	/// Over the game's sheets, for this canvas alone. Optional.
	[Scriptable]
	public Ref<GuiStyleSheet> Sheet = .(Guid());
	/// Among the scene's canvases: higher on top.
	[Scriptable]
	public int32 Order = 0;
	[Scriptable]
	public bool Visible = true;
	[Scriptable]
	public bool Interactive = true;
	[Scriptable]
	public GuiScalerMode ScalerMode = .ConstantPixel;
	[Scriptable]
	public Float2 ReferenceResolution = .(1920.0f, 1080.0f);
	[Scriptable]
	public GuiCanvasRenderMode RenderMode = .ScreenOverlay;
	/// Render texture mode: the texture's size, in pixels.
	[Scriptable]
	public uint32 RenderTextureWidth = 512;
	[Scriptable]
	public uint32 RenderTextureHeight = 512;

	// ---- runtime, never serialized ----

	/// The tree built from the document. A HELD reference.
	public Node Root = null;
	/// Its place in the scene's root, which carries the order and the scaler. A HELD reference.
	public UIWidget Host = null;
	/// The document product it was built from, compared by reference so a re-cook rebuilds
	/// (the resource manager parks a replaced product for frames, so a new one never takes its
	/// address while the GUI polls each frame). Borrowed.
	public GuiDocument BuiltFrom = null;
	/// The sheet product applied, compared as BuiltFrom is. Borrowed.
	public GuiStyleSheet SheetFrom = null;
	/// Render texture mode: a root of its own, never in a scene's GUI. A HELD reference.
	public SceneRoot RenderRoot = null;
	/// Render texture mode: the subsystem's, and null until first drawn.
	public ITexture RenderTexture = null;
	public ITextureView RenderTextureView = null;

	public this() {}

	/// The tree built from the document, `Root()` to a script: a node held weakly, as a script
	/// holds every node, so the GUI's finders reach inside it, as in
	/// `GuiCanvasComponent::of(hud).Root().Find("score")`.
	/// Null until the subsystem has built it. Named apart in Beef, where Root is the runtime field.
	[Scriptable, ScriptName("Root")]
	public Node RootNode() => Root;

	public void ResolveResources(ResourceManager manager) mut
	{
		Document.Bind(manager);
		Sheet.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "document", ref Document.Id);
		SerializeValue(ar, "sheet", ref Sheet.Id);
		SerializeValue(ar, "order", ref Order);
		SerializeValue(ar, "visible", ref Visible);
		SerializeValue(ar, "interactive", ref Interactive);

		ar.Key("scalerMode");
		SerializeEnum(ar, ref ScalerMode);

		SerializeValue(ar, "referenceResolution", ref ReferenceResolution);

		ar.Key("renderMode");
		SerializeEnum(ar, ref RenderMode);

		SerializeValue(ar, "renderTextureWidth", ref RenderTextureWidth);
		SerializeValue(ar, "renderTextureHeight", ref RenderTextureHeight);
	}
}
