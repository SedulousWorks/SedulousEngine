namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// View for a single cell in the asset browser grid/tile mode.
/// Shows: icon/thumbnail area (top) + editable name label (bottom).
class AssetGridCellView : ViewGroup
{
	private String mIconText = new .() ~ delete _;
	private Color mIconColor = .(140, 145, 165, 255);
	private bool mIsFolder;
	private bool mIsRegistered;
	private bool mIsMissing;

	private EditableLabel mNameLabel;

	/// The editable name label - used by the adapter to trigger rename.
	public EditableLabel NameLabel => mNameLabel;

	public this()
	{
		ClipsContent = true;

		mNameLabel = new EditableLabel();
		mNameLabel.FontSize = 10;
		mNameLabel.HAlign = .Center;
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
		mIsMissing = item.IsRegistered && !item.IsFolder && item.AbsolutePath != null && !System.IO.File.Exists(item.AbsolutePath);

		// Set name label color
		if (mIsMissing)
			mNameLabel.TextColor = .(200, 80, 80, 255);
		else
			mNameLabel.TextColor = .(200, 205, 220, 255);

		if (item.IsFolder)
		{
			mIconText.Set("DIR");
			mIconColor = .(200, 180, 80, 255);
		}
		else
		{
			let icon = GetIconForExtension(item.Extension);
			mIconText.Set(icon);
			mIconColor = GetIconColor(item.Extension);
		}
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(80), hSpec.Resolve(96));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;
		let h = bottom - top;
		let nameHeight = 18.0f;
		let nameY = h - nameHeight;

		// Position name label at the bottom
		mNameLabel.Measure(.Exactly(w - 4), .Exactly(nameHeight));
		mNameLabel.Layout(2, nameY, w - 4, nameHeight);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let iconFont = ctx.FontService?.GetFont(14);

		// Thumbnail/icon area (top portion)
		let nameHeight = 18.0f;
		let iconAreaHeight = Height - nameHeight;
		let iconBounds = RectangleF(2, 2, Width - 4, iconAreaHeight - 4);

		// Background for icon area
		let bgColor = ctx.Theme?.GetColor("GridCell.Background", .(35, 38, 48, 255)) ?? .(35, 38, 48, 255);
		ctx.VG.FillRoundedRect(iconBounds, 4, bgColor);

		// Icon text centered in area
		if (iconFont != null && mIconText.Length > 0)
			ctx.VG.DrawText(mIconText, iconFont, iconBounds, .Center, .Middle, mIconColor);

		// Registry badge (small dot in top-right corner)
		if (mIsRegistered)
		{
			let badgeColor = Color(80, 180, 80, 255);
			ctx.VG.FillCircle(.(Width - 8, 8), 3, badgeColor);
		}

		// Draw the name label (child view)
		DrawChildren(ctx);
	}

	private StringView GetIconForExtension(StringView ext)
	{
		if (ext == ".mesh" || ext == ".staticmesh") return "MESH";
		if (ext == ".skinnedmesh") return "SKIN";
		if (ext == ".material") return "MAT";
		if (ext == ".texture") return "TEX";
		if (ext == ".skeleton") return "SKEL";
		if (ext == ".animation") return "ANIM";
		if (ext == ".scene") return "SCN";
		if (ext == ".png" || ext == ".jpg" || ext == ".hdr" || ext == ".tga") return "IMG";
		if (ext == ".gltf" || ext == ".glb" || ext == ".fbx" || ext == ".obj") return "3D";
		return "FILE";
	}

	private Color GetIconColor(StringView ext)
	{
		if (ext == ".mesh" || ext == ".staticmesh" || ext == ".skinnedmesh") return .(100, 180, 220, 255);
		if (ext == ".material") return .(220, 140, 60, 255);
		if (ext == ".texture" || ext == ".png" || ext == ".jpg" || ext == ".hdr") return .(140, 200, 100, 255);
		if (ext == ".skeleton" || ext == ".animation") return .(200, 120, 200, 255);
		if (ext == ".scene") return .(220, 200, 80, 255);
		if (ext == ".gltf" || ext == ".glb" || ext == ".fbx") return .(180, 180, 220, 255);
		return .(140, 145, 165, 255);
	}
}
