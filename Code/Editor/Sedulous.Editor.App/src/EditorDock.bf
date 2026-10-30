using System;
using Sedulous.GUI; // with GUI.Docking's controller and area, and GUI.Hosting's host
using Sedulous.Settings;

namespace Sedulous.Editor.App;

/// What an EditorDock is given to make its panels' contents (the window's markup, say). Each
/// makes a node with one reference, the dock's; one not given, or one that makes none, is an
/// empty panel. Owned hooks.
class EditorDockContents
{
	/// The Project panel without a project.
	public delegate Node() Welcome ~ delete _;
	public delegate Node() Assets ~ delete _;
	public delegate Node() Console ~ delete _;
	public delegate Node() Profiler ~ delete _;
}

/// The editor's dock (Raptor's editor-gui spec, 5.1, layer 4). A GUI.Docking controller with its
/// area in the frame's `frame-dock`, its floats in OS windows of their own where the GUI's host
/// opens them (else over the main window), and the panels every project shares: the Project panel
/// (the open project's page, or the welcome without one), Assets, Console and the Profiler (X7: a tab
/// in the page area, not in the default layout until shown). Their ids are the ones saved layouts
/// and the MCP layout tools name: `welcome` (the Project panel kept the id it had as the Welcome
/// panel), `assets`, `console`, `profiler`. Pages come through it (EditorPages).
class EditorDock
{
	public const String cPanelProject = "welcome";
	public const String cPanelAssets = "assets";
	public const String cPanelConsole = "console";
	public const String cPanelProfiler = "profiler";

	/// The pane under the document: 30% of the height.
	private const float cPaneShare = 0.3f;
	/// The Console beside Assets: 35% of the pane.
	private const float cConsoleShare = 0.35f;

	// The controller first: its cleanup runs last, once the area (a view of it) is gone.
	private DockController mController = new .() ~ delete _;
	/// Ours, besides the frame's.
	private DockArea mArea = null ~ _?.ReleaseRef();
	private DockHostWindows mWindows = null ~ delete _;
	private EditorDockContents mContents = null ~ delete _;
	/// The Project panel's content (ours, besides the controller's): a holder of what it shows.
	private Sedulous.GUI.Panel mHolder = null ~ _?.ReleaseRef();
	/// Made the first time the holder shows it, kept after.
	private Node mWelcome = null ~ _?.ReleaseRef();
	/// The open project's page; null shows the welcome.
	private Node mProject = null ~ _?.ReleaseRef();

	public ~this()
	{
		Close();
	}

	/// Registers the shared panels, takes the default layout and shows it in `into` (the frame's
	/// dock node). `host` (nullable, borrowed: it outlives the dock or the dock closes first) opens
	/// the floats' windows when it can. TAKES OWNERSHIP of `contents`.
	public void Open(Node into, GuiHost host, EditorDockContents contents)
	{
		Close();
		delete mContents;
		mContents = contents;
		// Read when a panel is made, so a second Open's contents make what comes after it.
		RegisterPanel(cPanelProject, "Project", false, new () => Holder());
		RegisterPanel(cPanelAssets, "Assets", true, new () => Make(mContents.Assets));
		RegisterPanel(cPanelConsole, "Console", true, new () => Make(mContents.Console));
		RegisterPanel(cPanelProfiler, "Profiler", true, new () => Make(mContents.Profiler));
		AdoptDefault();
		mArea = new DockArea();
		into.AddChild(mArea);
		mArea.Show(mController);
		if ((host != null) && host.CanOpenWindows)
		{
			mWindows = new DockHostWindows(host, mArea);
			mArea.SetWindows(mWindows);
			if (mArea.Windows == null)
			{
				// A window would not open: the floats stay over the main window.
				DeleteAndNullify!(mWindows);
			}
		}
	}

	/// The area and its windows taken down (before the GUI's host goes). The panels, their
	/// contents and the layout stay, for an Open after.
	public void Close()
	{
		if (mArea == null)
			return;
		mArea.SetWindows(null); // the floats' windows close, their content back to the area
		DeleteAndNullify!(mWindows);
		mArea.RemoveFromParent();
		mArea.ReleaseRef();
		mArea = null;
	}

