using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Image;
using Sedulous.RHI;

namespace Samples.GUISandbox;

/// The hosts the pages leave to native code: a generated image, the viewport's cube, drag and
/// drop, the data views over native models, the menu bar and the context menu, the dock space,
/// and (SandboxToolkit.bf) the Toolkit page's sources.
extension GUISandboxApp
{
	// What native hosts hold. The models are ours (the views borrow them, so they go after the
	// root); the context menu and the dock space are references of ours.
	private OwnedImageData mChecker = null ~ delete _;
	private StringListModel mListModel = null ~ delete _;
	/// Rows the Data views page inserted at the top.
	private int32 mInsertedRows = 0;
	private TableModel mTableModel = null ~ delete _;
	private SortingProxyModel mTableProxy = null ~ delete _;
	private TreeModel mTreeModel = null ~ delete _;
	private Menu mContextMenu = null;

	// === The Docking page ===

	/// The layout's owner: after the dock space that shows it.
	private DockController mDock = null ~ delete _;
	private DockArea mDockArea = null;
	/// The floats in OS windows, while switched on.
	private DockHostWindows mDockWindows = null ~ delete _;
	/// The registered panels' ids, for "Show the closed panels".
	private List<String> mDockPanels = new .() ~ DeleteContainerAndItems!(_);
	/// How often each panel's content was made (its close policy shows).
	private uint32[8] mDockMade = .();

	private void FillNativeHosts()
	{
		// Controls: a generated image.
		if (let host = FindById(mShellNode, "controls-image"))
		{
			uint8[16 * 16 * 4] pixels = ?;
			for (int32 y = 0; y < 16; y++)
			{
				for (int32 x = 0; x < 16; x++)
				{
					let o = (y * 16 + x) * 4;
					let checker = (((x / 4) + (y / 4)) % 2) == 0;
					pixels[o + 0] = (uint8)(checker ? 40 + x * 12 : 20);
					pixels[o + 1] = (uint8)(checker ? 90 : 40 + y * 12);
					pixels[o + 2] = (uint8)(checker ? 160 : 80);
					pixels[o + 3] = 255;
				}
			}
			mChecker = new OwnedImageData(16, 16, .RGBA8, .(&pixels[0], pixels.Count));
			let view = new Sedulous.GUI.Image();
			view.Size = (host.Size.X > 0.0f) ? host.Size : .(160.0f, 160.0f);
			let drawable = new ImageDrawable(mChecker);
			view.SetDrawable(drawable);
			drawable.ReleaseRef(); // the image's keeps it
			view.Fit = .Contain;
			view.Tooltip = "An Image from code: a generated picture, object-fit: contain";
			host.AddChild(view);
			view.ReleaseRef(); // the tree's keeps it
		}

		// Docking: a dock space over a controller.
		if (let host = FindById(mShellNode, "docking-host"))
			FillDocking(host);
		// Toolkit: the tool bars' commands, their keys and the status bar's messages.
		if (let frame = FindById(mShellNode, "toolkit-frame"))
			FillToolkit(frame);
		// Toolkit: the property grid over three lamps.
		if (let grid = FindById(mShellNode, "props-grid") as PropertyGrid)
			FillProperties(grid);
		// Toolkit: a reflected object's grid.
		if (let grid = FindById(mShellNode, "reflected-grid") as PropertyGrid)
			FillReflected(grid);
		// Toolkit: a clip of the lamps' values in a dopesheet and a curve view, after the lamps.
		if (let section = FindById(mShellNode, "clip-section"))
			FillClip(section);
		// Toolkit: a dataflow graph and a lamp's state machine, after the clip.
		if (let section = FindById(mShellNode, "graph-section"))
			FillGraphs(section);
		// Code: a game's Beef code and a shader, in the shared languages.
		if (let editor = FindById(mShellNode, "code-source") as CodeEditor)
		{
			let dir = scope $"{cSandboxDir}code/"; // the sandbox's samples
			let languages = "Editor/Code/"; // the languages, the editor's too
			mCode = new CodePage();
			mCode.AttachSource(editor, ReadText(scope $"{languages}beef.xml", .. scope String()),
				ReadText(scope $"{dir}sample.bf", .. scope String()));
			if (let shader = FindById(mShellNode, "code-shader") as CodeEditor)
				mCode.AttachShader(shader, ReadText(scope $"{languages}hlsl.xml", .. scope String()), ReadText(scope $"{dir}sample.hlsl", .. scope String()));
		}
		if (let section = FindById(mShellNode, "crumbs-section"))
			FillCrumbs(section);
		if (let section = FindById(mShellNode, "toasts-section"))
			FillToasts(section);

		FillViewport();
		FillDragAndDrop();
		FillDataViews();
		FillMenus();
	}

