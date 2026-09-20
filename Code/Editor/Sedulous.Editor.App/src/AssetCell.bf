using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A list-row or grid-tile container that overlays small status dots in its top-right
/// corner: proper visual badges, not name-colour tints. The dots draw in local space after
/// the children, so they sit on top of the icon in both list and grid, stacking right to
/// left in a fixed order, export outermost. Set per bind. Also the drag source for instance
/// rows: the input layer walks ancestors for AsDragSource on a left press, so a bound cell
/// starts a potential drag automatically.
class AssetCell : FlexLayout, IDragSource
{
	/// Green: an "Always Export" root.
	public bool ShowExportBadge = false;
	/// Gold: a pinned favourite.
	public bool ShowFavoriteBadge = false;

	/// Empty means not draggable, a group row.
	private Guid mDragId = .Empty;
	private String mDragTypeName = new .() ~ delete _;
	private String mDragName = new .() ~ delete _;

	/// The drag identity, bound per row by the adapters; instances only, groups do not drag.
	public void BindDragPayload(Guid id, StringView typeName, StringView displayName)
	{
		mDragId = id;
		mDragTypeName.Set(typeName);
		mDragName.Set(displayName);
	}

	public void ClearDragPayload() => mDragId = .Empty;

	public override IDragSource AsDragSource() => mDragId.IsSet ? this : null;

	public DragData CreateDragData() => mDragId.IsSet ? new AssetDragData(mDragId, mDragTypeName, mDragName) : null;
	/// The default themed ghost.
	public View CreateDragVisual(DragData data) => null;
	public void OnDragStarted(DragData data) {}
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled) {}

	public override void OnDraw(UIDrawContext ctx)
	{
		base.OnDraw(ctx); // the children: icon, name, meta
		float x = Width - 7.0f;
		if (ShowExportBadge)
		{
			ctx.VG.FillCircle(.(x, 7.0f), 3.0f, Color(80.0f / 255.0f, 180.0f / 255.0f, 80.0f / 255.0f, 1.0f));
			x -= 8.0f;
		}
		if (ShowFavoriteBadge)
		{
			ctx.VG.FillCircle(.(x, 7.0f), 3.0f, Color(242.0f / 255.0f, 204.0f / 255.0f, 89.0f / 255.0f, 1.0f));
			x -= 8.0f;
		}
	}
}
