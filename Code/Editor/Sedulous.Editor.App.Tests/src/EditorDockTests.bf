using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.Shell.Null;
using Sedulous.GUI;
using Sedulous.Settings;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A dock opened into a panel 800 by 600 in a root of a GUI of its own, with no host: the welcome
/// a label of the bed's, the Assets panel's content one too, the Console given nothing.
class DockBed
{
	public SceneRoot Root;
	public Sedulous.GUI.Panel Into = new .();
	public EditorDock Dock = new .();
	/// The bed's references; the dock takes its own.
	public Sedulous.GUI.Label Welcome = new .();
	public Sedulous.GUI.Label Assets = new .();
	/// How often the dock made the welcome.
	public int WelcomesMade = 0;

	public this()
	{
		let context = new GUIContext();
		Root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		Root.Size = .(800.0f, 600.0f);
		Into.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		Root.AddChild(Into);
		let contents = new EditorDockContents();
		contents.Welcome = new () =>
			{
				++WelcomesMade;
				Welcome.AddRef(); // the dock's
				return Welcome;
			};
		contents.Assets = new () =>
			{
				Assets.AddRef();
				return Assets;
			};
		Dock.Open(Into, null, contents);
		Root.UpdateLayout();
	}

	public ~this()
	{
		// The dock first (its area leaves the controller's views as it goes), then the tree.
		delete Dock;
		Assets.ReleaseRef();
		Welcome.ReleaseRef();
		Into.ReleaseRef();
		Root.ReleaseRef();
	}

	public DockLayout Layout => Dock.Controller.Layout;

	/// The split holding `node`; null for a surface's root.
	public DockNode ParentOf(DockNodeId node)
	{
		let found = Layout.FindNode(node);
		return (found != null) ? Layout.FindNode(found.Parent) : null;
	}
}

/// A dock opened into the main window's root of a GUI host on the null device and shell, whose
/// opener makes null windows: the floats open in windows of their own.
class DockWindowsBed
{
	public NullShell Shell = new .();
	public GraphicsDevice Device;
	public IShaderModule Vs;
	public IShaderModule Fs;
	public RenderWindow Main;
	public GuiHost Host;
	public List<RenderWindow> Opened = new .();
	public int Closed = 0;
	public SceneRoot Root;
	public Sedulous.GUI.Panel Into = new .();
	public EditorDock Dock = new .();

	public this()
	{
		Device = NullGraphics.CreateDevice(2).Value;
		Vs = MakeModule(Device.Raw);
		Fs = MakeModule(Device.Raw);
		Main = Device.CreateRenderWindow(Shell.MainWindow, .()).Value;
		var shaders = VgShaderSet();
		shaders.Vertex = Vs;
		shaders.Fragment = Fs;
		Host = new .(Device, Shell, null, shaders);
		let opener = new GuiHost.WindowOpener();
		opener.Open = new (settings) =>
			{
				if (!(((NullWindowManager)Shell.WindowManager).CreateWindow(settings) case .Ok(let made)))
					return null;
				let rendered = Device.CreateRenderWindow(made, .()).Value;
				Opened.Add(rendered);
				return rendered;
			};
		opener.Close = new (window) =>
			{
				++Closed;
				((NullWindowManager)Shell.WindowManager).DestroyWindow(window.Window);
			};
		Host.SetWindowOpener(opener);
		Root = new SceneRoot(Host.Context);
		Into.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Percent(100.0f);
				s.Height = LayoutLength.Percent(100.0f);
			});
		Root.AddChild(Into);
		Host.AttachWindow(Main, Root);
		Dock.Open(Into, Host, new EditorDockContents());
	}

	public ~this()
	{
		// The dock (its floats' windows closed), the tree, then the host (which held the root),
		// the windows it drew, the device after the modules it made.
		delete Dock;
		Into.ReleaseRef();
		Root.ReleaseRef();
		delete Host;
		DeleteContainerAndItems!(Opened);
		delete Main;
		Device.Raw.DestroyShaderModule(ref Fs);
		Device.Raw.DestroyShaderModule(ref Vs);
		delete Device;
		delete Shell;
	}

	public void Frame()
	{
		Host.Update(1.0f / 60.0f);
		Device.AdvanceFrame();
	}

	/// A module the caller destroys.
	public static IShaderModule MakeModule(IDevice device)
	{
		uint8[4] code = .(0, 0, 0, 0);
		var desc = ShaderModuleDesc();
		desc.Code = .(&code[0], 4);
		desc.EntryPoint = "main";
		if (device.CreateShaderModule(desc) case .Ok(let module))
			return module;
		return null;
	}
}

