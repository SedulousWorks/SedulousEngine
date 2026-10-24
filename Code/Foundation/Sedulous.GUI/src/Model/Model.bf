using System;
using System.Collections;

namespace Sedulous.GUI;

// IModel: the abstract data source a model-backed view renders (eepp's Models::Model in role). A
// model exposes rows of cells under a parent (RowCount x ColumnCount; a flat model has the top
// level alone), returns a Variant per (index, role), and tells its clients (the views) what
// changed: rows inserted, removed, moved or changed under a parent, or, when it cannot say, a
// reset. A client that does not follow ranges takes each as a reset. Each row has an id that
// stays its own while rows come and go, so a view keeps its selection and expansion as id sets
// (Zero's and LunarSong's way). Editing (IsEditable, SetData) and sorting (Sort) are capabilities
// a model may have.
//
// What Data returns is a view of the model's value (see Variant): valid until the model changes,
// never disposed by the caller. What SetData is given the model copies.

/// A row's identity, its own while rows are inserted, removed and moved around it.
typealias ItemId = uint64;

static
{
	public const ItemId NoItem = ~(ItemId)0;
}

enum SortOrder
{
	None,
	Ascending,
	Descending
}

/// Where in a row a drop lands: before it, onto it (a tree's child), or after it.
enum DropPlace : uint8
{
	Before,
	On,
	After,
}

/// A drop on a view, as its model hears it: what is dropped, where (a row and a place; an
/// invalid row is the end of the top level), with which effect, and, from a view, the ids of
/// the rows dragged and their model. It borrows all of them from the one asking.
struct ModelDrop
{
	public DragPayload Payload = null;
	public ModelIndex Index = .();
	public DropPlace Place = .After;
	public DropEffect Effect = .Move;
	public Span<ItemId> Ids = default;
	public IModel Source = null;

	public this() { }
}

// What a model tells a view. Each range defaults to a reset, so a client follows only the
// ranges it can.
interface IModelClient
{
	/// Anything may have changed: read it all again.
	void OnModelReset();

	/// `count` rows were inserted under `parent`, the first now at `first`.
	void OnRowsInserted(ModelIndex parent, int32 first, int32 count)
	{
		OnModelReset();
	}

	/// `count` rows were removed under `parent`, the first having been at `first`.
	void OnRowsRemoved(ModelIndex parent, int32 first, int32 count)
	{
		OnModelReset();
	}

	/// `count` rows under `parent` that were at `first` now start at `to` (in the order after
	/// the move).
	void OnRowsMoved(ModelIndex parent, int32 first, int32 count, int32 to)
	{
		OnModelReset();
	}

	/// The data of `count` rows under `parent` from `first` changed (not their number or order).
	void OnRowsChanged(ModelIndex parent, int32 first, int32 count)
	{
		OnModelReset();
	}
}

abstract class IModel
{
	/// The clients told of each change; not owned (a client outlives the model or removes itself
	/// first).
	protected List<IModelClient> mClients = new .() ~ delete _;

