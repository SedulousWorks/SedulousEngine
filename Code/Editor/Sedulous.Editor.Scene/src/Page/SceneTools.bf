using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// The scene page's viewport tools (Raptor's editor-gui spec, 5.3, layer 5, part 3): each an action,
// `scene.tool.<id>`, toggling it over the page (so the menu bar, the palette, a chord the user binds
// and MCP reach it; it had only the bar), disabled where it has nothing to work on and saying why. On
// the bar from the tool registry: a category of several tools one menu by its first tool's icon, a
// lone tool a toggle. The active tool's panel in one place (ruling 23): the HUD's top start under the
// chips, in a chrome of the tool's name, a fold and a close (back to Select); dragged by its head
// anywhere in the viewport (kept inside it as it shrinks), its place kept per scene, a double click
// on its head putting it back under the chips.

/// The tool panel's head: what a drag holds and a double click resets.
class ToolPanelHead : UIWidget
{
	/// A drag by the head: its delta since the press, in pixels.
	public delegate void() DragStarted ~ delete _;
	public delegate void(Float2 delta) Dragged ~ delete _;
	public delegate void() DragEnded ~ delete _;
	public delegate void() ResetAsked ~ delete _;

	private bool mDragging = false;
	private Float2 mFrom = .(0.0f, 0.0f);

	public this()
	{
		AddClass("hud-panel-head");
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		if (e.ClickCount == 2)
		{
			if (ResetAsked != null)
				ResetAsked();
			return;
		}
		mDragging = true;
		mFrom = e.Position;
		if (let dispatcher = EventDispatcher)
			dispatcher.CapturePointer(this);
		if (DragStarted != null)
			DragStarted();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mDragging)
			return;
		e.Handled = true;
		if (Dragged != null)
			Dragged(e.Position - mFrom);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mDragging || (e.Button != .Left))
			return;
		e.Handled = true;
		mDragging = false;
		if (let dispatcher = EventDispatcher)
			dispatcher.ReleasePointer(this);
		if (DragEnded != null)
			DragEnded();
	}
}

/// What a page's tools ask of it. The hooks are its own; the rest is borrowed and outlives it.
class SceneToolsServices
{
	public EditorContext Context = null;
	public EditorPage Page = null;
	public ViewportToolManager Tools = null;
	public ViewportToolHostContext HostContext = .();
	/// The bar's buttons go before this node, in its parent (the bar).
	public Node BarEnd = null;
	/// The viewport's pane (the panel's room, a stack) and the chips' zone it sits under until
	/// moved.
	public Node Pane = null;
	public Node Zone = null;
	/// The panel was moved or put back: the page keeps its view state.
	public delegate void() PlaceChanged ~ delete _;
}

class SceneTools
{
	private class Category
	{
		public String Name = new .() ~ delete _;
		/// Ours, besides the bar's.
		public ToolMenuButton Button = null;
		public List<String> Ids = new .() ~ DeleteContainerAndItems!(_);
		/// The menu's, which the button keeps.
		public List<MenuItem> Items = new .() ~ delete _;
	}

	private SceneToolsServices mServices ~ delete _;
	// The lone tools' toggles.
	private PageActionBar mBar = null ~ delete _;
	// Ours, besides the bar's.
	private List<ButtonBase> mButtons = new .() ~ { for (let button in _) button.ReleaseRef(); delete _; };
	private List<Category> mCategories = new .() ~ DeleteContainerAndItems!(_);
	private ViewportToolPanelHost mHost = null ~ delete _;
	// The panel's frame: head, then the tool's body. Ours, besides the pane's while it shows.
	private Panel mChrome = null;
	private ToolPanelHead mHead = null;
	// The head's, which the chrome keeps.
	private Image mIcon = null;
	private Label mTitle = null;
	private Sedulous.GUI.Button mFold = null;
	// The tool's, while it is active: borrowed from the panel host.
	private Node mBody = null;
	private bool mPanelShown = false;
	private bool mMoved = false;
	private bool mFolded = false;
	private Float2 mPlace = .(0.0f, 0.0f);
	private Float2 mDragFrom = .(0.0f, 0.0f);

	/// Takes `services`.
	public this(SceneToolsServices services)
	{
		mServices = services;
		RegisterActions();
		BuildBar();
		BuildChrome();
		if (mServices.Tools != null)
			mHost = new ViewportToolPanelHost(mServices.Tools, ViewportToolPanelRegistry.Global, mServices.HostContext,
				new (panel, tool) => { Mount(panel, tool); }, new () => { Clear(); });
	}

