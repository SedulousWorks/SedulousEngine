using System;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// One asset or group as the Assets panel draws it (Raptor's editor-gui spec, 5.2, layer 7): a
/// tile's picture (its thumbnail once there is one, its type's glyph till then, the star in a
/// corner, a stale or failed badge in another) over its name, or a list row's glyph, its name and
/// what it is on one baseline (what it is at the end), then its badge, its Always Export icon and
/// star, on every row, lit when so and greyed when not (a tile marks Always Export with a dot in
/// its picture's corner). Its class (`asset-tile`
/// or `asset-row`) says which, and a group's has `group` too; the sheet draws the rest.
class AssetCell : UIWidget
{
	/// What a cell shows; its texts borrowed for the call (Show copies them).
	public struct Shown
	{
		public StringView Glyph;
		/// Its category's tint ("cat-rendering"); empty: the plain icon colour.
		public StringView GlyphClass;
		public StringView Name;
		/// What it is: its type's display name, or a group's count.
		public StringView Kind;
		/// "Cooked", "Stale", "Failed"; empty: none.
		public StringView Badge;
		/// success, warning, danger.
		public StringView BadgeClass;
		public bool Favourite;
		/// An export takes it (a group: all it holds) whatever reaches it.
		public bool AlwaysExported;
		public bool Group;
		/// A row without its badge and Always Export columns: a picker's, which asks neither.
		public bool HidesStateColumns;
		/// Its thumbnail, a tile's in place of its glyph (Show keeps a reference); null: none yet.
		public Sedulous.GUI.Drawable Picture;
	}

	private bool mTile;
	// The tree's: the cell holds its parts and never lets one go. A tile's glyph, badge and star
	// are in its picture (mThumb); a row's are its own.
	private Sedulous.GUI.Panel mThumb = null;
	/// A row's name and kind.
	private Sedulous.GUI.Panel mText = null;
	private Sedulous.GUI.Image mGlyph;
	/// A tile's thumbnail; null on a row.
	private Sedulous.GUI.Image mPicture = null;
	private Sedulous.GUI.Label mName;
	private Sedulous.GUI.Label mKind;
	private Sedulous.GUI.Label mBadge;
	/// A row's Always Export icon; null on a tile.
	private Sedulous.GUI.Image mExportIcon = null;
	/// A tile's Always Export mark; null on a row.
	private Sedulous.GUI.Panel mExportMark = null;
	private Sedulous.GUI.Image mStar;
	/// The classes on the glyph and the badge now, taken off when they change.
	private String mGlyphClass = new .() ~ delete _;
	private String mBadgeClass = new .() ~ delete _;

	public this(bool tile)
	{
		mTile = tile;
		AddClass(tile ? "asset-tile" : "asset-row");
		Node glyphHolder = this;
		if (tile)
		{
			mThumb = Part<Sedulous.GUI.Panel>(this, "asset-thumb");
			glyphHolder = mThumb;
		}
		Node marks = tile ? (Node)mThumb : this;
		mGlyph = Part<Sedulous.GUI.Image>(glyphHolder, tile ? "asset-glyph" : "row-icon");
		if (tile)
		{
			mPicture = Part<Sedulous.GUI.Image>(mThumb, "asset-picture");
			mPicture.Displayed = false;
		}
		// A row's name and kind share a baseline, the kind at the end, right-aligned (each row's
		// ends in the same place, its badge and star in columns after it).
		Node textHolder = this;
		if (!tile)
		{
			mText = Part<Sedulous.GUI.Panel>(this, "asset-row-text");
			textHolder = mText;
		}
		mName = Part<Sedulous.GUI.Label>(textHolder, tile ? "asset-name" : "row-name");
		mKind = Part<Sedulous.GUI.Label>(textHolder, "row-kind");
		mKind.Displayed = !tile; // a tile says what it is in its tooltip
		mBadge = Part<Sedulous.GUI.Label>(marks, "badge");
		// Always Export: a mark in a tile's corner; a row's icon in a column of its own, lit when it
		// is so, greyed when not, as its star is (every row shows both, so each column lines up).
		if (tile)
		{
			mExportMark = Part<Sedulous.GUI.Panel>(mThumb, "export-mark");
			mExportMark.Tooltip = "Always exported";
			mExportMark.HitTestVisible = true; // its tooltip
		}
		else
		{
			mExportIcon = Part<Sedulous.GUI.Image>(this, "badge-icon");
			mExportIcon.AddClass("always-export"); // not `export`: the export dialog's class
			mExportIcon.Source = "Editor/Icons/export.svg";
			mExportIcon.HitTestVisible = true; // its tooltip
		}
		mStar = Part<Sedulous.GUI.Image>(marks, "badge-icon");
		mStar.AddClass("star");
		mStar.Source = "Editor/Icons/star.svg";
		mStar.Tooltip = "Favourite";
		if (!tile)
			mStar.HitTestVisible = true; // its tooltip
	}

