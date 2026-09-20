using System;
using Sedulous.UI;

namespace Sedulous.Editor.Script;

/// The API browser beside the editor: a filter over the bound API's types and members,
/// rebuilt once per frame while visible and dirty; a double click inserts the row's text.
/// The surface is BORROWED from the page.
class ScriptApiBrowserView
{
	private ScriptApiSurface mSurface = null;
	private ScriptApiTree mTree = new .() ~ delete _;
	private ScriptApiTreeAdapter mAdapter = null ~ delete _;
	private bool mDirty = true;
	/// Owned through its reference.
	private View mRoot = null ~ { if (_ != null) _.ReleaseRef(); };
	/// Borrowed: the root owns them.
	private EditText mFilter = null;
	private TreeView mTreeView = null;

	/// What activating a row does with its insert text.
	public delegate void(StringView text) OnInsert ~ delete _;

	public this()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4.0f;
		mFilter = new EditText();
		mFilter.Placeholder.Value.Set("Filter API");
		mFilter.OnTextChanged.Add(new [=this](edit) => { mDirty = true; });
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilter, match);
		mTreeView = new TreeView();
		mTreeView.OnItemClick.Add(new [=this](info) =>
			{
				if ((info.ClickCount < 2) || (OnInsert == null))
					return;
				if (mTree.InRange(info.NodeId))
					OnInsert(mTree.Nodes[info.NodeId].InsertText);
			});
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		column.AddView(mTreeView, grow);
		mAdapter = new ScriptApiTreeAdapter(mTree);
		mAdapter.SetView(mTreeView);
		column.AddRef();
		mRoot = column;
	}

	public ~this()
	{
		mTreeView.SetAdapter(null);
	}

	public void SetSurface(ScriptApiSurface surface)
	{
		mSurface = surface;
		mDirty = true;
	}

	public View Root => mRoot;
	public ScriptApiTree Tree => mTree;

	/// The deferred rebuild bracket: once per frame.
	public void Update()
	{
		if (!mDirty || (mRoot.Visibility != .Visible) || (mSurface == null))
			return;
		mDirty = false;
		Rebuild();
	}

	private void Rebuild()
	{
		let surface = mSurface;
		mTree.Build(surface.Types, mFilter.Text, scope (type) => surface.IsEditorOnly(type));
		mTreeView.SetAdapter(mAdapter); // rebuilds the flat list and rows
	}
}
