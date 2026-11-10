using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// ListModel: a list of texts game code makes and fills, for a list, table or tree view to show
// through setModel. A reference-counted object over a StringListModel, so its maker holds it and
// a view keeps it alive while it shows it; its edits reach the views as the model's do (a row
// inserted, removed or changed, not a reset).

[GuiReflect(true)]
class ListModel : RefCounted
{
	private StringListModel mModel = new .() ~ delete _;

	public this()
	{
	}

	public void Add(StringView text) => mModel.AddItem(text);

	public void Insert(int32 row, StringView text) => mModel.InsertItem((row < 0) ? 0 : row, text);

	public void Remove(int32 row)
	{
		if (row >= 0)
			mModel.RemoveItem(row);
	}

	public void Set(int32 row, StringView text)
	{
		if (row >= 0)
			mModel.SetItem(row, text);
	}

	/// The row's text, the list's own (empty past the end).
	public StringView Get(int32 row) => mModel.ItemAt(row);

	public int32 Count => (int32)mModel.RowCount();

	public void Clear() => mModel.Clear();

	/// The model a view shows; the list's own.
	public StringListModel Model => mModel;
}
