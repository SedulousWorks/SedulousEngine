using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// What the docking tests share.
static class DockingFixtures
{
	/// A root of a GUI of its own, `width` by `height`, held by the caller: it releases it, and the
	/// GUI goes with it.
	public static SceneRoot NewRoot(float width, float height)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(width, height);
		return root;
	}

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	public static Float2 Centre(Rect r) => .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	public static Rect Bounds(Node n) => n.ScreenBounds;

	/// A description of `id` whose content is a Panel; the caller registers it (which takes it).
	public static DockPanelDescription PanelNamed(StringView id, StringView title = default, bool closable = true)
	{
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(title);
		description.Closable = closable;
		description.Factory = new () => new Panel();
		return description;
	}
}

/// The bed the drop and keyboard tests share: a DockSpace in a root, five panels registered, four
/// docked (scene and inspector tabbed in the central stack, the hierarchy beside it on the left, a
/// quarter, the console under the central stack), and the moves a user makes on it.
class DockBed
{
	public SceneRoot Root;
	public DockController Controller = new .();
	public DockSpace Space = new .();

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		Space.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		Root.AddChild(Space);
		String[5] ids = .("scene", "inspector", "hierarchy", "console", "log");
		for (let id in ids)
			Test.Assert(Controller.Register(PanelNamed(id)));
		Space.Show(Controller, Controller.Layout.MainSurface);
		let central = Controller.Layout.CentralStack;
		Test.Assert(Controller.Edit(scope (l) => l.InsertTab("scene", central)).Ok);
		Test.Assert(Controller.Edit(scope (l) => l.InsertTab("inspector", central)).Ok);
		Test.Assert(Controller.Edit(scope (l) => l.InsertBeside("hierarchy", central, .Start, 0.25f)).Ok);
		Test.Assert(Controller.Edit(scope (l) => l.InsertBeside("console", central, .Bottom, 0.3f)).Ok);
		Lay();
	}

	public ~this()
	{
		// The root (and the space with it, leaving the controller's views) before the controller.
		Space.ReleaseRef();
		Root.ReleaseRef();
		delete Controller;
	}

	public void Lay()
	{
		Root.UpdateLayout();
		// The tabs a size of their own: with no font their text measures nothing.
		String[4] ids = .("scene", "inspector", "hierarchy", "console");
		for (let id in ids)
		{
			let tab = TabOf(id);
			if (tab == null)
				continue;
			tab.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
		}
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;
	public DockNodeId StackOf(StringView panel) => Controller.Layout.StackOf(panel);
	public TabView ViewOf(StringView panel) => Space.WidgetOf(StackOf(panel)) as TabView;

	public Tab TabOf(StringView panel)
	{
		let view = ViewOf(panel);
		let page = Space.PageOf(panel);
		if ((view == null) || (page == null))
			return null;
		for (int32 i = 0; i < view.PageCount; ++i)
		{
			if (view.GetPage(i) == page)
				return view.Bar.GetTab(i);
		}
		return null;
	}

	/// A tab torn out of its strip (pulled down into its stack).
	public void Tear(StringView panel)
	{
		let tab = TabOf(panel);
		Test.Assert(tab != null);
		let at = Centre(Bounds(tab));
		D.InjectMouseDown(at, .Left);
		D.InjectMouseMove(.(at.X, at.Y + 50.0f));
		D.InjectMouseMove(.(at.X, at.Y + 60.0f));
		Test.Assert(D.IsDragging);
	}

	public void Over(Float2 at) { D.InjectMouseMove(at); }
	public void Release(Float2 at) { D.InjectMouseUp(at, .Left); }
	public bool Preview(out Rect outBounds) => Space.GetPreviewBounds(out outBounds);
}
