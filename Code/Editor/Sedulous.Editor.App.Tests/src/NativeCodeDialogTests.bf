using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Runtime;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Add Native Code's dialog: the parts of the game's package asked for, a box each.
class NativeCodeDialogTests
{
	/// A GUI scene of 800 by 600.
	private class Bed
	{
		public SceneRoot Root;
		public List<PluginPartKind> Accepted = new .() ~ delete _;
		public int Answers = 0;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
		}

		public ~this()
		{
			Root.ReleaseRef();
		}

		public NativeCodeDialog Open(Span<PluginPartKind> existing)
		{
			let request = new NativeCodeRequest();
			request.Path.Set("Plugins/Game");
			for (let kind in existing)
				request.Existing.Add(kind);
			request.Accepted = new [=this] (parts) =>
				{
					Accepted.Clear();
					for (let kind in parts)
						Accepted.Add(kind);
					Answers++;
				};
			let dialog = NativeCodeDialog.Open(Root, PagesBed.LoadMarkup(NativeCodeDialog.cMarkupPath), request);
			Test.Assert(dialog != null);
			Root.UpdateLayout();
			Root.UpdateLayout();
			return dialog;
		}

		public static Sedulous.GUI.CheckBox Box(NativeCodeDialog dialog, PluginPartKind kind) =>
			dialog.Window.FindElement(NativeCodeDialog.BoxId(kind, .. scope .())) as Sedulous.GUI.CheckBox;
	}

	/// A package not made yet: Engine starts checked, every box can change, and Add makes what is
	/// checked, in load order, then closes.
	[Test]
	public static void ANewPackageStartsWithEngineAndAddMakesTheCheckedPartsInLoadOrder()
	{
		let bed = scope Bed();
		let dialog = bed.Open(.());
		defer delete dialog;
		Test.Assert(dialog.Window.Title == "Add Native Code");
		let what = dialog.Window.FindElement("native-code-what") as Sedulous.GUI.Label;
		let add = dialog.Window.FindElement("native-code-add") as Sedulous.GUI.Button;
		Test.Assert(Bed.Box(dialog, .Engine).Checked && Bed.Box(dialog, .Engine).Enabled);
		Test.Assert(!Bed.Box(dialog, .Pipeline).Checked && !Bed.Box(dialog, .Tooling).Checked && !Bed.Box(dialog, .Editor).Checked);
		Test.Assert(add.Enabled);
		Test.Assert(what.Text == "Makes Plugins/Game with its Engine part, and enables it.", scope String(what.Text));

		Test.Assert(Bed.Box(dialog, .Editor).HandleActivate());
		Test.Assert(Bed.Box(dialog, .Pipeline).HandleActivate());
		Test.Assert(what.Text == "Makes Plugins/Game with its Engine, Pipeline, Editor parts, and enables it.", scope String(what.Text));
		Test.Assert(Bed.Box(dialog, .Engine).HandleActivate()); // unchecked: a package may lack an Engine part
		Test.Assert(Bed.Box(dialog, .Pipeline).HandleActivate());
		Test.Assert(Bed.Box(dialog, .Editor).HandleActivate());
		Test.Assert(!add.Enabled);
		Test.Assert(what.Text == "Check a part the package does not have yet.", scope String(what.Text));
		Test.Assert(add.HandleActivate());
		Test.Assert((bed.Answers == 0) && dialog.IsOpen, "Add waits with nothing checked");

		Test.Assert(Bed.Box(dialog, .Tooling).HandleActivate());
		Test.Assert(Bed.Box(dialog, .Engine).HandleActivate());
		Test.Assert(add.HandleActivate());
		Test.Assert(!dialog.IsOpen);
		Test.Assert((bed.Answers == 1) && (bed.Accepted.Count == 2) && (bed.Accepted[0] == .Engine) && (bed.Accepted[1] == .Tooling));
	}

	/// A package already there: its parts show checked and fixed, Add waits until a part it lacks is
	/// checked and hands only those.
	[Test]
	public static void APackagesOwnPartsAreFixedAndAddHandsOnlyTheNewOnes()
	{
		let bed = scope Bed();
		let dialog = bed.Open(scope PluginPartKind[](.Engine));
		defer delete dialog;
		Test.Assert(dialog.Window.Title == "Add Native Code Parts");
		let what = dialog.Window.FindElement("native-code-what") as Sedulous.GUI.Label;
		let add = dialog.Window.FindElement("native-code-add") as Sedulous.GUI.Button;
		Test.Assert(Bed.Box(dialog, .Engine).Checked && !Bed.Box(dialog, .Engine).Enabled);
		Test.Assert(!add.Enabled);
		Test.Assert(what.Text == "Check a part the package does not have yet.", scope String(what.Text));
		Test.Assert(Bed.Box(dialog, .Tooling).HandleActivate());
		Test.Assert(what.Text == "Adds the Tooling part to Plugins/Game.", scope String(what.Text));
		Test.Assert(add.HandleActivate());
		Test.Assert((bed.Accepted.Count == 1) && (bed.Accepted[0] == .Tooling));

		// Markup without its parts opens nothing, the request let go.
		let empty = new Sedulous.GUI.Panel();
		Test.Assert(NativeCodeDialog.Open(bed.Root, empty, new NativeCodeRequest()) == null);
	}
}
