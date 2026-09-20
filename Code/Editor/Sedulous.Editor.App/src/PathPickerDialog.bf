using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The AssetPickerDialog's sibling for source files: a modal picker over the files under a
/// project directory (typically the Sources root), constrained to a set of extensions.
/// Bespoke pages whose assets reference a raw file (FontAsset.FileName) use this instead of
/// a hand-typed string: the user can only pick paths that exist inside the project, so cooked
/// references never dangle. The walk is recursive from the root and rows show root-relative
/// paths; the ext filter is case-insensitive and empty means every file; the filter box
/// matches a substring of the relative path; double-click or Select confirms, Cancel and
/// Escape dismiss. The result is delivered through OnPicked before the dialog closes; Cancel
/// fires nothing.
class PathPickerDialog : Dialog
{
	/// The pick result, a root-relative path. Fired once, before close. Owned.
	public delegate void(StringView path) OnPicked ~ delete _;

	private class RowAdapter : ListAdapterBase
	{
		private PathPickerDialog mOwner;

		public this(PathPickerDialog owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			row.Padding = .(6, 2);
			let label = new Label();
			label.FontSize.Value = 12.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(label, grow);
			return row;
		}

		public override void BindView(View view, int32 position)
		{
			let row = view as FlexLayout;
			if ((row == null) || (row.ChildCount == 0) || (position < 0) || (position >= mOwner.mRows.Count))
				return;
			let label = row.GetChildAt(0) as Label;
			if (label == null)
				return;
			label.SetText(mOwner.mRows[position]);
		}
	}

	// Borrowed: the content owns them.
	private ListView mList;
	private EditText mFilterEdit;
	private RowAdapter mAdapter ~ delete _;
	private List<String> mExtensions = new .() ~ DeleteContainerAndItems!(_);
	/// Every match under the root, root-relative.
	private List<String> mFiles = new .() ~ DeleteContainerAndItems!(_);
	/// The filtered view of mFiles.
	private List<String> mRows = new .() ~ DeleteContainerAndItems!(_);
	private String mFilter = new .() ~ delete _;

	public this(StringView title, StringView rootPath, Span<StringView> extensions) : base(title)
	{
		for (let ext in extensions)
			mExtensions.Add(new String(ext));
		MinWidth.Value = 460.0f;
		MinHeight.Value = 340.0f;
		MaxWidth.Value = 560.0f;
		MaxHeight.Value = 420.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		mFilterEdit = new EditText();
		mFilterEdit.Placeholder.Value.Set("Filter...");
		mFilterEdit.OnTextChanged.Add(new (edit) =>
			{
				mFilter.Set(edit.Text);
				RebuildRows();
			});
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilterEdit, match);

		mAdapter = new RowAdapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 20.0f;
		mList.SetAdapter(mAdapter);
		mList.OnItemClicked.Add(new (position, clickCount, x, y) =>
			{
				if (clickCount >= 2)
					ConfirmAt(position);
			});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mList, grow);
		SetContent(column);

		let select = AddButton("Select", .None);
		select.OnClick.Add(new (b) => { ConfirmAt(mList.Selection.FirstSelected()); });
		AddButton("Cancel", .Cancel);

		CollectFiles(rootPath);
		RebuildRows();
	}

	public ~this()
	{
		mList.SetAdapter(null);
	}

	private bool ExtensionMatches(StringView name)
	{
		if (mExtensions.IsEmpty)
			return true;
		for (let ext in mExtensions)
		{
			if (name.EndsWith(ext, .OrdinalIgnoreCase))
				return true;
		}
		return false;
	}

	/// The recursive walk from the root; mFiles keeps root-relative paths.
	private void CollectFiles(StringView rootPath)
	{
		let fs = scope NativeFileSystem(rootPath);
		let pending = scope List<String>();
		pending.Add(new String(""));
		while (!pending.IsEmpty)
		{
			let folder = pending.PopBack();
			defer delete folder;
			let entries = scope:: List<DirEntry>();
			defer { for (var e in entries) e.Dispose(); }
			if (fs.Enumerate(folder, entries) case .Err)
				continue;
			for (let entry in entries)
			{
				let path = new String();
				if (folder.IsEmpty)
					path.Set(entry.Name);
				else
					PathJoin(folder, entry.Name, path);
				if (entry.IsDirectory)
					pending.Add(path);
				else if (ExtensionMatches(path))
					mFiles.Add(path);
				else
					delete path;
			}
		}
	}

	private void RebuildRows()
	{
		ClearAndDeleteItems(mRows);
		for (let file in mFiles)
		{
			if (mFilter.IsEmpty || (file.IndexOf(mFilter, true) >= 0))
				mRows.Add(new String(file));
		}
		mList.Selection.ClearSelection();
		mList.NotifyDataChanged();
	}

	private void ConfirmAt(int32 position)
	{
		if ((position < 0) || (position >= mRows.Count))
			return;
		if (OnPicked != null)
			OnPicked(mRows[position]);
		Close(.OK);
	}
}