	public ~this()
	{
		Clear();
		DeleteAndNullify!(mHost); // its panel goes with it
		if (mHead != null)
			mHead.ReleaseRef();
		if (mChrome != null)
			mChrome.ReleaseRef();
	}

	/// The action that toggles tool `id` over a scene page (registered by the first page that has
	/// it, each the same), appended.
	public static void ActionOf(StringView id, String outAction) => outAction.AppendF("scene.tool.{}", id);

	/// Once a frame: the buttons as their actions are, the panel as the active tool's.
	public void Sync()
	{
		if (mBar != null)
			mBar.Sync();
		if ((mServices.Context != null) && (mServices.Page != null))
		{
			let actions = mServices.Context.Actions;
			let action = scope String();
			let reason = scope String();
			for (let category in mCategories)
			{
				var any = false;
				for (int i < category.Ids.Count)
				{
					action.Clear();
					ActionOf(category.Ids[i], action);
					let on = actions.IsChecked(action, mServices.Page);
					let enabled = actions.IsEnabled(action, mServices.Page);
					any = any || on;
					let item = category.Items[i];
					if (item.Checked != on)
						item.SetCheckedSilently(on);
					if (item.Enabled != enabled)
						item.Enabled = enabled;
					reason.Clear();
					actions.DisabledReason(action, mServices.Page, reason);
					item.Tooltip = reason;
				}
				// Lit while one of its tools is on; it opens even when all are disabled (each item
				// says why).
				var state = BoundCommandState();
				state.Available = true;
				state.Checked = any;
				category.Button.OnBoundCommandState(state);
			}
		}
		if (mHost != null)
			mHost.Sync();
		// A panel made of the kit shows what the tool has now (its keys change it too).
		if (let body = mBody as ToolPanelBody)
			body.Sync();
		if (mPanelShown)
			Clamp();
	}

	/// Where the panel was moved to (its top start corner in the viewport); null while it sits
	/// under the chips.
	public Float2? Place => mMoved ? (Float2?)mPlace : null;

	/// The panel moved to `place` (kept inside the viewport), or back under the chips (null).
	public void SetPlace(Float2? place)
	{
		mMoved = place.HasValue;
		if (place.HasValue)
			mPlace = place.Value;
		Reparent();
	}

	public void SetFolded(bool folded)
	{
		mFolded = folded;
		if (mBody != null)
			mBody.Displayed = !folded;
		if (mFold != null)
		{
			mFold.Icon = folded ? "Editor/Icons/chevron-right.svg" : "Editor/Icons/chevron-down.svg";
			mFold.Tooltip = folded ? "Unfold the panel" : "Fold the panel to its title";
		}
	}

	// === For tests ===

	public Node Panel => mPanelShown ? mChrome : null;
	public StringView PanelTitle => (mPanelShown && (mTitle != null)) ? mTitle.Text : default;
	public ToolPanelHead Head => mHead;
	public bool Folded => mFolded;
	public int ButtonCount => mButtons.Count;

	public ToolMenuButton CategoryButton(StringView category)
	{
		for (let known in mCategories)
		{
			if (known.Name == category)
				return known.Button;
		}
		return null;
	}

	// === Building ===

	// The page's tool `id`, when the subject is a scene page that has it (and its manager).
	private static IViewportTool ToolOf(EditorPage page, StringView id, out ViewportToolManager manager)
	{
		let scene = page as ISceneEditorPage;
		manager = (scene != null) ? scene.ViewportTools : null;
		return (manager != null) ? manager.FindById(id) : null;
	}

