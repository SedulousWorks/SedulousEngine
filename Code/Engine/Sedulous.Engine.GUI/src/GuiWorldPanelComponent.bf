using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// A GUI document on a quad in the world, in its entity's plane: a sign, a terminal.
///
/// Drawn into a texture at a density of its own (GuiWorldMath.WorldPanelPixels), its entity's
/// sprite driven to show it (added when missing), so it sits in the scene with its depth; the
/// pointer reaches it by a ray through the scene's camera when it is interactive.
[SerializableComponent("gui.WorldPanel")]
[DisplayName("GUI World Panel")]
[Category("GUI")]
[Scriptable]
[Description("Shows a GUI document on a panel in the world, in the entity's plane, optionally taking the pointer.")]
struct GuiWorldPanelComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<GuiDocument> Document = .(Guid());
	/// Over the game's sheets, for this panel alone. Optional.
	[Scriptable]
	public Ref<GuiStyleSheet> Sheet = .(Guid());
	/// The quad's extent in the world.
	[Scriptable]
	public Float2 SizeMeters = .(1.6f, 0.9f);
	/// The texture's density.
	[Scriptable]
	public float PixelsPerMeter = 200.0f;
	[Scriptable]
	public bool Interactive = true;
	[Scriptable]
	public bool Visible = true;

	// ---- runtime, never serialized ----

	/// The tree built from the document. A HELD reference.
	public Node Root = null;
	/// Its own root, never in a scene's GUI. A HELD reference.
	public SceneRoot RenderRoot = null;
	/// What the tree was built from and the sheet applied, compared by reference (see
	/// GuiCanvasComponent.BuiltFrom). Borrowed.
	public GuiDocument BuiltFrom = null;
	public GuiStyleSheet SheetFrom = null;
	/// The subsystem's, and null until first drawn.
	public ITexture RenderTexture = null;
	public ITextureView RenderTextureView = null;

	public this() {}

	/// The tree built from the document, `Root()` to a script: a node held weakly, as a script
	/// holds every node, so the GUI's finders reach inside it, as in
	/// `GuiWorldPanelComponent::of(terminal).Root().Find("screen")`.
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
		SerializeValue(ar, "sizeMeters", ref SizeMeters);
		SerializeValue(ar, "pixelsPerMeter", ref PixelsPerMeter);
		SerializeValue(ar, "interactive", ref Interactive);
		SerializeValue(ar, "visible", ref Visible);
	}
}
