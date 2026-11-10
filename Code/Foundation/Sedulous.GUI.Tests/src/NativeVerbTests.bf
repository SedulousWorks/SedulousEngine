using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What a game's own code uses: On with a delegate, by the core's event names and a library's own, its handler deleted at Off or with its node; typed binds over the GUI's
/// data, followed on the GUI's frame; a tween's end heard once, its delegate the tween's.
class NativeVerbTests
{
	/// The handlers and expressions these tests made that were deleted (their destructors count).
	private static int sDeleted = 0;

	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void OnHearsAClickTakesItByAnsweringTrueAndOffStopsItAndDeletesTheHandler()
	{
		sDeleted = 0;
		let node = new UIWidget();
		defer node.ReleaseRef();
		int clicks = 0;
		bool answer = true;
		let token = node.On("click", new [&] (e) =>
			{
				clicks++;
				return answer;
			} ~ { sDeleted++; });
		Test.Assert(token > 0);

		let click = scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f));
		node.SendEvent(click);
		Test.Assert(clicks == 1);
		Test.Assert(click.Handled, "answering true takes the event");

		answer = false;
		let again = scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f));
		node.SendEvent(again);
		Test.Assert(clicks == 2);
		Test.Assert(!again.Handled, "answering false leaves it to go on");

		node.SendEvent(scope MouseEvent(.MouseDown, node, .(0.0f, 0.0f)));
		Test.Assert(clicks == 2, "another core event");

		Test.Assert(sDeleted == 0);
		Test.Assert(node.Off(token));
		Test.Assert(sDeleted == 1, "deleted at Off");
		node.SendEvent(scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f)));
		Test.Assert(clicks == 2, "not after Off");
		Test.Assert(!node.Off(token));
	}

	[Test]
	public static void ANameTheCoreDoesNotKnowIsALibrarysNamedEventHeardByThatNameOnly()
	{
		let node = new UIWidget();
		defer node.ReleaseRef();
		let detail = scope String();
		int heard = 0;
		Test.Assert(node.On("screenenter", new [&] (e) =>
			{
				heard++;
				detail.Set(((NamedEvent)e).Detail);
				return false;
			}) > 0);

		node.SendNamedEvent("screenleave", "menu");
		Test.Assert(heard == 0, "another name");
		node.SendNamedEvent("screenenter", "title");
		Test.Assert(heard == 1);
		Test.Assert(detail == "title");
	}

	[Test]
	public static void TheHandlersGoWithTheNodeAndNothingListensForAnEmptyName()
	{
		sDeleted = 0;
		var node = new UIWidget();
		node.On("click", new (e) => { return false; } ~ { sDeleted++; });
		node.On("screenenter", new (e) => { return false; } ~ { sDeleted++; });
		Test.Assert(sDeleted == 0);

		Test.Assert(node.On("", new (e) => { return false; } ~ { sDeleted++; }) == 0);
		Test.Assert(sDeleted == 1, "an empty name deletes what it was handed");
		Test.Assert(node.On("click", (delegate bool(Event e))null) == 0);

		node.ReleaseRef(); // the last hold: the node goes
		node = null;
		Test.Assert(sDeleted == 3, "with its node");
	}

	[Test]
	public static void OffFromInsideItsOwnHandlerDeletesItOnceTheListenersReturn()
	{
		sDeleted = 0;
		let node = new UIWidget();
		defer node.ReleaseRef();
		int32 token = 0;
		int calls = 0;
		token = node.On("click", new [&] (e) =>
			{
				calls++;
				Test.Assert(node.Off(token));
				Test.Assert(sDeleted == 0, "not under itself");
				return false;
			} ~ { sDeleted++; });
		node.SendEvent(scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f)));
		Test.Assert(calls == 1);
		Test.Assert(sDeleted == 1);
		node.SendEvent(scope MouseEvent(.MouseClick, node, .(0.0f, 0.0f)));
		Test.Assert(calls == 1);
	}

	[Test]
	public static void TypedBindsFollowTheGuisDataOnItsFrame()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		let bar = new ProgressBar();
		defer bar.ReleaseRef();
		let flag = new UIWidget();
		defer flag.ReleaseRef();
		root.AddChild(label);
		root.AddChild(slider);
		root.AddChild(bar);
		root.AddChild(flag);
		let gui = scope GuiFacade(root);
		gui.SetText("name", "Ada Lovelace");
		gui.SetNumber("volume", 0.25);
		gui.SetNumber("health", 0.5);
		gui.SetBool("shown", false);

		Test.Assert(label.BindText("text", new (outText) => { outText.AppendF("Hi {}", gui.GetText("name")); }));
		Test.Assert(slider.BindNumber("value", new () => gui.GetNumber("volume")));
		Test.Assert(bar.BindNumber("value", new () => gui.GetNumber("health")));
		Test.Assert(flag.BindBool("visible", new () => gui.GetBool("shown")));
		Test.Assert(label.Text == "Hi Ada Lovelace", "bound at once");
		Test.Assert(Near((float)slider.Value, 0.25f));
		Test.Assert(Near((float)bar.Value, 0.5f));
		Test.Assert(!flag.Visible);

		gui.SetText("name", "Bo"); // shorter: the text is the new one only
		gui.SetNumber("volume", 0.75);
		gui.SetNumber("health", 0.1);
		gui.SetBool("shown", true);
		Test.Assert(label.Text == "Hi Ada Lovelace", "waits for the frame");
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(label.Text == "Hi Bo");
		Test.Assert(Near((float)slider.Value, 0.75f));
		Test.Assert(Near((float)bar.Value, 0.1f));
		Test.Assert(flag.Visible);

		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.Context.LastBindingCount == 0, "settled");
	}

	[Test]
	public static void ATypedBindOwnsItsDelegateANameNoPropertyHasDeletesItAtOnce()
	{
		sDeleted = 0;
		var label = new Label();
		Test.Assert(!label.BindText("nonsense", new (outText) => { outText.Append("x"); } ~ { sDeleted++; }));
		Test.Assert(!label.BindNumber("nonsense", new () => { return 1.0; } ~ { sDeleted++; }));
		Test.Assert(!label.BindBool("nonsense", new () => { return true; } ~ { sDeleted++; }));
		Test.Assert(sDeleted == 3, "nothing binds: deleted at once");

		Test.Assert(label.BindText("text", new (outText) => { outText.Append("kept"); } ~ { sDeleted++; }));
		Test.Assert(label.BindBool("visible", new () => { return true; } ~ { sDeleted++; }));
		Test.Assert(label.Text == "kept");
		Test.Assert(label.BindText("text", new (outText) => { outText.Append("again"); } ~ { sDeleted++; }));
		Test.Assert(sDeleted == 4, "bound again: the old binding goes");
		Test.Assert(label.Text == "again");
		label.ReleaseRef(); // the last hold: its bindings go with it
		label = null;
		Test.Assert(sDeleted == 6);
	}

	[Test]
	public static void ATweensOnFinishedRunsOnceAtTheEndAndGoesWithTheTween()
	{
		sDeleted = 0;
		int finished = 0;
		{
			let bed = scope TweenBed("box { opacity: 1; }");
			let tween = bed.Widget.Animate("opacity", "0", 1.0f, "linear");
			tween.OnFinished(new () => { } ~ { sDeleted++; });
			tween.OnFinished(new [&] () => { finished++; } ~ { sDeleted++; });
			Test.Assert(sDeleted == 1, "one set before is deleted");
			bed.Frame(0.5);
			Test.Assert(finished == 0);
			bed.Frame(0.75);
			Test.Assert(finished == 1, "at the end");
			Test.Assert(Near(bed.Widget.Alpha, 0.0f));
			bed.Frame(1.0);
			Test.Assert(finished == 1, "once");
			Test.Assert(sDeleted == 1, "still the tween's");
			tween.ReleaseRef();
		}
		Test.Assert(sDeleted == 2, "with the tween");
	}

	/// GuiFacade.CaptureKey: the next key's binding name reaches the handler before the keymap
	/// sees it, Escape answers empty, and the handler is deleted after its one answer; with no GUI
	/// it is deleted uncalled.
	[Test]
	public static void TheFacadeCapturesTheNextKeyAndEscapeCancels()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let gui = scope GuiFacade(root);
		let d = root.EventDispatcher;
		let heard = scope String();
		int calls = 0;
		int deleted = 0;
		int jumps = 0;
		gui.DefineCommand("jump", "");
		root.OnCommand("jump", new [&] (command) => { jumps++; });
		Test.Assert(gui.BindKey("ctrl-q", "jump", ""));

		gui.CaptureKey(new [&] (keys) => { heard.Set(keys); calls++; } ~ { deleted++; });
		Test.Assert(d.IsCapturingKey);
		d.InjectKeyDown((uint32)KeyCode.Q, KeyModCtrl);
		Test.Assert(heard == "ctrl-q", heard);
		Test.Assert(jumps == 0, "taken before the keymap");
		Test.Assert((calls == 1) && (deleted == 1));
		Test.Assert(!d.IsCapturingKey);
		d.InjectKeyDown((uint32)KeyCode.Q, KeyModCtrl);
		Test.Assert(jumps == 1, "the keymap has keys again");

		gui.CaptureKey(new [&] (keys) => { heard.Set(keys); calls++; } ~ { deleted++; });
		d.InjectKeyDown((uint32)KeyCode.Escape, 0);
		Test.Assert(heard.IsEmpty, "cancelled: empty");
		Test.Assert((calls == 2) && (deleted == 2));

		let none = scope GuiFacade();
		none.CaptureKey(new [&] (keys) => { calls++; } ~ { deleted++; });
		Test.Assert((calls == 2) && (deleted == 3), "no GUI: deleted uncalled");
	}
}