	public void Show(Shown shown)
	{
		SwapClass(mGlyph, mGlyphClass, shown.GlyphClass);
		mGlyph.Source = shown.Glyph;
		// A tile shows the asset's picture once there is one, its type's glyph till then.
		let pictured = (mPicture != null) && (shown.Picture != null);
		if (mPicture != null)
		{
			if (mPicture.Drawable !== shown.Picture)
				mPicture.SetDrawable(shown.Picture);
			mPicture.Displayed = pictured;
		}
		mGlyph.Displayed = !pictured;
		mName.Text = shown.Name;
		mKind.Text = shown.Kind;
		SwapClass(mBadge, mBadgeClass, shown.BadgeClass);
		mBadge.Text = shown.Badge;
		// A tile marks only what needs a look (stale, failed); a row says each state, its badge
		// keeping its column when it has none, its Always Export and star lit or greyed.
		if (mTile)
		{
			mBadge.Displayed = !shown.Badge.IsEmpty && (shown.BadgeClass != "success");
			mStar.Displayed = shown.Favourite;
			mExportMark.Displayed = shown.AlwaysExported;
		}
		else
		{
			mBadge.Visible = !shown.Badge.IsEmpty;
			mBadge.Displayed = !shown.HidesStateColumns;
			mExportIcon.Displayed = !shown.HidesStateColumns;
			Lit(mExportIcon, shown.AlwaysExported);
			mExportIcon.Tooltip = shown.AlwaysExported ? "Always exported" : "Exported when something it ships uses it";
			Lit(mStar, shown.Favourite);
			mStar.Tooltip = shown.Favourite ? "Favourite" : "Not a favourite";
		}
		if (shown.Group)
			AddClass("group");
		else
			RemoveClass("group");
		if (!mTile)
			Tooltip = "";
		else if (shown.Kind.IsEmpty)
			Tooltip = shown.Name; // a group: its folder says what it is
		else
			Tooltip = scope String()..AppendF("{} ({})", shown.Name, shown.Kind);
	}

	public StringView Name => mName.Text;
	public StringView Kind => mKind.Text;
	public StringView Glyph => mGlyph.Source;
	/// The class tinting the glyph now; empty: none.
	public StringView GlyphClass => mGlyphClass;
	/// The badge's text, shown or not (ShowsBadge).
	public StringView Badge => mBadge.Text;
	public StringView BadgeClass => mBadgeClass;
	public bool ShowsBadge => mBadge.Displayed && mBadge.Visible;
	/// A tile's star shows; a row's is lit.
	public bool ShowsStar => mTile ? mStar.Displayed : mStar.HasClass("on");
	/// Marked always exported: a tile's corner mark shown, a row's icon lit.
	public bool ShowsAlwaysExport => mTile ? mExportMark.Displayed : mExportIcon.HasClass("on");
	/// A tile's Always Export mark, a row's icon: the part that shows it.
	public UIWidget AlwaysExportPart => mTile ? (UIWidget)mExportMark : mExportIcon;
	public bool IsTile => mTile;
	/// A tile showing its thumbnail; a row never does.
	public bool ShowsPicture => (mPicture != null) && mPicture.Displayed && (mPicture.Drawable != null);
	/// Its type's glyph shown: a row's always, a tile's until its thumbnail.
	public bool ShowsGlyph => mGlyph.Displayed;
	public Sedulous.GUI.Label NameLabel => mName;
	public Sedulous.GUI.Label KindLabel => mKind;

	/// A part of class `cls` in `holder`: the tree takes the pointer, a press on it the cell's.
	private static T Part<T>(Node holder, StringView cls) where T : UIWidget, new
	{
		let part = new T();
		part.AddClass(cls);
		part.HitTestVisible = false;
		holder.AddChild(part);
		part.ReleaseRef(); // the tree's reference keeps it
		return part;
	}

	/// `widget`'s class `now` (empty: none) in place of the one it had, `held`, which becomes it.
	private static void SwapClass(UIWidget widget, String held, StringView now)
	{
		if (!held.IsEmpty)
			widget.RemoveClass(held);
		held.Set(now);
		if (!held.IsEmpty)
			widget.AddClass(held);
	}

	private static void Lit(Sedulous.GUI.Image icon, bool on)
	{
		if (on)
			icon.AddClass("on");
		else
			icon.RemoveClass("on");
	}
}
