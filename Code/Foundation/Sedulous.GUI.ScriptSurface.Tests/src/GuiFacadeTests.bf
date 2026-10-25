using System;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.GUI;

namespace Sedulous.GUI.ScriptSurface.Tests;

/// The `Gui` facade, and Raptor's script stories that reach the GUI through it (its
/// Integration.GuiScript tests, their AngelScript halves): a script defines, handles and runs
/// commands; captures the next key, names it and binds it; binds widgets to the GUI's data and to
/// each other, and keeps a node as a data value; tweens a data value; reads the input kind and
/// hears it change; reads localized texts; and finds no GUI once its host takes its root away.
static class GuiFacadeTests
{
	/// A GUI for one script, as Raptor's GuiBed is: its root, 400 by 300, installed as the
	/// script's `Gui.Root()`.
	private class Bed
	{
		public SceneRoot Root;
		public GuiFacade Gui = new .() ~ delete _;
		// What the runtime is bound to: it points into the surface, so the surface outlives it.
		public ScriptSurface Surface = new .() ~ delete _;
		public AngelScriptRuntime Vm = new .();
		public String Module = new .() ~ delete _;

		public this(StringView module, StringView source)
		{
			RegisterGuiElements();
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(400.0f, 300.0f);
			Gui.RootNode = Root;
			GuiScriptSurface.Populate(Surface);
			Vm.Bind(Surface);
			Vm.SetService(Gui);
			Module.Set(module);
			let ok = Vm.Compile(module, scope $"{module}.as", source);
			Dump();
			Test.Assert(ok && Vm.Problems.IsEmpty, "compiled, with nothing to say");
		}

		public ~this()
		{
			Vm.DiscardModule(Module);
			Gui.RootNode = null;
			Root?.ReleaseRef();
			delete Vm;
			Vm = null;
		}

		public void Dump()
		{
			for (let p in Vm.Problems)
				Console.WriteLine("  {}", p);
		}

		public ScriptValue Call(StringView decl)
		{
			var r = ScriptValue.Nil;
			let ok = Vm.Call(Module, decl, default, ref r);
			Dump();
			Test.Assert(ok, scope $"{decl} ran");
			return r;
		}

		public void Update(double seconds = 0.0) => Root.Context.Update(TimeSpan((int64)(seconds * (double)TimeSpan.TicksPerSecond)));

		public DataModel Data => Root.Context.Data;
	}

	[Test]
	public static void TheFacadeIsAServiceNamedGui()
	{
		let s = scope ScriptSurface();
		GuiScriptSurface.Populate(s);
		let t = s.Find("Sedulous.GUI.GuiFacade");
		Test.Assert((t != null) && (t.Role == .Service), "a service a host sets");
		let vm = scope Sedulous.Script.Null.NullScriptRuntime();
		vm.Bind(s);
		let text = scope String();
		vm.Describe(text);
		Test.Assert(text.Contains("class GuiFacade [Service] \"Gui\""), "reached as Gui");
		Test.Assert(text.Contains("Root() -> Node") && text.Contains("SetNode(") && text.Contains("CaptureKey("), "with its verbs");
	}

	/// A host whose scripts' roots differ by what runs them gives a function: the root is its
	/// answer at each call.
	[Test]
	public static void AResolvingFacadeAnswersWithTheRootOfTheMoment()
	{
		let context = new GUIContext();
		let first = new SceneRoot(context);
		let second = new SceneRoot(context);
		context.ReleaseRef();
		SceneRoot current = first;
		let gui = scope GuiFacade(new [&] () => current);
		Test.Assert(gui.Root() == first);
		current = second;
		Test.Assert(gui.Root() == second);
		current = null;
		Test.Assert(gui.Root() == null);
		first.ReleaseRef();
		second.ReleaseRef();
	}

