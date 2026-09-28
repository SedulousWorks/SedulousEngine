using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A property row over an AssetPickerSlot: the referenced asset's name, its thumbnail, and
/// the pick, edit, clear, reveal and drop verbs.
///
/// The accepted asset types are a CONSTRUCTOR argument, so a row that names an asset cannot be
/// built without being a drop target for that asset: AssetPickerSlot.cAnyAsset for a genuinely
/// untyped field, and no types at all only for a row that is not an asset (an entity reference).
/// BindAsset wires every verb to one assignment, so a pick and a drop are the same write.
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
	/// Set by BindAsset: the context names assets and supplies the thumbnails.
	private EditorContext mContext = null;

	public this(StringView name, StringView valueText, StringView category, Span<StringView> acceptedTypes)
		: base(name, category)
	{
		mValueText.Set(valueText);
		for (let t in acceptedTypes)
			mAcceptedTypes.Add(new String(t));
		if (!acceptedTypes.IsEmpty && (acceptedTypes[0] != AssetPickerSlot.cAnyAsset))
			mPreviewIcon = EditorIcons.ForAssetType(acceptedTypes[0]);
	}

	public StringView ValueText => mValueText;
	public Span<String> AcceptedTypes => mAcceptedTypes;
	/// Null until the row is shown.
	public AssetPickerSlot Slot => mSlot;

	/// Wires pick, drop, clear, edit and reveal to one assignment through `context`:
	/// - pick opens the asset picker filtered by the accepted types, and its choice is assigned;
	/// - a drop of an accepted type is assigned, the same write; a refused one is reported;
	/// - clear assigns the nil id;
	/// - edit and reveal open and show the asset `current` names.
	/// `current` and `assign` are CONSUMED. The row shows `current` from then on (Refresh).
	public void BindAsset(EditorContext context, delegate Guid() current, delegate void(Guid id) assign)
	{
		mContext = context;
		delete OnPick;
		delete OnAssignDropped;
		delete OnClear;
		delete OnEdit;
		delete OnReveal;
		delete OnRejectedDrop;
		delete mCurrent;
		delete mAssign;
		mCurrent = current;
		mAssign = assign;
		OnPick = new [=this]() =>
		{
			let ui = (mSlot != null) ? mSlot.Context : null;
			if ((ui == null) || (mContext.Project == null))
				return;
			let names = scope List<StringView>();
			for (let t in mAcceptedTypes)
			{
				if (t != AssetPickerSlot.cAnyAsset)
					names.Add(t);
			}
			let dialog = new AssetPickerDialog(mContext, names);
			dialog.OnPicked = new [=this](picked) => { Assign(picked); };
			dialog.Show(ui);
		};
		OnAssignDropped = new [=this](id) => { Assign(id); };
		OnClear = new [=this]() => { Assign(.()); };
		OnEdit = new [=this]() =>
		{
			let id = mCurrent();
			if (!id.IsNil && (mContext.OpenAsset != null))
				mContext.OpenAsset(id);
		};
		OnReveal = new [=this]() =>
		{
			let id = mCurrent();
			if (!id.IsNil && (mContext.RevealAsset != null))
				mContext.RevealAsset(id);
		};
		OnRejectedDrop = new [=this](assetName, typeName) =>
		{
			let wanted = mAcceptedTypes.IsEmpty ? StringView("?") : StringView(mAcceptedTypes[0]);
			mContext.Notify(.Warning, scope $"{assetName} is a {typeName} - this field takes {wanted}");
		};
		Refresh();
	}

	/// Re-reads the bound asset: its name, and its thumbnail when the context has one.
	public void Refresh()
	{
		if ((mContext == null) || (mCurrent == null))
			return;
		let id = mCurrent();
		SetValueText(mContext.AssetNameFor(id, .. scope .()));
		SetPreviewThumbnail((!id.IsNil && (mContext.Thumbnails != null)) ? mContext.Thumbnails.Get(id) : null);
	}

	public void SetValueText(StringView text)
	{
		if (mValueText == text)
			return;
		mValueText.Set(text);
		if (mSlot != null)
			mSlot.SetValue(mValueText, HasValue);
	}

	public void SetPreviewIcon(SVGDrawable icon) => mPreviewIcon = icon;

	/// `thumbnail` is BORROWED; the slot retains its own reference.
	public void SetPreviewThumbnail(Drawable thumbnail)
	{
		if (mSlot == null)
			return;
		if (thumbnail != null)
			thumbnail.AddRef();
		mSlot.SetPreviewThumbnail(thumbnail);
	}

	public override void RefreshView() => Refresh();

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
		Refresh();
		return mSlot;
	}

	private delegate Guid() mCurrent ~ delete _;
	private delegate void(Guid id) mAssign ~ delete _;

	private void Assign(Guid id)
	{
		if (mAssign == null)
			return;
		mAssign(id);
		Refresh();
	}

	/// A "(missing)" reference still has a value: it can be cleared.
	private bool HasValue => mValueText != "(none)";
}
