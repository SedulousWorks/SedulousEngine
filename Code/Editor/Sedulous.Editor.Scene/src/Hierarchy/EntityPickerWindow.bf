using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

// An entity slot's pick (the mock's entity-picker.xml): the
// scene as its hierarchy shows it, the hierarchy's own tree model (SceneTreeModel) in a picker's
// frame. The scene is its top row (open, and no pick); each entity by its type's icon in its
// category's colour, opened and closed by its arrow; the way to the current entity open and its row
// lit. The search keeps each match with what holds it and opens every way to them. Up and Down
// move the light from the search, Enter or a double click picks; Esc or its close keeps the value
// (a slot's own clear sets nothing). It opens in the window's middle, as every picker does.

/// What an entity slot asks the picker for.
class EntityPickRequest
{
	/// Its value now (nil: none).
	public Guid Current = .Empty;
	/// A pick (nil: None). OWNED: it goes with the request.
	public delegate void(Guid id) Chosen ~ delete _;
}

/// What the entity picker shows the scene by, as the page's hierarchy does.
class EntityPickerServices
{
	/// The entities' type icons; null: none. Not owned.
	public EditorIcons Icons = null;
	/// The top row's icon.
	public String SceneIcon = new .() ~ delete _;
	/// The top row's text; null: the scene's name.
	public delegate StringView() SceneName ~ delete _;
}