	private void RegisterActions()
	{
		if ((mServices.Context == null) || (mServices.Tools == null))
			return;
		let actions = mServices.Context.Actions;
		let context = mServices.Context;
		// Every tool but the default (Select is the bar's own choice), the first page to have it
		// declaring it; the bindings name the tool by id, so they serve every page.
		for (int i = 1; i < mServices.Tools.Count; i++)
		{
			let tool = mServices.Tools.ToolAt(i);
			let action = ActionOf(tool.Id, .. scope String());
			if (actions.Find(action) != null)
				continue;
			let menuPath = scope String("Scene/Tools/");
			if (!tool.Category.IsEmpty)
				menuPath.AppendF("{}/", tool.Category);
			menuPath.Append(tool.DisplayName);
			let d = new EditorActionDeclaration(action, tool.DisplayName,
				scope $"Use the {tool.DisplayName} tool in the scene view (again: back to Select)", menuPath, 400 + (int32)i);
			d.Icon.Set(tool.Icon);
			d.Kind = .Toggle;
			let id = new String(tool.Id);
			d.Enabled = new [=id] (page) =>
				{
					let found = ToolOf(page, id, let manager);
					return (found != null) && !(page as ISceneEditorPage).IsSimulating && found.IsAvailable;
				} ~ delete id;
			let reasonId = new String(tool.Id);
			d.DisabledReason = new [=reasonId] (page, outReason) =>
				{
					let found = ToolOf(page, reasonId, let manager);
					if (found == null)
						return;
					if ((page as ISceneEditorPage).IsSimulating)
						outReason.Append("Stop the simulation to edit the scene.");
					else if (!found.IsAvailable)
						outReason.Append(found.UnavailableReason);
				} ~ delete reasonId;
			let checkedId = new String(tool.Id);
			d.Checked = new [=checkedId] (page) =>
				{
					let found = ToolOf(page, checkedId, let manager);
					return (found != null) && (manager.ActiveTool == found);
				} ~ delete checkedId;
			let executeId = new String(tool.Id);
			d.Execute = new [=executeId, =context] (page) =>
				{
					let found = ToolOf(page, executeId, let manager);
					if (found == null)
						return;
					if (manager.ActiveTool == found)
						manager.ActivateDefault();
					else if (!manager.ActivateById(executeId))
						context.Notify(.Warning, found.UnavailableReason); // said, not a silent snap-back
				} ~ delete executeId;
			actions.Register(d);
		}
	}

	private void BuildBar()
	{
		let end = mServices.BarEnd;
		let bar = (end != null) ? end.Parent : null;
		if ((bar == null) || (mServices.Tools == null) || (mServices.Context == null) || (mServices.Page == null))
			return;
		mBar = new PageActionBar(mServices.Context.Actions, mServices.Page);
		let groups = scope List<ViewportToolGroup>();
		defer { ClearAndDeleteItems!(groups); }
		ViewportToolGrouping.Group(mServices.Tools, groups);
		for (let group in groups)
		{
			if (group.Category.IsEmpty || (group.ToolIds.Count < 2))
			{
				for (let id in group.ToolIds)
				{
					let tool = mServices.Tools.FindById(id);
					let button = new ToolButton();
					button.IsToggle = true;
					if (!tool.Icon.IsEmpty)
						button.Icon = tool.Icon;
					else
						button.ShowsText = true;
					Insert(bar, end, button);
					mBar.Bind(button, ActionOf(id, .. scope String()));
					mButtons.Add(button);
				}
				continue;
			}
			// A category: one menu by its first tool's icon, each tool an item.
			let menuButton = new ToolMenuButton();
			menuButton.IsToggle = true; // lit while one of its tools is on
			let first = mServices.Tools.FindById(group.ToolIds[0]);
			if ((first != null) && !first.Icon.IsEmpty)
				menuButton.Icon = first.Icon;
			else
			{
				menuButton.Text = group.Category;
				menuButton.ShowsText = true;
			}
			menuButton.Tooltip = scope $"{group.Category} tools";
			let category = new Category();
			category.Name.Set(group.Category);
			category.Button = menuButton;
			let actions = mServices.Context.Actions;
			let page = mServices.Page;
			for (let id in group.ToolIds)
			{
				let tool = mServices.Tools.FindById(id);
				let action = ActionOf(id, .. new String());
				let item = menuButton.Menu.AddCheckItem(tool.DisplayName, false, new [=actions, =page, =action] (on) =>
					{
						actions.Execute(action, page).IgnoreError();
					} ~ delete action);
				category.Ids.Add(new String(id));
				category.Items.Add(item);
			}
			Insert(bar, end, menuButton);
			mButtons.Add(menuButton);
			mCategories.Add(category);
		}
	}

	// `button` in `bar`, before `end`.
	private static void Insert(Node bar, Node end, ButtonBase button)
	{
		int32 at = 0;
		while ((at < bar.ChildCount) && (bar.GetChildAt(at) != end))
			at++;
		bar.AddChildAt(button, at);
	}