	// Raptor's command story (G7): the script defines "music" (label "Music"), handles it on the
	// root by toggling its checked state, binds a CheckBox and F5 to it, and offers switchOff()
	// (disables it) and runIt() (runs it: whether a handler ran).
	private const String cCommands = """
		bool toggleMusic() { Gui.SetCommandChecked("music", !Gui.IsCommandChecked("music")); return false; }
		void main()
		{
			Node@ root = Gui.Root();
			Gui.DefineCommand("music", "Music");
			root.OnCommand("music", CommandHandler(toggleMusic));
			Node@ check = root.Add("CheckBox");
			check.Command = "music";
			Gui.BindKey("f5", "music", "");
		}
		void switchOff() { Gui.SetCommandEnabled("music", false); Gui.SetCommandDisabledReason("music", "No sound device"); }
		bool runIt() { return Gui.RunCommand("music"); }
		""";

	[Test]
	public static void AScriptDefinesHandlesAndRunsCommands()
	{
		let bed = scope Bed("commands", cCommands);
		bed.Call("void main()");
		let check = bed.Root.GetChildAt(0) as CheckBox;
		Test.Assert(check != null);
		let music = bed.Root.Context.Commands.Find("music");
		Test.Assert((music != null) && (music.Label == "Music"));
		bed.Update();
		Test.Assert(check.Enabled);
		Test.Assert(bed.Call("bool runIt()").AsBool, "the script's handler ran");
		bed.Update();
		Test.Assert(check.Checked, "and toggled it");
		bed.Root.EventDispatcher.InjectKeyDown((uint32)KeyCode.F5);
		bed.Update();
		Test.Assert(!check.Checked, "F5, as the script bound it");
		bed.Call("void switchOff()");
		bed.Update();
		Test.Assert(!check.Enabled);
		Test.Assert(bed.Root.Context.Commands.Find("music").DisabledReason == "No sound device");
		Test.Assert(!bed.Call("bool runIt()").AsBool, "disabled: nothing runs");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's key capture (E12): the next key's name lands in the data as `captured`, a key bound
	// from it runs its command, and `shown` is the key as a menu shows it.
	private const String cCapture = """
		double count = 0;
		bool jump() { count += 1; return false; }
		void onKey(const string &in keys)
		{
			Gui.SetText("captured", keys);
			if (keys != "") Gui.BindKey(keys, "jump", "");
			Gui.SetText("shown", Gui.KeyText(keys));
		}
		void main() { Gui.Root().OnCommand("jump", CommandHandler(jump)); }
		void listen() { Gui.CaptureKey(KeyHandler(onKey)); }
		double jumps() { return count; }
		""";

	[Test]
	public static void AScriptCapturesTheNextKeyNamesItAndBindsIt()
	{
		let bed = scope Bed("capture", cCapture);
		bed.Call("void main()");
		let d = bed.Root.EventDispatcher;
		bed.Call("void listen()");
		Test.Assert(d.IsCapturingKey);
		d.InjectKeyDown((uint32)KeyCode.Q, KeyModCtrl);
		bed.Update();
		Test.Assert(TextOf(bed.Data.Get("captured")) == "ctrl-q");
		Test.Assert(bed.Call("double jumps()").AsFloat == 0.0);
		d.InjectKeyDown((uint32)KeyCode.Q, KeyModCtrl); // now bound to jump
		bed.Update();
		Test.Assert(bed.Call("double jumps()").AsFloat == 1.0);
		bed.Call("void listen()");
		d.InjectKeyDown((uint32)KeyCode.Escape, 0); // cancelled: empty
		bed.Update();
		Test.Assert(TextOf(bed.Data.Get("captured")).IsEmpty);
		bed.Call("void listen()");
		d.InjectKeyDown((uint32)KeyCode.Keypad5, 0);
		Test.Assert(TextOf(bed.Data.Get("shown")) == "Numpad 5");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's binding story (G5). Before the script runs, the data holds score 3 and volume 0.5.
	// The script builds a Label bound to "Score: " and the score text, a Slider bound both ways to
	// volume, and a Label bound to the slider's value; keeps the slider, narrowed, as the data's
	// `picked`; and offers setNine(), which writes the score.
	private const String cBindings = """
		Slider@ slider;
		bool allBound = false;
		string scoreText() { return "Score: " + Gui.GetText("score"); }
		double sliderValue() { return slider.Value; }
		void main()
		{
			Node@ root = Gui.Root();
			Label@ score = Label::Of(root.Add("Label"));
			@slider = Slider::Of(root.Add("Slider"));
			Label@ volume = Label::Of(root.Add("Label"));
			bool a = score.Bind("Text", TextExpression(scoreText));
			bool b = slider.BindData("Value", "volume");
			bool c = volume.BindNumber("Text", NumberExpression(sliderValue));
			allBound = a && b && c;
			Node@ held = root.ChildAt(1);
			Slider@ narrowed = Slider::Of(held);
			Gui.SetNode("picked", narrowed);
		}
		bool bound() { return allBound; }
		void setNine() { Gui.SetNumber("score", 9); }
		double volumeNow() { return Gui.GetNumber("volume"); }
		""";

	[Test]
	public static void AScriptBindsWidgetsToDataAndToEachOtherAndKeepsANodeAsAValue()
	{
		let bed = scope Bed("bindings", cBindings);
		var three = System.Variant.Create((int32)3);
		bed.Data.Set("score", three);
		var half = System.Variant.Create(0.5);
		bed.Data.Set("volume", half);
		bed.Call("void main()");
		let score = bed.Root.GetChildAt(0) as Sedulous.GUI.Label;
		let slider = bed.Root.GetChildAt(1) as Slider;
		let volume = bed.Root.GetChildAt(2) as Sedulous.GUI.Label;
		Test.Assert((score != null) && (slider != null) && (volume != null));
		Test.Assert(score.Text == "Score: 3");
		Test.Assert(Math.Abs(slider.Value - 0.5) < 1e-9);
		Test.Assert(volume.Text == "0.5");
		Test.Assert(bed.Call("bool bound()").AsBool, "every bind answered true");
		// The narrowed handle reached the data as the same element.
		Test.Assert(NodeOf(bed.Data.Get("picked")) == slider);

		// The game changes the data: the script's binding follows on the GUI's frame.
		var four = System.Variant.Create((int32)4);
		bed.Data.Set("score", four);
		bed.Update();
		Test.Assert(score.Text == "Score: 4");

		// The user drags the slider: the data and the label reading the slider follow.
		slider.Value = 0.75;
		bed.Update();
		Test.Assert(volume.Text == "0.75");
		Test.Assert(Math.Abs(bed.Call("double volumeNow()").AsFloat - 0.75) < 1e-9);

		// The script writes the data.
		bed.Call("void setNine()");
		bed.Update();
		Test.Assert(score.Text == "Score: 9");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	/// A node kept as a data value is held weakly: gone, it reads as no node, and the value holds
	/// the element table alive past its GUI without the GUI.
	[Test]
	public static void ANodeKeptAsAValueReadsAsNoneOnceItIsGone()
	{
		let bed = scope Bed("kept", """
			void keep() { Gui.SetNode("kept", Gui.Root().Add("Panel")); }
			void clear() { Gui.SetNode("kept", null); }
			""");
		bed.Call("void keep()");
		let panel = bed.Root.GetChildAt(0);
		Test.Assert((panel != null) && (NodeOf(bed.Data.Get("kept")) == panel));
		var same = bed.Data.Get("kept");
		Test.Assert(!bed.Data.Set("kept", same), "the same node is no change");
		panel.Close();
		bed.Update();
		Test.Assert(bed.Root.ChildCount == 0);
		Test.Assert(NodeOf(bed.Data.Get("kept")) == null, "gone: no node");
		bed.Call("void keep()");
		bed.Call("void clear()");
		Test.Assert(!bed.Data.Get("kept").HasValue, "null clears it");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's data tween (K3): the script tweens `score` (0 at first) to 10 over a second and
	// offers done(), whether its tween ended.
	private const String cDataTween = """
		Tween@ counting;
		void main() { @counting = Gui.Tween("score", 10, 1.0, "linear"); }
		bool done() { return counting.IsDone; }
		""";

	[Test]
	public static void AScriptTweensADataValue()
	{
		let bed = scope Bed("datatween", cDataTween);
		var zero = System.Variant.Create((int32)0);
		bed.Data.Set("score", zero);
		bed.Call("void main()");
		bed.Update(0.5);
		let half = bed.Data.Get("score");
		Test.Assert((half.VariantType == typeof(int32)) && (half.Get<int32>() == 5), "halfway, in whole numbers");
		Test.Assert(!bed.Call("bool done()").AsBool);
		bed.Update(0.5);
		Test.Assert(bed.Data.Get("score").Get<int32>() == 10);
		Test.Assert(bed.Call("bool done()").AsBool);
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's input kind (K2b): the script offers isPad() from Gui.InputKind(), and counts the
	// root's `inputkind` events in changes().
	private const String cInputKind = """
		double heard = 0;
		bool onKind(GuiEvent@ e) { heard += 1; return false; }
		void main() { Gui.Root().On("inputkind", EventHandler(onKind)); }
		bool isPad() { return Gui.InputKind() == "pad"; }
		double changes() { return heard; }
		""";

	[Test]
	public static void AScriptReadsTheInputKindAndHearsItChange()
	{
		let bed = scope Bed("inputkind", cInputKind);
		bed.Call("void main()");
		Test.Assert(!bed.Call("bool isPad()").AsBool);
		bed.Root.EventDispatcher.InputKind = .Pad;
		Test.Assert(bed.Call("bool isPad()").AsBool);
		Test.Assert(bed.Call("double changes()").AsFloat == 1.0);
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's localized texts (E16): the GUI's localization has `title` and the plural `lives`.
	private const String cTexts = """
		bool textsRight()
		{
			return Gui.Tr("title") == "Settings" && Gui.TrCount("lives", 3) == "3 lives"
				&& Gui.TrCount("lives", 1) == "1 life" && Gui.Tr("missing") == "missing" && Gui.Language() == "en";
		}
		bool untranslated() { return Gui.Tr("title") == "title" && Gui.TrCount("lives", 2) == "lives" && Gui.Language() == ""; }
		""";

	[Test]
	public static void AScriptReadsLocalizedTexts()
	{
		let bed = scope Bed("texts", cTexts);
		Test.Assert(bed.Call("bool untranslated()").AsBool, "with no localization: the keys");
		let table = scope Sedulous.I18N.StringTable();
		Test.Assert(table.Set("title", "en", "Settings"));
		Test.Assert(table.SetPluralRule("en", "one: n = 1"));
		Test.Assert(table.SetPlural("lives", "en", .One, "{0} life"));
		Test.Assert(table.SetPlural("lives", "en", .Other, "{0} lives"));
		let loc = scope Sedulous.I18N.Localization();
		loc.AddTable(table);
		loc.SetLanguage("en");
		bed.Root.Context.Localization = loc;
		Test.Assert(bed.Call("bool textsRight()").AsBool);
		bed.Root.Context.Localization = null;
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}

	// Raptor's handle rule at its end: a host taking its root away leaves the script no GUI, a
	// handle it kept reads as gone, and the facade's verbs do nothing.
	private const String cGone = """
		Node@ kept;
		void main() { @kept = Gui.Root().Add("Panel"); }
		bool hasRoot() { return Gui.Root() !is null; }
		bool keptValid() { return kept !is null && kept.IsValid; }
		double quiet() { Gui.SetNumber("x", 1); Gui.DefineCommand("c", ""); return Gui.GetNumber("x"); }
		""";

	[Test]
	public static void AScriptFindsNoGuiOnceItsHostTakesTheRootAway()
	{
		let bed = scope Bed("gone", cGone);
		bed.Call("void main()");
		Test.Assert(bed.Call("bool hasRoot()").AsBool);
		Test.Assert(bed.Call("bool keptValid()").AsBool);
		bed.Gui.RootNode = null;
		bed.Root.ReleaseRef();
		bed.Root = null;
		Test.Assert(!bed.Call("bool hasRoot()").AsBool, "no GUI");
		Test.Assert(!bed.Call("bool keptValid()").AsBool, "the kept handle is gone");
		Test.Assert(bed.Call("double quiet()").AsFloat == 0.0, "and the verbs do nothing");
		Test.Assert(bed.Vm.Problems.IsEmpty);
	}
}
