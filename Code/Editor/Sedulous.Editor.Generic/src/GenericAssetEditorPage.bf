using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Runtime.Client;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Generic;

/// The fallback property-form editor for every asset without a dedicated page, on the GUI from its
/// markup (Data/Editor/AssetForm.xml; Raptor's editor-gui spec, 5.4, layer 1). Registered against
/// Object, so the registry's nearest-base dispatch routes every bespoke page first and everything
/// else lands here instead of the hard "No editor registered" failure. The form is serialize-driven
/// (see AssetForm).
///
/// On the grid the fields are a property bag: each value a row named by its key made readable (the
/// key itself its tooltip), the fields inside an array a group under the outermost array's key,
/// folded until opened (a model manifest's thousand node fields cost nothing until then), a guid
/// one asset reference taking any asset, a blob its size, read only. An array's count is not a
/// row (the replay cannot resize one), nor the version envelope's entries. Every edit is one undo
/// step, a snapshot of the whole object; a change of shape (a branch of Serialize flipped) builds
/// the rows again, and an undo shows the values again, on the next Refresh, never inside the
/// grid's commit.
class GenericAssetEditorPage : UIEditorPage
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/AssetForm.xml";

	/// Borrowed.
	private EditorContext mContext;
	private AssetPageServices mServices ~ delete _;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed.
	private ISerializable mObject = null ~ delete _;
	private List<AssetFormField> mFields = new .() ~ DeleteContainerAndItems!(_);
	/// By field: its row's path in the bag (empty: it has no row).
	private List<String> mPaths = new .() ~ DeleteContainerAndItems!(_);
	/// One reference, the page's.
	private Node mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	/// The markup's: the tree holds it.
	private PropertyGrid mGrid = null;
	/// The grid's source; after the content, so the grid lets go of it first.
	private Sedulous.GUI.PropertyBag mBag = null ~ delete _;
	private PageActionBar mBar = null ~ delete _;
	private List<uint8> mUndoBaseline = new .() ~ delete _;
	/// The shape changed: the bag is built again on Refresh.
	private bool mRebuild = false;
	/// The values changed under the rows (an undo): shown again on Refresh.
	private bool mReshow = false;

	/// `services` it takes.
	public this(EditorContext context, AssetPageServices services, Instance instance)
	{
		mContext = context;
		mServices = services;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		mObject = instance.ReadObject();
		if (mObject == null)
			GlobalLog(.Error, "Editor: asset '{}' failed to read, page opens empty", mTitle);
		else
			AssetForm.Scan(mObject, mFields).IgnoreError();
		Snapshot(mUndoBaseline);

		mContent = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cMarkupPath) : null;
		if (mContent != null)
		{
			mBar = new PageActionBar(context.Actions, this);
			mBar.Bind(Find<ButtonBase>("form-save"), "file.save");
			mBar.Bind(Find<ButtonBase>("form-undo"), "edit.undo");
			mBar.Bind(Find<ButtonBase>("form-redo"), "edit.redo");
			mBar.Bind(Find<ButtonBase>("form-discard"), "page.discardChanges");
			mBar.Bind(Find<ButtonBase>("form-cook"), "build.cookPage");
			mBar.Bind(Find<ButtonBase>("form-rebuild"), "build.rebuildPage");
			if (let kind = Find<Sedulous.GUI.Label>("form-kind"))
			{
				// Its display name, as every page's; its type's name without one.
				if (mObject != null)
				{
					if (mObject.GetType().GetCustomAttribute<DisplayNameAttribute>() case .Ok(let named))
						kind.Text = named.Name;
					else
						kind.Text = mObject.GetType().GetName(.. scope .());
				}
			}
			if (let state = Find<Node>("form-state"))
				state.Displayed = mObject == null;
			mGrid = Find<PropertyGrid>("form-grid");
			if (mGrid != null)
			{
				mGrid.Displayed = mObject != null;
				if (mServices.Refs != null)
					ResourceRefEditor.Register(mGrid.Editors, mServices.Refs);
			}
			if (let search = Find<TextField>("form-search"))
				search.SetOnTextChanging(new [=this] (text) =>
					{
						if (mGrid != null)
							mGrid.Filter = text;
					});
		}
		BuildBag();
	}

	public ~this()
	{
		if (mGrid != null)
			mGrid.Source = null;
	}

	public override StringView Title => mTitle;
	public override Node Content => mContent;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		Refresh();
	}

	/// The bar as the actions are over the page, and the rows built again after a change of shape
	/// or shown again after an undo; once a frame.
	public void Refresh()
	{
		if (mBar != null)
			mBar.Sync();
		if (mRebuild)
			BuildBag();
		else if (mReshow)
			ShowValues();
		mRebuild = false;
		mReshow = false;
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mObject == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mObject);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved asset '{}'", mTitle);
		}
		return saved;
	}

	// === For tests ===

	public List<AssetFormField> Fields => mFields;
	/// The bag's path of field `index` (empty: it has no row).
	public StringView PathOf(int index) => ((index >= 0) && (index < mPaths.Count)) ? (StringView)mPaths[index] : default;
	public Sedulous.GUI.PropertyBag Bag => mBag;
	public PropertyGrid Grid => mGrid;
	/// The kit's bar: Save, Undo, Redo, Discard Changes, Cook and Rebuild, each an action over the page.
	public PageActionBar Bar => mBar;
	public bool LoadFailed => mObject == null;

	/// Writes `value` to the row at `path` as the grid commits an edit.
	public void Edit(StringView path, Sedulous.GUI.Variant value)
	{
		let commit = scope Sedulous.GUI.PropertyBag.Commit();
		commit.Path.Set(path);
		commit.Before.Add((mBag != null) ? mBag.GetValue(path, 0) : .());
		commit.After.Add(value.Copy());
		if (mBag != null)
			mBag.SetValue(path, 0, value); // as the grid's commit leaves it
		Committed(commit);
	}

	/// Restores a snapshot, the undo and redo path; a no-op when the object already matches.
	public void ApplyBlob(List<uint8> blob)
	{
		if (mObject == null)
			return;
		let current = scope List<uint8>();
		Snapshot(current);
		if ((current.Count == blob.Count) && (Internal.MemCmp(current.Ptr, blob.Ptr, blob.Count) == 0))
			return;
		ObjectSnapshot.Restore(mObject, blob);
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		let rescanned = scope List<AssetFormField>();
		AssetForm.Scan(mObject, rescanned).IgnoreError();
		if (AssetForm.ShapeEquals(mFields, rescanned))
			mReshow = true;
		else
			mRebuild = true;
		ClearAndDeleteItems(mFields);
		mFields.AddRange(rescanned);
		rescanned.Clear();
		MarkDirty();
	}

	/// The content's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	/// The bag made anew from the fields, given to the grid.
	private void BuildBag()
	{
		let bag = new Sedulous.GUI.PropertyBag();
		ClearAndDeleteItems(mPaths);
		// An array's fields under one group, by the outermost array's key, in the order the arrays
		// come; a group's path is its ordinal, so what is open survives a rebuild of the same shape.
		let groups = scope List<StringView>();
		let shown = scope String();
		for (int i < mFields.Count)
		{
			let field = mFields[i];
			if ((field.Kind == .ArrayCount) || (field.Category == AssetFormField.cVersionsKey))
			{
				mPaths.Add(new String()); // structural, not authorable
				continue;
			}
			let parent = scope String();
			if (!field.Category.IsEmpty)
			{
				var group = groups.Count;
				for (int g < groups.Count)
				{
					if (groups[g] == field.Category)
						group = g;
				}
				parent.AppendF("g{}", group);
				if (group == groups.Count)
				{
					groups.Add(field.Category);
					let info = bag.Add(parent, .Group);
					shown.Clear();
					ReadablePropertyName(field.Category, shown);
					info.DisplayName.Set(shown);
					info.Description.Set(field.Category);
				}
			}
			let path = new String();
			JoinPropertyPath(parent, scope String()..AppendF("f{}", i), path);
			var value = ValueOf(field);
			defer value.Dispose();
			let info = bag.Add(path, KindOf(field), value);
			shown.Clear();
			ReadablePropertyName(field.Label, shown);
			info.DisplayName.Set(shown);
			info.Description.Set(field.Label); // the key as it is saved
			info.ReadOnly = !field.Editable;
			if (info.Kind == .Integer)
				IntegerRange(field.ScalarKind, info);
			mPaths.Add(path);
		}
		bag.SetOnCommit(new [=this] (commit) => { Committed(commit); });
		if (mGrid != null)
			mGrid.Source = bag;
		delete mBag; // after the grid let go of it
		mBag = bag;
	}

	/// Each row's value from the fields, where it differs.
	private void ShowValues()
	{
		if (mBag == null)
			return;
		for (int i < Math.Min(mFields.Count, mPaths.Count))
		{
			if (mPaths[i].IsEmpty)
				continue;
			var value = ValueOf(mFields[i]);
			defer value.Dispose();
			var shown = mBag.GetValue(mPaths[i], 0);
			defer shown.Dispose();
			if ((shown.Kind != value.Kind) || (shown.Compare(value) != 0))
				mBag.SetValue(mPaths[i], 0, value);
		}
	}

	private void Committed(Sedulous.GUI.PropertyBag.Commit commit)
	{
		var index = mPaths.Count;
		for (int i < mPaths.Count)
		{
			if (mPaths[i] == commit.Path)
				index = i;
		}
		if ((index >= mFields.Count) || commit.After.IsEmpty)
			return;
		let value = commit.After[0];
		let patch = scope AssetFormField();
		mFields[index].CopyTo(patch);
		switch (patch.Kind)
		{
		case .Text:
			patch.TextValue.Set(value.AsString);
		case .Guid:
			var parsed = Guid.Empty;
			if (!value.AsString.IsEmpty)
			{
				if (Guid.Parse(value.AsString) case .Ok(let id))
					parsed = id;
				else
				{
					mReshow = true; // not a guid: the row shows the old one again
					return;
				}
			}
			patch.GuidValue = parsed;
		case .Scalar:
			if (patch.ScalarKind == .Bool)
				patch.IntValue = value.AsBool ? 1 : 0;
			else if ((patch.ScalarKind == .Float32) || (patch.ScalarKind == .Float64))
				patch.FloatValue = value.AsFloat;
			else
				patch.IntValue = value.AsInt;
		default:
			return; // blobs and counts are not edited
		}
		ApplyFieldEdit(index, patch);
	}

	/// Patches one field with undo; re-scans, and builds the rows again only on a change of shape
	/// (on the next Refresh, never inside the grid's commit).
	private void ApplyFieldEdit(int index, AssetFormField newValue)
	{
		if (mObject == null)
			return;
		AssetForm.ApplyField(mObject, mFields, index, newValue).IgnoreError();

		// The undo step, coalesced per field label and ordinal.
		let key = scope $"{newValue.Label}#{index}";
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditGenericCommand(this, key, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();

		// The re-scan: a conditional-branch shape change builds the rows again; a same-shape patch
		// shows the values again (the replay may have narrowed one, a uint8 past 255).
		let rescanned = scope List<AssetFormField>();
		AssetForm.Scan(mObject, rescanned).IgnoreError();
		let sameShape = AssetForm.ShapeEquals(mFields, rescanned);
		ClearAndDeleteItems(mFields);
		mFields.AddRange(rescanned);
		rescanned.Clear();
		if (sameShape)
			mReshow = true;
		else
			mRebuild = true;
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mObject != null)
			ObjectSnapshot.Take(mObject, outBlob);
	}

	/// A field's value as its row shows it; the caller disposes it.
	private static Sedulous.GUI.Variant ValueOf(AssetFormField field)
	{
		switch (field.Kind)
		{
		case .Text: return Sedulous.GUI.Variant(field.TextValue).Copy();
		case .Guid: return Sedulous.GUI.Variant(field.GuidValue.ToString(.. scope String(), 'D')).Copy();
		case .Blob: return Sedulous.GUI.Variant(scope String()..AppendF("{} bytes", field.BlobValue.Count)).Copy();
		default:
		}
		if (field.ScalarKind == .Bool)
			return .(field.IntValue != 0);
		if ((field.ScalarKind == .Float32) || (field.ScalarKind == .Float64))
			return .(field.FloatValue);
		return .(field.IntValue);
	}

	private static PropertyKind KindOf(AssetFormField field)
	{
		switch (field.Kind)
		{
		case .Text, .Blob: return .String;
		case .Guid: return .Reference;
		default:
		}
		if (field.ScalarKind == .Bool)
			return .Bool;
		if ((field.ScalarKind == .Float32) || (field.ScalarKind == .Float64))
			return .Float;
		return .Integer;
	}

	/// An integer row's range: its scalar's.
	private static void IntegerRange(ScalarKind kind, PropertyInfo info)
	{
		info.HasRange = true;
		switch (kind)
		{
		case .Int8: info.Min = -128.0; info.Max = 127.0;
		case .UInt8: info.Min = 0.0; info.Max = 255.0;
		case .Int16: info.Min = -32768.0; info.Max = 32767.0;
		case .UInt16: info.Min = 0.0; info.Max = 65535.0;
		case .Int32: info.Min = -2147483648.0; info.Max = 2147483647.0;
		case .UInt32: info.Min = 0.0; info.Max = 4294967295.0;
		case .UInt64: info.Min = 0.0; info.Max = 9007199254740992.0;
		default: info.Min = -9007199254740992.0; info.Max = 9007199254740992.0;
		}
	}
}
