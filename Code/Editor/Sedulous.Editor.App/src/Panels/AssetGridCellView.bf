namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// View for a single cell in the asset browser grid/tile mode.
/// Shows: icon/thumbnail area (top) + name label (bottom).
class AssetGridCellView : View
{
	private String mName = new .() ~ delete _;
	private String mIconText = new .() ~ delete _;
	private Color mIconColor = .(140, 145, 165, 255);
	private bool mIsFolder;
	private bool mIsRegistered;
	private bool mIsMissing;

	public this()
	{
		ClipsContent = true;
	}

	public void Bind(AssetContentItem item)
	{
		mName.Set(item.Name);
		mIsFolder = item.IsFolder;
		mIsRegistered = item.IsRegistered;
		mIsMissing = item.IsRegistered && !item.IsFolder && item.AbsolutePath != null && !System.IO.File.Exists(item.AbsolutePath);

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

	public override void OnDraw(UIDrawContext ctx)
	{
		let font = ctx.FontService?.GetFont(10);
		if (font == null) return;

		let iconFont = ctx.FontService?.GetFont(14);

		// Thumbnail/icon area (top portion)
		let iconAreaHeight = Height - 20;
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

		// Name label (bottom portion) with ellipsis for long names
		let nameColor = mIsMissing ? Color(200, 80, 80, 255) : (ctx.Theme?.GetColor("Label.Foreground") ?? .(200, 205, 220, 255));
		let nameBounds = RectangleF(2, iconAreaHeight, Width - 4, 18);
		let nameW = font.Font.MeasureString(mName);
		if (nameW <= nameBounds.Width)
		{
			ctx.VG.DrawText(mName, font, nameBounds, .Center, .Middle, nameColor);
		}
		else
		{
			let ellipsisW = font.Font.MeasureString("...");
			let availW = nameBounds.Width - ellipsisW;
			let truncated = scope String();
			float w = 0;
			for (let c in mName.RawChars)
			{
				let charStr = scope String();
				charStr.Append(c);
				let charW = font.Font.MeasureString(charStr);
				if (w + charW > availW)
					break;
				truncated.Append(c);
				w += charW;
			}
			truncated.Append("...");
			ctx.VG.DrawText(truncated, font, nameBounds, .Center, .Middle, nameColor);
		}
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
