using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.UI;
using Sedulous.Engine.Composition;
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
				float volume = -1.0f;
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
					Ui.FindSlider("volume").OnChanged(ScriptCallback(this.onVolume));
				}
				void onVolume() { volume = Ui.FindSlider("volume").Value; }
				void onRetry() { retries++; Ui.FindLabel("title").SetText("Retried " + retries); }
				int count() { return Ui.Count; }
				bool topIsMenu() { return Ui.Top.IsValid && Ui.Top.Name == "menu"; }
				bool missing() { return !Ui.FindLabel("nope").IsValid && Ui.FindLabel("nope").Text == ""; }
				void close() { Ui.Pop(); }
				bool moved = false;
				bool shown = false;
				void showMap()
				{
					Image map = Ui.FindImage("minimap");
					map.SetSource(Guid::FromString("00000000-0000-0000-0000-000000000042"));
					shown = map.IsValid && !map.Source.IsNil;
				}
				void move()
				{
					Label marker = Ui.FindLabel("title");
					marker.SetTranslation(64.0f, 32.0f);
					marker.SetRotation(180.0f);
					moved = (marker.Translation.X == 64.0f) && (marker.Rotation > 179.0f);
				}
				bool tweened = false;
				void tween()
				{
					// Zero seconds lands at once, so the ends read back; the eased and the plain
					// calls both bind, and a pulse starts without a frame to run it.
					Image marker = Ui.FindImage("minimap");
					marker.MoveTo(10.0f, 20.0f, 0.0f, Ease::OutBack);
					marker.ScaleTo(2.0f, 0.0f);
					marker.RotateTo(30.0f, 0.0f, Ease::Linear);
					marker.FadeTo(0.5f, 0.0f, Ease::Out);
					marker.Pulse(1.2f, 0.3f);
					tweened = (marker.Translation.Y == 20.0f) && (marker.Scale == 2.0f) && (marker.Opacity == 0.5f);
				}
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

		// A slider moved, by a drag or a pad: its handler runs at the drain and reads the value.
		bed.Ui.FindSlider("volume").Resolve().Value.Value = 0.8f;
		bed.Context.BeginFrame(0.016f);
		vm.GetProperty(menu, "volume", ref v);
		Test.Assert(Math.Abs(v.AsFloat - 0.8f) < 0.0001f, scope $"the handler read the new value ({v.AsFloat})");

		// A view moves and turns from script (a minimap marker), and reads it back.
		Test.Assert(vm.Invoke(menu, "move", default, ref r));
		vm.GetProperty(menu, "moved", ref v);
		Test.Assert(v.AsBool, "read the transform back");
		let marker = bed.Ui.FindLabel("title").Resolve();
		Test.Assert(Math.Abs(marker.Transform.Translation.Y - 32.0f) < 0.0001f);
		Test.Assert(Math.Abs(marker.Transform.Rotation - DegreesToRadians(180.0f)) < 0.0001f);

		// Tweens from script, with or without an Ease.
		Test.Assert(vm.Invoke(menu, "tween", default, ref r));
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		vm.GetProperty(menu, "tweened", ref v);
		Test.Assert(v.AsBool, "the tweens' ends read back");
		let tweened = bed.Ui.FindImage("minimap").Resolve();
		Test.Assert(Math.Abs(tweened.Transform.Translation.X - 10.0f) < 0.0001f);
		Test.Assert(Math.Abs(tweened.Transform.Rotation - DegreesToRadians(30.0f)) < 0.0001f);

		// An image's source from script: the texture asset it shows.
		Test.Assert(vm.Invoke(menu, "showMap", default, ref r));
		vm.GetProperty(menu, "shown", ref v);
		Test.Assert(v.AsBool, "found the image and read its source back");
		Test.Assert(bed.Ui.FindImage("minimap").Resolve().Source.Value == "00000000-0000-0000-0000-000000000042");

		// The pop drops the screen; the delegate parked with the button dies with it, and the
		// runtime outliving it is fine.
		Test.Assert(vm.Invoke(menu, "close", default, ref r));
		Test.Assert(bed.Ui.Count == 0);
		UiHandles.Sweep();
		Test.Assert(UiHandles.Count == 0, scope $"{UiHandles.Count} handles left");
		vm.Release(menu);
	}
}
