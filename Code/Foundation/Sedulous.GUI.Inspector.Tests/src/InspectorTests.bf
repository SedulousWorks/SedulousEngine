using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.GUI.Inspector;

namespace Sedulous.GUI.Inspector.Tests;

/// The inspector: its tree follows the inspected one, its details show what a node is and where
/// its styles came from, and picking walks out through what holds the node under the pointer and
/// selects on a click; its details say what a screen reader is told.
class InspectorTests
{
	/// A root 300 by 200 holding a page (#page, padded 10 by its sheet) holding a button (#ok,
	/// 80 by 30), styled, laid out and inspected.
	private class Bed
	{
		public GUIContext Context = new .();
		public SceneRoot Root;
		public Panel Page = new .();
		public Button Ok = new .();
		public StyleManager Styles;
		public Inspector Inspect;

		public this()
		{
			Root = new SceneRoot(Context);
			let sheet = scope StyleSheet();
			CSSParser.Parse("#page { padding: 10px; }\nbutton { opacity: 0.8; }\n", "app.css", sheet);
			Styles = new StyleManager(sheet);
			Inspect = new Inspector(Context, null);

			Root.Size = .(300.0f, 200.0f);
			Page.Id = "page";
			Page.Size = .(300.0f, 200.0f);
			Root.AddChild(Page);
			Ok.Id = "ok";
			Ok.Size = .(80.0f, 30.0f);
			Page.AddChild(Ok);
			Styles.ApplyTree(Root);
			Root.UpdateLayout();
			Inspect.Inspect(Root, Styles);
			Inspect.Refresh();
		}

		public ~this()
		{
			delete Inspect;
			delete Styles;
			Ok?.ReleaseRef();
			Page.ReleaseRef();
			Root.ReleaseRef();
			Context.ReleaseRef();
		}

		public bool DetailsHave(StringView text)
		{
			let lines = scope List<String>();
			defer { ClearAndDeleteItems!(lines); }
			Inspect.DetailsText(lines);
			for (let line in lines)
			{
				if (line == text)
					return true;
			}
			return false;
		}

		/// The last field under the inspector's root showing `text`, or null.
		public TextField FieldShowing(StringView text) => FieldIn(Inspect.Root, text);

		private static TextField FieldIn(Node node, StringView text)
		{
			TextField found = null;
			if (let f = node as TextField)
			{
				if (f.Text == text)
					found = f;
			}
			for (int i = 0; i < node.ChildCount; i++)
			{
				if (let inner = FieldIn(node.GetChildAt(i), text))
					found = inner;
			}
			return found;
		}
	}

	[Test]
	public static void ItsTreeListsTheInspectedOneAndFollowsItWhenItChanges()
	{
		let bed = scope Bed();
		let before = bed.Inspect.TreeRowCount;
		Test.Assert(before >= 3);
		let more = new Panel();
		defer more.ReleaseRef();
		bed.Page.AddChild(more);
		for (int i = 0; i < 10; i++) // the shape is checked every few refreshes
			bed.Inspect.Refresh();
		Test.Assert(bed.Inspect.TreeRowCount == before + 1);
	}

	[Test]
	public static void TheDetailsShowWhatTheSelectedNodeIsAndWhereItsStylesCameFrom()
	{
		let bed = scope Bed();
		Test.Assert(bed.DetailsHave("Nothing selected: pick a node, choose one in the tree, or query a selector."));
		bed.Inspect.Select(bed.Ok);
		Test.Assert(bed.Inspect.Selected == bed.Ok);
		Test.Assert(bed.DetailsHave("Button #ok"));
		Test.Assert(bed.DetailsHave("button   app.css:2")); // the rule, its sheet and line
		Test.Assert(bed.DetailsHave("opacity")); // the declaration: its name, and its value in a field
		Test.Assert(bed.DetailsHave("0.8"));
		bed.Inspect.Select(bed.Page);
		Test.Assert(bed.DetailsHave("#page   app.css:1"));
		Test.Assert(bed.DetailsHave("padding-top"));
		Test.Assert(bed.DetailsHave("10px"));
		bed.Page.RemoveChild(bed.Ok);
		bed.Inspect.Select(bed.Ok);
		bed.Ok.ReleaseRef(); // gone: the selection lets it go
		bed.Ok = null;
		Test.Assert(bed.Inspect.Selected == null);
	}

	[Test]
	public static void PickingOutlinesWhatIsUnderThePointerTheWheelWalksOutToWhatHoldsItAClickSelects()
	{
		let bed = scope Bed();
		bed.Inspect.Picking = true;
		bed.Inspect.PickHover(.(30.0f, 25.0f)); // inside the button (the page's padding is 10)
		Test.Assert(bed.Inspect.Hovered == bed.Ok);
		bed.Inspect.PickWheel(1.0f); // out to the page
		Test.Assert(bed.Inspect.Hovered == bed.Page);
		bed.Inspect.PickWheel(-1.0f); // back in
		Test.Assert(bed.Inspect.Hovered == bed.Ok);
		bed.Inspect.PickClick();
		Test.Assert(!bed.Inspect.Picking);
		Test.Assert(bed.Inspect.Selected == bed.Ok);
		Test.Assert(bed.Inspect.Hovered == null);
	}