class EntityPickerWindow
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/EntityPicker.xml";

	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	/// Declared first: it goes last, after the model the tree it holds borrows.
	private Node mContent ~ _?.ReleaseRef();
	private SceneEditContext mEdit;
	private EntityPickerServices mServices ~ delete _;
	/// BORROWED: what it opened over, last.
	private SceneRoot mRoot = null;
	// The frame's: the tree holds them.
	private TextField mSearch = null;
	private TreeView mTree = null;
	private Sedulous.GUI.Label mState = null;
	private Sedulous.GUI.Label mHint = null;
	private SceneTreeModel mModel = new .() ~ delete _;
	/// What it was opened with last; an empty one before.
	private EntityPickRequest mRequest = new .() ~ delete _;
	private String mQuery = new .() ~ delete _;
	private uint32 mKeyListener = 0;

	/// The picker over `edit`'s scene in `content` (the markup's `entity-picker-search`,
	/// `entity-picker-tree`, `entity-picker-state`, `entity-picker-hint` and `entity-picker-close`,
	/// by id). `edit` is borrowed and outlives it; it TAKES OWNERSHIP of `services` and of a
	/// reference to `content` (null makes a picker that never opens).
	public this(SceneEditContext edit, EntityPickerServices services, Node content)
	{
		mEdit = edit;
		mServices = services;
		mContent = content;
		if (mContent == null)
			return;
		mSearch = Find<TextField>("entity-picker-search");
		mTree = Find<TreeView>("entity-picker-tree");
		mState = Find<Sedulous.GUI.Label>("entity-picker-state");
		mHint = Find<Sedulous.GUI.Label>("entity-picker-hint");
		if (mSearch != null)
			mSearch.SetOnTextChanging(new (text) => { Search(text); });
		if (mTree != null)
		{
			mTree.Model = mModel;
			mTree.SetOnActivated(new (index) => { PickEntity(mModel.EntityOfNode(index.InternalId)); });
		}
		if (let close = CloseButton)
			close.SetOnClick(new () => { Close(); });
		// Up, Down and Enter before the search takes them.
		mKeyListener = mContent.AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				let code = (Sedulous.GUI.KeyCode)key.KeyCode;
				if (key.Modifiers != 0)
					return;
				if ((code == .Down) || (code == .Up))
				{
					Step((code == .Down) ? 1 : -1);
					e.Handled = true;
				}
				else if ((code == .Return) || (code == .KeypadEnter))
				{
					PickLit();
					e.Handled = true;
				}
			}, true);
	}

	/// The content may outlive this: what of it calls back here goes first.
	public ~this()
	{
		Close();
		if (mContent != null)
			mContent.RemoveEventListener(mKeyListener);
		if (mTree != null)
			mTree.Model = null;
	}

	/// Opens it over `root` for `request`, in the window's middle: the scene's tree, the way to the
	/// current entity open and its row lit, the search empty and focused. False with no frame, a
	/// root in no GUI, or one open already. OWNERSHIP of `request` transfers, opened or not.
	public bool Open(SceneRoot root, EntityPickRequest request)
	{
		let dispatcher = root.EventDispatcher;
		if ((mContent == null) || (dispatcher == null) || IsOpen)
		{
			delete request;
			return false;
		}
		mRoot = root;
		delete mRequest;
		mRequest = request;
		mQuery.Clear();
		if (mSearch != null)
			mSearch.Text = default;
		Build();
		if (mHint != null)
		{
			let scene = mEdit.Scene;
			let current = mRequest.Current.IsNil ? EntityHandle() : scene.FindEntity(mRequest.Current);
			if (current.IsAssigned)
			{
				let name = scene.GetEntityName(current);
				mHint.Text = scope String()..AppendF("Enter picks, Esc keeps {}", name.IsEmpty ? "(unnamed)" : name);
			}
			else
				mHint.Text = "Enter picks, Esc closes";
		}
		let options = new PopupOptions();
		options.Kind = .Auto; // Escape and a press outside close it, keeping the current value
		options.Modal = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.Centered = true;
		dispatcher.OpenPopup(root, mContent, options);
		if (mSearch != null)
			dispatcher.FocusNode = mSearch;
		return true;
	}

	public void Close()
	{
		if (IsOpen)
			mRoot.EventDispatcher.ClosePopup(mContent);
	}

	public bool IsOpen => (mRoot != null) && (mContent != null) && (mRoot.EventDispatcher != null) && mRoot.EventDispatcher.IsPopupOpen(mContent);

	/// Searches the scene for `text` (as typing it): a match kept with what holds it.
	public void Search(StringView text)
	{
		if (mQuery == text)
			return;
		mQuery.Set(text);
		if ((mSearch != null) && (mSearch.Text != text))
			mSearch.Text = text;
		Build();
	}

	/// Moves the light `by` rows (the scene's own row among them).
	public void Step(int32 by)
	{
		if ((mTree == null) || (mTree.GetItemCount() == 0))
			return;
		let lit = mTree.SelectedItem;
		let last = (int32)mTree.GetItemCount() - 1;
		mTree.SelectedItem = (lit < 0) ? 0 : Math.Clamp(lit + by, 0, last);
	}

	/// Picks the lit entity; the scene's row, or none lit, picks nothing.
	public void PickLit()
	{
		if ((mTree != null) && (mTree.SelectedItem >= 0))
			PickEntity(mModel.EntityOfNode(mTree.GetItemIndex(mTree.SelectedItem).InternalId));
	}

	// === What it shows (for tests) ===

	public Node Content => mContent;
	public TreeView Tree => mTree;
	public Sedulous.GUI.Button CloseButton => Find<Sedulous.GUI.Button>("entity-picker-close");

	/// The shown rows' texts in order, the scene's first, nested by two spaces a level, joined by
	/// " | ", into `outText` (as the hierarchy's Rows).
	public void Rows(String outText)
	{
		if (mTree == null)
			return;
		let text = scope String();
		for (int32 item < (int32)mTree.GetItemCount())
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			for (int32 depth = mTree.ItemDepth(item); depth > 0; depth--)
				outText.Append("  ");
			text.Clear();
			mTree.GetItemText(item, text);
			outText.Append(text);
		}
	}

	/// The lit row's text, into `outText`; nothing lit, nothing.
	public void LitName(String outText)
	{
		if ((mTree != null) && (mTree.SelectedItem >= 0))
			mTree.GetItemText(mTree.SelectedItem, outText);
	}

	public StringView Hint => (mHint != null) ? mHint.Text : default;
	public StringView State => ((mState != null) && mState.Displayed) ? mState.Text : default;

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	// The tree from the scene as it is now: the scene's row open; with a search every way to a
	// match open, else the way to the current entity; the current entity lit when shown.
	private void Build()
	{
		let scene = mEdit.Scene;
		mModel.Build(scene, (mServices.SceneName != null) ? mServices.SceneName() : scene.Name, mServices.SceneIcon, mServices.Icons, mQuery);
		let empty = mModel.Rows.Count <= 1; // the scene's row alone
		if (mTree != null)
		{
			mTree.SetIdExpanded(SceneTreeModel.cSceneRowId, true);
			if (!mQuery.IsEmpty)
			{
				for (let row in mModel.Rows)
				{
					if (!row.Entity.IsNil && !row.Children.IsEmpty)
						mTree.SetIdExpanded(SceneTreeModel.IdOfEntity(row.Entity), true);
				}
			}
			else if (!mRequest.Current.IsNil)
			{
				let current = scene.FindEntity(mRequest.Current);
				for (var e = current.IsAssigned ? scene.GetParent(current) : EntityHandle(); scene.IsValid(e); e = scene.GetParent(e))
					mTree.SetIdExpanded(SceneTreeModel.IdOfEntity(scene.GetEntityId(e)), true);
			}
			mModel.Reset();
			mTree.Displayed = !empty;
			Light();
		}
		if (mState != null)
		{
			mState.Displayed = empty;
			if (!mQuery.IsEmpty)
				mState.Text = scope String()..AppendF("No entity matches \"{}\".", mQuery);
			else
				mState.Text = "The scene has no entity to point at.";
		}
	}

	// The current entity lit; not shown (or none), the first match with a search, else nothing.
	private void Light()
	{
		let first = mQuery.IsEmpty ? Guid.Empty : FirstMatch();
		int32 lit = -1;
		for (int32 item < (int32)mTree.GetItemCount())
		{
			let entity = mModel.EntityOfNode(mTree.GetItemIndex(item).InternalId);
			if (!mRequest.Current.IsNil && !entity.IsNil && (entity == mRequest.Current))
				lit = item;
			else if ((lit < 0) && !first.IsNil && (entity == first))
				lit = item;
		}
		if (lit >= 0)
			mTree.SelectedItem = lit;
		else
			mTree.SetSelectedIds(Span<ItemId>());
	}

	// The first entity, in the tree's order, whose own name or guid the search finds.
	private Guid FirstMatch()
	{
		let scene = mEdit.Scene;
		for (let row in mModel.Rows)
		{
			if (row.Entity.IsNil)
				continue;
			let e = scene.FindEntity(row.Entity);
			if (e.IsAssigned && SearchFilter.NameOrGuidMatches(scene.GetEntityName(e), row.Entity, mQuery))
				return row.Entity;
		}
		return .Empty;
	}

	// The scene's own row is no pick.
	private void PickEntity(Guid entity)
	{
		if (!entity.IsNil)
			Pick(entity);
	}

	private void Pick(Guid id)
	{
		let chosen = mRequest.Chosen;
		mRequest.Chosen = null; // ours until it has answered
		Close();
		if (chosen != null)
			chosen(id);
		delete chosen;
	}
}
