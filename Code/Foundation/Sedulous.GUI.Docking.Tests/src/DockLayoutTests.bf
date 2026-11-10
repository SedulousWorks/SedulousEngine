using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// The dock layout as data: panels tabbed, docked beside a
/// stack and at a surface's edge; moved, floated, closed and shown where they were; shares that
/// survive a child going; splits of one axis merged; refusals that change nothing; and a long run
/// of random operations after each of which the layout still holds together; a floating surface
/// docked whole; a stack moved whole (its strip's grip).
class DockLayoutTests
{
	// A small generator of its own (a linear congruential one), the same runs every time.
	private static uint32 Next(ref uint32 state, uint32 below)
	{
		state = state &* 1664525 &+ 1013904223;
		return (state >> 8) % below;
	}

	private static void Holds(DockLayout layout)
	{
		let why = scope String();
		let holds = layout.CheckInvariants(why);
		Test.Assert(holds, why);
	}

	private static DockNode Root(DockLayout layout, DockSurfaceId surface) => layout.FindNode(layout.FindSurface(surface).Root);

	// A float of two stacks side by side: profiler | memory, counters (counters active).
	private static void MakeFloat(DockLayout layout, out DockSurfaceId floating)
	{
		floating = cNoDock;
		Test.Assert(layout.InsertTab("scene", layout.CentralStack).Ok);
		Test.Assert(layout.Float("profiler", .(100.0f, 80.0f, 400.0f, 300.0f), &floating).Ok);
		let first = layout.StackOf("profiler");
		Test.Assert(layout.InsertBeside("memory", first, .End).Ok);
		Test.Assert(layout.InsertTab("counters", layout.StackOf("memory")).Ok);
	}

	// hierarchy | scene (central), with the console, log under the scene.
	private static void MakeStacks(DockLayout layout)
	{
		Test.Assert(layout.InsertTab("scene", layout.CentralStack).Ok);
		Test.Assert(layout.InsertBeside("hierarchy", layout.CentralStack, .Start, 0.25f).Ok);
		Test.Assert(layout.InsertBeside("console", layout.CentralStack, .Bottom, 0.3f).Ok);
		Test.Assert(layout.InsertTab("log", layout.StackOf("console")).Ok);
		Test.Assert(layout.Activate("console").Ok);
	}

	[Test]
	public static void AMainSurfaceWithItsCentralStackEmptyAndKept()
	{
		let layout = scope DockLayout();
		Test.Assert(layout.Surfaces.Count == 1);
		let central = layout.CentralStack;
		Test.Assert(central != cNoDock);
		Test.Assert(layout.FindSurface(layout.MainSurface).Root == central);
		Test.Assert(layout.FindNode(central).Panels.IsEmpty);
		Holds(layout);
	}

