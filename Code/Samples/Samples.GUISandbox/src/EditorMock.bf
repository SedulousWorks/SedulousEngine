using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Samples.GUISandbox;

// The editor mock (X0 of Raptor's Specs/editor-gui.md): the editor's frame and scene page, static,
// in the editor's sheet (Data/Editor/editor.css over its tokens), for judging the design before any
// editor code moves. `GUISandbox --editor-mock` shows it instead of the sandbox. The markup is
// Data/Editor/Mock's; what is here is what markup cannot say: the dock, the commands with their
// keys, the inspector's grid, and the Look menu, which stands in for Preferences' appearance inputs
// (the scheme, the density, the accent, less motion) the way the editor will set them: a `:root`
// block of inputs after the editor's sheet.

/// The editor's frame over a root of the sandbox's GUI. The frame and the dock space are the tree's
/// (our references let go of by ReleaseTree, before the root goes); the dock controller, the
/// inspectors' sources and what they show are ours, deleted after the root, as the views that read
/// them have gone with it.
class EditorMock
{
	/// What the mock asks of its host: markup and text by their path under the data folder.
	public class Host
	{
		/// A tree from the markup at a path, with one reference (the caller's); null when it does
		/// not load.
		public delegate Node(StringView path) Load ~ delete _;
		/// The text at a path, appended to the string given; nothing when it does not read.
		public delegate void(StringView path, String outText) Read ~ delete _;
	}

	// The candidates for the editor's new accent (ruling 7), each a fill white text reads on.
	private static (String Command, String Label, String Fill)[4] sAccents = .(
		("look.azure", "Azure", "#2f6fdf"),
		("look.violet", "Violet", "#6d5bd8"),
		("look.teal", "Teal", "#0f8a7e"),
		("look.magenta", "Magenta", "#b03d93"));
	// Each density's sizes in whole pixels, added after the editor's sheet.
	private static (String Command, String Label, String Sheet)[3] sDensities = .(
		("look.compact", "Compact", "Editor/density-compact.css"),
		("look.default", "Default", "Editor/density-default.css"),
		("look.comfortable", "Comfortable", "Editor/density-comfortable.css"));

	private GUIContext mContext;
	private SceneRoot mRoot;
	private StyleManager mStyles;
	private Host mHost ~ delete _;
	/// Our reference to the frame, besides the root's.
	private Node mFrame = null;
	private DockController mDock = null;
	/// Our reference to the dock space, besides the frame's.
	private DockArea mDockArea = null;
	/// The kit page's content, once the dock has made it: our reference, let go by ReleaseTree.
	private Node mKit = null;
	/// What each page's inspector shows, and the sources over them.
	private List<Object> mShown = new .();
	private List<ReflectedPropertySource> mSources = new .();
	private bool mDark = true;
	/// Compact, the editor's default (ruling).
	private int mDensity = 0;
	private int mAccent = 0;
	private bool mReduceMotion = false;
	private bool mSideBySide = false;

	/// `host`: OWNERSHIP transfers. The context, the root and the styles are borrowed.
	public this(GUIContext context, SceneRoot root, StyleManager styles, Host host)
	{
		mContext = context;
		mRoot = root;
		mStyles = styles;
		mHost = host;
	}

	public ~this()
	{
		ReleaseTree();
		// The controller first: the panels' contents it keeps go with it, and their grids leave
		// their sources as they go; the sources, then what they show.
		DeleteAndNullify!(mDock);
		DeleteContainerAndItems!(mSources);
		DeleteContainerAndItems!(mShown);
	}

	/// Our references to what the tree holds, let go of before the root goes.
	public void ReleaseTree()
	{
		if (mKit != null)
		{
			mKit.ReleaseRef();
			mKit = null;
		}
		if (mDockArea != null)
		{
			mDockArea.ReleaseRef();
			mDockArea = null;
		}
		if (mFrame != null)
		{
			mFrame.ReleaseRef();
			mFrame = null;
		}
	}

	/// The frame under the root, its panels in the dock, the editor's sheet applied. False when
	/// the frame's markup does not load.
	public bool Build()
	{
		mFrame = mHost.Load("Editor/Mock/frame.gml");
		if (mFrame == null)
			return false;
		mRoot.AddChild(mFrame);
		DefineCommands();
		BuildDock();
		ApplyLook();
		return true;
	}

	/// The kit page in front (--mock-kit): every shared piece in its states.
	public void ShowKit()
	{
		if (mDock != null)
			Said(mDock.Edit(scope (layout) => layout.Activate("kit")));
	}

	/// The kit page scrolled down this far (--scroll, for a screenshot further down).
	public void ScrollKit(float pixels)
	{
		if (mKit == null)
			return;
		if (let scroll = mKit.FindElement("kit-scroll"))
			scroll.ScrollOffset = .(0.0f, pixels);
	}