/// EditorDock (Raptor's editor-gui spec, 5.1, layer 4): the shared panels by the ids saved layouts
/// and the MCP tools name, their titles and which may close; the default layout (Project central,
/// Assets and Console under it side by side, at their shares); a layout that places none puts each
/// at its default place; the Project panel's content the open project's page or the welcome
/// wherever the panel shows; Assets' and Console's what their contents make, else an empty panel;
/// Reset Layout; a project's layout taken from its store, else the default, and captured into it;
/// closed, the area gone and the panels kept for an Open after; and with a host that
/// opens windows, the floats in windows of their own, closed with the dock.
static class EditorDockTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void TheSharedPanelsByTheirIdsTheProjectPanelCentralAndFixedAssetsAndConsoleUnderItSideBySide()
	{
		let bed = scope DockBed();
		let dock = bed.Dock;
		Test.Assert(dock.Area != null);
		Test.Assert(dock.Area.Parent == bed.Into);
		Test.Assert(dock.Area.Controller == dock.Controller);
		Test.Assert(!dock.FloatsInWindows, "no host to open windows");
		Test.Assert(dock.Area.Windows == null);

		let layout = bed.Layout;
		let central = layout.CentralStack;
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == central);
		let assets = layout.StackOf(EditorDock.cPanelAssets);
		let console = layout.StackOf(EditorDock.cPanelConsole);
		Test.Assert(assets != cNoDock);
		Test.Assert(console != cNoDock);
		Test.Assert(assets != console, "side by side, both shown");
		Test.Assert(assets != central);
		Test.Assert(console != central);

		// Under the document: a split one above another, the document 70% of the height.
		let column = bed.ParentOf(central);
		Test.Assert(column != null);
		Test.Assert(column.Axis == .Vertical);
		Test.Assert((column.Children.Count == 2) && (column.Children[0] == central));
		Test.Assert(Near(column.Weights[0], 0.7f) && Near(column.Weights[1], 0.3f));
		// The pane: Assets then the Console side by side, Assets 65% of it.
		let pane = bed.ParentOf(assets);
		Test.Assert(pane != null);
		Test.Assert(pane == bed.ParentOf(console));
		Test.Assert(pane.Id == column.Children[1]);
		Test.Assert(pane.Axis == .Horizontal);
		Test.Assert((pane.Children.Count == 2) && (pane.Children[0] == assets) && (pane.Children[1] == console));
		Test.Assert(Near(pane.Weights[0], 0.65f) && Near(pane.Weights[1], 0.35f));

		let controller = dock.Controller;
		Test.Assert(controller.Panels.Length == 4); // and the Profiler, a page closed until shown
		let project = controller.Describe(EditorDock.cPanelProject);
		Test.Assert(project != null);
		Test.Assert(project.Title == "Project");
		Test.Assert(!project.Closable);
		Test.Assert(!controller.Close(EditorDock.cPanelProject).Ok);
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == central);
		Test.Assert(controller.Describe(EditorDock.cPanelAssets).Title == "Assets");
		Test.Assert(controller.Describe(EditorDock.cPanelAssets).Closable);
		Test.Assert(controller.Describe(EditorDock.cPanelConsole).Title == "Console");
		Test.Assert(controller.Describe(EditorDock.cPanelConsole).Closable);
	}

	[Test]
	public static void ALayoutThatPlacesNoPanelPutsTheProjectCentralAndAssetsAndConsoleAtTheBottom()
	{
		let bed = scope DockBed();
		Test.Assert(bed.Dock.Controller.Adopt(scope DockLayout()).Ok);
		let layout = bed.Layout;
		let central = layout.CentralStack;
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == central);
		// Each along the main surface's bottom edge: in the column under the document.
		let column = bed.ParentOf(central);
		Test.Assert(column != null);
		Test.Assert(column.Axis == .Vertical);
		let at = column.Children.IndexOf(central);
		let assets = column.Children.IndexOf(layout.StackOf(EditorDock.cPanelAssets));
		let console = column.Children.IndexOf(layout.StackOf(EditorDock.cPanelConsole));
		Test.Assert((assets > at) && (console > at));
	}

	[Test]
	public static void TheProjectPanelShowsTheWelcomeTheOpenProjectsPageWhileOneIsOpenTheWelcomeAgainAfter()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		let holder = controller.Content(EditorDock.cPanelProject);
		Test.Assert(holder != null);
		Test.Assert((holder as UIWidget).HasClass("project-panel"));
		Test.Assert(holder.ChildCount == 1);
		Test.Assert(holder.GetChildAt(0) == bed.Welcome);

		let page = new Sedulous.GUI.Label();
		defer page.ReleaseRef();
		bed.Dock.SetProjectContent(page);
		Test.Assert(holder.ChildCount == 1);
		Test.Assert(holder.GetChildAt(0) == page);
		Test.Assert(bed.Welcome.Parent == null);
		// Moved to another stack, the panel keeps its content: the same holder.
		Test.Assert(controller.Edit(scope (l) =>
			{
				let beside = DockDrop(.Tab, l.StackOf(EditorDock.cPanelAssets), cNoDock, 0, .Start);
				return ApplyDrop(l, EditorDock.cPanelProject, beside);
			}).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelProject) == bed.Layout.StackOf(EditorDock.cPanelAssets));
		Test.Assert(controller.Content(EditorDock.cPanelProject) == holder);
		Test.Assert(holder.GetChildAt(0) == page);

		bed.Dock.SetProjectContent(null);
		Test.Assert(holder.ChildCount == 1);
		Test.Assert(holder.GetChildAt(0) == bed.Welcome);
		Test.Assert(page.Parent == null);
		Test.Assert(bed.WelcomesMade == 1, "the welcome made once, kept after");
	}

	[Test]
	public static void AssetsAndConsoleAreWhatTheirContentsMakeElseAnEmptyPanel()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		Test.Assert(controller.Content(EditorDock.cPanelAssets) == bed.Assets);
		let console = controller.Content(EditorDock.cPanelConsole);
		Test.Assert(console != null, "given nothing: an empty panel");
		Test.Assert(console is Sedulous.GUI.Panel);
		Test.Assert(console.ChildCount == 0);
	}

	[Test]
	public static void ResetLayoutTakesTheDefaultAgainAClosedPanelShownWhereItBelongs()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		Test.Assert(controller.Close(EditorDock.cPanelConsole).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelConsole) == cNoDock);
		// The Project panel tabbed in with Assets: the central stack left empty.
		Test.Assert(controller.Edit(scope (l) => l.MoveToTab(EditorDock.cPanelProject, l.StackOf(EditorDock.cPanelAssets))).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelProject) != bed.Layout.CentralStack);

		bed.Dock.ResetLayout();
		let layout = bed.Layout;
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == layout.CentralStack);
		let assets = layout.StackOf(EditorDock.cPanelAssets);
		let console = layout.StackOf(EditorDock.cPanelConsole);
		Test.Assert(console != cNoDock);
		Test.Assert(assets != console);
		Test.Assert(bed.ParentOf(console) == bed.ParentOf(assets), "beside Assets again");
		Test.Assert(bed.ParentOf(assets).Axis == .Horizontal);
	}

	/// The layout a project opens with: its store's, over whatever the dock showed; a store with
	/// none captured, or none, the default. A capture is the dock's layout, a copy.
	[Test]
	public static void TakeLayoutTakesTheStoresLayoutElseTheDefault()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		let layout = bed.Layout;
		// The console tabbed in with the assets: an arrangement the default does not make.
		Test.Assert(controller.Edit(scope (l) => l.MoveToTab(EditorDock.cPanelConsole, l.StackOf(EditorDock.cPanelAssets))).Ok);
		let store = scope Settings();
		bed.Dock.CaptureLayout(store);
		let section = store.Find<EditorDockLayoutSettings>();
		Test.Assert((section != null) && section.Captured);
		Test.Assert(section.Document.Layout != layout, "a copy");
		Test.Assert(section.Document.Layout.StackOf(EditorDock.cPanelConsole) == section.Document.Layout.StackOf(EditorDock.cPanelAssets));

		// Shown otherwise, then taken from the store: the store's.
		bed.Dock.ResetLayout();
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != layout.StackOf(EditorDock.cPanelAssets));
		bed.Dock.TakeLayout(store);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == layout.StackOf(EditorDock.cPanelAssets));

		// A store with none captured: the default, over the store's.
		bed.Dock.TakeLayout(scope Settings());
		let assets = layout.StackOf(EditorDock.cPanelAssets);
		let console = layout.StackOf(EditorDock.cPanelConsole);
		Test.Assert((console != cNoDock) && (console != assets));
		Test.Assert(bed.ParentOf(console) == bed.ParentOf(assets), "beside the assets, as the default has it");

		// No store: the default too.
		bed.Dock.TakeLayout(store);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == layout.StackOf(EditorDock.cPanelAssets));
		bed.Dock.TakeLayout(null);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != layout.StackOf(EditorDock.cPanelAssets));
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == layout.CentralStack);
	}

	[Test]
	public static void ClosedTheAreaGoesAndThePanelsStayForAnOpenAfter()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		let holder = controller.Content(EditorDock.cPanelProject);
		bed.Dock.Close();
		Test.Assert(bed.Dock.Area == null);
		Test.Assert(bed.Into.ChildCount == 0);
		Test.Assert(!bed.Dock.FloatsInWindows);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelProject) == bed.Layout.CentralStack);
		bed.Dock.Close(); // again: nothing left to close

		let other = new Sedulous.GUI.Panel();
		defer other.ReleaseRef();
		bed.Root.AddChild(other);
		bed.Dock.Open(other, null, new EditorDockContents());
		Test.Assert(bed.Dock.Area.Parent == other);
		Test.Assert(controller.Panels.Length == 4, "registered once"); // the Profiler among them
		Test.Assert(controller.Content(EditorDock.cPanelProject) == holder);
		Test.Assert(holder.GetChildAt(0) == bed.Welcome, "the welcome kept");
	}

	[Test]
	public static void WithAHostThatOpensWindowsAFloatOpensAWindowOfItsOwnClosedWithTheDock()
	{
		let bed = scope DockWindowsBed();
		let dock = bed.Dock;
		Test.Assert(bed.Host.CanOpenWindows);
		Test.Assert(dock.FloatsInWindows);
		Test.Assert(dock.Area.Windows != null);
		bed.Frame();
		Test.Assert(bed.Host.WindowCount == 1);

		Test.Assert(dock.Controller.Edit(scope (l) => l.Float(EditorDock.cPanelConsole, .(100.0f, 80.0f, 300.0f, 200.0f))).Ok);
		bed.Frame();
		Test.Assert(bed.Host.WindowCount == 2, "the Console's float in a window of its own");
		Test.Assert(bed.Opened.Count == 1);
		Test.Assert(dock.Area.FloatCount == 0, "not over the main window");

		dock.Close();
		Test.Assert(bed.Closed == 1);
		Test.Assert(bed.Host.WindowCount == 1);
		Test.Assert(!dock.FloatsInWindows);
		Test.Assert(bed.Into.ChildCount == 0);
	}

	[Test]
	public static void AClosedConsoleOrAssetsComesBackWhereItBelongsTheRestOfTheLayoutKept()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		// Moved first, so a reset would show: Assets beside the Project panel instead of under it.
		Test.Assert(controller.Edit(scope (l) => l.MoveBeside(EditorDock.cPanelAssets, l.CentralStack, .End, 0.3f)).Ok);
		let assetsStack = bed.Layout.StackOf(EditorDock.cPanelAssets);
		Test.Assert(controller.Close(EditorDock.cPanelConsole).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelConsole) == cNoDock);
		bed.Dock.BringToFront(EditorDock.cPanelConsole);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelAssets) == assetsStack, "not reset");

		Test.Assert(controller.Close(EditorDock.cPanelAssets).Ok);
		bed.Dock.BringToFront(EditorDock.cPanelAssets);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelAssets) != cNoDock);
	}

	/// BringToFront shows a closed panel where it belongs, and puts a docked one's tab in front of
	/// the tab before it in its stack (Show alone refuses a docked panel): an asset slot's Reveal
	/// reaches the Assets panel either way.
	[Test]
	public static void BringToFrontShowsAClosedPanelAndPutsADockedOnesTabInFront()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		Test.Assert(controller.Close(EditorDock.cPanelAssets).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelAssets) == cNoDock);
		bed.Dock.BringToFront(EditorDock.cPanelAssets);
		let stack = bed.Layout.StackOf(EditorDock.cPanelAssets);
		Test.Assert(stack != cNoDock, "shown again");

		// The Console tabbed into its stack, in front of it.
		Test.Assert(controller.Edit(scope (l) => l.MoveToTab(EditorDock.cPanelConsole, stack)).Ok);
		Test.Assert(controller.Edit(scope (l) => l.Activate(EditorDock.cPanelConsole)).Ok);
		var node = bed.Layout.FindNode(bed.Layout.StackOf(EditorDock.cPanelAssets));
		Test.Assert((node.Panels.Count == 2) && (node.Panels[node.Active] == EditorDock.cPanelConsole));
		bed.Dock.BringToFront(EditorDock.cPanelAssets);
		node = bed.Layout.FindNode(bed.Layout.StackOf(EditorDock.cPanelAssets));
		Test.Assert(node.Panels[node.Active] == EditorDock.cPanelAssets, "its tab in front");
	}

	/// The Profiler is a page: out of the default layout until presented, then in the page area,
	/// and to the front when presented again behind another tab.
	[Test]
	public static void TheProfilerIsAPageOutOfTheDefaultLayoutUntilPresentedThenInThePageAreaAndToTheFront()
	{
		let bed = scope DockBed();
		let controller = bed.Dock.Controller;
		let profiler = controller.Describe(EditorDock.cPanelProfiler);
		Test.Assert(profiler != null);
		Test.Assert(profiler.Title == "Profiler");
		Test.Assert(profiler.Default.Central);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelProfiler) == cNoDock);

		bed.Dock.BringToFront(EditorDock.cPanelProfiler);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelProfiler) == bed.Layout.CentralStack);

		// Presented again behind the Project panel's tab: to the front.
		Test.Assert(controller.Edit(scope (l) => l.Activate(EditorDock.cPanelProject)).Ok);
		bed.Dock.BringToFront(EditorDock.cPanelProfiler);
		let central = bed.Layout.FindNode(bed.Layout.CentralStack);
		Test.Assert(central != null);
		Test.Assert(central.Panels[central.Active] == EditorDock.cPanelProfiler);
	}
}