	/// Viewport: a cube drawn into the widget's targets, under the page's note.
	private void FillViewport()
	{
		let host = FindById(mShellNode, "viewport-host");
		if (host == null)
			return;
		mViewport = new Viewport();
		mViewport.AddClass("viewport-scene");
		host.AddChildAt(mViewport, 0); // under the note
		mViewport.ReleaseRef(); // the tree's keeps it
		mViewport.HostIn(mGuiHost);
		mViewport.OnRender = new (viewport, encoder, frameIndex) =>
			{
				let width = viewport.RenderWidth;
				let height = viewport.RenderHeight;
				let aspect = (float)width / (float)Math.Max(height, 1U);
				let projection = Float4x4.PerspectiveFovRH(1.0f, aspect, 0.1f, 100.0f);
				let view = Float4x4.LookAtRH(mCamera.Position, mCamera.Position + mCamera.Forward, mCamera.Up);
				let model = Float4x4.RotationY(mSpin) * Float4x4.RotationX(mSpin * 0.5f);
				// Row vectors: v * M * V * P.
				mCube.Render(encoder, viewport.ColorView, viewport.DepthView, width, height, viewport.LinearClearColor,
					model * view * projection, frameIndex);
			};
		mRoot.OnCommand("viewport.reset", new (e) => { ResetCamera(); });
		mRoot.OnCommand("viewport.fit", new (e) =>
			{
				// A fixed 16:9 picture letterboxed in the widget, or the widget's own pixels.
				let fixedSize = mViewport.FitMode != .Letterbox;
				mViewport.SetFixedResolution(fixedSize ? 1280U : 0U, fixedSize ? 720U : 0U);
				mViewport.FitMode = fixedSize ? .Letterbox : .Stretch;
				if (let button = FindById(mShellNode, "viewport-fit") as Sedulous.GUI.Button)
					button.Text = fixedSize ? "Follow the widget" : "Letterbox at 16:9";
			});
		ResetCamera();
	}

