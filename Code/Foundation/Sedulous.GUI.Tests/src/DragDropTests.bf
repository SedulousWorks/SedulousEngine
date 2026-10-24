using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Drag and drop: a press past the threshold offers the drag up from the pressed node, a node owning
/// its press ending the walk; every move, modifier change and requery asks the node under the
/// pointer and up its ancestors what a drop would do (an effect, a reason, a place); the cursor, the
/// preview (a DragPreview, Node's default) and a hint show it; a release drops, Escape, a right
/// press or the source leaving cancels; the source is told how it ended; a finger drags after a long
/// press; a source may follow the drag itself, with no preview. Across roots of one GUI, where a
/// host tells where they are: a drag goes on over another root, its targets asked there, and one let
/// go over none ends outside, where on the screen said; a root gone mid-drag is forgotten.
class DragDropTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A box at a place of its own in `root`, which holds it (borrowed).
	private static Panel Box(Node root, float x, float y, float w, float h)
	{
		let panel = new Panel();
		panel.EditLayoutStyle(scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(x);
				s.Top = LayoutLength.Px(y);
				s.Width = LayoutLength.Px(w);
				s.Height = LayoutLength.Px(h);
			});
		root.AddChild(panel);
		panel.ReleaseRef();
		return panel;
	}

	/// A root holding a source that drags a card and a target beside it. The root (and the tree) go
	/// with the scene.
	private class Scene
	{
		public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
		public Panel Source;
		public Panel Target;
		public DragResult Ended = .();
		public int Ends = 0;

		public this()
		{
			Source = Box(Root, 10.0f, 10.0f, 80.0f, 40.0f);
			Target = Box(Root, 200.0f, 10.0f, 100.0f, 100.0f);
			Source.SetDragSource(new (request) =>
				{
					request.Payload.Type.Set("card");
					request.Payload.Value.Dispose();
					request.Payload.Value = TextVariant("ace");
					request.Payload.Label.Set("Ace of spades");
					return true;
				});
			Source.SetOnDragEnd(new (result) =>
				{
					Ended = result;
					Ends++;
				});
			Root.UpdateLayout();
		}

		public EventDispatcher D => Root.EventDispatcher;

		/// Presses the source and moves `to`, in steps.
		public void DragTo(Float2 to, uint32 modifiers = 0)
		{
			D.InjectMouseDown(.(30.0f, 30.0f), .Left);
			D.InjectMouseMove(.(40.0f, 30.0f), modifiers);
			D.InjectMouseMove(to, modifiers);
		}
	}

	[Test]
	public static void APressStartsADragOnlyPastTheThresholdAndThePressIsCancelledNoClick()
	{
		let s = scope Scene();
		int clicks = 0;
		s.Source.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		bool started = false;
		s.Source.AddEventListener(.DragStart, new [&] (e) => { started = true; });
		s.D.InjectMouseDown(.(30.0f, 30.0f), .Left);
		s.D.InjectMouseMove(.(33.0f, 31.0f)); // 4 px: short of the 6
		Test.Assert(!s.D.IsDragging);
		s.D.InjectMouseMove(.(38.0f, 31.0f));
		Test.Assert(s.D.IsDragging);
		Test.Assert(started);
		Test.Assert(s.D.DragSource == s.Source);
		Test.Assert(s.Source.IsDragSource); // `:drag-source`
		Test.Assert(s.D.DragPayload.Type == "card");
		s.D.InjectMouseUp(.(38.0f, 31.0f), .Left);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(clicks == 0);
		Test.Assert(s.Ends == 1);
		Test.Assert(s.Ended.Effect == .None); // dropped where nothing takes it
		Test.Assert(!s.Source.IsDragSource);

		// A press too short to drag still clicks.
		s.D.InjectMouseDown(.(30.0f, 30.0f), .Left);
		s.D.InjectMouseUp(.(31.0f, 30.0f), .Left);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void TheDragIsOfferedUpFromThePressedNodeOneOwningItsPressEndsTheWalk()
	{
		let s = scope Scene();
		// A plain child of the source: the source above it gives the drag.
		let child = new Panel();
		defer child.ReleaseRef();
		child.EditLayoutStyle(scope (st) =>
			{
				st.Width = LayoutLength.Px(20.0f);
				st.Height = LayoutLength.Px(20.0f);
			});
		s.Source.AddChild(child);
		s.Root.UpdateLayout();
		let c = child.ScreenBounds;
		let at = Float2(c.X + 5.0f, c.Y + 5.0f);
		s.D.InjectMouseDown(at, .Left);
		s.D.InjectMouseMove(.(at.X + 20.0f, at.Y));
		Test.Assert(s.D.IsDragging);
		Test.Assert(s.D.DragSource == s.Source);
		s.D.CancelDrag();
		s.D.InjectMouseUp(at, .Left);

		// A slider inside the source owns its press: no drag, the slider moves instead.
		child.RemoveFromParent();
		let slider = new Slider();
		defer slider.ReleaseRef();
		slider.EditLayoutStyle(scope (st) =>
			{
				st.Width = LayoutLength.Px(70.0f);
				st.Height = LayoutLength.Px(20.0f);
			});
		s.Source.AddChild(slider);
		s.Root.UpdateLayout();
		let sl = slider.ScreenBounds;
		s.D.InjectMouseDown(.(sl.X + 10.0f, sl.Y + 10.0f), .Left);
		s.D.InjectMouseMove(.(sl.X + 50.0f, sl.Y + 10.0f));
		Test.Assert(!s.D.IsDragging);
		Test.Assert(slider.Value > 0.0);
		s.D.InjectMouseUp(.(sl.X + 50.0f, sl.Y + 10.0f), .Left);
	}

	[Test]
	public static void EachMoveAsksTheNodeUnderThePointerAndUpItsAncestorsTheFirstThatTakesItIsTheTarget()
	{
		let s = scope Scene();
		let inner = Box(s.Root, 220.0f, 30.0f, 40.0f, 40.0f); // over the target, not its child
		inner.AddRef(); // held while it moves
		s.Root.RemoveChild(inner);
		s.Target.AddChild(inner);
		inner.ReleaseRef();
		s.Root.UpdateLayout();
		s.Target.DropTypes = "card chip";
		int enters = 0;
		int leaves = 0;
		int overs = 0;
		s.Target.AddEventListener(.DragEnter, new [&] (e) => { enters++; });
		s.Target.AddEventListener(.DragLeave, new [&] (e) => { leaves++; });
		s.Target.AddEventListener(.DragOver, new [&] (e) => { overs++; });

		s.DragTo(.(100.0f, 200.0f)); // over nothing that takes it
		Test.Assert(s.D.DropTarget == null);
		Test.Assert(s.D.DropEffect == .None);
		Test.Assert(s.D.Cursor == .NoDrop);

		// Over the inner box, inside the target: the target (its ancestor) takes it.
		let area = inner.ScreenBounds;
		s.D.InjectMouseMove(.(area.X + 10.0f, area.Y + 10.0f));
		Test.Assert(s.D.DropTarget == s.Target);
		Test.Assert(s.Target.IsDropTarget); // `:drop-target`
		Test.Assert(enters == 1);
		Test.Assert(overs == 1);
		Test.Assert(s.D.DropEffect == .Move);
		Test.Assert(s.D.Cursor == .Move);
		s.D.InjectMouseMove(.(area.X + 12.0f, area.Y + 10.0f));
		Test.Assert(overs == 2);
		Test.Assert(enters == 1);

		// Off it: left.
		s.D.InjectMouseMove(.(100.0f, 200.0f));
		Test.Assert(leaves == 1);
		Test.Assert(!s.Target.IsDropTarget);
		s.D.InjectMouseUp(.(100.0f, 200.0f), .Left);
	}

	[Test]
	public static void TheModifiersChooseTheEffectAmongThoseTheSourceAllowsAskedAgainAsTheyChange()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card";
		s.DragTo(.(250.0f, 50.0f));
		Test.Assert(s.D.DropEffect == .Move);
		s.D.InjectKeyDown((uint32)KeyCode.Unknown, KeyModCtrl); // Ctrl held
		Test.Assert(s.D.DropEffect == .Copy);
		Test.Assert(s.D.Cursor == .Copy);
		s.D.InjectMouseMove(.(252.0f, 50.0f), KeyModCtrl | KeyModShift);
		Test.Assert(s.D.DropEffect == .Link);
		Test.Assert(s.D.Cursor == .Alias);
		s.D.InjectKeyUp((uint32)KeyCode.Unknown, 0);
		Test.Assert(s.D.DropEffect == .Move);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(252.0f, 50.0f), .Left);

		// A source allowing copy alone: Shift asks for a move, gets a copy.
		s.Source.SetDragSource(new (request) =>
			{
				request.Payload.Type.Set("card");
				request.Payload.Allowed = DropEffectsCopy;
				return true;
			});
		s.DragTo(.(250.0f, 50.0f), KeyModShift);
		Test.Assert(s.D.DropEffect == .Copy);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
	}

	[Test]
	public static void ATargetSaysWhatADropWouldDoOrRefusesWithAReasonThatEndsTheWalkTheHintShowsIt()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card"; // would take it, but a child refuses first
		let picky = Box(s.Root, 0.0f, 0.0f, 50.0f, 50.0f);
		picky.AddRef();
		s.Root.RemoveChild(picky);
		s.Target.AddChild(picky);
		picky.ReleaseRef();
		picky.SetOnDragQuery(new (query) =>
			{
				if ((query.Modifiers & KeyModShift) != 0)
					query.Refuse("The discard pile takes no aces");
				else
				{
					query.Accept(.Copy);
					query.Reason.Set("Copy to the discard pile");
					query.Place = 3;
				}
			});
		s.Root.UpdateLayout();
		let p = picky.ScreenBounds;
		s.DragTo(.(p.X + 10.0f, p.Y + 10.0f));
		Test.Assert(s.D.DropTarget == picky);
		Test.Assert(s.D.DropEffect == .Copy);
		Test.Assert(s.D.DropReason == "Copy to the discard pile");
		Test.Assert(s.D.DropHint != null);
		Test.Assert(!(s.D.DropHint as UIWidget).HasClass("refused"));

		s.D.InjectMouseMove(.(p.X + 11.0f, p.Y + 10.0f), KeyModShift);
		Test.Assert(s.D.DropTarget == null); // refused: not passed on to the target above
		Test.Assert(s.D.DropEffect == .None);
		Test.Assert(s.D.DropReason == "The discard pile takes no aces");
		Test.Assert(s.D.DropHint != null);
		Test.Assert((s.D.DropHint as UIWidget).HasClass("refused"));

		// Dropped with the place the target gave.
		int32 place = -1;
		DropEffect effect = .None;
		picky.AddEventListener(.Drop, new [&] (e) =>
			{
				place = ((DragEvent)e).Place;
				effect = ((DragEvent)e).Effect;
			});
		s.D.InjectMouseMove(.(p.X + 12.0f, p.Y + 10.0f), 0);
		s.D.InjectMouseUp(.(p.X + 12.0f, p.Y + 10.0f), .Left);
		Test.Assert(place == 3);
		Test.Assert(effect == .Copy);
		Test.Assert(s.Ended.Effect == .Copy); // the source told
		Test.Assert(s.Ended.Target == picky);
		Test.Assert(!s.Ended.Cancelled);
		Test.Assert(s.D.DropHint == null);
	}

	[Test]
	public static void ThePreviewFollowsThePointerHeldWhereThePressWasAndShowsTheEffect()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card";
		s.DragTo(.(120.0f, 150.0f));
		let preview = s.D.DragPreview as DragPreview;
		Test.Assert(preview != null);
		Test.Assert(preview.Text == "Ace of spades");
		Test.Assert(preview.Effect == .None);
		s.Root.UpdateLayout();
		Test.Assert(Near(preview.ScreenBounds.X, 120.0f + 14.0f)); // beside the pointer
		s.D.InjectMouseMove(.(250.0f, 50.0f));
		Test.Assert(preview.Effect == .Move);
		// It takes no hits: the target under it is still what is asked.
		Test.Assert(s.D.DropTarget == s.Target);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(s.D.DragPreview == null);

		// A preview of the source's own keeps the grab point.
		s.Source.SetDragSource(new (request) =>
			{
				request.Payload.Type.Set("card");
				let own = new Panel();
				own.EditLayoutStyle(scope (st) =>
					{
						st.Width = LayoutLength.Px(80.0f);
						st.Height = LayoutLength.Px(40.0f);
					});
				request.Preview = own;
				own.ReleaseRef(); // the request's reference keeps it
				return true;
			});
		s.DragTo(.(150.0f, 150.0f));
		s.Root.UpdateLayout();
		// Pressed at (30, 30), 20 in from the source's corner (10, 10): the preview's corner 20 back.
		Test.Assert(Near(s.D.DragPreview.ScreenBounds.X, 130.0f));
		Test.Assert(Near(s.D.DragPreview.ScreenBounds.Y, 130.0f));
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(150.0f, 150.0f), .Left);
	}

	[Test]
	public static void ASourceThatFollowsTheDragItselfHasNoPreviewItMovesFirstAndWhatItLeavesIsAsked()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card";
		let followed = scope List<Float2>();
		let source = s.Source;
		s.Source.SetDragSource(new (request) =>
			{
				request.Payload.Type.Set("card");
				request.Follow = new (pointer) =>
					{
						followed.Add(pointer);
						source.HitTestVisible = false; // what a following source does: the drop is asked of what is below
						source.Position = .(pointer.X - 20.0f, pointer.Y - 20.0f); // the source under the pointer
					};
				return true;
			});
		s.DragTo(.(250.0f, 50.0f));
		Test.Assert(s.D.IsDragging);
		Test.Assert(s.D.DragPreview == null);
		Test.Assert(followed.Count >= 2);
		Test.Assert(Near(followed.Back.X, 250.0f));
		Test.Assert(Near(s.Source.Position.X, 230.0f));
		Test.Assert(s.D.DropTarget == s.Target); // under the source, the target answered
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(!s.D.IsDragging);
		let calls = followed.Count;
		s.D.InjectMouseMove(.(260.0f, 50.0f)); // over: no more calls
		Test.Assert(followed.Count == calls);
	}

	[Test]
	public static void EscapeARightPressAndTheSourceLeavingTheTreeCancelTheSourceHearsItCancelled()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card";
		s.DragTo(.(250.0f, 50.0f));
		s.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ended.Cancelled);
		Test.Assert(s.Ended.Effect == .None);
		Test.Assert(!s.Target.IsDropTarget);
		int drops = 0;
		s.Target.AddEventListener(.Drop, new [&] (e) => { drops++; });
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(drops == 0); // the release after a cancel drops nothing

		s.DragTo(.(250.0f, 50.0f));
		s.D.InjectMouseDown(.(250.0f, 50.0f), .Right);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ends == 2);
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Right);
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(drops == 0);

		s.DragTo(.(250.0f, 50.0f));
		s.Source.RemoveFromParent();
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ends == 2); // a source gone hears nothing
	}

	[Test]
	public static void AFingerDragsAfterALongPressOverASourceAndOpensNoContextMenu()
	{
		let s = scope Scene();
		s.Target.DropTypes = "card";
		int menus = 0;
		s.Source.AddEventListener(.ContextMenu, new [&] (e) => { menus++; });
		// A quick move is no drag (a finger's move pans first).
		s.D.InjectTouchDown(1, .(30.0f, 30.0f));
		s.D.InjectTouchMove(1, .(50.0f, 30.0f));
		Test.Assert(!s.D.IsDragging);
		s.D.InjectTouchUp(1, .(50.0f, 30.0f));

		s.D.InjectTouchDown(1, .(30.0f, 30.0f));
		s.D.Tick(0.6f); // held still
		Test.Assert(menus == 0);
		s.D.InjectTouchMove(1, .(60.0f, 30.0f));
		Test.Assert(s.D.IsDragging);
		s.D.InjectTouchMove(1, .(250.0f, 50.0f));
		Test.Assert(s.D.DropTarget == s.Target);
		s.D.InjectTouchUp(1, .(250.0f, 50.0f));
		Test.Assert(s.Ended.Effect == .Move);
	}

	[Test]
	public static void CodeCanStartADragNoPressOfItsOwnAndRequeryDragAsksAgain()
	{
		let s = scope Scene();
		bool open = false;
		s.Target.SetOnDragQuery(new [&] (query) =>
			{
				if (open)
					query.Accept();
			});
		s.D.InjectMouseMove(.(250.0f, 50.0f));
		let request = scope DragRequest();
		request.Payload.Type.Set("card");
		s.D.StartDrag(s.Source, request);
		Test.Assert(s.D.IsDragging);
		Test.Assert(s.D.DropTarget == null);
		open = true; // what is under the pointer changed with the pointer still
		s.D.RequeryDrag();
		Test.Assert(s.D.DropTarget == s.Target);
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(s.Ended.Effect == .Move);
	}

	[Test]
	public static void ADragNearAScrollersEdgeScrollsItFasterDeeperInAndAsksTheDropAgain()
	{
		let s = scope Scene();
		let list = Box(s.Root, 200.0f, 120.0f, 150.0f, 100.0f);
		list.EditLayoutStyle(scope (st) => { st.OverflowY = .Auto; });
		for (int i = 0; i < 20; ++i)
		{
			let row = new Panel();
			row.EditLayoutStyle(scope (st) =>
				{
					st.Height = LayoutLength.Px(30.0f);
					st.Shrink = 0.0f;
				});
			list.AddChild(row);
			row.ReleaseRef();
		}
		int queries = 0;
		list.SetOnDragQuery(new [&] (query) =>
			{
				++queries;
				query.Accept();
			});
		s.Root.UpdateLayout();
		s.DragTo(.(270.0f, 170.0f)); // the middle: no scroll
		s.D.Tick(0.1f);
		Test.Assert(Near(list.ScrollOffset.Y, 0.0f));
		let before = queries;
		s.D.InjectMouseMove(.(270.0f, 210.0f)); // 10 into the bottom band of 24
		s.D.Tick(0.1f);
		let slow = list.ScrollOffset.Y;
		Test.Assert(slow > 0.0f);
		Test.Assert(queries > before + 1); // asked again as the content moved
		s.D.InjectMouseMove(.(270.0f, 219.0f)); // at the edge
		s.D.Tick(0.1f);
		Test.Assert(list.ScrollOffset.Y - slow > slow);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(270.0f, 219.0f), .Left);
	}

	[Test]
	public static void FilesTheOSDropsGoThroughTheSamePathAsACopyOfTheirPathsNoneTakingThemTheGUIsHandlerHasThem()
	{
		let s = scope Scene();
		s.Target.DropTypes = "files";
		let got = scope List<String>();
		defer { ClearAndDeleteItems!(got); }
		DropEffect effect = .None;
		s.Target.AddEventListener(.Drop, new [&] (e) =>
			{
				ClearAndDeleteItems!(got);
				DroppedPaths(((DragEvent)e).Payload, got);
				effect = ((DragEvent)e).Effect;
			});
		let leftover = scope List<String>();
		defer { ClearAndDeleteItems!(leftover); }
		s.D.SetOnFileDrop(new [&] (paths, at) =>
			{
				ClearAndDeleteItems!(leftover);
				for (let path in paths)
					leftover.Add(new String(path));
				return true;
			});
		StringView[2] paths = .("/tmp/a.png", "/tmp/b.png");
		Test.Assert(s.D.InjectFileDrop(.(250.0f, 50.0f), Span<StringView>(&paths[0], 2)));
		Test.Assert(got.Count == 2);
		Test.Assert(got[1] == "/tmp/b.png");
		Test.Assert(effect == .Copy);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(leftover.IsEmpty);

		Test.Assert(s.D.InjectFileDrop(.(100.0f, 250.0f), Span<StringView>(&paths[0], 2))); // over nothing that takes files
		Test.Assert(leftover.Count == 2);
		Test.Assert(!s.Target.IsDropTarget);
	}

	[Test]
	public static void FromTheKeysDragPickPicksUpAtTheFocusTheFocusMovingIsAskedReturnDropsEscapeCancels()
	{
		let s = scope Scene();
		s.Source.TabFocusable = true;
		s.Target.TabFocusable = true;
		s.Target.DropTypes = "card";
		s.Source.RequestFocus();
		Test.Assert(s.D.PickDrag());
		Test.Assert(s.D.IsKeyboardDrag);
		Test.Assert(s.D.DropTarget == null); // the source itself takes no cards
		s.D.InjectKeyDown((uint32)KeyCode.Tab); // the focus moves on
		Test.Assert(s.Target.IsFocused);
		Test.Assert(s.D.DropTarget == s.Target);
		Test.Assert(s.D.DragPreview != null);
		s.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ended.Effect == .Move);
		Test.Assert(s.Ended.Target == s.Target);

		// Ctrl+Shift+D (drag.pick in every GUI), then Escape.
		s.Source.RequestFocus();
		s.D.InjectKeyDown((uint32)KeyCode.D, KeyModCtrl | KeyModShift);
		Test.Assert(s.D.IsKeyboardDrag);
		s.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ended.Cancelled);

		// The pad: North picks up, South drops.
		s.Source.RequestFocus();
		s.D.InjectPadButton(.North);
		Test.Assert(s.D.IsKeyboardDrag);
		s.Target.RequestFocus();
		s.D.InjectPadButton(.South);
		Test.Assert(!s.D.IsDragging);
		Test.Assert(s.Ended.Effect == .Move);
	}

	[Test]
	public static void ADragQueryListenerThatTakesTheEventTakesTheDrop()
	{
		let s = scope Scene();
		int asked = 0;
		s.Target.AddEventListener(.DragQuery, new [&] (e) =>
			{
				++asked;
				let drag = (DragEvent)e;
				if (drag.Payload.Type == "card")
					e.Handled = true;
			});
		s.DragTo(.(250.0f, 50.0f));
		Test.Assert(asked >= 1);
		Test.Assert(s.D.DropTarget == s.Target);
		s.D.InjectMouseUp(.(250.0f, 50.0f), .Left);
		Test.Assert(s.Ended.Effect == .Move);
	}

	[Test]
	public static void ADragRestingAMomentOpensAClosedTreeNodeAndSelectsATab()
	{
		let model = scope TreeModel(); // outlives the scene, whose tree is its client
		let s = scope Scene();
		let a = model.AddNode(TreeModel.Root, "A");
		model.AddNode(a, "A1");
		let tree = new TreeView();
		tree.EditLayoutStyle(scope (st) =>
			{
				st.Placement = .Absolute;
				st.Left = LayoutLength.Px(200.0f);
				st.Top = LayoutLength.Px(150.0f);
				st.Width = LayoutLength.Px(150.0f);
				st.Height = LayoutLength.Px(100.0f);
			});
		tree.RowHeight = 20.0f;
		s.Root.AddChild(tree);
		tree.ReleaseRef();
		tree.Model = model;
		s.Root.UpdateLayout();

		s.DragTo(.(260.0f, 160.0f)); // over row 0, A (closed)
		s.D.Tick(0.3f);
		Test.Assert(!tree.IsItemExpanded(0));
		s.D.Tick(0.4f);
		Test.Assert(tree.IsItemExpanded(0));
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(260.0f, 160.0f), .Left);

		let bar = new TabBar();
		bar.EditLayoutStyle(scope (st) =>
			{
				st.Placement = .Absolute;
				st.Left = LayoutLength.Px(10.0f);
				st.Top = LayoutLength.Px(250.0f);
			});
		s.Root.AddChild(bar);
		bar.ReleaseRef();
		StringView[2] names = .("One", "Two");
		for (let name in names)
		{
			bar.AddTab(name).EditLayoutStyle(scope (st) =>
				{
					st.Width = LayoutLength.Px(60.0f);
					st.Height = LayoutLength.Px(24.0f);
				});
		}
		s.Root.UpdateLayout();
		let two = bar.GetTab(1).ScreenBounds;
		s.DragTo(.(two.X + 20.0f, two.Y + 10.0f));
		s.D.Tick(0.7f);
		Test.Assert(bar.SelectedIndex == 1);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(two.X + 20.0f, two.Y + 10.0f), .Left);
	}

	/// Two lists side by side in a root 500 by 300, their rows dragging as `row`: A to E on the
	/// left, X on the right. The models outlive the views.
	private class Lists
	{
		public StringListModel Left = new .() ~ delete _;
		public StringListModel Right = new .() ~ delete _;
		public SceneRoot Root = SceneFixtures.NewScene(500.0f, 300.0f);
		public ListView A;
		public ListView B;

		public this()
		{
			StringView[5] letters = .("A", "B", "C", "D", "E");
			for (let l in letters)
				Left.AddItem(l);
			Right.AddItem("X");
			A = View(10.0f, Left);
			B = View(250.0f, Right);
			Root.UpdateLayout();
		}

		public ~this()
		{
			Root.ReleaseRef(); // the views first: they listen to the models
		}

		private ListView View(float x, StringListModel model)
		{
			let view = new ListView();
			view.EditLayoutStyle(scope (st) =>
				{
					st.Placement = .Absolute;
					st.Left = LayoutLength.Px(x);
					st.Top = LayoutLength.Px(10.0f);
					st.Width = LayoutLength.Px(200.0f);
					st.Height = LayoutLength.Px(200.0f);
				});
			view.RowHeight = 20.0f;
			view.DragType = "row";
			Root.AddChild(view);
			view.ReleaseRef(); // the tree holds it
			view.Model = model;
			return view;
		}

		public EventDispatcher D => Root.EventDispatcher;

		/// A point `frac` down row `item` of view `v`.
		public static Float2 Row(ListView v, int item, float frac = 0.5f)
		{
			let r = v.ScreenBounds;
			return .(r.X + 50.0f, r.Y + 20.0f * ((float)item + frac));
		}

		public void Drag(ListView from, int item, Float2 to, uint32 modifiers = 0)
		{
			let at = Row(from, item);
			D.InjectMouseDown(at, .Left, modifiers);
			D.InjectMouseMove(.(at.X + 10.0f, at.Y), modifiers);
			D.InjectMouseMove(to, modifiers);
		}

		/// A model's rows run together.
		public static bool Items(StringListModel m, StringView expected)
		{
			let text = scope String();
			ItemViewFixtures.Items(m, text);
			return text == expected;
		}
	}

	[Test]
	public static void AListsRowsDragADropBetweenRowsReordersThemTheLineShowingWhere()
	{
		let l = scope Lists();
		l.Drag(l.A, 0, Lists.Row(l.A, 2, 0.9f)); // A, past C's middle: after C
		Test.Assert(l.D.DropTarget == l.A);
		Test.Assert(l.A.IsDropOver);
		Test.Assert(l.A.DropItem == 2);
		Test.Assert(l.A.DropPlace == .After);
		Test.Assert(l.D.DragPayload.Label == "A");
		// The middle of a row: a list takes nothing onto a row, so the halves decide.
		l.D.InjectMouseMove(Lists.Row(l.A, 3, 0.4f));
		Test.Assert(l.A.DropItem == 3);
		Test.Assert(l.A.DropPlace == .Before);
		l.D.InjectMouseUp(Lists.Row(l.A, 3, 0.4f), .Left);
		Test.Assert(Lists.Items(l.Left, "BCADE"));
		Test.Assert(!l.A.IsDropOver);
		Test.Assert(l.A.SelectedItem == 2); // the moved row keeps its id, and its selection
	}

	[Test]
	public static void AMultiSelectionDragsAsOneInOrderAPlainPressOnItAloneSelectsItOnTheClick()
	{
		let l = scope Lists();
		l.A.SelectionMode = .Multi;
		SceneFixtures.Click(l.D, Lists.Row(l.A, 0));
		l.D.InjectMouseDown(Lists.Row(l.A, 2), .Left, KeyModCtrl);
		l.D.InjectMouseUp(Lists.Row(l.A, 2), .Left, KeyModCtrl);
		Test.Assert(l.A.SelectionCount == 2);
		l.Drag(l.A, 2, Lists.Row(l.A, 4, 0.9f)); // A and C, after E
		Test.Assert(l.A.SelectionCount == 2); // the press kept them
		Test.Assert(l.D.DragPayload.Label == "2 items");
		l.D.InjectMouseUp(Lists.Row(l.A, 4, 0.9f), .Left);
		Test.Assert(Lists.Items(l.Left, "BDEAC"));

		// A plain click on one of a multi-selection: that row alone.
		SceneFixtures.Click(l.D, Lists.Row(l.A, 3));
		Test.Assert(l.A.SelectionCount == 1);
		Test.Assert(l.A.SelectedItem == 3);
	}

	[Test]
	public static void RowsMovedToAnotherListLeaveTheSourceCopiedCtrlTheyStay()
	{
		let l = scope Lists();
		l.Drag(l.A, 1, Lists.Row(l.B, 0, 0.9f)); // B after X
		Test.Assert(l.D.DropTarget == l.B);
		Test.Assert(l.D.DropEffect == .Move);
		l.D.InjectMouseUp(Lists.Row(l.B, 0, 0.9f), .Left);
		Test.Assert(Lists.Items(l.Right, "XB"));
		Test.Assert(Lists.Items(l.Left, "ACDE"));

		l.Drag(l.A, 0, Lists.Row(l.B, 0, 0.1f), KeyModCtrl); // A before X, copied
		Test.Assert(l.D.DropEffect == .Copy);
		l.D.InjectMouseUp(Lists.Row(l.B, 0, 0.1f), .Left, KeyModCtrl); // released with Ctrl held
		Test.Assert(Lists.Items(l.Right, "AXB"));
		Test.Assert(Lists.Items(l.Left, "ACDE"));

		// Below the last row: the end.
		l.Drag(l.A, 3, .(300.0f, 180.0f));
		Test.Assert(l.B.DropItem == -1);
		l.D.InjectMouseUp(.(300.0f, 180.0f), .Left);
		Test.Assert(Lists.Items(l.Right, "AXBE"));
	}

	[Test]
	public static void ATreeTakesANodeOntoAnotherItsChildOrBesideItAndRefusesOneInsideItself()
	{
		let model = scope TreeModel();
		let a = model.AddNode(TreeModel.Root, "A");
		let a1 = model.AddNode(a, "A1");
		let b = model.AddNode(TreeModel.Root, "B");
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let tree = new TreeView();
		tree.Size = .(300.0f, 200.0f);
		tree.RowHeight = 20.0f;
		tree.DragType = "node";
		root.AddChild(tree);
		tree.ReleaseRef();
		tree.Model = model;
		tree.ExpandItem(0); // A, A1, B
		root.UpdateLayout();
		let d = root.EventDispatcher;
		Float2 Row(int item, float frac) => .(100.0f, 20.0f * ((float)item + frac));

		// A onto A1 (its own child): refused, with the reason.
		d.InjectMouseDown(Row(0, 0.5f), .Left);
		d.InjectMouseMove(Row(0, 0.8f));
		d.InjectMouseMove(Row(1, 0.5f));
		Test.Assert(d.DropTarget == null);
		Test.Assert(d.DropReason == "A node cannot go inside itself");
		d.CancelDrag();
		d.InjectMouseUp(Row(1, 0.5f), .Left);

		// B onto A: B becomes A's last child.
		d.InjectMouseDown(Row(2, 0.5f), .Left);
		d.InjectMouseMove(Row(2, 0.2f));
		d.InjectMouseMove(Row(0, 0.5f));
		Test.Assert(tree.DropPlace == .On);
		d.InjectMouseUp(Row(0, 0.5f), .Left);
		Test.Assert(model.RowCount() == 1); // A alone at the top
		Test.Assert(model.RowCount(model.IndexOfNode(a)) == 2);
		Test.Assert(model.IdOf(model.Index(1, 0, model.IndexOfNode(a))) == (ItemId)b);

		// A1 before A: back to the top level, first.
		root.UpdateLayout();
		d.InjectMouseDown(Row(1, 0.5f), .Left);
		d.InjectMouseMove(Row(1, 0.8f));
		d.InjectMouseMove(Row(0, 0.1f));
		Test.Assert(tree.DropPlace == .Before);
		d.InjectMouseUp(Row(0, 0.1f), .Left);
		Test.Assert(model.RowCount() == 2);
		Test.Assert(model.IdOf(model.Index(0)) == (ItemId)a1);
	}

	[Test]
	public static void FromTheKeysAListsRowsMoveTheArrowsMoveTheKeyboardsRowNotTheSelection()
	{
		let l = scope Lists();
		l.A.RequestFocus();
		l.A.SelectedItem = 0; // A
		Test.Assert(l.D.PickDrag());
		Test.Assert(l.D.DragPayload.Label == "A");
		l.D.InjectKeyDown((uint32)KeyCode.Down);
		l.D.InjectKeyDown((uint32)KeyCode.Down); // the keyboard on C
		Test.Assert(l.A.SelectedItem == -1); // the keyboard moved; A stays selected, not current
		Test.Assert(l.A.IsItemSelected(0));
		Test.Assert(l.A.DropItem == 2);
		Test.Assert(l.A.DropPlace == .After); // a list takes nothing onto a row
		l.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(Lists.Items(l.Left, "BCADE"));
	}

	/// Two roots of one GUI side by side on a screen: the scene's at 0,0 (400 by 300) and another at
	/// 500,0 (300 by 300), as a host that places its windows would tell.
	private class TwoPlaces : IRootPlaces
	{
		public EventDispatcher First = null;
		public EventDispatcher Second = null;

		public EventDispatcher DispatcherAt(Float2 screen, out Float2 local)
		{
			local = screen;
			if ((screen.Y < 0.0f) || (screen.Y >= 300.0f))
				return null;
			if ((screen.X >= 0.0f) && (screen.X < 400.0f))
				return First;
			if ((Second != null) && (screen.X >= 500.0f) && (screen.X < 800.0f))
			{
				local = .(screen.X - 500.0f, screen.Y);
				return Second;
			}
			return null;
		}

		public bool ToScreen(EventDispatcher dispatcher, Float2 local, out Float2 screen)
		{
			screen = local;
			if (dispatcher == First)
				screen = local;
			else if ((Second != null) && (dispatcher == Second))
				screen = .(local.X + 500.0f, local.Y);
			else
				return false;
			return true;
		}
	}

	[Test]
	public static void AcrossRootsOfOneGUIADragGoesOnOverAnotherRootLetGoOverNoneItEndsOutsideWhereSaid()
	{
		let s = scope Scene();
		var other = new SceneRoot(s.Root.Context);
		other.Size = .(300.0f, 300.0f);
		var far = Box(other, 50.0f, 20.0f, 100.0f, 100.0f);
		far.AddRef(); // the test's own, as the root's goes with it
		far.DropTypes = "card";
		int enters = 0;
		int drops = 0;
		far.AddEventListener(.DragEnter, new [&] (e) => { enters++; });
		far.AddEventListener(.Drop, new [&] (e) => { drops++; });
		other.UpdateLayout();
		let places = scope TwoPlaces();
		places.First = s.D;
		places.Second = other.EventDispatcher;
		s.Root.Context.RootPlaces = places;
		Test.Assert(other.EventDispatcher != null);

		// Over the other root (its 100,50: the screen's 600,50, past this root's edge).
		s.DragTo(.(600.0f, 50.0f));
		Test.Assert(s.D.IsDragging);
		Test.Assert(s.D.DragOver == other.EventDispatcher);
		Test.Assert(s.D.DropTarget == far);
		Test.Assert(enters == 1);
		s.D.InjectMouseUp(.(600.0f, 50.0f), .Left);
		Test.Assert(drops == 1);
		Test.Assert(s.Ends == 1);
		Test.Assert(s.Ended.Target == far);
		Test.Assert(!s.Ended.Outside);

		// Between the two: over no root, outside, at the screen's 450,50.
		s.DragTo(.(450.0f, 50.0f));
		Test.Assert(s.D.DragOver == null);
		Test.Assert(s.D.DropTarget == null);
		s.D.InjectMouseUp(.(450.0f, 50.0f), .Left);
		Test.Assert(s.Ends == 2);
		Test.Assert(s.Ended.Target == null);
		Test.Assert(s.Ended.Outside);
		Test.Assert(s.Ended.ScreenKnown);
		Test.Assert(Near(s.Ended.Screen.X, 450.0f));

		// The other root goes while the drag is over it: forgotten, and let go it is outside.
		s.DragTo(.(600.0f, 50.0f));
		Test.Assert(s.D.DropTarget == far);
		places.Second = null;
		far.ReleaseRef();
		far = null;
		other.ReleaseRef();
		other = null;
		Test.Assert(s.D.DropTarget == null);
		s.D.InjectMouseUp(.(600.0f, 50.0f), .Left);
		Test.Assert(s.Ends == 3);
		Test.Assert(s.Ended.Outside);
		s.Root.Context.RootPlaces = null;
	}

	[Test]
	public static void WhereNoHostTellsTheRootsPlacesADragLetGoPastItsRootsEdgeEndsOutsideNowhereSaid()
	{
		let s = scope Scene();
		s.DragTo(.(-30.0f, 20.0f));
		s.D.InjectMouseUp(.(-30.0f, 20.0f), .Left);
		Test.Assert(s.Ends == 1);
		Test.Assert(s.Ended.Outside);
		Test.Assert(!s.Ended.ScreenKnown);
		// Let go over its own root where nothing takes it: not outside.
		s.DragTo(.(150.0f, 200.0f));
		s.D.InjectMouseUp(.(150.0f, 200.0f), .Left);
		Test.Assert(s.Ends == 2);
		Test.Assert(!s.Ended.Outside);
	}

	[Test]
	public static void ADragRestingOnAClosedExpandersHeaderOpensIt()
	{
		let s = scope Scene();
		let expander = new Expander();
		defer expander.ReleaseRef();
		expander.Title = "More";
		expander.EditLayoutStyle(scope (st) =>
			{
				st.Placement = .Absolute;
				st.Left = LayoutLength.Px(10.0f);
				st.Top = LayoutLength.Px(150.0f);
				st.Width = LayoutLength.Px(150.0f);
			});
		s.Root.AddChild(expander);
		s.Root.UpdateLayout();
		let header = expander.Header.ScreenBounds;
		s.DragTo(.(header.X + 40.0f, header.Y + header.Height * 0.5f));
		s.D.Tick(0.7f);
		Test.Assert(expander.Open);
		s.D.CancelDrag();
		s.D.InjectMouseUp(.(header.X + 40.0f, header.Y + 5.0f), .Left);
	}

	[Test]
	public static void InMarkupDragTypeDragValueAndDragLabelMakeASourceDropTypesAndDropReasonATarget()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let page = loader.LoadFromString(
			"<Panel width=\"400\" height=\"300\" flex-direction=\"row\" align-items=\"start\">\n" +
			"    <Panel id=\"swatch\" width=\"80\" height=\"40\" drag-type=\"color\" drag-value=\"red\" drag-label=\"Red\">\n" +
			"        <Label id=\"grip\" text=\"grip\" width=\"30\" height=\"20\" drag=\"block\"/>\n" +
			"        <Label id=\"quiet\" text=\"quiet\" width=\"30\" height=\"20\" drag=\"none\" drag-type=\"other\"/>\n" +
			"    </Panel>\n" +
			"    <Panel id=\"canvas\" width=\"200\" height=\"200\" drop-types=\"color\" drop-reason=\"Paint it\"/>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		root.AddChild(page);
		root.UpdateLayout();
		let swatch = page.GetChildAt(0);
		let canvas = page.GetChildAt(1);
		let grip = swatch.GetChildAt(0);
		let quiet = swatch.GetChildAt(1);
		let painted = scope String();
		canvas.AddEventListener(.Drop, new [&] (e) =>
			{
				painted.Set(TextOf(((DragEvent)e).Payload.Value));
			});
		let d = root.EventDispatcher;
		void Drag(Node from, Float2 to)
		{
			let r = from.ScreenBounds;
			let at = Float2(r.X + 5.0f, r.Y + 5.0f);
			d.InjectMouseDown(at, .Left);
			d.InjectMouseMove(.(at.X + 10.0f, at.Y));
			d.InjectMouseMove(to);
		}
		let c = canvas.ScreenBounds;
		let onCanvas = Float2(c.X + 50.0f, c.Y + 50.0f);

		// A press on the block child: the walk ends there, nothing drags.
		Drag(grip, onCanvas);
		Test.Assert(!d.IsDragging);
		d.InjectMouseUp(onCanvas, .Left);
		// A press on the none child (with a type of its own): it passes the press up to the swatch.
		Drag(quiet, onCanvas);
		Test.Assert(d.IsDragging);
		Test.Assert(d.DragPayload.Type == "color");
		Test.Assert(d.DragPayload.Label == "Red");
		Test.Assert(d.DropTarget == canvas);
		Test.Assert(d.DropReason == "Paint it");
		d.InjectMouseUp(onCanvas, .Left);
		Test.Assert(painted == "red");
	}
}
