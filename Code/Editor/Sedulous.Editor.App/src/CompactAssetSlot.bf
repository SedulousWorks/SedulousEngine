using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// An asset reference for a toolbar or a preview bar: a caption and the same slot every asset
/// row uses, at bar height, so a preview's skeleton, mesh or document picks, takes a dropped
/// asset of its type and clears exactly like an inspector row. Bind it through Editor.BindAsset.
class CompactAssetSlot : FlexLayout
{
	/// OWNED: the row whose slot this shows.
	public ResourceRefEditor Editor ~ delete _;

	public this(StringView caption, Span<StringView> acceptedTypes, StringView emptyText = "(none)")
	{
		Direction = .Horizontal;
		Spacing = 4.0f;
		let label = new Label(caption);
		label.FontSize.Value = 12.0f;
		var center = LayoutStyle();
		center.AlignSelf = .Center;
		AddView(label, center);
		Editor = new ResourceRefEditor(caption, emptyText, "", acceptedTypes);
		Editor.EmptyText.Set(emptyText);
	}

	/// Adds the slot; call after binding, which decides the slot's affordances.
	public void Build()
	{
		let slot = Editor.EditorView as AssetPickerSlot;
		if (slot != null)
			slot.SetFontSize(12.0f);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		AddView(Editor.EditorView, grow);
	}
}