	/// The default layout: the Project panel in the central stack, under it a pane of Assets and
	/// Console side by side (the document 70% of the height; Assets 65% of the pane). The caller
	/// owns it.
	public static DockLayout DefaultLayout()
	{
		let layout = new DockLayout();
		let central = layout.CentralStack;
		layout.InsertTab(cPanelProject, central);
		layout.InsertBeside(cPanelAssets, central, .Bottom, cPaneShare);
		layout.InsertBeside(cPanelConsole, layout.StackOf(cPanelAssets), .End, cConsoleShare);
		return layout;
	}

	/// The default layout taken again (View > Reset Layout): a closed panel shows where it
	/// belongs.
	public void ResetLayout() => AdoptDefault();

	/// The layout a project opens with: the one saved in its store, else the default (the dock
	/// may be showing another project's). `store` null: the default.
	public void TakeLayout(Settings store)
	{
		if ((store == null) || !(ProjectEditorSettings.ApplyDockLayout(mController, store) case .Ok))
			ResetLayout();
	}

	/// The layout into a project's store, a copy (each time the store is written).
	public void CaptureLayout(Settings store)
	{
		ProjectEditorSettings.CaptureDockLayout(mController, store);
	}

	/// `panel` to the front: shown where it was closed, and its tab made its stack's current one
	/// (Show alone leaves a docked panel behind the tab in front of it).
	public void BringToFront(StringView panel)
	{
		if (mController.Layout.StackOf(panel) == cNoDock)
			mController.Show(panel);
		mController.Edit(scope (layout) => layout.Activate(panel));
	}

	/// The Project panel's content: the open project's page, or the welcome when null. The panel's
	/// own content is a holder of it, so it shows wherever the panel is docked. The dock takes a
	/// reference of its own.
	public void SetProjectContent(Node content)
	{
		if (content == mProject)
			return;
		if (content != null)
			content.AddRef();
		if (mProject != null)
			mProject.ReleaseRef(); // the holder's tree keeps it until FillHolder takes it out
		mProject = content;
		if (mHolder != null)
			FillHolder();
	}

	public DockController Controller => mController;
	/// Null while closed. The dock's.
	public DockArea Area => mArea;
	/// Whether its floats open as OS windows (else over the main window).
	public bool FloatsInWindows => mWindows != null;

	// The default layout, the Profiler closed in it: adopting places every registered panel, and the
	// Profiler is a page shown when asked (View > Profiler), where it was last.
	private void AdoptDefault()
	{
		let layout = DefaultLayout();
		defer delete layout;
		mController.Adopt(layout);
		mController.Close(cPanelProfiler);
	}

	/// TAKES OWNERSHIP of `factory` (one not needed is deleted).
	private void RegisterPanel(StringView id, StringView title, bool closable, delegate Node() factory)
	{
		if (mController.Describe(id) != null)
		{
			delete factory; // opened before: registered then
			return;
		}
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(title);
		description.Closable = closable;
		description.Default.Central = (id == cPanelProject) || (id == cPanelProfiler); // the Profiler is a page
		description.Default.Side = .Bottom;
		description.Factory = factory;
		mController.Register(description); // the controller's
	}

	/// The Project panel's factory: the holder, made once; a reference for the controller.
	private Node Holder()
	{
		if (mHolder == null)
		{
			mHolder = new Sedulous.GUI.Panel();
			mHolder.AddClass("project-panel");
			FillHolder();
		}
		mHolder.AddRef();
		return mHolder;
	}

	/// The holder shows the project's page, else the welcome (made the first time).
	private void FillHolder()
	{
		var shown = mProject;
		if (shown == null)
		{
			if (mWelcome == null)
				mWelcome = Make((mContents != null) ? mContents.Welcome : null);
			shown = mWelcome;
		}
		if ((mHolder.ChildCount == 1) && (mHolder.GetChildAt(0) == shown))
			return;
		mHolder.RemoveAllChildren();
		shown.RemoveFromParent();
		mHolder.AddChild(shown);
	}

	/// What `make` makes, else an empty panel: a node with one reference, the caller's.
	private static Node Make(delegate Node() make)
	{
		if (make != null)
		{
			let made = make();
			if (made != null)
				return made;
		}
		return new Sedulous.GUI.Panel();
	}
}