	private void BuildChrome()
	{
		mChrome = new Panel();
		mChrome.AddClass("hud-panel");
		mChrome.AddClass("tool-panel");
		mHead = new ToolPanelHead();
		mIcon = new Image();
		mIcon.AddClass("row-icon");
		mHead.AddChild(mIcon);
		mIcon.ReleaseRef(); // the head's keeps it
		mTitle = new Label();
		mTitle.AddClass("hud-panel-title");
		mHead.AddChild(mTitle);
		mTitle.ReleaseRef();
		let spacer = new Panel();
		spacer.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		mHead.AddChild(spacer);
		spacer.ReleaseRef();
		mFold = new Sedulous.GUI.Button();
		mFold.AddClass("slot-button");
		mFold.Icon = "Editor/Icons/chevron-down.svg";
		mFold.Tooltip = "Fold the panel to its title";
		mFold.SetOnClick(new () => { SetFolded(!mFolded); });
		mHead.AddChild(mFold);
		mFold.ReleaseRef();
		let close = new Sedulous.GUI.Button();
		close.AddClass("slot-button");
		close.Icon = "Editor/Icons/close.svg";
		close.Tooltip = "Close the tool (back to Select)";
		close.SetOnClick(new () =>
			{
				if (mServices.Tools != null)
					mServices.Tools.ActivateDefault();
			});
		mHead.AddChild(close);
		close.ReleaseRef();
		mHead.Tooltip = "Drag to move; double-click to put it back under the view's chips";
		mChrome.AddChild(mHead);

		mHead.DragStarted = new () =>
			{
				// From where it stands (under the chips until it was moved).
				mMoved = true;
				mDragFrom = mPlace;
			};
		mHead.Dragged = new (delta) =>
			{
				mPlace = mDragFrom + delta;
				Clamp();
			};
		mHead.DragEnded = new () => { PlaceChanged(); };
		mHead.ResetAsked = new () =>
			{
				SetPlace(null);
				PlaceChanged();
			};
	}

	private void PlaceChanged()
	{
		if (mServices.PlaceChanged != null)
			mServices.PlaceChanged();
	}

	private void Mount(Node panel, IViewportTool tool)
	{
		mBody = panel;
		mBody.Displayed = !mFolded;
		mChrome.AddChild(mBody);
		mTitle.Text = tool.DisplayName;
		mIcon.Displayed = !tool.Icon.IsEmpty;
		if (!tool.Icon.IsEmpty)
			mIcon.Source = tool.Icon;
		mPanelShown = true;
		Reparent();
	}

	private void Clear()
	{
		if (mBody != null)
		{
			mBody.RemoveFromParent();
			mBody = null;
		}
		if ((mChrome != null) && (mChrome.Parent != null))
			mChrome.RemoveFromParent();
		mPanelShown = false;
	}

	// In the viewport's room (a stack), at its top start, its place its margins: always there, so
	// a drag never takes it out of the tree under the pointer.
	private void Reparent()
	{
		if (!mPanelShown || (mServices.Pane == null))
			return;
		if (mChrome.Parent != mServices.Pane)
		{
			if (mChrome.Parent != null)
				mChrome.RemoveFromParent();
			mServices.Pane.AddChild(mChrome);
			mChrome.EditLayoutStyle(scope (s) =>
				{
					s.AlignSelf = .Start;
					s.JustifySelf = .Start;
				});
		}
		Clamp();
	}

	// Under the chips while it has not moved (the zone's content edge, below the zone); else its
	// place, kept inside the viewport (which may have shrunk since).
	private void Clamp()
	{
		if (mServices.Pane == null)
			return;
		let pane = mServices.Pane.ScreenBounds;
		if (!mMoved && (mServices.Zone != null))
		{
			let zone = mServices.Zone.ScreenBounds;
			mPlace = .(zone.X - pane.X + mServices.Zone.ContentBounds.X, zone.Y + zone.Height - pane.Y);
		}
		let size = mChrome.Size;
		mPlace.X = Math.Max(0.0f, Math.Min(mPlace.X, pane.Width - size.X));
		mPlace.Y = Math.Max(0.0f, Math.Min(mPlace.Y, pane.Height - size.Y));
		let now = mChrome.LayoutStyle.Margin;
		if ((now.Left != mPlace.X) || (now.Top != mPlace.Y))
		{
			let place = mPlace;
			mChrome.EditLayoutStyle(scope [&] (s) => { s.Margin = .(place.X, place.Y, 0.0f, 0.0f); });
		}
	}
}
