namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// View for a single cell in the asset browser grid/tile mode.
/// Shows: icon/thumbnail area (top) + editable name label (bottom).
class AssetGridCellView : ViewGroup
{
	private SVGDrawable mIconDrawable;
	private bool mIsFolder;
	private bool mIsRegistered;
	private bool mIsMissing;

	private EditableLabel mNameLabel;

	/// The editable name label - used by the adapter to trigger rename.
	public EditableLabel NameLabel => mNameLabel;

	public this()
	{
		StyleId = new String("gridcell");
		ClipsContent = true;

		mNameLabel = new EditableLabel();
		mNameLabel.FontSize = 10;
		mNameLabel.HAlign = .Center;
		mNameLabel.Ellipsis = true;
		mNameLabel.DoubleClickToEdit = false;
		mNameLabel.SlowClickToEdit = false; // Rename via context menu or F2 only in grid
		mNameLabel.ValidateRename = new (name) => {
			for (let c in name.RawChars)
			{
				if (c == '/' || c == '\\' || c == ':' || c == '*' ||
					c == '?' || c == '"' || c == '<' || c == '>' || c == '|')
					return false;
			}
			return true;
		};
		AddView(mNameLabel);
	}

	public void Bind(AssetContentItem item)
	{
		mNameLabel.SetText(item.Name);
		mIsFolder = item.IsFolder;
		mIsRegistered = item.IsRegistered;
		mIsMissing = item.IsMissing;

		if (mIsMissing)
			mNameLabel.TextColor = .(200, 80, 80, 255);
		else
			mNameLabel.TextColor = .(200, 205, 220, 255);

		// Per-extension SVG icon. EditorIcons returns a non-owning reference
		// to a shared drawable, so rebinding during grid cell recycling is
		// just a pointer copy (no per-bind allocation).
		mIconDrawable = EditorIcons.GetForExtension(item.Extension, item.IsFolder);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(80), constraints.ConstrainHeight(96));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let nameHeight = 18.0f;
		let nameY = height - nameHeight;

		// Position name label at the bottom
		mNameLabel.Measure(BoxConstraints.Tight(width - 4, nameHeight));
		mNameLabel.Layout(2, nameY, width - 4, nameHeight);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Thumbnail/icon area (top portion)
		let nameHeight = 18.0f;
		let iconAreaHeight = Height - nameHeight;
		let iconBounds = RectangleF(2, 2, Width - 4, iconAreaHeight - 4);

		// Background for icon area
		let bgColor = ResolveStyleColor(.Background, .(35, 38, 48, 255));
		ctx.VG.FillRoundedRect(iconBounds, 4, bgColor);

		// SVG icon centered in the icon area. The drawable is owned by
		// EditorIcons; we just paint into our bounds.
		if (mIconDrawable != null)
		{
			// Inset slightly so the icon doesn't touch the rounded corners.
			let iconInset = 8.0f;
			let drawBounds = RectangleF(
				iconBounds.X + iconInset, iconBounds.Y + iconInset,
				iconBounds.Width - iconInset * 2, iconBounds.Height - iconInset * 2);
			mIconDrawable.Draw(ctx, drawBounds, GetControlState());
		}

		// Registry badge (small dot in top-right corner)
		if (mIsRegistered)
		{
			let badgeColor = Color(80, 180, 80, 255);
			ctx.VG.FillCircle(.(Width - 8, 8), 3, badgeColor);
		}

		// Draw the name label (child view)
		DrawChildren(ctx);
	}
}
