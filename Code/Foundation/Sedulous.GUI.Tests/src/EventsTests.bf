using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Events and actions without a scene: the names events, cursors and touch actions go by, the
/// keys that type text, a drop's effect, a keymap's resolution by context depth and its chords,
/// media queries' parsing, popup placement at the edges, model indices, and an action's lifecycle
/// in an ActionManager.
class EventsTests
{
	private static bool Near(float a, float b, float epsilon = 1e-5f) => Math.Abs(a - b) <= epsilon;

	private static bool Matches(StringView query, MediaContext context)
	{
		let q = scope MediaQuery(query);
		return q.Evaluate(context);
	}

	private static Keystroke Stroke(StringView keys) => ParseKeystroke(keys).Value;

	private static TimeSpan Sec(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	// === Event names ===

	[Test]
	public static void TouchActionsReadAndWriteTheirWords()
	{
		Test.Assert(TouchActionsNamed("pan-x pinch-zoom").Value == (cTouchPanX | cTouchPinchZoom));
		Test.Assert(TouchActionsNamed(" manipulation ").Value == cTouchAuto);
		Test.Assert(TouchActionsNamed("auto").Value == cTouchAuto);
		Test.Assert(TouchActionsNamed("none").Value == 0);
		Test.Assert(!TouchActionsNamed("pan-x bogus").HasValue);
		Test.Assert(!TouchActionsNamed("").HasValue);

		let text = scope String();
		TouchActionsName(cTouchPanX | cTouchPanY, text);
		Test.Assert(text == "pan-x pan-y");
		text.Clear();
		TouchActionsName(cTouchAuto, text);
		Test.Assert(text == "auto");
		text.Clear();
		TouchActionsName(0, text);
		Test.Assert(text == "none");
		text.Clear();
		TouchActionsName(cTouchPinchZoom, text);
		Test.Assert(text == "pinch-zoom");
	}

	[Test]
	public static void CursorsAndEventTypesGoByTheirNames()
	{
		Test.Assert(CursorNamed("not-allowed") == .NotAllowed);
		Test.Assert(CursorNamed("no-drop") == .NoDrop);
		Test.Assert(CursorNamed("bogus") == .Auto);
		Test.Assert(CursorName(.NeswResize) == "nesw-resize");
		Test.Assert(CursorName(.None) == "none");

		Test.Assert(EventTypeNamed("blur", let blur) && (blur == .FocusLost));
		Test.Assert(EventTypeNamed("activate", let activate) && (activate == .ItemActivate));
		Test.Assert(!EventTypeNamed("frobnicate", ?));
		Test.Assert(EventTypeName(.MouseClick) == "click");
		Test.Assert(EventTypeName(.Entered) == "entered");
		Test.Assert(EventTypeName(.PositionChanged).IsEmpty); // no name

		Test.Assert(InputKindName(.Pad) == "pad");
		Test.Assert(PopupCloseReasonName(.OutsidePress) == "outside-press");
	}

	[Test]
	public static void TheKeysThatTypeTextAndTheModifierKeysOwnModifier()
	{
		Test.Assert(KeyTypesText(.A) && KeyTypesText(.Z) && KeyTypesText(.Num3));
		Test.Assert(KeyTypesText(.Slash) && KeyTypesText(.Minus) && KeyTypesText(.Keypad5) && KeyTypesText(.KeypadDecimal));
		Test.Assert(!KeyTypesText(.KeypadEnter));
		Test.Assert(!KeyTypesText(.Return) && !KeyTypesText(.F1) && !KeyTypesText(.LeftShift) && !KeyTypesText(.CapsLock));
		Test.Assert(ModifierOfKey(.RightCtrl) == KeyModCtrl);
		Test.Assert(ModifierOfKey(.LeftSuper) == KeyModSuper);
		Test.Assert(ModifierOfKey(.A) == KeyModNone);
	}

	[Test]
	public static void ADropTakesAnAllowedEffectElseThePreferredOne()
	{
		let payload = scope DragPayload();
		payload.Allowed = DropEffectsCopy;
		let query = scope DropQuery(payload);
		Test.Assert(query.Preferred == .Move);
		query.Accept(.Copy);
		Test.Assert(query.Effect == .Copy);
		query.Accept(.Link); // not allowed: the preferred
		Test.Assert(query.Effect == .Move);
		query.Refuse("read only");
		Test.Assert(query.Effect == .None);
		Test.Assert(query.Refused);
		Test.Assert(query.Reason == "read only");
		Test.Assert(DropEffectFlag(.Link) == DropEffectsLink);
		Test.Assert(DropEffectFlag(.None) == DropEffectsNone);
	}

	[Test]
	public static void AFilesPayloadsPathsAreItsTextItemsAndACopyOwnsItsText()
	{
		let list = scope List<System.Variant>();
		defer
		{
			for (var item in list)
				item.Dispose();
		}
		list.Add(TextVariant("a.png"));
		list.Add(System.Variant.Create(3));
		list.Add(TextVariant("b.txt"));

		let payload = scope DragPayload();
		payload.Type.Set("files");
		payload.Label.Set("2 files");
		payload.Value = System.Variant.Create(list);
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		DroppedPaths(payload, paths);
		Test.Assert(paths.Count == 2);
		Test.Assert((paths[0] == "a.png") && (paths[1] == "b.txt"));

		let copy = scope DragPayload();
		copy.Set(payload);
		payload.Type.Set("text");
		Test.Assert(copy.Type == "files");
		Test.Assert(copy.Label == "2 files");
		Test.Assert(copy.Allowed == DropEffectsAll);
		let again = scope List<String>();
		defer { ClearAndDeleteItems!(again); }
		DroppedPaths(copy, again);
		Test.Assert(again.Count == 2);

		let empty = scope DragPayload();
		DroppedPaths(empty, again);
		Test.Assert(again.Count == 2); // no value: nothing added
	}

	// === Keymap ===

	[Test]
	public static void TheDeepestContextWinsThenTheLaterBindingAndAnEmptyCommandUnbinds()
	{
		let game = scope KeyContextLayer();
		game.Declare("game");
		let menu = scope KeyContextLayer();
		menu.Set(game);
		menu.Declare("menu mode=main");
		KeyContextLayer[2] inMenu = .(game, menu);
		KeyContextLayer[1] inGame = .(game);
		Keystroke[1] escape = .(Stroke("escape"));

		let keymap = scope Keymap();
		Test.Assert(keymap.Bind("escape", "quit"));
		Test.Assert(keymap.Bind("escape", "close", "menu"));
		Test.Assert(keymap.Bind("escape", "pause", "game")); // later, but outer
		let command = scope String();
		Test.Assert(keymap.Match(escape, inMenu, command) == .Matched);
		Test.Assert(command == "close");
		Test.Assert(keymap.Match(escape, inGame, command) == .Matched);
		Test.Assert(command == "pause");
		Test.Assert(keymap.Match(escape, default, command) == .Matched);
		Test.Assert(command == "quit"); // no stack: only the context-free binding holds

		Test.Assert(keymap.Bind("escape", "", "mode == main")); // as deep as the menu's, later: unbinds
		Test.Assert(keymap.Match(escape, inMenu, command) == .Matched);
		Test.Assert(command.IsEmpty);
		Test.Assert(!keymap.MatchWhole(escape, inMenu, command)); // an unbinding runs nothing
		Keystroke[1] f1 = .(Stroke("f1"));
		Test.Assert(keymap.Match(f1, inMenu, command) == .None);
	}

	[Test]
	public static void AChordWaitsForItsNextKeystrokeUnlessAContextualBindingIsWhole()
	{
		let menu = scope KeyContextLayer();
		menu.Declare("menu");
		KeyContextLayer[1] inMenu = .(menu);
		let keymap = scope Keymap();
		Test.Assert(keymap.Bind("ctrl-x ctrl-c", "comment"));
		Test.Assert(keymap.Bind("ctrl-k", "kill"));
		Test.Assert(keymap.Bind("ctrl-k ctrl-a", "kill-all"));
		let command = scope String();
		Keystroke[1] ctrlX = .(Stroke("ctrl-x"));
		Keystroke[2] chord = .(Stroke("ctrl-x"), Stroke("ctrl-c"));
		Keystroke[1] ctrlK = .(Stroke("ctrl-k"));
		Keystroke[1] ctrlQ = .(Stroke("ctrl-q"));
		Test.Assert(keymap.Match(ctrlX, inMenu, command) == .Pending);
		Test.Assert(keymap.Match(chord, inMenu, command) == .Matched);
		Test.Assert(command == "comment");
		Test.Assert(keymap.Match(ctrlQ, inMenu, command) == .None);
		Test.Assert(keymap.Match(ctrlK, inMenu, command) == .Pending); // a context-free whole match waits
		Test.Assert(keymap.MatchWhole(ctrlK, inMenu, command));
		Test.Assert(command == "kill"); // cut short: what the first key binds alone
		Test.Assert(!keymap.MatchWhole(ctrlX, inMenu, command));

		Test.Assert(keymap.Bind("ctrl-k", "kill-line", "menu"));
		Test.Assert(keymap.Match(ctrlK, inMenu, command) == .Matched); // a contextual whole match wins
		Test.Assert(command == "kill-line");
		Test.Assert(keymap.BindingCount == 4);
	}

	[Test]
	public static void AShortcutShownIsTheOneBoundWhereTheControlIsAndFollowsRebinding()
	{
		let menu = scope KeyContextLayer();
		menu.Declare("menu");
		KeyContextLayer[1] inMenu = .(menu);
		let keymap = scope Keymap();
		Test.Assert(keymap.Bind("ctrl-s", "save", "menu"));
		Test.Assert(keymap.Bind("ctrl-shift-s", "save", "editor")); // later, but elsewhere
		let text = scope String();
		keymap.ShortcutText("save", inMenu, text);
		Test.Assert(text == "Ctrl+S");
		text.Clear();
		keymap.ShortcutText("save", text); // no stack: the latest
		Test.Assert(text == "Ctrl+Shift+S");

		// A read a binding follows.
		let length = scope Computed<int>(new [&]() =>
			{
				let shown = scope String();
				keymap.ShortcutText("open", shown);
				return shown.Length;
			});
		Test.Assert(length.Get() == 0);
		Test.Assert(keymap.Bind("ctrl-o", "open"));
		Test.Assert(length.IsStale);
		Test.Assert(length.Get() == 6); // "Ctrl+O"
	}

	[Test]
	public static void AContextInsideAnotherAndALayersDeclarations()
	{
		let outer = scope KeyContextLayer();
		outer.Declare("menu");
		let inner = scope KeyContextLayer();
		inner.Set(outer);
		inner.Declare("textinput");
		let elsewhere = scope KeyContextLayer();
		elsewhere.Declare("textinput");
		KeyContextLayer[2] nested = .(outer, inner);
		KeyContextLayer[1] alone = .(elsewhere);
		let p = scope ContextPredicate();
		Test.Assert(p.Parse("menu > textinput"));
		Test.Assert(p.Eval(nested, 1));
		Test.Assert(!p.Eval(nested, 0)); // the menu itself
		Test.Assert(!p.Eval(alone, 0)); // a field in no menu
		Test.Assert(!p.Eval(nested, 2)); // past the stack
		Test.Assert(p.Parse("menu > textinput && !multiline || game")); // `>` binds loosest
		Test.Assert(p.Eval(nested, 1));
		Test.Assert(!p.Parse("menu >"));
		Test.Assert(p.Parse("  "));
		Test.Assert(p.IsEmpty && p.Eval(alone, 0)); // empty: everywhere

		let layer = scope KeyContextLayer();
		layer.Declare("editor mode=insert");
		layer.Declare("mode=normal");
		Test.Assert(layer.Keys.Count == 2);
		Test.Assert(layer.Find("mode") == "normal"); // a deeper value replaces
		Test.Assert((layer.Find("editor") != null) && layer.Find("editor").IsEmpty);
		Test.Assert(layer.Find("menu") == null);
		Test.Assert(inner.Keys.Count == 2 && outer.Keys.Count == 1); // a copy, not a share
		Test.Assert(p.Parse("mode != insert"));
		Test.Assert(p.Eval(layer));
		Test.Assert(p.Parse("menu != insert")); // undeclared: not equal
		Test.Assert(p.Eval(layer));
	}

	// === Media queries ===

	[Test]
	public static void MediaQueriesReadResolutionInputAndUnknownFeatures()
	{
		var context = MediaContext(800.0f, 600.0f, 192.0f);
		Test.Assert(Matches("(min-resolution: 2dppx)", context));
		Test.Assert(Matches("(resolution: 192dpi)", context));
		Test.Assert(Matches("(min-resolution: 2x)", context));
		Test.Assert(!Matches("(max-resolution: 1x)", context));
		context.Dpi = 96.0f;
		Test.Assert(Matches("(max-resolution: 1x)", context));
		Test.Assert(!Matches("(min-width: abc)", context)); // a value it cannot read
		Test.Assert(Matches("only screen and (min-width: 600px)", context));
		Test.Assert(!Matches("tv", context));

		Test.Assert(Matches("(input: pointer)", context)); // the pointer by default
		context.Input = .Pad;
		Test.Assert(Matches("(input: pad)", context));
		Test.Assert(!Matches("(input: keyboard)", context));
		Test.Assert(!Matches("(input: gamepad)", context));

		let wide = MediaContext(800.0f, 600.0f, 96.0f);
		Test.Assert(!Matches("(aspect-ratio: 16/9)", wide));
		Test.Assert(!Matches("(prefers-reduced-motion)", wide));
		Test.Assert(!Matches("(min-width: 600px) and (hover: hover)", wide));
		Test.Assert(Matches("(prefers-color-scheme: dark)", wide)); // dark by default

		Test.Assert(wide == MediaContext(800.0f, 600.0f, 96.0f));
		Test.Assert(wide != context);
	}

	[Test]
	public static void AMediaQueryCopyIsItsOwn()
	{
		let source = scope MediaQuery("(min-width: 600px) and (max-width: 900px), print");
		let copy = scope MediaQuery("(orientation: portrait)");
		copy.Set(source);
		Test.Assert(copy.FeatureCount == 2);
		Test.Assert(copy.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!copy.Evaluate(.(1000.0f, 0.0f, 96.0f)));
		copy.Set(scope MediaQuery());
		Test.Assert(copy.IsEmpty);
		Test.Assert(source.FeatureCount == 2);
	}

	// === Popup placement ===

	[Test]
	public static void APopupFlipsToTheSideWithMoreRoomAndShrinksToIt()
	{
		let bounds = Rect(0.0f, 0.0f, 800.0f, 600.0f);
		// Below fits: it stays.
		var placed = PlacePopup(.(100.0f, 100.0f, 80.0f, 20.0f), .(120.0f, 200.0f), bounds, .(), false);
		Test.Assert(placed.Side == .Below);
		Test.Assert(Near(placed.Position.X, 100.0f) && Near(placed.Position.Y, 120.0f));

		// 80 below, 500 above: it flips above.
		placed = PlacePopup(.(100.0f, 500.0f, 80.0f, 20.0f), .(120.0f, 200.0f), bounds, .(), false);
		Test.Assert(placed.Side == .Above);
		Test.Assert(Near(placed.Position.X, 100.0f) && Near(placed.Position.Y, 300.0f));
		Test.Assert(Near(placed.Size.X, 120.0f) && Near(placed.Size.Y, 200.0f));

		// Neither side fits and above has no more room: it stays below, shrunk to the 140 there.
		placed = PlacePopup(.(100.0f, 140.0f, 80.0f, 20.0f), .(120.0f, 200.0f), .(0.0f, 0.0f, 800.0f, 300.0f), .(), false);
		Test.Assert(placed.Side == .Below);
		Test.Assert(Near(placed.Position.Y, 160.0f) && Near(placed.Size.Y, 140.0f));

		// A gap between them.
		PopupPlacement gapped = .();
		gapped.Gap = 4.0f;
		placed = PlacePopup(.(100.0f, 100.0f, 80.0f, 20.0f), .(120.0f, 50.0f), bounds, gapped, false);
		Test.Assert(Near(placed.Position.Y, 124.0f));

		// At the inline end against the right edge: it flips to the start.
		PopupPlacement side = .();
		side.Side = .InlineEnd;
		placed = PlacePopup(.(700.0f, 100.0f, 80.0f, 20.0f), .(100.0f, 50.0f), bounds, side, false);
		Test.Assert(placed.Side == .InlineStart);
		Test.Assert(Near(placed.Position.X, 600.0f) && Near(placed.Position.Y, 100.0f));
	}

	[Test]
	public static void APopupsLogicalSideAndAlignmentFollowTheDirectionAndItIsClampedIn()
	{
		let bounds = Rect(0.0f, 0.0f, 800.0f, 600.0f);
		let anchor = Rect(300.0f, 100.0f, 80.0f, 20.0f);
		// A dropdown's start: the left edges in left to right, the right edges in right to left.
		var placed = PlacePopup(anchor, .(120.0f, 50.0f), bounds, .(), false);
		Test.Assert(Near(placed.Position.X, 300.0f));
		placed = PlacePopup(anchor, .(120.0f, 50.0f), bounds, .(), true);
		Test.Assert(Near(placed.Position.X, 260.0f));
		PopupPlacement centred = .();
		centred.Align = .Center;
		placed = PlacePopup(anchor, .(120.0f, 50.0f), bounds, centred, true);
		Test.Assert(Near(placed.Position.X, 280.0f));

		// The inline end is the left in right to left.
		PopupPlacement side = .();
		side.Side = .InlineEnd;
		placed = PlacePopup(anchor, .(100.0f, 50.0f), bounds, side, true);
		Test.Assert(placed.Side == .InlineEnd);
		Test.Assert(Near(placed.Position.X, 200.0f) && Near(placed.Position.Y, 100.0f));

		// Past the right edge: slid back in.
		placed = PlacePopup(.(750.0f, 100.0f, 40.0f, 20.0f), .(120.0f, 50.0f), bounds, .(), false);
		Test.Assert(Near(placed.Position.X, 680.0f));
		placed = PlaceAtPoint(.(790.0f, 10.0f), .(100.0f, 50.0f), bounds, false);
		Test.Assert(Near(placed.Position.X, 700.0f) && Near(placed.Position.Y, 10.0f));

		Test.Assert(OppositeSide(.Below) == .Above);
		Test.Assert(OppositeSide(.InlineStart) == .InlineEnd);
	}

	// === Model indices ===

	[Test]
	public static void AModelIndexIsEqualOnlyWithItsNodeIdToo()
	{
		let index = MakeModelIndex(2);
		Test.Assert((index.Row == 2) && (index.Column == 0) && (index.InternalId == -1));
		Test.Assert(index == ModelIndex(2, 0, -1));
		Test.Assert(!(MakeModelIndex(2, 0, 7) == MakeModelIndex(2, 0, 8)));
		Test.Assert(MakeModelIndex(2, 0, 7).Equals(MakeModelIndex(2, 0, 7)));
		Test.Assert(!MakeModelIndex(0, -1).IsValid);
	}

	// === Actions ===

	[Test]
	public static void ATickActionRunsUntilItsFunctionSaysStopAndTheManagerHoldsItsOwnReference()
	{
		let manager = scope ActionManager();
		int ticks = 0;
		double seconds = 0.0;
		int done = 0;
		let tick = new TickAction(new [&](elapsed) =>
			{
				ticks++;
				seconds += elapsed.TotalSeconds;
				return ticks < 3;
			});
		defer tick.ReleaseRef();
		tick.SetOnDone(new [&](action) => { done++; });
		tick.Tag = 7;
		tick.Id = 42;
		tick.Stop();
		Test.Assert(tick.IsDone);

		manager.AddAction(tick); // started
		Test.Assert(!tick.IsDone);
		Test.Assert(tick.RefCount == 2);
		Test.Assert(manager.Count == 1 && !manager.IsEmpty);
		Test.Assert(manager.GetActionByTag(7) === tick);
		Test.Assert(manager.GetActionByTag(8) == null);
		int visited = 0;
		manager.ForEachAction(scope [&](action) => { visited++; });
		Test.Assert(visited == 1);

		tick.Update(Sec(0.25));
		tick.Update(Sec(0.25));
		Test.Assert(!tick.IsDone && (done == 0) && (tick.CurrentProgress == 0.0f));
		tick.Update(Sec(0.25)); // its function says stop
		Test.Assert(tick.IsDone && (done == 1) && (tick.CurrentProgress == 1.0f));
		tick.Update(Sec(0.25)); // done: not called again
		Test.Assert((ticks == 3) && (done == 1));
		Test.Assert(Math.Abs(seconds - 0.75) < 1e-6);
		Test.Assert(tick.TotalTime == default(TimeSpan));
		Test.Assert(tick.Overrun == default(TimeSpan));
		Test.Assert(tick.CanMoveTarget);
		Test.Assert(tick.Id == 42);

		manager.Clear();
		Test.Assert(manager.IsEmpty);
		Test.Assert(tick.RefCount == 1); // its own, released by the manager

		// One the manager alone holds goes with it; one with no function is done at once.
		let bare = new TickAction(null);
		manager.AddAction(bare);
		bare.ReleaseRef();
		Test.Assert(bare.RefCount == 1);
		bare.Update(Sec(0.1));
		Test.Assert(bare.IsDone);
	}
}
