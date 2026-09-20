using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.UI;
using Sedulous.Engine.ScriptSurface;
using Sedulous.Engine.UI.Script;

namespace Sedulous.Engine.UI.Script.Tests;

/// The whole path from a script: `Ui` resolved as the run's service, handles by value,
/// a click handler bound as a ScriptCallback and run at the drain, and the stack verbs.
static class UiScriptedTests
{
	private static bool sRegistered = false;

	[Test]
	public static void AScriptDrivesTheScreenTierThroughUi()
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			sRegistered = true;
		}
		let bed = scope UiScriptBed();
		bed.Document = new () => UiScriptBed.Screen("menu");
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		let vm = scope AngelScriptRuntime();
		vm.Bind(surface);
		ClearAndDeleteItems!(vm.Problems);
		vm.SetService(bed.Ui);

		let ok = vm.Compile("ui", "ui.as", """
			class Menu
			{
				int retries = 0;
				string seen;
				bool bound = false;
				void open()
				{
					Screen s = Ui.Push(Guid::FromString("00000000-0000-0000-0000-000000000001"));
					if (!s.IsValid) return;
					Label title = s.FindLabel("title");
					seen = title.Text;
					title.SetText("Welcome");
					Button retry = Ui.FindButton("retry");
					retry.OnClick(ScriptCallback(this.onRetry));
					bound = retry.IsValid;
					Ui.FindProgressBar("health").SetValue(0.25f);
					Ui.FindTextBox("name").SetText("Grace");
				}
				void onRetry() { retries++; Ui.FindLabel("title").SetText("Retried " + retries); }
				int count() { return Ui.Count; }
				bool topIsMenu() { return Ui.Top.IsValid && Ui.Top.Name == "menu"; }
				bool missing() { return !Ui.FindLabel("nope").IsValid && Ui.FindLabel("nope").Text == ""; }
				void close() { Ui.Pop(); }
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let menu = vm.Instantiate("ui", "Menu");
		Test.Assert(menu != null);
		var r = ScriptValue.Nil;
		Test.Assert(vm.Invoke(menu, "open", default, ref r), "open ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		var v = ScriptValue.Nil;
		vm.GetProperty(menu, "seen", ref v);
		Test.Assert(v.AsString == "Hello", "read the label through the handle");
		vm.GetProperty(menu, "bound", ref v);
		Test.Assert(v.AsBool, "the button was found and bound");
		Test.Assert(bed.Ui.FindLabel("title").Text == "Welcome", "wrote it");
		Test.Assert(bed.Ui.FindProgressBar("health").Value == 0.25f);
		Test.Assert(bed.Ui.FindTextBox("name").Text == "Grace");
		Test.Assert(vm.Invoke(menu, "int count()", default, ref r) || vm.Invoke(menu, "count", default, ref r));
		Test.Assert(r.AsInt == 1);
		Test.Assert(vm.Invoke(menu, "topIsMenu", default, ref r) && r.AsBool);
		Test.Assert(vm.Invoke(menu, "missing", default, ref r) && r.AsBool, "a miss is null but valid in script too");

		// A click: the script's handler runs at the drain, not in the dispatch.
		bed.Ui.FindButton("retry").Resolve().FireClick();
		vm.GetProperty(menu, "retries", ref v);
		Test.Assert(v.AsInt == 0, "not inline");
		bed.Context.BeginFrame(0.016f);
		vm.GetProperty(menu, "retries", ref v);
		Test.Assert(v.AsInt == 1, "ran at the drain");
		Test.Assert(bed.Ui.FindLabel("title").Text == "Retried 1", "and reached the UI again from inside the callback");

		// The pop drops the screen; the delegate parked with the button dies with it, and the
		// runtime outliving it is fine.
		Test.Assert(vm.Invoke(menu, "close", default, ref r));
		Test.Assert(bed.Ui.Count == 0);
		UiHandles.Sweep();
		Test.Assert(UiHandles.Count == 0, scope $"{UiHandles.Count} handles left");
		vm.Release(menu);
	}
}
