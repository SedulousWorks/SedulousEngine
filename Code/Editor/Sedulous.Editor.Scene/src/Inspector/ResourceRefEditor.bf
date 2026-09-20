using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// A property row over an AssetPickerSlot: the referenced asset's name, its thumbnail, and
/// the pick, edit, clear, reveal and drop verbs, each wired by whoever builds the row.
class ResourceRefEditor : PropertyEditor
{
	public delegate void() OnPick ~ delete _;
	public delegate void() OnEdit ~ delete _;
	public delegate void() OnClear ~ delete _;
	public delegate void() OnReveal ~ delete _;
	public delegate void(Guid id) OnAssignDropped ~ delete _;
	public delegate void(StringView assetName, StringView typeName) OnRejectedDrop ~ delete _;

	private String mValueText = new .() ~ delete _;
	/// Borrowed, from EditorIcons.
	private SVGDrawable mPreviewIcon = null;
	private List<String> mAcceptedTypes = new .() ~ DeleteContainerAndItems!(_);
	private AssetPickerSlot mSlot = null;

	public this(StringView name, StringView valueText, StringView category) : base(name, category)
	{
		mValueText.Set(valueText);
	}

	public StringView ValueText => mValueText;

	public void SetValueText(StringView text)
	{
		if (mValueText == text)
			return;
		mValueText.Set(text);
		if (mSlot != null)
			mSlot.SetValue(mValueText, HasValue);
	}

	public void SetPreviewIcon(SVGDrawable icon) => mPreviewIcon = icon;

	public void SetAcceptedTypes(Span<StringView> types)
	{
		ClearAndDeleteItems(mAcceptedTypes);
		for (let t in types)
			mAcceptedTypes.Add(new String(t));
	}

	/// `thumbnail` is BORROWED; the slot retains its own reference.
	public void SetPreviewThumbnail(Drawable thumbnail)
	{
		if (mSlot == null)
			return;
		if (thumbnail != null)
			thumbnail.AddRef();
		mSlot.SetPreviewThumbnail(thumbnail);
	}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		mSlot = new AssetPickerSlot();
		if (OnPick != null)
			mSlot.OnPick = new [=this]() => { OnPick(); };
		if (OnEdit != null)
			mSlot.OnEdit = new [=this]() => { OnEdit(); };
		if (OnClear != null)
			mSlot.OnClear = new [=this]() => { OnClear(); };
		if (OnReveal != null)
			mSlot.OnReveal = new [=this]() => { OnReveal(); };
		if (OnAssignDropped != null)
			mSlot.OnAssignDropped = new [=this](id) => { OnAssignDropped(id); };
		if (OnRejectedDrop != null)
			mSlot.OnRejectedDrop = new [=this](assetName, typeName) => { OnRejectedDrop(assetName, typeName); };
		let types = scope List<StringView>();
		for (let t in mAcceptedTypes)
			types.Add(t);
		mSlot.SetAcceptedTypes(types);
		mSlot.SetPreviewIcon(mPreviewIcon);
		mSlot.SetValue(mValueText, HasValue);
		return mSlot;
	}

	private bool HasValue => mValueText != "(none)";
}
