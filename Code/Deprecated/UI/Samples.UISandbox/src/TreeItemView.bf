using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A tree row that draws its own text, indented to clear the expander column.
///
/// It takes the indent from the tree that owns it rather than writing a pixel constant,
/// which drifts the moment the tree's indent width changes and puts the chevron through
/// the text.
class TreeItemView : View
{
	private String mText = new .() ~ delete _;
	private int32 mDepth = 0;
	/// BORROWED: the tree outlives its rows.
	private TreeView mTree = null;

	public void Set(TreeView tree, StringView text, int32 depth)
	{
		mTree = tree;
		mText.Set(text);
		mDepth = depth;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mText.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);

		let font = ctx.FontService.GetFont(family, 14.0f);
		if (font == null)
			return;

		let textX = (mTree != null) ? mTree.ContentInset(mDepth) : ((float)(mDepth + 1) * 20.0f);
		let color = ResolveStyleColor(.TextColor, Color.Rgb(220, 220, 230));
		ctx.VG.DrawText(mText, font, Rectangle(textX, 0, Width - textX, Height),
			TextAlignment.Left, VerticalAlignment.Middle, color);
	}
}
