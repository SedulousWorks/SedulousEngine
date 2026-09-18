using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// A screen space UI canvas on an entity.
///
/// Menus and heads up displays ride in SCENES and PREFABS, so spawning and despawning one is
/// what opening and closing it means: there is no separate UI lifetime to keep in step with
/// the game's.
///
/// The view tree, the host group and the offscreen target are OWNED BY THE SUBSYSTEM, a
/// component being a struct in a packed pool that cannot own heap data.
[SerializableComponent("ui.Canvas")]
[DisplayName("UI Canvas")]
[Category("UI")]
[Scriptable]
struct UICanvasComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<UIDocument> Document = .(Guid());
	/// Optional. Unset takes the context's own theme.
	[Scriptable]
	public Ref<UITheme> Theme = .(Guid());
	/// Draw and dispatch order, higher being on top.
	[Scriptable]
	public int32 Order = 0;
	[Scriptable]
	public bool Visible = true;
	[Scriptable]
	public bool Interactive = true;
	[Scriptable]
	public CanvasScalerMode ScalerMode = .ConstantPixel;
	[Scriptable]
	public Float2 ReferenceResolution = .(1920.0f, 1080.0f);
	[Scriptable]
	public CanvasRenderMode RenderMode = .ScreenOverlay;
	/// Render texture mode: how big the target is, in pixels.
	[Scriptable]
	public uint32 RenderTextureWidth = 512;
	[Scriptable]
	public uint32 RenderTextureHeight = 512;

	// ---- runtime, never serialized ----

	/// The instantiated tree, whose template is the document.
	public View Root = null;
	/// This canvas's host in the scene's root, which carries the order and the scaler.
	public ViewGroup Host = null;
	/// Render texture mode: a STANDALONE root, never one of the tiers.
	public RootView RenderRoot = null;
	/// What the tree was built from, compared by reference so a hot reload rebuilds.
	public UIDocument BuiltFrom = null;
	/// The parsed override, rebuilt when the theme changes.
	public StyleSheet ThemeSheet = null;
	public UITheme ThemeFrom = null;
	/// Render texture mode: subsystem owned, and null until the first render.
	public ITexture RenderTexture = null;
	public ITextureView RenderTextureView = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Document.Bind(manager);
		Theme.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "document", ref Document.Id);
		SerializeValue(ar, "theme", ref Theme.Id);
		SerializeValue(ar, "order", ref Order);
		SerializeValue(ar, "visible", ref Visible);

		ar.Key("scalerMode");
		SerializeEnum(ar, ref ScalerMode);

		SerializeValue(ar, "referenceResolution", ref ReferenceResolution);
		SerializeValue(ar, "interactive", ref Interactive);

		ar.Key("renderMode");
		SerializeEnum(ar, ref RenderMode);

		SerializeValue(ar, "renderTextureWidth", ref RenderTextureWidth);
		SerializeValue(ar, "renderTextureHeight", ref RenderTextureHeight);
	}
}