	/// The two scene pages side by side, or tabbed in one stack (the default).
	public void SetSideBySide(bool side)
	{
		if (mDock != null)
		{
			let layout = DefaultLayout(side);
			defer delete layout;
			Said(mDock.Adopt(layout));
		}
		mContext.DefineCommand("mock.side-by-side").Checked = side;
		mSideBySide = side;
	}

	/// The scheme from the start (--light).
	public void SetDark(bool dark)
	{
		mDark = dark;
		ApplyLook();
	}

	private void Define(StringView id, StringView label, StringView keys = default, StringView icon = default)
	{
		let command = mContext.DefineCommand(id);
		command.Label = label;
		if (icon.Length != 0)
			command.Icon = icon;
		if (keys.Length != 0)
			mContext.Keymap.Bind(keys, id);
	}

	private void DefineCommands()
	{
		// What the mock's menus and bars name. They do nothing but say so: the mock is a picture.
		Define("mock.new-scene", "New Scene", "ctrl-n");
		Define("mock.open", "Open...", "ctrl-o");
		Define("mock.save", "Save", "ctrl-s", "Editor/Icons/save.svg");
		Define("mock.save-all", "Save All", "ctrl-shift-s");
		Define("mock.exit", "Exit");
		Define("mock.undo", "Undo", "ctrl-z", "Editor/Icons/undo.svg");
		Define("mock.redo", "Redo", "ctrl-shift-z", "Editor/Icons/redo.svg");
		Define("mock.preferences", "Preferences...", "ctrl-comma", "Editor/Icons/settings.svg");
		Define("mock.view-assets", "Assets");
		Define("mock.view-console", "Console");
		Define("mock.view-profiler", "Profiler");
		Define("mock.palette", "Command Palette...", "ctrl-shift-p");
		Define("mock.side-by-side", "Pages Side by Side");
		Define("mock.play", "Play", "f5", "Editor/Icons/play.svg");
		Define("mock.pause", "Pause", "f6", "Editor/Icons/pause.svg");
		Define("mock.stop", "Stop", "shift-f5", "Editor/Icons/stop.svg");
		Define("mock.frame", "Frame Selection", "f", "Editor/Icons/frame-selection.svg");
		Define("mock.grid", "Grid", default, "Editor/Icons/grid.svg");
		Define("mock.snap", "Snap", default, "Editor/Icons/magnet.svg");
		Define("mock.space", "World Space", default, "Editor/Icons/world.svg");
		Define("mock.view-lit", "Lit");
		Define("mock.view-unlit", "Unlit");
		Define("mock.view-wire", "Wireframe");
		Define("mock.about", "About AssiduousEngine");
		mContext.DefineCommand("mock.grid").Checked = true;
		mContext.DefineCommand("mock.space").Checked = true;
		let pause = mContext.DefineCommand("mock.pause");
		pause.Enabled = false;
		pause.DisabledReason = "Nothing is playing";
		let stop = mContext.DefineCommand("mock.stop");
		stop.Enabled = false;
		stop.DisabledReason = "Nothing is playing";

		// The Look menu: Preferences' appearance inputs, here to compare.
		mRoot.OnCommand("mock.side-by-side", new (e) => { SetSideBySide(!mSideBySide); });
		Define("look.dark", "Dark");
		Define("look.light", "Light");
		mRoot.OnCommand("look.dark", new (e) =>
			{
				mDark = true;
				ApplyLook();
			});
		mRoot.OnCommand("look.light", new (e) =>
			{
				mDark = false;
				ApplyLook();
			});
		for (int i < sDensities.Count)
		{
			let index = i;
			Define(sDensities[i].Command, sDensities[i].Label);
			mRoot.OnCommand(sDensities[i].Command, new (e) =>
				{
					mDensity = index;
					ApplyLook();
				});
		}
		for (int i < sAccents.Count)
		{
			let index = i;
			Define(sAccents[i].Command, sAccents[i].Label);
			mRoot.OnCommand(sAccents[i].Command, new (e) =>
				{
					mAccent = index;
					ApplyLook();
				});
		}
		Define("look.motion", "Reduce Motion");
		mRoot.OnCommand("look.motion", new (e) =>
			{
				mReduceMotion = !mReduceMotion;
				ApplyLook();
			});
	}

