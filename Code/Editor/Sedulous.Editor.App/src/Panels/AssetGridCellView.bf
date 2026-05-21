namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;

/// View for a single cell in the asset browser grid/tile mode.
/// Shows: icon/thumbnail area (top) + editable name label (bottom).
class AssetGridCellView : ViewGroup
{
	private Drawable mIconOrThumb;
	private bool mIsFolder;
	private bool mIsRegistered;
	private bool mIsMissing;

	private EditableLabel mNameLabel;

	private ThumbnailService mThumbnails;
	private ThumbnailRequest mPendingRequest;

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

	public ~this()
	{
		CancelPending();
	}

	/// Wire the thumbnail service (called once by the adapter after CreateView).
	/// Non-owning - the EditorContext owns the service.
	public void SetThumbnailService(ThumbnailService service)
	{
		mThumbnails = service;
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

		// Start with the default icon (so rebind during scroll never shows a
		// blank cell, and so unsupported extensions stay on the icon).
		mIconOrThumb = EditorIcons.GetForExtension(item.Extension, item.IsFolder);

		// Cancel any in-flight request from the previous bind. Cells get
		// recycled freely during scroll - if the previous request resolved
		// after rebind, the callback would write a stale thumbnail.
		CancelPending();

		// Ask the service for a thumbnail. Returns null when there's an
		// immediate cache hit (callback fires synchronously) or when no
		// generator is registered. Holding a non-null handle means the
		// request is queued; we must cancel it on rebind / destruction.
		if (mThumbnails != null && !item.IsFolder && item.RegistryId != .())
		{
			let uri = scope String();
			uri.AppendF("{}://{}", item.Scheme, item.RelativePath);

			mPendingRequest = mThumbnails.Request(
				item.RegistryId, uri, item.Extension,
				/* w */ 96, /* h */ 96,
				new (drawable) => {
					// Clear the local handle - the service has deleted the
					// request by the time this callback fires, so Cancel on
					// it later would be use-after-free.
					mPendingRequest = null;
					if (drawable != null)
						mIconOrThumb = drawable;
				});
		}
	}

	private void CancelPending()
	{
		if (mPendingRequest != null && mThumbnails != null)
		{
			mThumbnails.Cancel(mPendingRequest);
			mPendingRequest = null;
		}
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

		// Draw the icon or thumbnail. SVG icons want a small inset so they
		// don't touch the rounded corners; bitmap thumbnails want to fill
		// the area for maximum size.
		if (mIconOrThumb != null)
		{
			if (mIconOrThumb is SVGDrawable)
			{
				let iconInset = 8.0f;
				let drawBounds = RectangleF(
					iconBounds.X + iconInset, iconBounds.Y + iconInset,
					iconBounds.Width - iconInset * 2, iconBounds.Height - iconInset * 2);
				mIconOrThumb.Draw(ctx, drawBounds, GetControlState());
			}
			else
			{
				mIconOrThumb.Draw(ctx, iconBounds, GetControlState());
			}
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
