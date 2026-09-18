using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// A UI document ON A SURFACE IN THE WORLD.
///
/// The panel renders its tree into an offscreen target sized by PIXELS PER METRE, so density
/// is uniform however big the quad is, and drives a sibling sprite with it. That makes the
/// panel ordinary scene content: depth, occlusion, temporal antialiasing and post all come
/// out right by construction rather than by a special case. UNLIT by design.
///
/// An interactive panel takes the pointer through a camera ray: the ray finds the nearest
/// panel, the hit becomes a texture coordinate, and that becomes a pixel injected into the
/// panel's own root.
[SerializableComponent("ui.WorldPanel")]
[DisplayName("UI World Panel")]
[Category("UI")]
[Scriptable]
struct UIWorldPanelComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<UIDocument> Document = .(Guid());
	/// Optional. Unset takes the context's own theme.
	[Scriptable]
	public Ref<UITheme> Theme = .(Guid());
	/// How big the quad is in the world.
	[Scriptable]
	public Float2 SizeMeters = .(1.6f, 0.9f);
	/// The texture's density: the target is the size times this.
	[Scriptable]
	public float PixelsPerMeter = 200.0f;
	[Scriptable]
	public bool Interactive = true;
	[Scriptable]
	public bool Visible = true;

	// ---- runtime, never serialized ----

	public View Root = null;
	/// STANDALONE, never one of the tiers.
	public RootView RenderRoot = null;
	public UIDocument BuiltFrom = null;
	public StyleSheet ThemeSheet = null;
	public UITheme ThemeFrom = null;
	/// Subsystem owned.
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
		SerializeValue(ar, "sizeMeters", ref SizeMeters);
		SerializeValue(ar, "pixelsPerMeter", ref PixelsPerMeter);
		SerializeValue(ar, "interactive", ref Interactive);
		SerializeValue(ar, "visible", ref Visible);
	}
}