	// Number of rows under `parent` (an invalid parent = the top level). Flat models
	// ignore the parent (they only have a top level).
	public abstract int RowCount(ModelIndex parent);
	/// The rows of the top level.
	public int RowCount() => RowCount(.());
	public abstract int ColumnCount();
	/// Appends the column's name; nothing by default.
	public virtual void ColumnName(int column, String outText) { }
	/// The cell's value for `role`: a view, valid until the model changes.
	public abstract Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display);

	// === Identity ===
	/// The id of the row `index` is in. By default a tree's node id (InternalId), else the
	/// row number, which a model whose rows move should replace with ids of its own.
	public virtual ItemId IdOf(ModelIndex index)
	{
		if (!index.IsValid)
			return NoItem;
		return (index.InternalId >= 0) ? (ItemId)index.InternalId : (ItemId)index.Row;
	}

	/// The top-level row whose id is `id` (invalid: none). A tree's view finds its nodes itself.
	public virtual ModelIndex IndexOfId(ItemId id)
	{
		for (int r = 0; r < RowCount(); r++)
		{
			let index = Index((int32)r);
			if (IdOf(index) == id)
				return index;
		}
		return .();
	}

	// === Capabilities ===
	public virtual bool IsEditable(ModelIndex index) => false;
	/// Writes an edited value (the model keeps its own copy); false when it is refused (the
	/// editor then stays open).
	public virtual bool SetData(ModelIndex index, Sedulous.GUI.Variant value) => false;
	/// Sorts by `column` (None: the source's order); false when the model cannot sort.
	public virtual bool Sort(int column, SortOrder order) => false;

	/// What a drop would do: an effect, or none, with a reason (set into `reason`) when it says
	/// why; none with no reason means the place is not one it takes (the view tries another).
	public virtual DropEffect CanDrop(ModelDrop drop, String reason) => .None;
	/// Does the drop; false when it could not.
	public virtual bool Drop(ModelDrop drop) => false;
	/// Removes rows by id (what a view moved to another model leaves behind); false when it
	/// cannot.
	public virtual bool RemoveIds(Span<ItemId> ids) => false;

	// === Tree structure (flat defaults; a tree model overrides these) ===
	// The index of the cell at (row, column) under `parent`.
	public virtual ModelIndex Index(int32 row, int32 column, ModelIndex parent) => MakeModelIndex(row, column);
	/// The index of the cell at (row, column) of the top level.
	public ModelIndex Index(int32 row, int32 column = 0) => Index(row, column, .());
	// The parent of `child` (invalid = a top-level node; flat models have no parents).
	public virtual ModelIndex ParentIndex(ModelIndex child) => .();
	// Whether `parent` has any child rows.
	public virtual bool HasChildren(ModelIndex parent) => RowCount(parent) > 0;
	/// Whether the top level has any rows.
	public bool HasChildren() => HasChildren(.());

	public bool IsValidIndex(ModelIndex index) =>
		(index.Row >= 0) && (index.Row < RowCount()) && (index.Column >= 0) && (index.Column < ColumnCount());

	// Client (view) registration. Clients are non-owning and must outlive the model or
	// unregister first.
	public void AddClient(IModelClient client)
	{
		if (client != null)
			mClients.Add(client);
	}

	public void RemoveClient(IModelClient client)
	{
		for (int i = 0; i < mClients.Count; i++)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	// === Telling the clients (after the change is made) ===
	public void NotifyReset()
	{
		for (int i = 0; i < mClients.Count; i++)
			mClients[i].OnModelReset();
	}

	public void NotifyRowsInserted(ModelIndex parent, int32 first, int32 count)
	{
		for (int i = 0; i < mClients.Count; i++)
			mClients[i].OnRowsInserted(parent, first, count);
	}

	public void NotifyRowsRemoved(ModelIndex parent, int32 first, int32 count)
	{
		for (int i = 0; i < mClients.Count; i++)
			mClients[i].OnRowsRemoved(parent, first, count);
	}

	public void NotifyRowsMoved(ModelIndex parent, int32 first, int32 count, int32 to)
	{
		for (int i = 0; i < mClients.Count; i++)
			mClients[i].OnRowsMoved(parent, first, count, to);
	}

	public void NotifyRowsChanged(ModelIndex parent, int32 first, int32 count)
	{
		for (int i = 0; i < mClients.Count; i++)
			mClients[i].OnRowsChanged(parent, first, count);
	}
}

/// Ids for a flat model's rows: one per row, handed out in turn, moving with its row. Finding
/// an id's row is a lookup (an accessibility node asks it for every item it describes), its
/// index made again on the first ask after the rows change.
class RowIds
{
	private List<ItemId> mIds = new .() ~ delete _;
	private ItemId mNext = 0;
	/// Id to row, as of the last ask.
	private Dictionary<ItemId, int32> mRows = new .() ~ delete _;
	private bool mStale = true;

	public int Count => mIds.Count;

	public ItemId At(int row) => ((row >= 0) && (row < mIds.Count)) ? mIds[row] : NoItem;

	public int32 RowOf(ItemId id)
	{
		if (mStale)
		{
			mRows.Clear();
			for (int i = 0; i < mIds.Count; i++)
				mRows[mIds[i]] = (int32)i;
			mStale = false;
		}
		return mRows.TryGetValue(id, let row) ? row : -1;
	}

	public void Reset(int count)
	{
		mIds.Clear();
		for (int i = 0; i < count; i++)
			mIds.Add(mNext++);
		mStale = true;
	}

	public void Insert(int row)
	{
		mIds.Insert(row, mNext++);
		mStale = true;
	}

	/// Puts an existing id back at `row` (a row moved by a drop keeps its id).
	public void InsertId(int row, ItemId id)
	{
		mIds.Insert(row, id);
		mStale = true;
	}

	public void Remove(int row)
	{
		mIds.RemoveAt(row);
		mStale = true;
	}

	public void Move(int from, int to)
	{
		let id = mIds[from];
		mIds.RemoveAt(from);
		mIds.Insert(to, id);
		mStale = true;
	}
}
