using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.UI;
using Sedulous.Engine.Composition;
using Sedulous.Engine.UI;
using Sedulous.Engine.UI.Script;

namespace Sedulous.Engine.UI.Script.Tests;

/// A world space UI component hands a script its instantiated tree as Root, the same
/// ViewGroup handle `Ui.Root` gives the screen tier, so the same finders fill a bar or set a
/// label inside it: a meter over a guard's head.
static class UiWorldRootTests
{
	private static bool sRegistered = false;

	[Test]
	public static void AScriptFillsTheViewsInsideAWorldPanel()
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			sRegistered = true;
		}
		let bed = scope UiScriptBed();
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		let vm = scope AngelScriptRuntime();
		vm.Bind(surface);
		ClearAndDeleteItems!(vm.Problems);
		vm.SetService(bed.Ui);

		let ok = vm.Compile("guard", "guard.as", """
			bool fill(const Entity &in guard)
			{
				ViewGroup views = UIWorldPanelComponent(guard).Root;
				views.FindProgressBar("meter").SetValue(0.75f);
				views.FindLabel("status").SetText("Seen");
				return views.IsValid;
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene("guard");
		let panels = scene.AddSystem<UIWorldPanelComponentManager>();
		let guard = scene.CreateEntity("guard");
		let panel = panels.Add(guard);
		// The tree the subsystem would build from the document: a group holding a bar and a label.
		let root = new ViewGroup();
		let bar = new ProgressBar();
		bar.Name.Set("meter");
		root.AddView(bar);
		let label = new Label();
		label.Name.Set("status");
		root.AddView(label);
		panel.Root = root;

		var args = ScriptValue[1](.FromEntity(guard, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("guard", "bool fill(const Entity &in)", args, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(r.AsBool, "the panel's tree reached the script");
		Test.Assert(Math.Abs(bar.Value.Value - 0.75f) < 1e-4f, "the bar inside the panel was filled");
		Test.Assert(label.Text.Value == "Seen", "the label inside the panel was set");

		// Before the tree is built the handle is null but valid: every finder misses quietly.
		panel.Root = null;
		Test.Assert(vm.Call("guard", "bool fill(const Entity &in)", args, ref r), "ran without a tree");
		Test.Assert(!r.AsBool, "no tree yet");
		panel.Root = root;
	}
}