	/// Drag and drop: the cards are sources, the bins targets; the hand takes cards, the discard
	/// pile refuses aces with a reason; the chip goes nowhere.
	private void FillDragAndDrop()
	{
		let said = FindById(mShellNode, "dnd-said") as Sedulous.GUI.Label;
		StringView[3] cards = .("dnd-ace", "dnd-king", "dnd-chip");
		for (let id in cards)
		{
			let card = FindById(mShellNode, id);
			if (card == null)
				continue;
			let chip = id == "dnd-chip";
			card.TabFocusable = true; // Ctrl+Shift+D or the pad's North picks it up
			let label = card as Sedulous.GUI.Label;
			card.SetDragSource(new (r) =>
				{
					r.Payload.Type.Set(chip ? "chip" : "card");
					r.Payload.Label.Set((label != null) ? label.Text : StringView());
					r.Payload.Value.Dispose();
					r.Payload.Value = TextVariant(r.Payload.Label);
					return true;
				});
			card.SetOnDragEnd(new (r) =>
				{
					if (label == null)
						return;
					// The card goes where it was dropped (a move), or a copy of it does.
					if ((r.Target != null) && (r.Effect == .Move))
						r.Target.ChildHost.AddChild(label);
					else if ((r.Target != null) && (r.Effect == .Copy))
					{
						let copy = new Sedulous.GUI.Label();
						copy.Text = label.Text;
						copy.AddClass("dnd-card");
						r.Target.ChildHost.AddChild(copy);
						copy.ReleaseRef(); // the tree's keeps it
					}
					if (said == null)
						return;
					StringView how = "dropped nowhere";
					if (r.Cancelled)
						how = "cancelled";
					else if (r.Effect == .Copy)
						how = "copied";
					else if (r.Effect == .Move)
						how = "moved";
					else if (r.Effect == .Link)
						how = "linked";
					said.Text = scope $"{label.Text}: {how}";
				});
		}
		StringView[3] targets = .("dnd-hand", "dnd-discard", "dnd-files");
		for (let id in targets)
		{
			if (let target = FindById(mShellNode, id))
				target.TabFocusable = true; // a keyboard drag goes where the focus goes
		}
		if (let hand = FindById(mShellNode, "dnd-hand"))
		{
			hand.SetOnDragQuery(new (q) =>
				{
					if (q.Payload.Type != "card")
						return;
					q.Accept();
					q.Reason.Set((q.Effect == .Copy) ? "Copy it to the hand" : "Move it to the hand");
				});
		}
		// Files from the OS: the files pile takes them; dropped anywhere else, the GUI's own handler
		// says so.
		if (let files = FindById(mShellNode, "dnd-files"))
		{
			files.DropTypes = "files";
			files.AddEventListener(.Drop, new (e) =>
				{
					let drag = e as DragEvent;
					if ((drag == null) || (said == null))
						return;
					let paths = scope List<String>();
					defer { ClearAndDeleteItems!(paths); }
					DroppedPaths(drag.Payload, paths);
					if (!paths.IsEmpty)
						said.Text = scope $"Dropped {paths.Count} file(s), the first {paths[0]}";
				});
		}
		mRoot.EventDispatcher.SetOnFileDrop(new (paths, at) =>
			{
				if (said != null)
					said.Text = scope $"{paths.Length} file(s) dropped where nothing takes them";
				return true;
			});
		StringView[2] piles = .("dnd-long", "dnd-hidden");
		for (let id in piles)
		{
			if (let pile = FindById(mShellNode, id))
				pile.DropTypes = "card";
		}
		if (let discard = FindById(mShellNode, "dnd-discard"))
		{
			discard.SetOnDragQuery(new (q) =>
				{
					if (q.Payload.Type != "card")
						return;
					if (q.Payload.Label.StartsWith("Ace"))
						q.Refuse("The discard pile takes no aces");
					else
					{
						q.Accept(.Move);
						q.Reason.Set("Discard it");
					}
				});
		}
	}

