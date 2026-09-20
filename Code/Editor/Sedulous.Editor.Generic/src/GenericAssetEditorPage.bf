using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Generic;

/// The fallback property-form editor for every asset without a dedicated page. Registered
/// against Object, so the registry's nearest-base dispatch routes every bespoke page first and
/// everything else lands here instead of the hard "No editor registered" failure. The form is
/// serialize-driven (see AssetForm); each array's rows group under a default-collapsed
/// expander, and a shape change after a patch rebuilds the grid, deferred.
class GenericAssetEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed.
	private ISerializable mObject = null ~ delete _;
	private List<AssetFormField> mFields = new .() ~ DeleteContainerAndItems!(_);
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	// Borrowed: the content owns them.
	private Label mInfo = null;
	private PropertyGrid mGrid = null;
	private List<uint8> mUndoBaseline = new .() ~ delete _;

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		mObject = instance.ReadObject();
		if (mObject == null)
			GlobalLog(.Error, "Editor: asset '{}' failed to read, page opens empty", mTitle);
		else
			AssetForm.Scan(mObject, mFields).IgnoreError();
		Snapshot(mUndoBaseline);

		mInfo = new Label("");
		mInfo.FontSize.Value = 12.0f;
		if (mObject != null)
			mInfo.SetText(scope $"{mObject.GetType().GetFullName(.. scope .())}  (generic editor)");

		mGrid = new PropertyGrid();
		BuildGrid();

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6.0f;
		column.Padding = .(8, 6);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mInfo, match);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		column.AddView(mGrid, grow);
		mContent = column;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;

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

	private void BuildGrid()
	{
		mGrid.Clear();
		// Each array's rows group under a default-collapsed expander, since they carry the
		// outermost array key as category; top-level scalars stay visible.
		for (let field in mFields)
		{
			if (!field.Category.IsEmpty)
				mGrid.SetCategoryDefaultCollapsed(field.Category);
		}
		for (int i < mFields.Count)
		{
			let field = mFields[i];
			let index = i;
			let cat = field.Category.IsEmpty ? "Properties" : StringView(field.Category);
			if ((field.Kind == .ArrayCount) || (field.Category == AssetFormField.cVersionsKey))
				continue; // structural, not authorable
			if (field.Kind == .Blob)
			{
				mGrid.AddProperty(new StringEditor(field.Label, scope $"(blob, {field.BlobValue.Count} bytes)", null, cat));
				continue;
			}
			if (field.Kind == .Text)
			{
				mGrid.AddProperty(new StringEditor(field.Label, field.TextValue, new [=index, =this](v) =>
					{
						let patch = scope AssetFormField();
						mFields[index].CopyTo(patch);
						patch.TextValue.Set(v);
						ApplyFieldEdit(index, patch);
					}, cat));
				continue;
			}
			if (field.Kind == .Guid)
			{
				// The canonical string row, parse-validated, plus an untyped Pick button.
				mGrid.AddProperty(new StringEditor(field.Label, field.GuidValue.ToString(.. scope .(), 'D'), new [=index, =this](v) =>
					{
						if (!(Guid.Parse(v) case .Ok(let parsed)))
							return; // invalid: the old value stays
						let patch = scope AssetFormField();
						mFields[index].CopyTo(patch);
						patch.GuidValue = parsed;
						ApplyFieldEdit(index, patch);
					}, cat));
				mGrid.AddProperty(new ButtonEditor(scope $"Pick {field.Label}", new [=index, =this]() =>
					{
						let ctx = Ctx;
						if ((ctx == null) || (mContext.Project == null))
							return;
						let dialog = new AssetPickerDialog(mContext, .()); // an empty filter is every type
						dialog.OnPicked = new [=index, =this](picked) =>
							{
								let patch = scope AssetFormField();
								mFields[index].CopyTo(patch);
								patch.GuidValue = picked;
								ApplyFieldEdit(index, patch);
							};
						dialog.Show(ctx);
					}, cat));
				continue;
			}
			// The scalars.
			switch (field.ScalarKind)
			{
			case .Bool:
				mGrid.AddProperty(new BoolEditor(field.Label, field.IntValue != 0, new [=index, =this](v) =>
					{
						let patch = scope AssetFormField();
						mFields[index].CopyTo(patch);
						patch.IntValue = v ? 1 : 0;
						ApplyFieldEdit(index, patch);
					}, cat));
			case .Float32, .Float64:
				mGrid.AddProperty(new FloatEditor(field.Label, field.FloatValue, -1e12, 1e12, 0.01, 4, new [=index, =this](v) =>
					{
						let patch = scope AssetFormField();
						mFields[index].CopyTo(patch);
						patch.FloatValue = v;
						ApplyFieldEdit(index, patch);
					}, cat));
			default:
				mGrid.AddProperty(new IntEditor(field.Label, field.IntValue, -9007199254740992L, 9007199254740992L, new [=index, =this](v) =>
					{
						let patch = scope AssetFormField();
						mFields[index].CopyTo(patch);
						patch.IntValue = v;
						ApplyFieldEdit(index, patch);
					}, cat));
			}
		}
	}

	/// Patches one field with undo, re-scans, and rebuilds the grid only on a shape change,
	/// deferred through the mutation queue, never mid scrub.
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

		// The re-scan: a conditional-branch shape change rebuilds the grid; a same-shape patch
		// just refreshes the stored fields.
		let rescanned = scope List<AssetFormField>();
		AssetForm.Scan(mObject, rescanned).IgnoreError();
		let sameShape = AssetForm.ShapeEquals(mFields, rescanned);
		ClearAndDeleteItems(mFields);
		mFields.AddRange(rescanned);
		rescanned.Clear();
		if (!sameShape)
		{
			if (let ctx = Ctx)
				ctx.MutationQueue.QueueAction(new () => { BuildGrid(); });
		}
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mObject == null)
			return;
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		mObject.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
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
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		mObject.Serialize(ar);
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		AssetForm.Scan(mObject, mFields).IgnoreError();
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(new () => { BuildGrid(); });
		else
			BuildGrid();
		MarkDirty();
	}

	private UIContext Ctx => (mGrid != null) ? mGrid.Context : null;
}
