namespace Sedulous.Engine.UI;

using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.UI;

/// How a billboard interprets its `Offset` relative to the anchor entity.
public enum BillboardOrientation
{
	/// `Offset` is in the entity's local space (transformed through
	/// `entity.LocalToWorld`). Billboard position follows the entity's
	/// rotation. Useful when the billboard is conceptually attached to
	/// part of the entity (e.g., button on a character's arm).
	ScreenBillboard,

	/// `Offset` is in world space (Y stays world-up). Billboard position
	/// is a fixed world-relative offset from the entity regardless of
	/// entity rotation. The typical mode for nameplates / health bars
	/// above enemies.
	Cylindrical,
}

/// How a billboard's content scales with distance to camera.
public enum BillboardScale
{
	/// Content renders at native screen size, distance-independent.
	Fixed,

	/// Content scales inversely with camera distance. At
	/// `ReferenceDistance`, scale = 1; closer = larger, farther = smaller.
	/// Clamped to `[MinScale, MaxScale]`.
	Distance,
}

/// World-anchored screen-space UI component.
///
/// Entity-attached. The billboard's `Content` view subtree is added to
/// the per-scene `BillboardUIComponentManager`'s shared root and
/// positioned each frame at the projected screen point of the entity's
/// transform + `Offset`. No per-component texture or `VGRenderer`; the
/// manager draws every billboard in the scene through one shared
/// `VGRenderer` via Track 0's `IPipelineOverlay` hook.
///
/// See `Documentation/Roadmap/UI_BILLBOARD.md` for the design.
class BillboardUIComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.BeginObject("Offset");
		s.Float("X", ref Offset.X);
		s.Float("Y", ref Offset.Y);
		s.Float("Z", ref Offset.Z);
		s.EndObject();

		var orient = (int32)Orientation;
		s.Int32("Orientation", ref orient);
		Orientation = (BillboardOrientation)orient;

		var scaleMode = (int32)ScaleMode;
		s.Int32("ScaleMode", ref scaleMode);
		ScaleMode = (BillboardScale)scaleMode;

		s.Float("ReferenceDistance", ref ReferenceDistance);
		s.Float("MinScale", ref MinScale);
		s.Float("MaxScale", ref MaxScale);
	}

	// === Serialized properties ===

	/// Offset from the anchor entity's position. Interpretation depends
	/// on `Orientation` (see enum).
	public Vector3 Offset;

	/// Orientation / anchor mode.
	public BillboardOrientation Orientation = .Cylindrical;

	/// Scaling mode.
	public BillboardScale ScaleMode = .Fixed;

	/// Reference distance for `BillboardScale.Distance` (world units).
	public float ReferenceDistance = 5.0f;

	/// Clamp bounds for `BillboardScale.Distance`.
	public float MinScale = 0.25f;
	public float MaxScale = 4.0f;

	// === Runtime state ===

	/// The view subtree this billboard renders. **Owned by the component**
	/// (deleted when the component is destroyed via the destructor below).
	/// Added as a child of the manager's shared root when the manager
	/// first sees it in `Render`; removed by `OnComponentDestroyed` before
	/// the component is freed.
	public View Content;

	public ~this()
	{
		if (Content != null)
		{
			// Detach from any parent before delete (manager may have torn
			// down its layer first depending on shutdown order).
			if (let group = Content.Parent as ViewGroup)
				group.RemoveView(Content, false);
			delete Content;
			Content = null;
		}
	}
}