	// The editor's sheet, the density's after it, then the inputs; the scheme and motion through
	// the media.
	private void ApplyLook()
	{
		let text = scope String();
		mHost.Read("Editor/editor.css", text);
		text.Append("\n");
		mHost.Read(sDensities[mDensity].Sheet, text);
		text.Append("\n");
		mHost.Read("Editor/Mock/kit.css", text); // the kit page's own layout
		text.AppendF("\n:root {{ --accent-input: {}; }}\n", sAccents[mAccent].Fill);
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, "Editor/editor.css", sheet);
		mStyles.StyleSheet = sheet; // copied
		mContext.DarkScheme = mDark;
		mContext.ReducedMotion = mReduceMotion;
		mContext.DefineCommand("look.dark").Checked = mDark;
		mContext.DefineCommand("look.light").Checked = !mDark;
		for (int i < sDensities.Count)
			mContext.DefineCommand(sDensities[i].Command).Checked = i == mDensity;
		for (int i < sAccents.Count)
			mContext.DefineCommand(sAccents[i].Command).Checked = i == mAccent;
		mContext.DefineCommand("look.motion").Checked = mReduceMotion;
	}

	// The dock: pages in the middle (two scene pages, each with its own hierarchy and inspector,
	// so they can stand side by side), the shared panels below: assets and the console.
	private void BuildDock()
	{
		let host = mFrame.FindElement("frame-dock");
		if (host == null)
			return;
		DefineDockingCommands(mContext);
		mDock = new DockController();
		Register("scene", "Level 1", "Editor/Mock/scene.gml");
		Register("scene-2", "Level 2", "Editor/Mock/scene.gml");
		Register("kit", "Kit", "Editor/Mock/kit.gml");
		Register("assets", "Assets", "Editor/Mock/assets.gml");
		Register("console", "Console", "Editor/Mock/console.gml");
		{
			let layout = DefaultLayout(false);
			defer delete layout;
			Said(mDock.Adopt(layout));
		}
		mDockArea = new DockArea();
		mDockArea.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		host.AddChild(mDockArea);
		mDockArea.Show(mDock);
	}

	// A layout step the dock refused, said (the default arrangement is the mock's own: a refusal
	// is a bug).
	private static void Said(DockOutcome outcome)
	{
		if (!outcome.Ok)
			Console.Error.WriteLine("EditorMock: the dock refused: {}", outcome.Refused);
	}

	/// The caller owns it.
	private static DockLayout DefaultLayout(bool sideBySide)
	{
		let layout = new DockLayout();
		let central = layout.CentralStack;
		Said(layout.InsertTab("scene", central));
		if (sideBySide)
			Said(layout.InsertBeside("scene-2", central, .End, 0.5f));
		else
			Said(layout.InsertTab("scene-2", central));
		Said(layout.InsertTab("kit", central));
		Said(layout.Activate("scene"));
		Said(layout.InsertBeside("assets", central, .Bottom, 0.28f));
		Said(layout.InsertTab("console", layout.StackOf("assets")));
		Said(layout.Activate("assets"));
		return layout;
	}

	private void Register(StringView id, StringView title, StringView markup)
	{
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(title);
		description.Close = .Hide;
		description.Closable = true;
		description.Default.Central = id.StartsWith("scene") || (id == "kit");
		let path = new String(markup);
		let panel = new String(id);
		description.Factory = new () =>
			{
				let content = mHost.Load(path);
				if ((content != null) && (panel == "kit"))
				{
					content.AddRef(); // ours, for ScrollKit
					mKit = content;
				}
				if ((content != null) && panel.StartsWith("scene"))
					FillScenePage(content, panel == "scene-2");
				if ((content != null) && (panel == "assets"))
				{
					if (let crumbs = content.FindElement("assets-crumbs") as BreadcrumbBar)
						crumbs.SetPath("Content/Models/Props");
				}
				return content; // its one reference, the controller's
			} ~ { delete path; delete panel; };
		mDock.Register(description); // the controller's
	}

	// A scene page's inspector: on the first page an entity is selected, on the second the scene
	// itself (its top row in the hierarchy), whose settings the same inspector shows.
	private void FillScenePage(Node content, bool sceneSelected)
	{
		let grid = content.FindElement("inspector-grid") as PropertyGrid;
		if (grid == null)
			return;
		Object shown = null;
		GuiTypeInfo type = null;
		if (sceneSelected)
		{
			shown = new MockScene();
			type = MockScene.StaticGuiType;
			if (let tree = content.FindElement("hierarchy-tree") as TreeView)
				tree.SelectedItem = 0;
			if (let icon = content.FindElement("inspector-icon") as Sedulous.GUI.Image)
				icon.Source = "Editor/Icons/layers.svg";
			if (let name = content.FindElement("inspector-name") as TextField)
				name.Text = "Level 2";
			if (let kind = content.FindElement("inspector-kind") as Label)
				kind.Text = "Scene";
			// A scene has settings, not components: nothing to add.
			if (let add = content.FindElement("add-component"))
				add.Displayed = false;
		}
		else
		{
			shown = new MockEntity();
			type = MockEntity.StaticGuiType;
		}
		mShown.Add(shown);
		let source = new ReflectedPropertySource();
		mSources.Add(source);
		Object[1] objects = .(shown);
		source.SetObjects(Span<Object>(&objects[0], 1), type);
		grid.Source = source;
		// Each section open, as the inspector shows a selection's components.
		StringView[3] entitySections = .("Transform", "MeshRenderer", "RigidBody");
		StringView[4] sceneSections = .("Environment", "Rendering", "Physics", "Audio");
		if (sceneSelected)
		{
			for (let section in sceneSections)
				grid.SetOpen(section, true);
		}
		else
		{
			for (let section in entitySections)
				grid.SetOpen(section, true);
		}
	}
}