	[Test]
	public static void FramesRecordedReachTheFramesTab()
	{
		let bed = scope Bed();
		let stats = scope FrameStats();
		stats.DrawMs = 2.0;
		bed.Inspect.RecordFrame(stats);
		bed.Inspect.RecordFrame(stats);
		Test.Assert(bed.Inspect.Root.ChildCount == 1); // its shell
	}

	[Test]
	public static void ABranchFoldsOutOfTheTreeAndOpensAgainAndSelectingInsideItOpensIt()
	{
		let bed = scope Bed();
		let all = bed.Inspect.TreeRowCount;
		bed.Inspect.SetCollapsed(bed.Page, true);
		Test.Assert(bed.Inspect.IsCollapsed(bed.Page));
		Test.Assert(bed.Inspect.TreeRowCount < all); // the button and its parts are gone from the list
		let folded = bed.Inspect.TreeRowCount;
		bed.Inspect.Select(bed.Ok); // inside the fold: it opens
		Test.Assert(!bed.Inspect.IsCollapsed(bed.Page));
		Test.Assert(bed.Inspect.TreeRowCount == all);
		bed.Inspect.SetCollapsed(bed.Page, true);
		Test.Assert(bed.Inspect.TreeRowCount == folded);
		bed.Inspect.SetCollapsed(bed.Page, false);
		Test.Assert(bed.Inspect.TreeRowCount == all);
	}

	[Test]
	public static void AStyleValueEditedInItsFieldChangesTheRuleAndEveryNodeItMatchesFollows()
	{
		let bed = scope Bed();
		bed.Inspect.Select(bed.Ok);
		// The field showing opacity's 0.8 (the button rule's).
		let field = bed.FieldShowing("0.8");
		Test.Assert(field != null);
		let d = bed.Inspect.Root.EventDispatcher;
		d.FocusNode = field;
		field.Text = "0.3";
		d.InjectKeyDown((uint32)KeyCode.Return);
		bed.Styles.ApplyTree(bed.Root);
		Test.Assert(Math.Abs(bed.Ok.Alpha - 0.3f) < 1e-4f);
		bed.Inspect.Refresh(); // shown again, with the new value
		Test.Assert(bed.DetailsHave("0.3"));
	}

	[Test]
	public static void TheDetailsSayWhatAScreenReaderIsToldOfTheNode()
	{
		let bed = scope Bed();
		bed.Ok.Text = "Save";
		bed.Inspect.Select(bed.Ok);
		Test.Assert(bed.DetailsHave("Accessibility"));
		Test.Assert(bed.DetailsHave("button \"Save\""));
		Test.Assert(bed.DetailsHave("audit: nothing in this GUI a screen reader trips on"));
	}

	// --- Further behaviour ---

	[Test]
	public static void AReflectedPropertyEditedInItsFieldSetsItAsMarkupDoes()
	{
		let bed = scope Bed();
		bed.Ok.Text = "Save";
		bed.Inspect.Select(bed.Ok);
		let field = bed.FieldShowing("Save"); // the Text property's
		Test.Assert(field != null);
		let d = bed.Inspect.Root.EventDispatcher;
		d.FocusNode = field;
		field.Text = "Go";
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(bed.Ok.Text == "Go");
	}

	[Test]
	public static void AForcedStateToggleSetsTheSelectedNodesForcedStatesAndTheDetailsListThem()
	{
		let bed = scope Bed();
		bed.Inspect.Select(bed.Ok);
		Test.Assert(bed.DetailsHave(":hover")); // the toggle
		Test.Assert(bed.DetailsHave("(none)")); // no state yet
		bed.Ok.ForcedStyleStates = Node.StateHover;
		bed.Inspect.Select(bed.Ok); // shown again
		Test.Assert(bed.DetailsHave("hover (forced)"));
	}

	[Test]
	public static void ASelectorQuerySelectsTheFirstMatchAndSaysHowManyItMatched()
	{
		let bed = scope Bed();
		Test.Assert(bed.Inspect.SelectQuery("#ok") == 1);
		Test.Assert(bed.Inspect.Selected == bed.Ok);
		Test.Assert(bed.Inspect.SelectQuery(".nothing") == 0);
		Test.Assert(bed.Inspect.Selected == bed.Ok); // nothing matched: the selection stays
	}

	[Test]
	public static void TheFramesGraphKeepsTheLastFramesAndNoMore()
	{
		let graph = new FramesGraph();
		defer graph.ReleaseRef();
		let stats = scope FrameStats();
		stats.StyleMs = 1.0;
		for (int i = 0; i < FramesGraph.cFrames + 10; i++)
			graph.Record(stats);
		Test.Assert(graph.SampleCount == FramesGraph.cFrames);
		Test.Assert(FramesGraph.cFrames == 240);
	}

	[Test]
	public static void APickingPathIsEmptyWhenPickingIsOffAndTheWheelStopsAtTheOutermostNode()
	{
		let bed = scope Bed();
		bed.Inspect.PickHover(.(30.0f, 25.0f)); // not picking: nothing
		Test.Assert(bed.Inspect.Hovered == null);
		bed.Inspect.Picking = true;
		bed.Inspect.PickHover(.(30.0f, 25.0f));
		for (int i = 0; i < 5; i++)
			bed.Inspect.PickWheel(1.0f);
		Test.Assert(bed.Inspect.Hovered == bed.Page); // the path stops below the root
		bed.Inspect.PickWheel(-1.0f);
		bed.Inspect.PickWheel(-1.0f);
		Test.Assert(bed.Inspect.Hovered == bed.Ok);
	}
}
