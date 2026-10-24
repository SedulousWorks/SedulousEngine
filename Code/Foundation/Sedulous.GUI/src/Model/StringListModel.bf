using System;
using System.Collections;

namespace Sedulous.GUI;

// StringListModel: the simplest concrete Model - a single column of strings, one per row, each
// with an id of its own (eepp's ItemListModel in role). Its edits tell its views the rows they
// touch: an insert, a removal, a move or a change; SetItems and Clear reset them. Editable, a
// view may edit its rows in place. It keeps its own copy of each string it is given.

class StringListModel : IModel
{
	private List<String> mItems = new .() ~ DeleteContainerAndItems!(_);
	private RowIds mIds = new .() ~ delete _;
	private bool mEditable = false;

	public this() { }

	public this(Span<StringView> items)
	{
		for (let item in items)
			mItems.Add(new String(item));
		mIds.Reset(mItems.Count);
	}

	public void SetItems(Span<StringView> items)
	{
		// The copies first: `items` may view the strings being replaced.
		let next = new List<String>(items.Length);
		for (let item in items)
			next.Add(new String(item));
		DeleteContainerAndItems!(mItems);
		mItems = next;
		mIds.Reset(mItems.Count);
		NotifyReset();
	}

	public void AddItem(StringView item) => InsertItem(mItems.Count, item);

	/// Inserts at `row` (past the end: last).
	public void InsertItem(int row, StringView item)
	{
		var row;
		if ((row < 0) || (row > mItems.Count))
			row = mItems.Count;
		mItems.Insert(row, new String(item));
		mIds.Insert(row);
		NotifyRowsInserted(.(), (int32)row, 1);
	}

	public void RemoveItem(int row)
	{
		if ((row < 0) || (row >= mItems.Count))
			return;
		delete mItems[row];
		mItems.RemoveAt(row);
		mIds.Remove(row);
		NotifyRowsRemoved(.(), (int32)row, 1);
	}

	public void SetItem(int row, StringView item)
	{
		if ((row < 0) || (row >= mItems.Count))
			return;
		mItems[row].Set(item);
		NotifyRowsChanged(.(), (int32)row, 1);
	}

	public void MoveItem(int from, int to)
	{
		if ((from < 0) || (from >= mItems.Count) || (to < 0) || (to >= mItems.Count) || (from == to))
			return;
		let item = mItems[from];
		mItems.RemoveAt(from);
		mItems.Insert(to, item);
		mIds.Move(from, to);
		NotifyRowsMoved(.(), (int32)from, 1, (int32)to);
	}

	public void Clear()
	{
		ClearAndDeleteItems!(mItems);
		mIds.Reset(0);
		NotifyReset();
	}

	/// Its rows may be edited in place.
	public bool Editable
	{
		get => mEditable;
		set => mEditable = value;
	}

	/// The row's text (empty past the end), a view of the model's.
	public StringView ItemAt(int row) => ((row >= 0) && (row < mItems.Count)) ? (StringView)mItems[row] : default;

	public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mItems.Count;
	public override int ColumnCount() => 1;

	public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
	{
		if (!IsValidIndex(index))
			return .();
		if ((role == .Display) || (role == .Sort))
			return .((StringView)mItems[index.Row]);
		return .();
	}

	public override ItemId IdOf(ModelIndex index) => index.IsValid ? mIds.At(index.Row) : NoItem;

	public override ModelIndex IndexOfId(ItemId id)
	{
		let row = mIds.RowOf(id);
		return (row >= 0) ? MakeModelIndex(row) : .();
	}

	public override bool IsEditable(ModelIndex index) => mEditable && IsValidIndex(index);

	public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
	{
		if (!IsEditable(index))
			return false;
		let text = scope String();
		value.ToString(text);
		SetItem(index.Row, text);
		return true;
	}

	// === Drops ===
	// Its own rows move or copy between rows (not onto one); another model's rows, or `text`,
	// come in as text, copied or moved (the source removes what moved).
	public override DropEffect CanDrop(ModelDrop drop, String reason)
	{
		if (drop.Place == .On)
			return .None; // a list has nothing to drop onto: the view tries between
		let rows = (drop.Source != null) && !drop.Ids.IsEmpty;
		let text = (drop.Payload != null) && (drop.Payload.Type == "text");
		if (!rows && !text)
			return .None;
		if (drop.Effect == .Link)
		{
			reason.Set("A list cannot link its rows");
			return .None;
		}
		return text ? .Copy : drop.Effect;
	}

	public override bool Drop(ModelDrop drop)
	{
		if (CanDrop(drop, scope String()) == .None)
			return false;
		int at = !drop.Index.IsValid ? mItems.Count
			: (drop.Place == .Before) ? drop.Index.Row
			: drop.Index.Row + 1;
		if (drop.Ids.IsEmpty)
		{
			// The payload's string, or its label.
			let value = drop.Payload.Value;
			StringView text = drop.Payload.Label;
			if ((value.VariantType == typeof(String)) && (value.Get<String>() != null))
				text = value.Get<String>();
			mItems.Insert(Math.Min(at, mItems.Count), new String(text));
			mIds.Insert(Math.Min(at, mIds.Count));
			NotifyReset();
			return true;
		}
		// The rows, in their order, taken out (moving within) or read (copying, or from another model).
		let within = (drop.Source === this) && (drop.Effect == .Move);
		let rows = scope List<int>();
		for (let id in drop.Ids)
		{
			let index = drop.Source.IndexOfId(id);
			if (index.IsValid)
				rows.Add(index.Row);
		}
		for (int i = 1; i < rows.Count; i++) // in row order
		{
			for (int j = i; (j > 0) && (rows[j - 1] > rows[j]); j--)
			{
				let t = rows[j];
				rows[j] = rows[j - 1];
				rows[j - 1] = t;
			}
		}
		// Copied out before any row is taken: what the source hands out is a view.
		let texts = scope List<String>();
		let ids = scope List<ItemId>();
		for (let row in rows)
		{
			let text = new String();
			drop.Source.Data(drop.Source.Index((int32)row)).ToString(text);
			texts.Add(text);
			ids.Add(drop.Source.IdOf(drop.Source.Index((int32)row)));
		}
		if (within)
		{
			for (int i = rows.Count - 1; i >= 0; i--)
			{
				delete mItems[rows[i]];
				mItems.RemoveAt(rows[i]);
				mIds.Remove(rows[i]);
				if (rows[i] < at)
					at--;
			}
		}
		at = Math.Min(at, mItems.Count);
		for (int i = 0; i < texts.Count; i++)
		{
			mItems.Insert(at + i, texts[i]); // the list takes the string
			if (within)
				mIds.InsertId(at + i, ids[i]); // a moved row keeps its id (and its selection)
			else
				mIds.Insert(at + i);
		}
		NotifyReset();
		return true;
	}

	public override bool RemoveIds(Span<ItemId> ids)
	{
		bool removed = false;
		for (let id in ids)
		{
			let row = mIds.RowOf(id);
			if (row < 0)
				continue;
			delete mItems[row];
			mItems.RemoveAt(row);
			mIds.Remove(row);
			removed = true;
		}
		if (removed)
			NotifyReset();
		return removed;
	}
}
