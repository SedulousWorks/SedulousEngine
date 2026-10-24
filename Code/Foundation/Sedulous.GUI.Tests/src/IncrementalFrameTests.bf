using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Incremental frames: a frame restyles only the widgets that changed and their subtrees, lays out
// only the containers that asked, once per frame, and an idle GUI needs no frame at all.

/// A node whose drawing marks another node (one drawn before it) dirty, once.
class Toucher : Node
{
	public Node Touches = null;
	public bool Done = false;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if ((Touches != null) && !Done)
		{
			Done = true;
			Touches.Invalidate();
		}
	}
}

/// Incremental frames: what an unchanged, a hovered, a reclassed or an animating GUI redoes, and
/// what a deferred layout, a hidden subtree and an animation out of view ask for.
class IncrementalFrameTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new widget tagged `tag`, 40 x 20, held by the caller.
	private static UIWidget Widget(StringView tag)
	{
		let w = new UIWidget();
		w.Tag = tag;
		w.Size = .(40.0f, 20.0f);
		return w;
	}

	/// A new widget tagged `tag`, 40 x 20, the last child of `parent` (borrowed: the tree holds it).
	private static UIWidget AddWidget(Node parent, StringView tag)
	{
		let w = Widget(tag);
		parent.AddChild(w);
		w.ReleaseRef();
		return w;
	}

	/// `styles` styling by `css`.
	private static void UseSheet(StyleManager styles, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
	}

	/// One host frame: styles, ticks, lays out and draws, as a sample does.
	private static void Frame(SceneRoot root, StyleManager styles)
	{
		styles.ApplyTree(root);
		root.Context.Update(SceneFixtures.Frame);
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.Draw(dc);
	}

	[Test]
	public static void AnUnchangedFrameRestylesNothingAndNeedsNoFrame()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = AddWidget(root, "panel");
		AddWidget(a, "button");
		let styles = scope StyleManager();
		UseSheet(styles, "panel { opacity: 0.8; } button { background-color: red; }");

		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount >= 2);
		Test.Assert(!root.NeedsFrame());

		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount == 0);
		Test.Assert(root.LastLayoutCount == 0);
		Test.Assert(!root.NeedsFrame());
	}

	[Test]
	public static void AClassChangeRestylesOnlyThatWidgetsSubtree()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let left = AddWidget(root, "panel");
		let leftChild = AddWidget(left, "button");
		let right = AddWidget(root, "panel");
		let rightChild = AddWidget(right, "button");
		let styles = scope StyleManager();
		UseSheet(styles, ".on button { opacity: 0.25; }");
		Frame(root, styles);

		left.AddClass("on");
		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount == 2); // left and its child; right's side untouched
		Test.Assert(Near(leftChild.Alpha, 0.25f));
		Test.Assert(Near(rightChild.Alpha, 1.0f));
	}

	[Test]
	public static void HoverRestylesTheHoveredWidgetAlone()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = AddWidget(root, "button");
		let b = AddWidget(root, "button");
		b.Position = .(100.0f, 0.0f);
		let styles = scope StyleManager();
		UseSheet(styles, "button:hover { opacity: 0.5; }");
		Frame(root, styles);

		let d = root.EventDispatcher;
		d.InjectMouseMove(.(10.0f, 190.0f)); // into the GUI, over nothing in it
		Frame(root, styles);
		d.InjectMouseMove(.(10.0f, 10.0f));
		Test.Assert(root.NeedsFrame());
		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount == 1);
		Test.Assert(Near(a.Alpha, 0.5f));

		d.InjectMouseMove(.(12.0f, 12.0f)); // still over it: nothing to do
		Test.Assert(!root.NeedsFrame());
	}

	[Test]
	public static void AChangedCustomPropertyRestylesTheChildrenThatReadIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let panel = AddWidget(root, "panel");
		panel.Size = .(200.0f, 200.0f);
		let button = AddWidget(panel, "button");
		button.Position = .(100.0f, 100.0f);
		let styles = scope StyleManager();
		UseSheet(styles, "panel { --fade: 0.9; } panel.dim { --fade: 0.3; } button { opacity: var(--fade); }");
		Frame(root, styles);
		Test.Assert(Near(button.Alpha, 0.9f));

		panel.AddClass("dim"); // marks the panel's subtree
		Frame(root, styles);
		Test.Assert(Near(button.Alpha, 0.3f));

		// A state change no rule reads through the panel restyles the panel alone.
		root.EventDispatcher.InjectMouseMove(.(10.0f, 10.0f)); // over the panel only
		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount == 1);
		Test.Assert(Near(button.Alpha, 0.3f));
	}

	/// The panel's hover alone changes under `css`: how many widgets the frame restyled.
	private static uint32 RestyledByPanelHover(StringView css)
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let panel = AddWidget(root, "panel");
		panel.Size = .(100.0f, 100.0f);
		for (int i = 0; i < 4; i++)
		{
			let label = AddWidget(panel, "label");
			label.Position = .(0.0f, 200.0f + (float)i * 10.0f); // away from the pointer
		}
		let after = AddWidget(root, "note");
		after.Position = .(300.0f, 300.0f);
		let styles = scope StyleManager();
		UseSheet(styles, css);
		root.EventDispatcher.InjectMouseMove(.(390.0f, 390.0f)); // in the window, over nothing
		Frame(root, styles);
		root.EventDispatcher.InjectMouseMove(.(10.0f, 10.0f)); // the panel's hover alone changes
		Frame(root, styles);
		return styles.LastRestyleCount;
	}

	[Test]
	public static void AStateRestylesTheSubtreeOrTheLaterSiblingsOnlyWhenARuleReadsItThere()
	{
		Test.Assert(RestyledByPanelHover("panel:hover { opacity: 0.5; }") == 1); // the panel alone
		Test.Assert(RestyledByPanelHover("panel:hover label { opacity: 0.5; }") == 5); // and its four labels
		Test.Assert(RestyledByPanelHover("panel:hover + note { opacity: 0.5; }") == 2); // and the note after it
		Test.Assert(RestyledByPanelHover(":is(panel:hover) > label { opacity: 0.5; }") == 5); // read inside :is() too
		Test.Assert(RestyledByPanelHover("label:not(:hover) { opacity: 0.5; }") == 1); // a subject's own state
	}

	private struct JoinRun
	{
		public uint32 Restyled;
		public float OldLastLabel;
		public float NewLabel;
	}

	/// A list of an `other` row and three rows, then a fourth row joining, under `css`: how many
	/// widgets that frame restyled, and the old last label's and the new label's opacity.
	private static JoinRun RowJoins(StringView css)
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let list = AddWidget(root, "panel");
		let labels = scope List<UIWidget>(); // borrowed: the tree holds them
		void AddRow(StringView tag)
		{
			let r = Widget(tag);
			for (int i = 0; i < ((tag == "row") ? 1 : 2); i++)
				labels.Add(AddWidget(r, "label"));
			list.AddChild(r);
			r.ReleaseRef();
		}
		AddRow("other");
		for (int i = 0; i < 3; i++)
			AddRow("row");
		let styles = scope StyleManager();
		UseSheet(styles, css);
		Frame(root, styles);
		let oldLast = labels[labels.Count - 1];
		AddRow("row");
		Frame(root, styles);
		JoinRun run = default;
		run.Restyled = styles.LastRestyleCount;
		run.OldLastLabel = oldLast.Alpha;
		run.NewLabel = labels[labels.Count - 1].Alpha;
		return run;
	}

	// A popup, tooltip or window joining the root rearranges its children. Restyling each child's
	// whole subtree for it restyled the whole page each time (a second in Debug); a child's subtree
	// restyles only when a rule reads siblings in a compound that child can match, with a step
	// below.
	[Test]
	public static void AChildJoiningRestylesItsSiblingsAndWhatTheyHoldOnlyWhenARuleReadsSiblingsThere()
	{
		Test.Assert(RowJoins("label { opacity: 0.9; }").Restyled == 3); // the list (its children changed), the new row, its label
		Test.Assert(RowJoins("row:last-child { opacity: 0.5; }").Restyled == 7); // and the four children before it themselves
		let through = RowJoins("row:last-child label { opacity: 0.5; }");
		Test.Assert(through.Restyled == 10); // and the old rows' labels; not the other's two
		Test.Assert(Near(through.OldLastLabel, 1.0f));
		Test.Assert(Near(through.NewLabel, 0.5f));
		Test.Assert(RowJoins("row + row label { opacity: 0.5; }").Restyled == 10);
		Test.Assert(RowJoins(":first-child label { opacity: 0.5; }").Restyled == 12); // a compound any child matches
	}

	[Test]
	public static void ASheetChangeRestylesEverythingOnce()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let a = AddWidget(root, "button");
		let styles = scope StyleManager();
		UseSheet(styles, "button { opacity: 1; }");
		Frame(root, styles);

		UseSheet(styles, "button { opacity: 0.6; }");
		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount >= 1);
		Test.Assert(Near(a.Alpha, 0.6f));
		Frame(root, styles);
		Test.Assert(styles.LastRestyleCount == 0);
	}

	[Test]
	public static void ARunningAnimationKeepsFramesComingUntilItEnds()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let a = AddWidget(root, "button");
		let styles = scope StyleManager();
		UseSheet(styles, "button { opacity: 1; transition: opacity 0.1s linear; } button.off { opacity: 0; }");
		Frame(root, styles);
		Test.Assert(!root.NeedsFrame());

		a.AddClass("off");
		Frame(root, styles);
		Test.Assert(root.NeedsFrame()); // the transition runs
		for (int i = 0; i < 20; i++)
			Frame(root, styles);
		Test.Assert(Near(a.Alpha, 0.0f));
		Test.Assert(!root.NeedsFrame());
	}

	[Test]
	public static void SettingGeometryToWhatItIsChangesNothing()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let a = Widget("button");
		a.Position = .(5.0f, 6.0f);
		root.AddChild(a);
		a.ReleaseRef();
		let styles = scope StyleManager();
		UseSheet(styles, "button { opacity: 1; }");
		Frame(root, styles);
		Test.Assert(!root.NeedsFrame());

		a.Position = .(5.0f, 6.0f);
		a.Size = .(40.0f, 20.0f);
		a.Scale = .(1.0f, 1.0f);
		a.Rotation = 0.0f;
		Test.Assert(!root.NeedsFrame());

		a.Position = .(7.0f, 6.0f);
		Test.Assert(root.NeedsFrame());
	}

	[Test]
	public static void ManyAddsToALayoutInASceneLayItOutOnceAtTheFrame()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let column = new Panel();
		defer column.ReleaseRef();
		column.Size = .(100.0f, 400.0f);
		root.AddChild(column);
		root.UpdateLayout();

		let rows = scope List<UIWidget>();
		defer
		{
			for (let r in rows)
				r.ReleaseRef();
		}
		for (int i = 0; i < 10; ++i)
		{
			let row = Widget("row");
			column.AddChild(row);
			rows.Add(row);
		}
		Test.Assert(Near(rows[9].Position.Y, 0.0f)); // deferred: not yet placed
		Test.Assert(root.NeedsFrame());

		root.UpdateLayout();
		Test.Assert(root.LastLayoutCount == 1);
		Test.Assert(Near(rows[9].Position.Y, 180.0f)); // nine 20-high rows above
		root.UpdateLayout();
		Test.Assert(root.LastLayoutCount == 0);
	}

	[Test]
	public static void ALayoutOutsideASceneLaysOutWhenAsked()
	{
		let column = new Panel();
		defer column.ReleaseRef();
		column.Size = .(100.0f, 400.0f);
		let a = Widget("row");
		defer a.ReleaseRef();
		let b = Widget("row");
		defer b.ReleaseRef();
		column.AddChild(a);
		column.AddChild(b);
		Test.Assert(column.UpdateLayout() == 1);
		Test.Assert(Near(b.Position.Y, 20.0f));
	}

	[Test]
	public static void AChildResizedAfterALayoutLaysItsContainerOutAgainOnce()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let column = new Panel();
		defer column.ReleaseRef();
		column.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		column.Size = .(200.0f, 400.0f);
		root.AddChild(column);
		let a = new UIWidget(); // unsized when the layout first meets them
		defer a.ReleaseRef();
		let b = new UIWidget();
		defer b.ReleaseRef();
		a.Tag = "item";
		b.Tag = "item";
		column.AddChild(a);
		column.AddChild(b);
		root.UpdateLayout();
		Test.Assert(Near(b.Position.Y, 0.0f)); // both empty, stacked at the top

		// The sheet sizes them afterwards (a frame's restyle): the flex takes the new basis.
		let styles = scope StyleManager();
		UseSheet(styles, "item { width: 100px; height: 40px; }");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(Near(b.Position.Y, 40.0f));
		Test.Assert(Near(b.Size.Y, 40.0f));

		root.UpdateLayout(); // its own writes asked for nothing more
		Test.Assert(root.LastLayoutCount == 0);
	}

	[Test]
	public static void AChildDisplayedOrNotLaysItsContainerOutAgain()
	{
		// The showcase's panels: one shown in place of another after the first layout lands in the
		// slot the other had, not wherever it was left.
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let column = new Panel();
		defer column.ReleaseRef();
		column.Size = .(200.0f, 400.0f);
		root.AddChild(column);
		AddWidget(column, "title");
		let menu = AddWidget(column, "menu");
		let settings = AddWidget(column, "settings");
		settings.Displayed = false;
		root.UpdateLayout();
		Test.Assert(Near(menu.Position.Y, 20.0f));

		menu.Displayed = false;
		settings.Displayed = true;
		root.UpdateLayout();
		Test.Assert(root.LastLayoutCount >= 1);
		Test.Assert(Near(settings.Position.Y, 20.0f)); // under the title, where the menu was
		root.UpdateLayout();
		Test.Assert(root.LastLayoutCount == 0);
	}

	[Test]
	public static void AChangeUnderANodeThatWasHiddenThroughAFrameStillAsksForAFrame()
	{
		// A hidden node is not drawn, so it keeps its invalidation: a change under it later must
		// still reach the root (pooled item rows are hidden and shown again; their changes went
		// unseen).
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let row = AddWidget(root, "panel");
		let label = new Label();
		defer label.ReleaseRef();
		row.AddChild(label);
		let styles = scope StyleManager();
		UseSheet(styles, "panel { opacity: 1; }");
		row.Displayed = false;
		Frame(root, styles);
		Test.Assert(!root.NeedsFrame());
		row.Displayed = true;
		Frame(root, styles);
		Test.Assert(!root.NeedsFrame());
		row.Displayed = false;
		Frame(root, styles);
		label.Text = "changed while hidden";
		Frame(root, styles);
		row.Displayed = true;
		label.Text = "changed again, shown";
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(root.NeedsFrame());
	}

	[Test]
	public static void ANodeMarkedDuringTheFramesDrawingDoesNotStopLaterChangesUnderItAskingForAFrame()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = AddWidget(root, "panel");
		let label = new Label();
		defer label.ReleaseRef();
		a.AddChild(label);
		let toucher = new Toucher();
		defer toucher.ReleaseRef();
		toucher.Size = .(10.0f, 10.0f);
		toucher.Touches = a; // drawn after `a`, it marks `a` again
		root.AddChild(toucher);
		let styles = scope StyleManager();
		UseSheet(styles, "panel { opacity: 1; }");
		Frame(root, styles); // `a` is marked again after it was drawn
		// A host skips a frame the root does not need, so `a` stays marked; a change under it must
		// still reach the root.
		label.Text = "a change under it";
		styles.ApplyTree(root);
		root.UpdateLayout(); // as a host does before it asks
		Test.Assert(root.NeedsFrame());
	}

	[Test]
	public static void AnAnimationOnAPageOutOfViewAsksForNoFramesOneInViewDoesHidingAsksForOne()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let page = AddWidget(root, "panel");
		let bar = new ProgressBar();
		defer bar.ReleaseRef();
		bar.Size = .(100.0f, 10.0f);
		page.AddChild(bar);
		bar.Indeterminate = true; // sweeps on the GUI's clock
		let styles = scope StyleManager();
		UseSheet(styles, "panel { opacity: 1; }");
		Frame(root, styles);
		Frame(root, styles);
		root.UpdateLayout();
		Test.Assert(root.NeedsFrame()); // shown: its sweep moves

		page.Displayed = false;
		root.UpdateLayout();
		Frame(root, styles);
		Frame(root, styles);
		root.UpdateLayout();
		Test.Assert(!root.NeedsFrame()); // out of view: nothing on screen moves

		page.Displayed = true;
		root.UpdateLayout();
		Frame(root, styles);
		root.UpdateLayout();
		Test.Assert(root.NeedsFrame()); // back in view, sweeping again

		let still = AddWidget(root, "panel");
		bar.Indeterminate = false;
		Frame(root, styles);
		Frame(root, styles);
		root.UpdateLayout();
		Test.Assert(!root.NeedsFrame());
		still.Visible = false; // what drew it must draw again
		Test.Assert(root.NeedsFrame());
	}
}
