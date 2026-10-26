using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// A GUI document over its entity, facing the view: a nameplate, a health bar.
///
/// Its trees live in a layer under the scene's canvases, each placed through the view's camera
/// as it draws (GuiWorldMath.PlaceBillboard): hung by its bottom centre on the projected point,
/// hidden behind the camera, scaled with distance when asked.
[SerializableComponent("gui.Billboard")]
[DisplayName("GUI Billboard")]
[Category("GUI")]
[Description("Shows a GUI document over the entity, such as a nameplate or a health bar.")]
struct GuiBillboardComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	public Ref<GuiDocument> Document = .(Guid());
	/// Over the game's sheets, for this billboard alone. Optional.
	public Ref<GuiStyleSheet> Sheet = .(Guid());
	public Float3 Offset = .(0.0f, 0.0f, 0.0f);
	public GuiBillboardOrientation Orientation = .Cylindrical;
	public GuiBillboardScale ScaleMode = .Fixed;
	/// Distance mode: the scale is this over the distance, within MinScale and MaxScale.
	public float ReferenceDistance = 10.0f;
	public float MinScale = 0.3f;
	public float MaxScale = 2.0f;
	public bool Visible = true;

	// ---- runtime, never serialized ----

	/// The tree built from the document. A HELD reference.
	public Node Root = null;
	/// What the tree was built from and the sheet applied, compared by reference (see
	/// GuiCanvasComponent.BuiltFrom). Borrowed.
	public GuiDocument BuiltFrom = null;
	public GuiStyleSheet SheetFrom = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Document.Bind(manager);
		Sheet.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "document", ref Document.Id);
		SerializeValue(ar, "sheet", ref Sheet.Id);
		SerializeValue(ar, "offset", ref Offset);

		ar.Key("orientation");
		SerializeEnum(ar, ref Orientation);

		ar.Key("scaleMode");
		SerializeEnum(ar, ref ScaleMode);

		SerializeValue(ar, "referenceDistance", ref ReferenceDistance);
		SerializeValue(ar, "minScale", ref MinScale);
		SerializeValue(ar, "maxScale", ref MaxScale);
		SerializeValue(ar, "visible", ref Visible);
	}
}
