using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The collapsible bottom strip's state machine: the toggle gesture, switching tabs, and which
/// content is visible. The half where a host wires the event to a split view's pane is covered
/// by [[SplitViewTests]].
class BottomDockTests
{
	[Test]
	public static void ItStartsCollapsedAndTheSameTabTogglesIt()
	{
		let dock = new BottomDock();
		defer dock.ReleaseRef();

		let animation = new Panel();
		defer animation.ReleaseRef();
		dock.AddTab("animation", "Animation", animation);

		Test.Assert(dock.TabCount == 1);
		Test.Assert(!dock.IsExpanded);
		Test.Assert(animation.Visibility == .Gone);

		var events = 0;
		var lastExpanded = false;
		dock.OnExpandedChanged.Add(new [&events, &lastExpanded](expanded) =>
			{
				events++;
				lastExpanded = expanded;
			});

		dock.ClickTab("animation");
		Test.Assert(dock.IsExpanded);
		Test.Assert(animation.Visibility == .Visible);
		Test.Assert(dock.ActiveTabId == "animation");
		Test.Assert(events == 1);
		Test.Assert(lastExpanded);

		// The SAME tab collapses, which is what makes a one tab dock a show and hide button.
		dock.ClickTab("animation");
		Test.Assert(!dock.IsExpanded);
		Test.Assert(animation.Visibility == .Gone);
		Test.Assert(events == 2);
		Test.Assert(!lastExpanded);
	}

	[Test]
	public static void SwitchingTabsStaysExpandedAndShowsOnlyTheActiveContent()
	{
		let dock = new BottomDock();
		defer dock.ReleaseRef();

		let a = new Panel();
		defer a.ReleaseRef();
		let b = new Panel();
		defer b.ReleaseRef();
		dock.AddTab("a", "A", a);
		dock.AddTab("b", "B", b);

		dock.ClickTab("a");
		Test.Assert(dock.IsExpanded);
		Test.Assert(a.Visibility == .Visible);
		Test.Assert(b.Visibility == .Gone);

		dock.ClickTab("b");
		Test.Assert(dock.IsExpanded, "switching does not collapse");
		Test.Assert(dock.ActiveTabId == "b");
		Test.Assert(a.Visibility == .Gone);
		Test.Assert(b.Visibility == .Visible);

		dock.SetExpanded(false);
		Test.Assert(!dock.IsExpanded);
		Test.Assert(a.Visibility == .Gone);
		Test.Assert(b.Visibility == .Gone);
	}

	[Test]
	public static void ActivateTabExpandsTheNamedTabAndIgnoresAnUnknownOne()
	{
		let dock = new BottomDock();
		defer dock.ReleaseRef();

		let a = new Panel();
		defer a.ReleaseRef();
		dock.AddTab("a", "A", a);

		dock.ActivateTab("nope");
		Test.Assert(!dock.IsExpanded);

		dock.ActivateTab("a");
		Test.Assert(dock.IsExpanded);
		Test.Assert(dock.ActiveTabId == "a");
		Test.Assert(a.Visibility == .Visible);
	}

	/// ActivateTab switching WHILE expanded still has to hide the tab it left, even though the
	/// expanded state itself did not change.
	[Test]
	public static void ActivatingAnotherTabWhileExpandedHidesTheOldOne()
	{
		let dock = new BottomDock();
		defer dock.ReleaseRef();

		let a = new Panel();
		defer a.ReleaseRef();
		let b = new Panel();
		defer b.ReleaseRef();
		dock.AddTab("a", "A", a);
		dock.AddTab("b", "B", b);

		dock.ActivateTab("a");
		dock.ActivateTab("b");
		Test.Assert(a.Visibility == .Gone);
		Test.Assert(b.Visibility == .Visible);
	}

	/// Opened from elsewhere, the dock is GONE while nothing is open, bar and all, so the pane
	/// holding it takes no height; a tab added for a docked tool panel comes and goes with it.
	[Test]
	public static void HiddenWhenCollapsedAndTabsComeAndGo()
	{
		let dock = new BottomDock();
		defer dock.ReleaseRef();
		dock.HideWhenCollapsed = true;
		let animation = new Panel();
		defer animation.ReleaseRef();
		dock.AddTab("animation", "Animation", animation);

		// Collapsed: nothing to measure.
		dock.Measure(BoxConstraints(400, 400, 0, 300));
		Test.Assert(dock.MeasuredSize.Y == 0.0f, "no bar while nothing is open");

		// A docked tool's tab opens it, and removing the open tab closes it again.
		let terrain = new Panel();
		defer terrain.ReleaseRef();
		dock.AddTab("tool:Terrain", "Terrain", terrain);
		dock.ActivateTab("tool:Terrain");
		Test.Assert(dock.IsExpanded && (terrain.Visibility == .Visible));
		dock.Measure(BoxConstraints(400, 400, 0, 300));
		Test.Assert(dock.MeasuredSize.Y > 0.0f);
		dock.RemoveTab("tool:Terrain");
		Test.Assert(!dock.IsExpanded && !dock.HasTab("tool:Terrain") && (dock.TabCount == 1));
		dock.Measure(BoxConstraints(400, 400, 0, 300));
		Test.Assert(dock.MeasuredSize.Y == 0.0f);

		// The remaining tab's button still toggles it, by id after the removal.
		dock.AddTab("tool:Terrain", "Terrain", terrain);
		dock.RemoveTab("animation");
		dock.ClickTab("tool:Terrain");
		Test.Assert(dock.IsExpanded && (dock.ActiveTabId == "tool:Terrain"));
		dock.ClickTab("tool:Terrain");
		Test.Assert(!dock.IsExpanded);
	}
}
