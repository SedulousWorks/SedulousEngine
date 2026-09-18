using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// A nameplate or a health bar over an entity.
///
/// ONE shared layer under the canvases and ONE batch: a world position becomes clip space,
/// then screen pixels. An anchor BEHIND the camera parks off screen rather than being pulled
/// out of the tree, so nothing churns as an entity turns away.
[SerializableComponent("ui.Billboard")]
[DisplayName("UI Billboard")]
[Category("UI")]
[Scriptable]
struct UIBillboardComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<UIDocument> Document = .(Guid());
	[Scriptable]
	public Float3 Offset = .(0.0f, 0.0f, 0.0f);
	[Scriptable]
	public BillboardOrientation Orientation = .Cylindrical;
	[Scriptable]
	public BillboardScale ScaleMode = .Fixed;
	/// Distance mode: the scale is the reference over the distance, clamped.
	[Scriptable]
	public float ReferenceDistance = 10.0f;
	[Scriptable]
	public float MinScale = 0.3f;
	[Scriptable]
	public float MaxScale = 2.0f;
	[Scriptable]
	public bool Visible = true;

	// ---- runtime, never serialized ----

	public View Root = null;
	public UIDocument BuiltFrom = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Document.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "document", ref Document.Id);
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
