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
