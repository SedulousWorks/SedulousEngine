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
/// untyped field, AssetPickerSlot.cEntity for an entity reference (a hierarchy row drops on it).
/// BindAsset and BindEntity wire every verb to one assignment, so a pick and a drop are the same
/// write.
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
	/// A bound row's value state comes from its id, not its text.
	private bool mBoundHasValue = false;

	/// What a bound row shows for the nil id: "(none)", or what nil means for the field (the
	/// material page's preview mesh shows its primitive shape).
	public String EmptyText = new .("(none)") ~ delete _;

	public this(StringView name, StringView valueText, StringView category, Span<StringView> acceptedTypes)
		: base(name, category)
	{
		mValueText.Set(valueText);
		for (let t in acceptedTypes)
			mAcceptedTypes.Add(new String(t));
		if (!acceptedTypes.IsEmpty && (acceptedTypes[0] != AssetPickerSlot.cAnyAsset) && (acceptedTypes[0] != AssetPickerSlot.cEntity))
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
	/// `current` and `assign` are CONSUMED. The row shows `current` from then on (Refresh), and
	/// refreshes after every assignment, so `assign` must not destroy this row synchronously: a
	/// write that rebuilds its grid defers the rebuild, as every grid here does.
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

	/// Wires an ENTITY reference the same way: `pick` opens the scene's entity picker (the
	/// caller's, which assigns through AssignValue), a hierarchy row dropped on the slot is
	/// assigned, clear assigns the nil id, and `nameFor` names the entity. Build the row with
	/// AssetPickerSlot.cEntity as its accepted type. All four are CONSUMED; the same contract
	/// on `assign` as BindAsset.
	public void BindEntity(delegate Guid() current, delegate void(Guid id) assign,
		delegate void(Guid id, String outName) nameFor, delegate void() pick)
	{
		mContext = null;
		delete OnPick;
		delete OnAssignDropped;
		delete OnClear;
		delete OnEdit;
		delete OnReveal;
		delete OnRejectedDrop;
		delete mCurrent;
		delete mAssign;
		delete mNameFor;
		OnEdit = null;
		OnReveal = null;
		OnRejectedDrop = null;
		mCurrent = current;
		mAssign = assign;
		mNameFor = nameFor;
		OnPick = pick;
		OnAssignDropped = new [=this](id) => { Assign(id); };
		OnClear = new [=this]() => { Assign(.()); };
		Refresh();
	}

	/// Assigns through the bound write, as a pick would: for a caller's own picker.
	public void AssignValue(Guid id) => Assign(id);

	/// Re-reads the bound reference: its name, and an asset's thumbnail when the context has
	/// one.
	public void Refresh()
	{
		if ((mCurrent == null) || ((mContext == null) && (mNameFor == null)))
			return;
		let id = mCurrent();
		mBoundHasValue = !id.IsNil;
		if (id.IsNil)
			SetValueText(EmptyText);
		else if (mNameFor != null)
			SetValueText(mNameFor(id, .. scope .()));
		else
			SetValueText(mContext.AssetNameFor(id, .. scope .()));
		if (mSlot != null)
			mSlot.SetValue(mValueText, HasValue);
		if (mContext != null)
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
	/// Set by BindEntity: names what the id refers to.
	private delegate void(Guid id, String outName) mNameFor ~ delete _;

	private void Assign(Guid id)
	{
		if (mAssign == null)
			return;
		mAssign(id);
		Refresh();
	}

	/// A bound row has a value when its id is set (a "(missing)" one can still be cleared); an
	/// unbound row reads its text.
	private bool HasValue => (mCurrent != null) ? mBoundHasValue : (mValueText != "(none)");
}
