using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Expander: HTML's <details>. Its header toggles `open` and reports `toggle`; one of a name per
/// GUI open at a time; content built on first open; an optional eased height.
class ExpanderTests
{
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) => NodeFixtures.Near(a, b, epsilon);

	/// An expander titled "Advanced" whose content is a panel `contentHeight` tall, the last child
	/// of `root`, held by the caller.
	private static Expander AddExpander(SceneRoot root, float contentHeight)
	{
		let e = new Expander();
		e.Title = "Advanced";
		let body = new Panel();
		body.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(contentHeight); });
		e.Content.AddChild(body);
		body.ReleaseRef(); // its expander's content keeps it
		root.AddChild(e);
		return e;
	}

	[Test]
	public static void ItsHeaderTogglesItReportingToggleClosedItTakesOnlyItsHeadersHeight()
	{
		let root = SceneFixtures.NewScene(300.0f, 400.0f);
		defer root.ReleaseRef();
		let expander = AddExpander(root, 80.0f);
		defer expander.ReleaseRef();
		int toggles = 0;
		bool lastOpen = false;
		expander.AddEventListener(.Toggle, new [&] (e) =>
			{
				++toggles;
				lastOpen = ((ToggleEvent)e).Open;
			});
		root.UpdateLayout();
		let closed = expander.Size.Y;
		Test.Assert(expander.Header.Text == "Advanced");
		Test.Assert(!expander.Open);

		let d = root.EventDispatcher;
		let header = expander.Header.ScreenBounds;
		d.InjectMouseDown(.(header.X + 30.0f, header.Y + header.Height * 0.5f), .Left);
		d.InjectMouseUp(.(header.X + 30.0f, header.Y + header.Height * 0.5f), .Left);
		Test.Assert(expander.Open);
		Test.Assert(toggles == 1);
		Test.Assert(lastOpen);
		Test.Assert((expander.WidgetStates & WidgetStateChecked) != 0);
		root.UpdateLayout();
		Test.Assert(Near(expander.Size.Y, closed + 80.0f));

		// The keyboard: the header is a button.
		expander.Header.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!expander.Open);
		Test.Assert(toggles == 2);
	}

	[Test]
	public static void OneOfANameInAGUIOpenAtATimeContentBuiltOnFirstOpen()
	{
		let root = SceneFixtures.NewScene(300.0f, 400.0f);
		defer root.ReleaseRef();
		let a = AddExpander(root, 40.0f);
		defer a.ReleaseRef();
		let b = AddExpander(root, 40.0f);
		defer b.ReleaseRef();
		a.Name = "faq";
		b.Name = "faq";
		let otherRoot = SceneFixtures.NewScene(300.0f, 400.0f);
		defer otherRoot.ReleaseRef();
		let elsewhere = AddExpander(otherRoot, 40.0f);
		defer elsewhere.ReleaseRef();
		elsewhere.Name = "faq";
		elsewhere.Open = true;

		a.Open = true;
		b.Open = true;
		Test.Assert(!a.Open);
		Test.Assert(b.Open);
		Test.Assert(elsewhere.Open); // another GUI

		int built = 0;
		let lazy = AddExpander(root, 10.0f);
		defer lazy.ReleaseRef();
		lazy.SetContentFactory(new [&] (content) =>
			{
				++built;
				let more = new Panel();
				content.AddChild(more);
				more.ReleaseRef();
			});
		Test.Assert(built == 0);
		lazy.Open = true;
		lazy.Open = false;
		lazy.Open = true;
		Test.Assert(built == 1);
		Test.Assert(lazy.Content.ChildCount == 2);
	}

	[Test]
	public static void AnimatedItsHeightEasesOpenThroughAClipAndBack()
	{
		let root = SceneFixtures.NewScene(300.0f, 400.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let e = AddExpander(root, 100.0f);
		defer e.ReleaseRef();
		e.Animated = true;
		root.UpdateLayout();
		let closed = e.Size.Y;
		let gui = root.Context;

		e.Open = true;
		root.UpdateLayout();
		gui.Update(SceneFixtures.Seconds(0.09)); // half way: smoothstep(0.5) = 0.5
		root.UpdateLayout();
		Test.Assert(Near(e.Size.Y, closed + 50.0f, 0.05f));
		gui.Update(SceneFixtures.Seconds(0.2));
		root.UpdateLayout();
		Test.Assert(Near(e.Size.Y, closed + 100.0f));
		Test.Assert(Near(e.Reveal, 1.0f));

		e.Open = false;
		gui.Update(SceneFixtures.Seconds(0.3));
		root.UpdateLayout();
		Test.Assert(Near(e.Size.Y, closed));
	}
}
