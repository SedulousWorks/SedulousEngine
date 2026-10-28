using System;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// One asset or group as the Assets panel draws it (Raptor's editor-gui spec, 5.2, layer 7): a
/// tile's picture (its glyph, the star in a corner, a stale or failed badge in another) over its
/// name, or a list row's glyph, name, what it is, badge and star. Its class (`asset-tile` or
/// `asset-row`) says which, and a group's has `group` too; the sheet draws the rest.
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
		public bool Group;
	}

	private bool mTile;
	// The tree's: the cell holds its parts and never lets one go. A tile's glyph, badge and star
	// are in its picture (mThumb); a row's are its own.
	private Sedulous.GUI.Panel mThumb = null;
	private Sedulous.GUI.Image mGlyph;
	private Sedulous.GUI.Label mName;
	private Sedulous.GUI.Label mKind;
	private Sedulous.GUI.Label mBadge;
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
		mName = Part<Sedulous.GUI.Label>(this, tile ? "asset-name" : "row-name");
		mKind = Part<Sedulous.GUI.Label>(this, "row-kind");
		mKind.Displayed = !tile; // a tile says what it is in its tooltip
		mBadge = Part<Sedulous.GUI.Label>(marks, "badge");
		mStar = Part<Sedulous.GUI.Image>(marks, "badge-icon");
		mStar.AddClass("star");
		mStar.Source = "Editor/Icons/star.svg";
		mStar.Tooltip = "Favourite";
	}

	public void Show(Shown shown)
	{
		SwapClass(mGlyph, mGlyphClass, shown.GlyphClass);
		mGlyph.Source = shown.Glyph;
		mName.Text = shown.Name;
		mKind.Text = shown.Kind;
		SwapClass(mBadge, mBadgeClass, shown.BadgeClass);
		mBadge.Text = shown.Badge;
		// A tile marks only what needs a look (stale, failed); a row says each state.
		mBadge.Displayed = !shown.Badge.IsEmpty && (!mTile || (shown.BadgeClass != "success"));
		mStar.Displayed = shown.Favourite;
		if (shown.Group)
			AddClass("group");
		else
			RemoveClass("group");
		if (mTile)
			Tooltip = scope String()..AppendF("{} ({})", shown.Name, shown.Kind);
		else
			Tooltip = "";
	}

	public StringView Name => mName.Text;
	public StringView Kind => mKind.Text;
	public StringView Glyph => mGlyph.Source;
	/// The class tinting the glyph now; empty: none.
	public StringView GlyphClass => mGlyphClass;
	/// The badge's text, shown or not (ShowsBadge).
	public StringView Badge => mBadge.Text;
	public StringView BadgeClass => mBadgeClass;
	public bool ShowsBadge => mBadge.Displayed;
	public bool ShowsStar => mStar.Displayed;
	public bool IsTile => mTile;

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
}