	/// Data views over native models.
	private void FillDataViews()
	{
		if (let host = FindById(mShellNode, "views-list"))
		{
			mListModel = new StringListModel();
			let texts = scope List<String>();
			defer { ClearAndDeleteItems!(texts); }
			let rows = scope List<StringView>();
			for (int i < 500)
			{
				let text = new String()..AppendF("Row {}", i);
				texts.Add(text);
				rows.Add(text);
			}
			mListModel.SetItems(rows); // copied
			let list = new ListView();
			list.Size = .(320.0f, 180.0f);
			list.Font = mFont;
			list.RowHeight = 24.0f;
			list.Model = mListModel;
			mListModel.Editable = true; // F2 renames a row
			list.DragType = "row"; // rows drag to reorder
			let picked = FindById(mShellNode, "views-picked") as Sedulous.GUI.Label;
			let model = mListModel;
			list.SetOnSelectionChanged(new (index) =>
				{
					if ((picked != null) && index.IsValid)
						picked.Text = scope $"picked: {model.ItemAt(index.Row)}";
				});
			list.SetOnActivated(new (index) =>
				{
					if ((picked != null) && index.IsValid)
						picked.Text = scope $"activated: {model.ItemAt(index.Row)}";
				});
			host.AddChild(list);
			list.ReleaseRef(); // the tree's keeps it
			if (let insert = FindById(mShellNode, "views-insert") as Sedulous.GUI.Button)
			{
				insert.SetOnClick(new () =>
					{
						mInsertedRows++;
						model.InsertItem(0, scope $"Inserted {mInsertedRows}");
					});
			}
		}
		if (let host = FindById(mShellNode, "views-table"))
		{
			mTableModel = new TableModel();
			mTableModel.SetColumns(scope StringView[]("Name", "Score"));
			StringView[6] names = .("Ivy", "Cara", "Bo", "Ada", "Eve", "Dan");
			int64[6] scores = .(42, 7, 91, 15, 68, 30);
			for (int i < 6)
			{
				Sedulous.GUI.Variant[2] cells = .(.(names[i]), .(scores[i]));
				mTableModel.AddRow(cells); // copied
			}
			mTableModel.Editable = true; // F2 edits a name
			mTableProxy = new SortingProxyModel(mTableModel);
			let table = new TableView();
			table.Size = .(320.0f, 180.0f);
			table.Font = mFont;
			table.RowHeight = 24.0f;
			table.Model = mTableProxy; // a header click sorts through the proxy (the model's sort capability)
			table.ColumnWidthsText = "60% auto";
			host.AddChild(table);
			table.ReleaseRef(); // the tree's keeps it
		}
		if (let host = FindById(mShellNode, "views-tree"))
		{
			mTreeModel = new TreeModel();
			let code = mTreeModel.AddNode(TreeModel.Root, "Code");
			let experimental = mTreeModel.AddNode(code, "Experimental");
			mTreeModel.AddNode(experimental, "GUI");
			mTreeModel.AddNode(experimental, "GUI.Sandbox");
			let foundation = mTreeModel.AddNode(code, "Foundation");
			mTreeModel.AddNode(foundation, "VG");
			mTreeModel.AddNode(foundation, "Physics");
			let data = mTreeModel.AddNode(TreeModel.Root, "Data");
			mTreeModel.AddNode(data, "Assets");
			let tree = new TreeView();
			tree.Size = .(320.0f, 180.0f);
			tree.Font = mFont;
			tree.RowHeight = 24.0f;
			tree.Model = mTreeModel;
			tree.DragType = "node"; // nodes drag onto and beside others
			tree.ExpandItem(0);
			host.AddChild(tree);
			tree.ReleaseRef(); // the tree's keeps it
		}
	}

	/// A menu item's action: it says what was picked through the data (`what` is a literal).
	private delegate void() MenuSaid(StringView what)
	{
		let data = mGui.Data;
		return new () =>
			{
				var text = TextVariant(what);
				data.Set("menu", text);
				text.Dispose();
			};
	}

	/// Menus: a menu bar and a context menu, each saying what was picked through the data.
	private void FillMenus()
	{
		if (let host = FindById(mShellNode, "menus-bar"))
		{
			let bar = new MenuBar();
			bar.Size = .(590.0f, 28.0f);
			bar.Font = mFont;
			let file = bar.AddMenu("File");
			file.AddItem("New", MenuSaid("File > New"));
			file.AddItem("Open...", MenuSaid("File > Open"));
			file.AddSeparator();
			file.AddItem("Close", MenuSaid("File > Close"));
			let edit = bar.AddMenu("Edit");
			edit.AddItem("Undo", MenuSaid("Edit > Undo")).Shortcut = "Ctrl+Z";
			edit.AddItem("Redo", MenuSaid("Edit > Redo")).Shortcut = "Ctrl+Y";
			let insert = edit.AddSubMenu("Insert");
			insert.AddItem("Image", MenuSaid("Edit > Insert > Image"));
			insert.AddItem("Table", MenuSaid("Edit > Insert > Table"));
			let view = bar.AddMenu("View");
			let data = mGui.Data;
			view.AddCheckItem("Show grid", true, new (on) =>
				{
					var text = TextVariant(on ? "grid on" : "grid off");
					data.Set("menu", text);
					text.Dispose();
				});
			host.AddChild(bar);
			bar.ReleaseRef(); // the tree's keeps it
		}
		if (let area = FindById(mShellNode, "menus-context"))
		{
			for (int i = 0; i < area.ChildCount; i++)
				area.GetChildAt(i).HitTestVisible = false; // the hint lets the click reach the box
			mContextMenu = new Menu();
			mContextMenu.Font = mFont;
			mContextMenu.SetWidth(200.0f);
			mContextMenu.AddItem("Cut", MenuSaid("context > Cut")).Shortcut = "Ctrl+X";
			mContextMenu.AddItem("Copy", MenuSaid("context > Copy")).Shortcut = "Ctrl+C";
			mContextMenu.AddSeparator();
			let more = mContextMenu.AddSubMenu("More");
			more.Font = mFont;
			more.SetWidth(140.0f);
			more.AddItem("Rename", MenuSaid("context > More > Rename"));
			let menu = mContextMenu;
			// A right release, a long press or Shift+F10 asks for it.
			area.AddEventListener(.ContextMenu, new (e) =>
				{
					let mouse = e as MouseEvent;
					if (mouse == null)
						return;
					e.Handled = true;
					menu.Open(area, area.RootNode.ConvertToNodeSpace(mouse.Position));
				});
		}
	}

