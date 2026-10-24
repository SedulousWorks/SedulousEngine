using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The accessibility tree: roles from the widget types, names, values, ranges and states from
/// their reflected properties and selector states; a node with no role passes what it holds up, a
/// leaf's parts are none; markup's role and aria attributes override; a bridge that listens gets
/// the whole tree, then only what changed and the focus; a platform's requests run through the
/// paths input takes, and one a node does not advertise is refused.
class AccessibilityTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	private static TimeSpan Frame => TimeSpan((int64)((double)TimeSpan.TicksPerSecond / 60.0));

	private const String cForm =
		"""
		<Panel>
		    <Label id="title" text="Settings"/>
		    <Button id="save" text="Save"/>
		    <CheckBox id="music" text="Music" checked="true"/>
		    <Slider id="volume" min="0" max="10" step="1" value="4"/>
		    <TextField id="name" placeholder="Your name"/>
		    <TextField id="secret" password="true" text="hunter2"/>
		</Panel>
		""";

	/// A page from markup in a root 400 by 300, styled once (inline styles, the aria attributes
	/// among them, apply in the style pass) and stepped one frame.
	private class Bed
	{
		public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
		public Node Page ~ _?.ReleaseRef();

		public this(StringView markup)
		{
			Page = MarkupFixtures.Load(markup);
			Test.Assert(Page != null);
			Root.AddChild(Page);
			let styles = scope StyleManager();
			WidgetFixtures.UseSheet(styles, "");
			styles.ApplyTree(Root);
			Step();
		}

		public GUIContext Context => Root.Context;
		public void Step() => Context.Update(Frame);
		public Node Find(StringView id) => MarkupFixtures.Find(Root, id);

		public uint64 IdOf(StringView id)
		{
			let tree = Context.BuildAccessTree(Root);
			defer delete tree;
			let node = Find(id);
			for (let n in tree.Nodes)
			{
				if (Context.ResolveAccessId(n.Id) == node)
					return n.Id;
			}
			return 0;
		}

		public AccessNode Described(AccessTreeUpdate tree, StringView id)
		{
			let node = Find(id);
			for (let n in tree.Nodes)
			{
				if (Context.ResolveAccessId(n.Id) == node)
					return n;
			}
			return null;
		}
	}

	// Runs a request of `action` on `target` now.
	private static bool Run(GUIContext gui, uint64 target, AccessAction action, StringView text = default, bool hasNumber = false, double number = 0.0)
	{
		let request = scope AccessActionRequest();
		request.Target = target;
		request.Action = action;
		request.Text.Set(text);
		request.HasNumber = hasNumber;
		request.Number = number;
		return gui.RunAccessAction(request);
	}

	[Test]
	public static void RolesFromTheWidgetTypesAPanelPassesWhatItHoldsUpALeafsPartsAreNone()
	{
		let bed = scope Bed(cForm);
		let tree = bed.Context.BuildAccessTree(bed.Root);
		defer delete tree;
		Test.Assert(tree.Full);
		let root = tree.Find(tree.Root);
		Test.Assert(root != null);
		Test.Assert(root.Role == .Window);
		Test.Assert(root.Children.Count == 6); // the panel has no role: its widgets are the window's
		let save = bed.Described(tree, "save");
		Test.Assert(save != null);
		Test.Assert(save.Role == .Button);
		Test.Assert(save.Name == "Save");
		Test.Assert(save.Children.IsEmpty); // its label part reads as the button
		Test.Assert(save.Takes(.Activate));
		Test.Assert(save.Has(AccessFocusable));
		Test.Assert(bed.Described(tree, "title").Role == .Label);
		Test.Assert(bed.Described(tree, "title").Name == "Settings");
		Test.Assert(!bed.Described(tree, "title").Takes(.Activate));
		let music = bed.Described(tree, "music");
		Test.Assert(music.Role == .CheckBox);
		Test.Assert(music.Has(AccessChecked));
		let volume = bed.Described(tree, "volume");
		Test.Assert(volume.Role == .Slider);
		Test.Assert(volume.HasNumber);
		Test.Assert(Near(volume.Number, 4.0));
		Test.Assert(Near(volume.Max, 10.0));
		Test.Assert(Near(volume.Step, 1.0));
		Test.Assert(volume.Takes(.Increment));
		let name = bed.Described(tree, "name");
		Test.Assert(name.Role == .TextInput);
		Test.Assert(name.Description == "Your name"); // its placeholder
		Test.Assert(name.Has(AccessEditable));
		Test.Assert(name.Takes(.SetValue));
		Test.Assert(bed.Described(tree, "secret").Value.Length == 0); // a password is not read out
	}

	[Test]
	public static void MarkupsRoleAndAriaAttributesOverrideWhatTheTypeSays()
	{
		let bed = scope Bed(
			"<Panel>\n" +
			"    <Label id=\"caption\" text=\"Volume\"/>\n" +
			"    <Panel id=\"box\" role=\"group\" aria-label=\"Sound\">\n" +
			"        <Slider id=\"level\" aria-labelledby=\"caption\" aria-describedby=\"hint\"/>\n" +
			"        <Label id=\"hint\" text=\"From quiet to loud\"/>\n" +
			"    </Panel>\n" +
			"    <Label id=\"deco\" text=\"*\" aria-hidden=\"true\"/>\n" +
			"</Panel>");
		let tree = bed.Context.BuildAccessTree(bed.Root);
		defer delete tree;
		let @box = bed.Described(tree, "box");
		Test.Assert(@box != null);
		Test.Assert(@box.Role == .Group);
		Test.Assert(@box.Name == "Sound");
		Test.Assert(@box.Children.Count == 2);
		let level = bed.Described(tree, "level");
		Test.Assert(level.Name == "Volume"); // the label that names it
		Test.Assert(level.Description == "From quiet to loud");
		Test.Assert(level.LabelledBy.Count == 1);
		Test.Assert(bed.Described(tree, "deco") == null); // hidden from screen readers
	}

	[Test]
	public static void AListeningBridgeGetsTheWholeTreeThenWhatChangedAndTheFocus()
	{
		let bed = scope Bed(cForm);
		let bridge = scope AccessRecorder();
		bed.Context.AccessibilityBridge = bridge;
		bed.Step();
		Test.Assert(bridge.Updates.Count == 1);
		Test.Assert(bridge.Updates[0].Full);
		Test.Assert(bridge.Updates[0].Nodes.Count == 7); // the window and its six
		bed.Step();
		Test.Assert(bridge.Updates.Count == 1); // nothing changed: nothing sent

		(bed.Find("save") as Button).Text = "Save all";
		bed.Step();
		Test.Assert(bridge.Updates.Count == 2);
		Test.Assert(!bridge.Updates[1].Full);
		let save = bed.Described(bridge.Updates[1], "save");
		Test.Assert(save != null);
		Test.Assert(save.Name == "Save all");
		Test.Assert(bridge.Updates[1].Nodes.Count <= 3); // the button and what holds it

		bed.Find("name").RequestFocus();
		bed.Step();
		Test.Assert(bridge.Updates.Count == 3);
		Test.Assert(bridge.Updates[2].Focus == bed.IdOf("name"));

		bridge.Listening = false;
		(bed.Find("save") as Button).Text = "Save";
		bed.Step();
		Test.Assert(bridge.Updates.Count == 3); // no one listens: nothing built
		bridge.Listening = true;
		bed.Step();
		Test.Assert(bridge.Updates.Count == 4);
		Test.Assert(bridge.Updates[3].Full); // listening again: from the whole tree
		bed.Context.AccessibilityBridge = null;
	}

	[Test]
	public static void APlatformsRequestsRunAsInputDoesWhatANodeDoesNotTakeIsRefused()
	{
		let bed = scope Bed(cForm);
		int clicks = 0;
		(bed.Find("save") as Button).SetOnClick(new [&] () => { ++clicks; });
		let gui = bed.Context;
		Test.Assert(Run(gui, bed.IdOf("save"), .Activate));
		Test.Assert(clicks == 1);
		Test.Assert(!Run(gui, bed.IdOf("title"), .Activate));

		let volume = bed.Find("volume") as Slider;
		Test.Assert(Run(gui, bed.IdOf("volume"), .Increment));
		Test.Assert(Near(volume.Value, 5.0));
		Test.Assert(Run(gui, bed.IdOf("volume"), .SetValue, default, true, 8.0));
		Test.Assert(Near(volume.Value, 8.0));

		let name = bed.Find("name") as TextField;
		Test.Assert(Run(gui, bed.IdOf("name"), .SetValue, "Ana"));
		Test.Assert(name.Text == "Ana");
		Test.Assert(Run(gui, bed.IdOf("name"), .Focus));
		Test.Assert(name.IsFocused);

		// Queued from elsewhere, run in the next frame.
		let queued = scope AccessActionRequest();
		queued.Target = bed.IdOf("save");
		queued.Action = .Activate;
		gui.RequestAccessAction(queued);
		Test.Assert(clicks == 1);
		bed.Step();
		Test.Assert(clicks == 2);
		Test.Assert(!Run(gui, 0xFFFFFFFF, .Focus)); // no such node
	}

	[Test]
	public static void AnExpanderReadsExpandedOrCollapsedAndTakesTheOtherAnnouncementsReachAListener()
	{
		let bed = scope Bed("<Panel><Expander id=\"more\" title=\"More\" open=\"false\"/></Panel>");
		var tree = bed.Context.BuildAccessTree(bed.Root);
		let more = bed.Described(tree, "more");
		Test.Assert(more != null);
		Test.Assert(more.Name == "More");
		Test.Assert(more.Has(AccessCollapsed));
		Test.Assert(more.Takes(.Expand));
		Test.Assert(Run(bed.Context, more.Id, .Expand));
		Test.Assert((bed.Find("more") as Expander).Open);
		delete tree;
		tree = bed.Context.BuildAccessTree(bed.Root);
		Test.Assert(bed.Described(tree, "more").Has(AccessExpanded));
		delete tree;

		let bridge = scope AccessRecorder();
		bed.Context.Announce("unheard");
		bed.Context.AccessibilityBridge = bridge;
		bed.Context.Announce("Level 2", .Assertive);
		Test.Assert(bridge.Spoken.Count == 1);
		Test.Assert(bridge.Spoken[0] == "Level 2");
		bed.Context.AccessibilityBridge = null;
	}

	[Test]
	public static void ANodeMarkedAgainButReadingTheSameAnAnimationsFramesIsNotSentAgain()
	{
		let bed = scope Bed(cForm);
		let bridge = scope AccessRecorder();
		bed.Context.AccessibilityBridge = bridge;
		bed.Step();
		Test.Assert(bridge.Updates.Count == 1);
		bed.Find("save").Alpha = 0.5f; // drawn differently, read the same
		bed.Step();
		Test.Assert(bridge.Updates.Count == 1);
		(bed.Find("save") as Button).Text = "Save now";
		bed.Step();
		Test.Assert(bridge.Updates.Count == 2);
		bed.Context.AccessibilityBridge = null;
	}
}
