using System;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// One asset or group as the Assets panel draws it (Raptor's editor-gui spec, 5.2, layer 7): a
/// tile's picture (its glyph, the star in a corner, a stale or failed badge in another) over its
/// name, or a list row's glyph, its name and what it is on one baseline (what it is at the end),
/// then its badge and star. Its class (`asset-tile` or `asset-row`) says which, and a group's has
/// `group` too; the sheet draws the rest.
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
	/// A row's name and kind.
	private Sedulous.GUI.Panel mText = null;
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
		// A tile marks only what needs a look (stale, failed); a row says each state, its badge
		// and star keeping their columns when it has none.
		if (mTile)
		{
			mBadge.Displayed = !shown.Badge.IsEmpty && (shown.BadgeClass != "success");
			mStar.Displayed = shown.Favourite;
		}
		else
		{
			mBadge.Visible = !shown.Badge.IsEmpty;
			mStar.Visible = shown.Favourite;
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
	public bool ShowsStar => mStar.Displayed && mStar.Visible;
	public bool IsTile => mTile;
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
}