	/// The Docking page's layout as it starts and resets: the scene in the middle, the hierarchy
	/// on the left, the inspector on the right, the console, the log and the assets under the
	/// scene, and a profiler the layout names before it is registered (a placeholder until it
	/// is). The caller owns it.
	private static DockLayout DefaultDockLayout()
	{
		let layout = new DockLayout();
		let central = layout.CentralStack;
		layout.InsertTab("scene", central);
		layout.InsertBeside("hierarchy", central, .Start, 0.22f);
		layout.InsertBeside("inspector", central, .End, 0.3f);
		layout.InsertBeside("console", central, .Bottom, 0.34f);
		let bottom = layout.StackOf("console");
		layout.InsertTab("log", bottom);
		layout.InsertTab("assets", bottom);
		layout.InsertTab("profiler", bottom);
		layout.Activate("console");
		layout.Float("assets", .(350.0f, 70.0f, 220.0f, 160.0f)); // a float, over them
		return layout;
	}

	private void RegisterDockPanel(StringView id, StringView title, DockClosePolicy close, StringView line)
	{
		let index = mDockPanels.Count;
		mDockPanels.Add(new String(id));
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(title);
		description.Close = close;
		description.Closable = id != "scene";
		description.Default.Central = id == "scene";
		StringView policy = default;
		switch (close)
		{
		case .Hide: policy = "closing hides it, its content kept";
		case .Rebuild: policy = "closing lets its content go; shown again, it is made anew";
		case .Destroy: policy = "closing forgets it, its place too";
		}
		let text = new String(line);
		let note = new String(description.Closable ? policy : "it cannot be closed");
		description.Factory = new () =>
			{
				mDockMade[index]++;
				let content = new Panel();
				content.AddClass("dock-content");
				content.EditLayoutStyle(scope (s) => { s.Direction = .Column; });
				let made = scope String()..AppendF("Made {} time{}.", mDockMade[index], (mDockMade[index] == 1) ? "" : "s");
				StringView[3] lines = .(text, note, made);
				for (let l in lines)
				{
					let label = new Sedulous.GUI.Label();
					label.Text = l;
					content.AddChild(label);
					label.ReleaseRef(); // the panel's keeps it
				}
				return content; // its one reference, the controller's
			} ~ { delete text; delete note; };
		mDock.Register(description);
	}

