using System;

namespace Sedulous.GUI;

// ListModel: a list of texts a script makes and fills, for a list, table or tree view to show
// through setModel. A reference-counted object over a StringListModel, so a script holds it and
// a view keeps it alive while it shows it; its edits reach the views as the model's do (a row
// inserted, removed or changed, not a reset).

[GuiReflect(true)]
class ListModel : RefCounted
{
	private StringListModel mModel = new .() ~ delete _;

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

	/// Appends the row's text (nothing past the end).
	public void Get(int32 row, String outText)
	{
		if ((row >= 0) && (row < mModel.RowCount()))
			outText.Append(mModel.ItemAt(row));
	}

	public int32 Count => (int32)mModel.RowCount();

	public void Clear() => mModel.Clear();

	/// The model a view shows; the list's own.
	public StringListModel Model => mModel;
}
