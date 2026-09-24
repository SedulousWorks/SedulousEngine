using System;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The editor chrome: a RootView holding the menu bar, the dock manager (grow) and the
/// status bar. The global panels are Assets and Console only: everything scene-scoped
/// (viewport, hierarchy, inspector, selection, camera) lives inside each editor page,
/// because several scene pages can be open at once. The dock centre is the document area:
/// each open page docks there as a closable tab via AddPagePanel; a non-closable Welcome
/// panel holds the centre until the first page opens and keeps the centre tab group alive
/// when all pages close.
class EditorShell
{
	/// Stable persistence ids for the global panels; the layout match keys, never renamed.
	public const String cPanelWelcome = "welcome";
	public const String cPanelConsole = "console";
	public const String cPanelAssets = "assets";

	private RootView mRoot = null ~ { if (_ != null) _.ReleaseRef(); };
	// Borrowed: the tree owns them.
	private MenuBar mMenuBar = null;
	private StatusBar mStatusBar = null;
	private DockManager mDock = null;
	private LogView mLogView = null;
	// Borrowed: the DockManager owns registered panels.
	private DockablePanel mWelcome = null;
	private DockablePanel mConsole = null;
	private DockablePanel mAssets = null;

	/// Builds the chrome. `dockHost` (nullable) lets panels float into real OS windows.
	public void Build(EditorContext context, IDockableWindowHost dockHost, uint32 width, uint32 height)
	{
		mRoot = new RootView();
		mRoot.ViewportSize = .((float)width, (float)height);
		mRoot.DpiScale = 1.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;

		mMenuBar = new MenuBar();
		column.AddView(mMenuBar);

		mDock = new DockManager();
		mDock.DockableWindowHost = dockHost;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		column.AddView(mDock, grow);

		mStatusBar = new StatusBar();
		column.AddView(mStatusBar);

		mRoot.AddView(column);

		BuildPanels();

		// Context status text routes to the status bar.
		let status = mStatusBar;
		delete context.OnStatus;
		context.OnStatus = new (text) => { status.SetText(text); };
	}

	public RootView Root => mRoot;
	public MenuBar Menus => mMenuBar;
	public StatusBar StatusBar => mStatusBar;
	public DockManager Docks => mDock;
	public DockablePanel WelcomePanel => mWelcome;
	public DockablePanel ConsolePanel => mConsole;
	public DockablePanel AssetsPanel => mAssets;

	/// Replaces the Assets panel's placeholder with the real browser, once the project and
	/// cook service exist. Consumes the reference.
	public void SetAssetsContent(View content)
	{
		if (mAssets != null)
			mAssets.SetContent(content);
	}

	/// The Console panel's log view, fed by the app's EditorLogBuffer drain.
	public LogView Console => mLogView;

	// ---- the document area -----------------------------------------------------------------

	/// Docks a page's content view as a closable tab in the centre document area, tabbed
	/// with the other open pages. The DockManager owns the returned panel. Consumes the
	/// content reference.
	public DockablePanel AddPagePanel(StringView title, View content)
	{
		let panel = mDock.AddPanel(title, content);
		panel.Closable = true;
		mDock.DockPanelRelativeTo(panel, .Center, mWelcome.Parent);
		return panel;
	}

	/// Dock-layout persistence via the per-project settings store; the app owns loading
	/// and saving the store's file, these only capture and apply the dock section.
	public Result<void, ErrorCode> SaveLayout(Settings store) => ProjectEditorSettings.CaptureDockLayout(mDock, store);
	public Result<void, ErrorCode> RestoreLayout(Settings store) => ProjectEditorSettings.ApplyDockLayout(mDock, store);

	/// Rebuilds the default arrangement (View > Reset Layout).
	public void ResetLayout() => DockDefaults();

	private void BuildPanels()
	{
		mWelcome = mDock.AddPanel("Welcome", new Label("Editor - open an asset to begin"));
		mWelcome.SetPersistenceId(cPanelWelcome);
		mWelcome.Closable = false;

		mLogView = new LogView();
		mConsole = mDock.AddPanel("Console", mLogView);
		mConsole.SetPersistenceId(cPanelConsole);

		mAssets = mDock.AddPanel("Assets", new Label("Asset browser"));
		mAssets.SetPersistenceId(cPanelAssets);

		DockDefaults();
	}

	/// The document area's share of the window height in the default layout.
	private const float cDefaultDocumentShare = 0.7f;

	private void DockDefaults()
	{
		// Documents centre, the south-stacked tool pane below; scene-scoped views live
		// inside the pages. Assets leads it and the Console is its second tab. A bottom
		// dock inserts at half the height, so the ratio, which is the first (top) child's
		// share, is set afterwards.
		mDock.DockPanel(mWelcome, .Center);
		mDock.DockPanel(mAssets, .Bottom);
		mDock.DockPanelRelativeTo(mConsole, .Center, mAssets.Parent);
		mDock.ActivatePanel(mAssets);
		if (let split = mDock.RootNode as DockSplit)
			split.SplitRatio = cDefaultDocumentShare;
	}
}