	[Test]
	public static void TabsAStackBesideASurfacesEdgeSplitsOfOneAxisMerged()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		Test.Assert(layout.InsertTab("material", central).Ok);
		Test.Assert(layout.FindNode(central).Active == 1); // the one tabbed in last
		Test.Assert(layout.InsertBeside("hierarchy", central, .Start, 0.25f).Ok);
		var root = Root(layout, layout.MainSurface);
		Test.Assert(!root.IsStack);
		Test.Assert(root.Axis == .Horizontal);
		Test.Assert(root.Children.Count == 2);
		Test.Assert(Near(root.Weights[0], 0.25f));
		// Another beside the central stack on the same axis joins the same split, parting its share.
		Test.Assert(layout.InsertBeside("inspector", central, .End, 0.4f).Ok);
		root = Root(layout, layout.MainSurface);
		Test.Assert(root.Children.Count == 3);
		Test.Assert(Near(root.Weights[0], 0.25f));
		Test.Assert(Near(root.Weights[1], 0.45f)); // 0.75 less its 0.4
		Test.Assert(Near(root.Weights[2], 0.30f));
		// The console along the whole bottom: a vertical split over all of it.
		Test.Assert(layout.InsertAtEdge("console", layout.MainSurface, .Bottom, 0.2f).Ok);
		root = Root(layout, layout.MainSurface);
		Test.Assert(root.Axis == .Vertical);
		Test.Assert(Near(root.Weights[1], 0.2f));
		Test.Assert(layout.StackOf("console") == root.Children[1]);
		Holds(layout);
	}

	[Test]
	public static void AChildThatGoesGivesItsShareToItsNeighboursASplitOfOneGivesWay()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertBeside("a", central, .Start, 0.2f).Ok);
		Test.Assert(layout.InsertBeside("b", central, .End, 0.5f).Ok); // 0.2, 0.4, 0.4
		float[3] shares = .(0.2f, 0.3f, 0.5f);
		Test.Assert(layout.SetWeights(Root(layout, layout.MainSurface).Id, shares).Ok);
		Test.Assert(layout.Close("b").Ok); // its 0.5 goes to the central stack, its one neighbour
		let root = Root(layout, layout.MainSurface);
		Test.Assert(root.Children.Count == 2);
		Test.Assert(Near(root.Weights[0], 0.2f)); // a keeps its own
		Test.Assert(Near(root.Weights[1], 0.8f));
		Test.Assert(layout.Close("a").Ok); // the split of one gives way to the central stack
		Test.Assert(layout.FindSurface(layout.MainSurface).Root == central);
		Holds(layout);
	}

	[Test]
	public static void MovedBetweenStacksReorderedAmongItsOwnTabsRefusedBesideItselfAlone()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("one", central).Ok);
		Test.Assert(layout.InsertTab("two", central).Ok);
		Test.Assert(layout.InsertTab("three", central).Ok);
		Test.Assert(layout.MoveToTab("three", central, 0).Ok);
		Test.Assert(layout.FindNode(central).Panels[0] == "three");
		Test.Assert(layout.MoveBeside("two", central, .Bottom).Ok);
		let two = layout.StackOf("two");
		Test.Assert(two != central);
		let alone = layout.MoveBeside("two", two, .Top);
		Test.Assert(!alone.Ok);
		Test.Assert(layout.StackOf("two") == two); // refused: nothing changed
		Test.Assert(layout.MoveToTab("two", central).Ok); // back: its stack goes
		Test.Assert(layout.FindNode(two) == null);
		Holds(layout);
	}

	[Test]
	public static void FloatingSurfacesAreWholeTreesAndGoWhenEmptied()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		DockSurfaceId floating = cNoDock;
		Test.Assert(layout.Float("profiler", .(100.0f, 80.0f, 400.0f, 300.0f), &floating).Ok);
		Test.Assert(layout.Surfaces.Count == 2);
		let stack = layout.StackOf("profiler");
		Test.Assert(layout.SurfaceOf(stack) == floating);
		Test.Assert(Near(layout.FindSurface(floating).Bounds.Width, 400.0f));
		// Docked into: a tab, and a stack beside.
		Test.Assert(layout.InsertTab("memory", stack).Ok);
		Test.Assert(layout.InsertBeside("counters", stack, .Bottom).Ok);
		Test.Assert(layout.SurfaceOf(layout.StackOf("counters")) == floating);
		// Everything moved out: the surface goes.
		Test.Assert(layout.MoveToTab("profiler", central).Ok);
		Test.Assert(layout.MoveToTab("memory", central).Ok);
		Test.Assert(layout.MoveToEdge("counters", layout.MainSurface, .End).Ok);
		Test.Assert(layout.FindSurface(floating) == null);
		Test.Assert(layout.Surfaces.Count == 1);
		Holds(layout);
	}

	[Test]
	public static void AFloatingSurfaceDocksWholeItsPanelsAsTabsItsTreeBesideAStackOrAlongAnEdge()
	{
		{
			let layout = scope DockLayout();
			DockSurfaceId floating;
			MakeFloat(layout, out floating);
			let central = layout.CentralStack;
			Test.Assert(layout.DockSurfaceInto(floating, central).Ok);
			let stack = layout.FindNode(central);
			Test.Assert(stack.Panels.Count == 4);
			Test.Assert(stack.Panels[1] == "profiler");
			Test.Assert(stack.Panels[2] == "memory");
			Test.Assert(stack.Panels[3] == "counters");
			Test.Assert(stack.Panels[(int)stack.Active] == "profiler"); // the float's first stack's active
			Test.Assert(layout.FindSurface(floating) == null);
			Holds(layout);
		}
		{
			let layout = scope DockLayout();
			DockSurfaceId floating;
			MakeFloat(layout, out floating);
			let central = layout.CentralStack;
			Test.Assert(layout.DockSurfaceBeside(floating, central, .Bottom, 0.4f).Ok);
			Test.Assert(layout.FindSurface(floating) == null);
			let root = Root(layout, layout.MainSurface);
			Test.Assert(root.Axis == .Vertical);
			Test.Assert(root.Children.Count == 2);
			Test.Assert(root.Children[0] == central);
			Test.Assert(Near(root.Weights[1], 0.4f));
			let moved = layout.FindNode(root.Children[1]); // the float's own split, kept
			Test.Assert(moved.Axis == .Horizontal);
			Test.Assert(moved.Children.Count == 2);
			Test.Assert(layout.SurfaceOf(layout.StackOf("counters")) == layout.MainSurface);
			Holds(layout);
		}
		{
			let layout = scope DockLayout();
			DockSurfaceId floating;
			MakeFloat(layout, out floating);
			Test.Assert(layout.InsertBeside("hierarchy", layout.CentralStack, .Start).Ok);
			Test.Assert(layout.DockSurfaceAtEdge(floating, layout.MainSurface, .End, 0.3f).Ok);
			let root = Root(layout, layout.MainSurface);
			Test.Assert(root.Axis == .Horizontal);
			// Same axis as the float's split: merged into one row, hierarchy | scene | profiler | memory.
			Test.Assert(root.Children.Count == 4);
			Test.Assert(layout.FindNode(root.Children[2]).Panels[0] == "profiler");
			Holds(layout);
		}
		{
			// Refusals change nothing.
			let layout = scope DockLayout();
			DockSurfaceId floating;
			MakeFloat(layout, out floating);
			let inside = layout.StackOf("memory");
			Test.Assert(!layout.DockSurfaceInto(floating, inside).Ok); // into itself
			Test.Assert(!layout.DockSurfaceBeside(layout.MainSurface, layout.CentralStack, .End).Ok); // not floating
			Test.Assert(!layout.DockSurfaceAtEdge(floating, floating, .End).Ok);
			Test.Assert(layout.SetStackFlags(layout.CentralStack, DockStackCentral | DockStackNoTabs).Ok);
			Test.Assert(!layout.DockSurfaceInto(floating, layout.CentralStack).Ok); // it holds one panel
			Test.Assert(layout.SetStackFlags(inside, DockStackLocked).Ok);
			Test.Assert(layout.SetStackFlags(layout.CentralStack, DockStackCentral).Ok);
			Test.Assert(!layout.DockSurfaceInto(floating, layout.CentralStack).Ok); // a locked stack's panels stay
			Test.Assert(layout.DockSurfaceBeside(floating, layout.CentralStack, .End).Ok); // whole, its stacks kept
			Holds(layout);
		}
	}

	[Test]
	public static void AStackMovesWholeIntoAnotherAsItsTabsBesideOneAlongAnEdgeFloated()
	{
		{
			let layout = scope DockLayout();
			MakeStacks(layout);
			let bottom = layout.StackOf("console");
			let hierarchy = layout.StackOf("hierarchy");
			Test.Assert(layout.MoveStackInto(bottom, hierarchy, 0).Ok);
			let into = layout.FindNode(hierarchy);
			Test.Assert(into.Panels.Count == 3);
			Test.Assert(into.Panels[0] == "console");
			Test.Assert(into.Panels[1] == "log");
			Test.Assert(into.Panels[2] == "hierarchy");
			Test.Assert(into.Panels[(int)into.Active] == "console"); // its active panel, active there
			Test.Assert(layout.FindNode(bottom) == null); // emptied, gone
			Holds(layout);
		}
		{
			let layout = scope DockLayout();
			MakeStacks(layout);
			let bottom = layout.StackOf("console");
			let hierarchy = layout.StackOf("hierarchy");
			Test.Assert(layout.MoveStackBeside(bottom, hierarchy, .Bottom, 0.4f).Ok);
			Test.Assert(layout.StackOf("log") == bottom); // the same stack, moved: its id kept
			let split = layout.FindNode(layout.FindNode(bottom).Parent);
			Test.Assert(split.Axis == .Vertical);
			Test.Assert(split.Children[0] == hierarchy);
			Test.Assert(split.Children[1] == bottom);
			Test.Assert(Near(split.Weights[1], 0.4f));
			// The scene, alone where the two were stacked, no longer in a vertical split.
			Test.Assert(layout.FindNode(layout.FindNode(layout.CentralStack).Parent).Axis == .Horizontal);
			Holds(layout);
		}
		{
			let layout = scope DockLayout();
			MakeStacks(layout);
			let hierarchy = layout.StackOf("hierarchy");
			Test.Assert(layout.MoveStackToEdge(hierarchy, layout.MainSurface, .End, 0.2f).Ok);
			let root = Root(layout, layout.MainSurface);
			Test.Assert(root.Axis == .Horizontal);
			Test.Assert(root.Children.Back == hierarchy);
			Test.Assert(Near(root.Weights.Back, 0.2f));
			Holds(layout);
		}
		{
			let layout = scope DockLayout();
			MakeStacks(layout);
			let bottom = layout.StackOf("console");
			DockSurfaceId floating = cNoDock;
			Test.Assert(layout.FloatStack(bottom, .(100.0f, 80.0f, 300.0f, 200.0f), &floating).Ok);
			let made = layout.FindSurface(floating);
			Test.Assert(made != null);
			Test.Assert(made.Kind == .Floating);
			Test.Assert(made.Root == bottom);
			Test.Assert(Near(made.Bounds.Width, 300.0f));
			Test.Assert(layout.FindNode(bottom).Panels.Count == 2);
			Holds(layout);
			// Alone in its float: it floats already; docked back beside the scene, the float goes.
			Test.Assert(!layout.FloatStack(bottom, .(0.0f, 0.0f, 300.0f, 200.0f)).Ok);
			Test.Assert(layout.MoveStackBeside(bottom, layout.CentralStack, .Top).Ok);
			Test.Assert(layout.FindSurface(floating) == null);
			Holds(layout);
		}
		{
			// The central stack's panels go; it stays, empty, where it was.
			let layout = scope DockLayout();
			MakeStacks(layout);
			Test.Assert(layout.InsertTab("game", layout.CentralStack).Ok);
			let central = layout.CentralStack;
			DockSurfaceId floating = cNoDock;
			Test.Assert(layout.FloatStack(central, .(0.0f, 0.0f, 300.0f, 200.0f), &floating).Ok);
			Test.Assert(layout.CentralStack == central);
			Test.Assert(layout.FindNode(central).Panels.IsEmpty);
			Test.Assert(layout.SurfaceOf(layout.StackOf("game")) == floating);
			Test.Assert(layout.FindNode(layout.StackOf("scene")).Panels.Count == 2);
			Holds(layout);
			Test.Assert(!layout.MoveStackInto(central, layout.StackOf("hierarchy")).Ok); // empty now
		}
		{
			// Refusals change nothing.
			let layout = scope DockLayout();
			MakeStacks(layout);
			let bottom = layout.StackOf("console");
			let hierarchy = layout.StackOf("hierarchy");
			Test.Assert(!layout.MoveStackInto(bottom, bottom).Ok);
			Test.Assert(!layout.MoveStackBeside(bottom, bottom, .End).Ok);
			Test.Assert(layout.SetStackFlags(hierarchy, DockStackNoTabs).Ok);
			Test.Assert(!layout.MoveStackInto(bottom, hierarchy).Ok); // it holds one panel
			Test.Assert(layout.SetStackFlags(hierarchy, DockStackNoSplit).Ok);
			Test.Assert(!layout.MoveStackBeside(bottom, hierarchy, .Top).Ok);
			Test.Assert(layout.SetStackFlags(bottom, DockStackLocked).Ok);
			Test.Assert(!layout.FloatStack(bottom, .(0.0f, 0.0f, 300.0f, 200.0f)).Ok);
			Test.Assert(layout.StackOf("log") == bottom);
			Test.Assert(layout.Surfaces.Count == 1);
			Holds(layout);
		}
	}

	[Test]
	public static void AClosedPanelIsShownWhereItWasOrNearItsNeighboursOrInTheCentre()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		Test.Assert(layout.InsertBeside("outline", central, .Start).Ok);
		let left = layout.StackOf("outline");
		Test.Assert(layout.InsertTab("assets", left).Ok);
		Test.Assert(layout.InsertTab("history", left).Ok);
		// Among its stack's tabs again, at its place.
		Test.Assert(layout.Close("assets").Ok);
		Test.Assert(layout.FindHidden("assets") != null);
		Test.Assert(layout.StackOf("assets") == cNoDock);
		Test.Assert(layout.Show("assets").Ok);
		Test.Assert(layout.StackOf("assets") == left);
		Test.Assert(layout.FindNode(left).Panels[1] == "assets");
		Test.Assert(layout.FindHidden("assets") == null);
		// Its stack gone: beside a panel that was about it.
		Test.Assert(layout.Close("outline").Ok);
		Test.Assert(layout.Close("assets").Ok);
		Test.Assert(layout.Close("history").Ok); // the stack goes
		Test.Assert(layout.FindNode(left) == null);
		// Closed alone, its neighbours were those beside its stack (the scene): beside them again.
		Test.Assert(layout.Show("history").Ok);
		let history = layout.StackOf("history");
		Test.Assert(history != central);
		Test.Assert(layout.FindNode(history).Parent == layout.FindNode(central).Parent);
		// Its stack's tabs gone too, outline goes beside one of them (history) docked again.
		Test.Assert(layout.Show("outline").Ok);
		Test.Assert(layout.StackOf("outline") != history);
		Test.Assert(layout.FindNode(layout.StackOf("outline")).Parent == layout.FindNode(history).Parent);
		// None of its neighbours docked: the central stack.
		Test.Assert(layout.Close("history").Ok);
		Test.Assert(layout.Close("outline").Ok);
		Test.Assert(layout.Close("scene").Ok);
		Test.Assert(layout.Show("history").Ok);
		Test.Assert(layout.StackOf("history") == central);
		Test.Assert(layout.Show("history").Refused == "it is docked");
		Holds(layout);
	}

	[Test]
	public static void FlagsRefuseAndARefusalChangesNothing()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("game", central).Ok);
		Test.Assert(layout.SetStackFlags(central, DockStackCentral | DockStackLocked | DockStackNoSplit).Ok);
		Test.Assert(!layout.InsertTab("x", central).Ok);
		Test.Assert(!layout.InsertBeside("x", central, .End).Ok);
		Test.Assert(!layout.Close("game").Ok);
		Test.Assert(!layout.MoveToTab("game", central, 0).Ok); // its stack is locked: it stays
		Test.Assert(!layout.SetStackFlags(central, 0).Ok); // the central stack stays the central one
		Test.Assert(!layout.InsertTab("", central).Ok);
		Test.Assert(layout.InsertAtEdge("x", layout.MainSurface, .Top).Ok); // the surface's edge is not beside it
		Test.Assert(!layout.InsertTab("x", layout.StackOf("x")).Ok); // docked already
		Holds(layout);
	}

	[Test]
	public static void AMaximizedStackDroppedWhenItGoes()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertBeside("side", central, .End).Ok);
		let side = layout.StackOf("side");
		Test.Assert(layout.Maximize(side).Ok);
		Test.Assert(layout.FindSurface(layout.MainSurface).Maximized == side);
		Test.Assert(layout.Close("side").Ok);
		Test.Assert(layout.FindSurface(layout.MainSurface).Maximized == cNoDock);
	}

	[Test]
	public static void ALongRunOfRandomOperationsTheLayoutHoldingTogetherAfterEach()
	{
		// A small generator of its own: the same runs every time.
		uint32[5] seeds = .(12345, 1, 777, 2026, 31337);
		for (let seed in seeds)
		{
			uint32 state = seed;
			String[10] names = .("p0", "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9");
			DockSide[4] sides = .(.Start, .End, .Top, .Bottom);
			let layout = scope DockLayout();
			int done = 0;
			for (int step < 4000)
			{
				let panel = names[Next(ref state, 10)];
				// A stack to act on: one that is there, or the central one.
				var stack = layout.CentralStack;
				let nodes = layout.Nodes;
				let pick = nodes[Next(ref state, (uint32)nodes.Count)];
				if (pick.IsStack)
					stack = pick.Id;
				let surface = layout.Surfaces[Next(ref state, (uint32)layout.Surfaces.Count)].Id;
				let side = sides[Next(ref state, 4)];
				let share = 0.1f + 0.1f * (float)Next(ref state, 8);
				DockOutcome outcome = .();
				// A floating surface to dock whole, when there is one.
				DockSurfaceId floating = cNoDock;
				for (let each in layout.Surfaces)
				{
					if (each.Kind == .Floating)
						floating = each.Id;
				}
				switch (Next(ref state, 17))
				{
				case 0: outcome = layout.InsertTab(panel, stack, (int32)Next(ref state, 4) - 1);
				case 1: outcome = layout.InsertBeside(panel, stack, side, share);
				case 2: outcome = layout.InsertAtEdge(panel, surface, side, share);
				case 3: outcome = layout.MoveToTab(panel, stack, (int32)Next(ref state, 4) - 1);
				case 4: outcome = layout.MoveBeside(panel, stack, side, share);
				case 5: outcome = layout.MoveToEdge(panel, surface, side, share);
				case 6: outcome = layout.Float(panel, .(0.0f, 0.0f, 300.0f, 200.0f));
				case 7: outcome = layout.Close(panel);
				case 8: outcome = layout.Show(panel);
				case 9: outcome = layout.DockSurfaceInto(floating, stack);
				case 10: outcome = layout.DockSurfaceBeside(floating, stack, side, share);
				case 11: outcome = layout.DockSurfaceAtEdge(floating, surface, side, share);
				case 12: outcome = layout.MoveStackInto(stack, layout.StackOf(panel), (int32)Next(ref state, 4) - 1);
				case 13: outcome = layout.MoveStackBeside(stack, layout.StackOf(panel), side, share);
				case 14: outcome = layout.MoveStackToEdge(stack, surface, side, share);
				case 15: outcome = layout.FloatStack(stack, .(0.0f, 0.0f, 300.0f, 200.0f));
				default: outcome = layout.Maximize(stack);
				}
				done += outcome.Ok ? 1 : 0;
				let why = scope String();
				if (!layout.CheckInvariants(why))
				{
					Test.Assert(false, scope String()..AppendF("seed {}, step {}: {}", seed, step, why));
					return;
				}
			}
			Test.Assert(done > 1000); // most did something
		}
	}

	/// A closed panel forgotten is remembered no more: shown again it is new to the layout (its
	/// place gone), and forgetting what is not closed is refused, changing nothing.
	[Test]
	public static void AClosedPanelForgottenHasNoPlaceLeftAndForgettingOneNotClosedIsRefused()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		Test.Assert(layout.InsertBeside("outline", central, .Start).Ok);
		Test.Assert(layout.Forget("outline").Refused == "it is not closed"); // docked, not closed
		Test.Assert(layout.Forget("never").Refused == "it is not closed");
		Test.Assert(layout.Close("outline").Ok);
		Test.Assert(layout.FindHidden("outline") != null);
		Test.Assert(layout.Forget("outline").Ok);
		Test.Assert(layout.FindHidden("outline") == null);
		Test.Assert(layout.Hidden.IsEmpty);
		Test.Assert(layout.Show("outline").Refused == "it was never closed");
		Test.Assert(!layout.Forget("outline").Ok); // once is all
		// Docked again from new, it is at the place it is given, not where it was.
		Test.Assert(layout.InsertTab("outline", central).Ok);
		Test.Assert(layout.StackOf("outline") == central);
		Holds(layout);
	}

	/// A share asked for past the ends is kept to between a twentieth and nineteen twentieths:
	/// neither side of a split is left with nothing, nor a negative share.
	[Test]
	public static void AShareAskedPastTheEndsKeepsBothSidesOfTheSplit()
	{
		let layout = scope DockLayout();
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		Test.Assert(layout.InsertBeside("hierarchy", central, .Start, 2.0f).Ok);
		var root = Root(layout, layout.MainSurface);
		Test.Assert(Near(root.Weights[0], 0.95f));
		Test.Assert(Near(root.Weights[1], 0.05f));
		Test.Assert(layout.InsertBeside("console", central, .Bottom, -1.0f).Ok);
		let split = layout.FindNode(layout.FindNode(central).Parent);
		Test.Assert(split.Axis == .Vertical);
		Test.Assert(Near(split.Weights[1], 0.05f));
		Holds(layout);
	}
}