	private void FillDocking(Node host)
	{
		DefineDockingCommands(mGui);
		mDock = new DockController();
		RegisterDockPanel("scene", "Scene", .Hide, "The central stack: it stays when every tab leaves it.");
		RegisterDockPanel("hierarchy", "Hierarchy", .Hide, "World, Camera, Light, Cube.");
		RegisterDockPanel("inspector", "Inspector", .Hide, "The cube: position 0 0 0, spin 1.");
		RegisterDockPanel("console", "Console", .Rebuild, "> ready");
		RegisterDockPanel("log", "Log", .Hide, "Loaded the sandbox.");
		RegisterDockPanel("assets", "Assets", .Destroy, "cube.glb, sky.png, theme.css.");
		{
			let layout = DefaultDockLayout();
			defer delete layout;
			mDock.Adopt(layout);
		}
		mDockArea = new DockArea();
		host.AddChild(mDockArea);
		mDockArea.Show(mDock);

		mRoot.OnCommand("docking.reset", new (e) =>
			{
				// The default layout's float stands in the area's units: adopted there, then taken
				// back to its own window when floats are.
				let own = mDockWindows != null;
				SetDockWindows(false);
				let layout = DefaultDockLayout();
				mDock.Adopt(layout);
				delete layout;
				SetDockWindows(own);
			});
		// The floats in the area or in OS windows of their own, where the host opens windows.
		mRoot.OnCommand("docking.os-windows", new (e) => { SetDockWindows(mDockWindows == null); });
		mRoot.OnCommand("docking.show-closed", new (e) =>
			{
				for (let id in mDockPanels)
				{
					if (mDock.Layout.StackOf(id) == cNoDock)
						mDock.Show(id);
				}
			});
		mRoot.OnCommand("docking.register", new (e) =>
			{
				if (mDock.Describe("profiler") == null)
					RegisterDockPanel("profiler", "Profiler", .Hide, "Registered late: it fills the place the layout kept for it.");
			});
		// What a torn tab leaves, both to try: its strip closing up, or it dimmed in place (the
		// page's sheet, for every dock space in the area: the floats' too).
		mRoot.OnCommand("docking.torn-tab", new (e) =>
			{
				let holder = host as UIWidget;
				if (holder == null)
					return;
				let dim = holder.HasClass("torn-close");
				if (dim)
					holder.RemoveClass("torn-close");
				else
					holder.AddClass("torn-close");
				let page = (host.Parent != null) ? host.Parent.Parent : null;
				if (let button = FindById(page, "docking-torn") as Sedulous.GUI.Button)
					button.Text = dim ? "A torn tab dims" : "A torn tab closes up";
			});
	}

	/// The Docking page's floats in OS windows of their own (`own`), or in the area. A window's
	/// root is styled as the page is, its sheet scoped to the page reaching no other root.
	private void SetDockWindows(bool own)
	{
		if ((mDockArea == null) || (own == (mDockWindows != null)))
			return;
		if (own)
		{
			if (!mGuiHost.CanOpenWindows)
				return;
			mDockWindows = new DockHostWindows(mGuiHost, mDockArea);
			mDockWindows.SetOnRootMade(new (root) =>
				{
					for (let page in mPages)
					{
						if (page.Id != "docking")
							continue;
						let sheet = scope StyleSheet();
						CSSParser.Parse(page.Sheet, "pages/docking.css", sheet);
						mStyles.SetSubtreeSheet(root, sheet);
					}
				});
			mDockArea.SetWindows(mDockWindows);
			if (mDockArea.Windows == null)
				DeleteAndNullify!(mDockWindows); // a window would not open: the floats stayed in the area
		}
		else
		{
			mDockArea.SetWindows(null);
			DeleteAndNullify!(mDockWindows);
		}
		if (let button = FindById(mRoot, "docking-windows") as Sedulous.GUI.Button)
			button.Text = (mDockWindows != null) ? "Floats in OS windows" : "Floats in the window";
	}

	/// Our references to what the tree holds, let go of before the root goes.
	private void ReleaseNativeHosts()
	{
		if (mContextMenu != null)
		{
			mContextMenu.ReleaseRef();
			mContextMenu = null;
		}
		if (mDockArea != null)
		{
			mDockArea.ReleaseRef();
			mDockArea = null;
		}
	}

	/// The models and the dock controller, after the root: the views and the dock space that
	/// read them are gone.
	private void ReleaseModels()
	{
		DeleteAndNullify!(mDock);
		DeleteAndNullify!(mTableProxy); // before the model it reads
		DeleteAndNullify!(mTableModel);
		DeleteAndNullify!(mListModel);
		DeleteAndNullify!(mTreeModel);
		DeleteAndNullify!(mChecker);
	}
}
