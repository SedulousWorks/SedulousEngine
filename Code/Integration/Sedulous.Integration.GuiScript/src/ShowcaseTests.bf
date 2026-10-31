using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.VFS;
using Sedulous.VG.SVG;
using Sedulous.GUI;
using Sedulous.GUI.Gamekit.ScriptSurface;

namespace Sedulous.Integration.GuiScript;

/// The data folder's files, as the sandbox reads them: a path relative to Data/.
class ShowcaseFiles : IResourceProvider
{
	public override ImageData LoadImage(StringView path) => null;

	public override bool LoadText(StringView path, String outText) => Showcase.ReadData(path, outText);

	public override SVGDocument LoadSvg(StringView path) => null;
}

/// The GUI's game menu as the sandbox hosts it: its frame (Data/Samples/UI/showcase/menu.xml)
/// filling a 960 x 820 root, its sheet over it, the menu's one action given to its prompts, and
/// its script running, which pushes its screens' documents from the data folder.
class Showcase
{
	public SceneRoot Root;
	public StyleManager Styles = new .() ~ delete _;
	public ShowcaseFiles Files = new .() ~ delete _;
	public Sedulous.Input.ActionRuntime Actions = new .() ~ delete _;
	public InputPrompts Prompts = new .() ~ delete _;
	public GuiFacade Gui = new .() ~ delete _;
	// What the runtime is bound to: it points into the surface, so the surface outlives it.
	public Sedulous.Script.ScriptSurface Surface = new .() ~ delete _;
	public AngelScriptRuntime Vm = new .();
	/// The menu's frame and its stack: BORROWED, the root's tree holds them.
	public Node MenuFrame;
	public ScreenStack Stack;

	public this()
	{
		RegisterGuiElements();
		RegisterGamekitElements();
		let context = new GUIContext();
		Root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		Root.Size = .(960.0f, 820.0f);
		Root.Context.ResourceProvider = Files;
		let data = Root.Context.Data;
		var name = TextVariant("Ada");
		data.Set("name", name);
		name.Dispose();
		var volume = System.Variant.Create(0.7);
		data.Set("volume", volume);
		var music = System.Variant.Create(true);
		data.Set("music", music);

		// The menu's one action, which its HUD's prompt shows.
		let map = scope Sedulous.Input.InputMap();
		let game = new Sedulous.Input.ActionSet();
		game.Name.Set("Game");
		let pause = new Sedulous.Input.InputAction();
		pause.Name.Set("pause");
		Sedulous.Input.Binding escape = .();
		escape.Source = .Key;
		escape.Code = (uint32)Sedulous.Shell.KeyCode.Escape;
		pause.Bindings.Add(escape);
		Sedulous.Input.Binding start = .();
		start.Source = .GamepadButton;
		start.Code = (uint32)Sedulous.Shell.GamepadButton.Start;
		pause.Bindings.Add(start);
		game.Actions.Add(pause); // the set owns it
		map.Sets.Add(game); // the map owns it
		Actions.SetMap(map);
		Prompts.SetRuntime(Actions);
		Prompts.Install(Root.Context);

		let markup = scope String();
		Test.Assert(ReadData("Samples/UI/showcase/menu.xml", markup), "the frame reads");
		let loader = scope MarkupLoader(Root.ElementSet, Files);
		loader.SetDataModel(Root.Context.Data);
		MenuFrame = loader.LoadFromString(markup);
		Test.Assert(MenuFrame != null, "the frame loads");
		Root.AddChild(MenuFrame);
		MenuFrame.ReleaseRef(); // the root's keeps it
		MenuFrame.Size = Root.Size;
		for (int i = 0; i < MenuFrame.ChildCount; i++)
			MenuFrame.GetChildAt(i).Size = Root.Size;
		let css = scope String();
		Test.Assert(ReadData("Samples/UI/showcase/menu.css", css), "the sheet reads");
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.SetSubtreeSheet(MenuFrame, sheet);
		Styles.ApplyTree(Root);
		Stack = MenuFrame.FindElement("screens") as ScreenStack;
		Test.Assert(Stack != null, "the frame holds the screens");

		Gui.RootNode = Root;
		GamekitScriptSurface.Populate(Surface);
		Vm.Bind(Surface);
		Vm.SetService(Gui);
		let source = scope String();
		Test.Assert(ReadData("Samples/UI/showcase/menu.as", source), "the script reads");
		let ok = Vm.Compile("menu", "menu.as", source);
		Dump();
		Test.Assert(ok && Vm.Problems.IsEmpty, "compiled, with nothing to say");
		var r = ScriptValue.Nil;
		Test.Assert(Vm.Call("menu", "void main()", default, ref r), "the menu opened");
		Dump();
		Frame(0.0);
	}

	public ~this()
	{
		// The runtime first: it holds the script's handles and borrows the facade and the surface.
		Vm.DiscardModule("menu");
		delete Vm;
		Vm = null;
		Gui.RootNode = null;
		InputPrompts.Uninstall(Root.Context);
		Root.Context.ResourceProvider = null;
		Root.ReleaseRef();
	}

	/// The file at `relative` under the data root, appended to `outText`; false when it does not
	/// read.
	public static bool ReadData(StringView relative, String outText)
	{
		let root = FindDataRoot(.. scope String());
		let path = DataPath(root, relative, .. scope String());
		return File.ReadAllText(path, outText, true) case .Ok;
	}

	public void Dump()
	{
		for (let p in Vm.Problems)
			Console.WriteLine("  {}", p);
	}

	public EventDispatcher D => Root.EventDispatcher;

	/// A host's frame: the script's update, the GUI's clock, the style pass and the layout.
	public void Frame(double seconds)
	{
		var args = ScriptValue[1](.FromFloat(seconds));
		var r = ScriptValue.Nil;
		Vm.Call("menu", "bool update(double)", args, ref r);
		Dump();
		Root.Context.Update(GuiBed.Seconds(seconds));
		Styles.ApplyTree(Root);
		Root.UpdateLayout();
	}

	public void Frames(double seconds, double step = 0.05)
	{
		for (double t = 0.0; t < seconds - 1e-6; t += step)
			Frame(step);
	}

	/// `key` pressed and released, then a frame.
	public void Key(KeyCode key)
	{
		D.InjectKeyDown((uint32)key);
		D.InjectKeyUp((uint32)key);
		Frame(0.0);
	}

	/// Moves the focus to the button `id` on the top screen and presses Return, as a player would.
	public void Choose(StringView id)
	{
		let top = Stack.Top;
		Test.Assert(top != null, "a screen on top");
		let target = top.FindElement(id);
		Test.Assert(target != null, scope $"{id} on the top screen");
		D.FocusNode = target;
		Key(.Return);
	}

	/// The focused widget's id ("" with none).
	public StringView Focused
	{
		get
		{
			let focus = D.FocusNode as UIWidget;
			return (focus != null) ? focus.Id : "";
		}
	}

	/// The GUI's data value `name`, read without a binding following it: a view.
	public System.Variant Data(StringView name) => Root.Context.Data.Peek(name);

	/// Whether the title over the menu's pages shows.
	public bool StageShown => MenuFrame.FindElement("stage").Displayed;

	public static Sedulous.GUI.Prompt FindPrompt(Node node)
	{
		if (let prompt = node as Sedulous.GUI.Prompt)
			return prompt;
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (let found = FindPrompt(node.GetChildAt(i)))
				return found;
		}
		return null;
	}
}

/// The GUI's game menu (the sandbox's showcase, K7 of Raptor's gui-lab-evolution-3.md) played end
/// to end from its real files, Raptor's ShowcaseScriptTests: Data/Samples/UI/showcase's frame,
/// sheet, screen documents and AngelScript, on the gamekit's stack. A player's keys and pad drive
/// it: pages and Back, the quit question, loading into the game, the HUD's prompt following the
/// device, the score counting up in whole numbers, pause from Escape and Start stopping the game,
/// back to the menu, and leaving.
static class ShowcaseTests
{
	[Test]
	public static void TheMenusPagesPushAndPopBackGoesBackAndTheTitleKeepsItsOwnBack()
	{
		let menu = scope Showcase();
		Test.Assert(menu.Vm.Problems.IsEmpty);
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.Focused == "play", scope $"focused: {menu.Focused}");
		menu.Key(.Escape); // the title keeps its back
		Test.Assert(menu.Stack.Count == 1);

		menu.Choose("settings-btn");
		Test.Assert(menu.Stack.Count == 2);
		Test.Assert(menu.Stack.Top.Covers);
		Test.Assert(menu.D.FocusNode != null, "the page took the focus");
		menu.Frames(0.5); // its entrance; then Back
		menu.Key(.Escape);
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.Focused == "settings-btn", "where the player left from");

		menu.Choose("controls-btn");
		Test.Assert(menu.Stack.Count == 2);
		menu.Frames(0.5);
		menu.D.InjectPadButton(.East); // Back from the pad
		menu.Frame(0.0);
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.Vm.Problems.IsEmpty);
	}

	[Test]
	public static void TheQuitQuestionOpensOverTheMenuStayAndBackCloseItLeaveSetsQuitForTheHost()
	{
		let menu = scope Showcase();
		menu.Choose("quit");
		Test.Assert(menu.Stack.Count == 2);
		Test.Assert(!menu.Stack.Top.Covers, "the menu shows behind it");
		Test.Assert(menu.Focused == "confirm-no", "Stay, the safe answer");
		menu.Frames(0.5);
		menu.Key(.Return); // Stay
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.Focused == "quit");
		menu.Choose("quit");
		menu.Frames(0.5);
		menu.Key(.Escape); // Back is Stay too
		Test.Assert(menu.Stack.Count == 1);

		menu.Choose("quit");
		menu.Frames(0.5);
		menu.Choose("confirm-yes"); // Leave
		// As the host reads it (a script's true may arrive as a number).
		var quit = ConvertVariant(menu.Data("quit"), typeof(bool));
		defer quit.Dispose();
		Test.Assert((quit.VariantType == typeof(bool)) && quit.Get<bool>(), "quit is set");
		Test.Assert((menu.MenuFrame as UIWidget).HasClass("closing"), "the menu fades out");
		Test.Assert(menu.Vm.Problems.IsEmpty);
	}

	[Test]
	public static void PlayLoadsIntoTheGameBackFromLoadingReturnsToTheMenu()
	{
		let menu = scope Showcase();
		menu.Choose("play");
		Test.Assert(menu.Stack.Count == 2);
		Test.Assert(!menu.StageShown, "the loading screen replaces the menu");
		menu.Frames(1.0);
		menu.Key(.Escape); // Back cancels the loading
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.StageShown);
		menu.Frames(4.0); // nothing goes on loading behind it
		Test.Assert(menu.Stack.Count == 1);

		menu.Choose("play");
		menu.Frames(3.5); // 2.5 s loading, a moment on Ready, then the game
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.Stack.Top.Covers);
		Test.Assert(menu.Stack.Top.FindElement("hud-score") != null, "the HUD");
		Test.Assert(!menu.StageShown);
		Test.Assert(menu.Vm.Problems.IsEmpty);
	}

	[Test]
	public static void InTheGameTheScoreCountsUpInWholeNumbersThePromptFollowsTheDeviceAndPauseStopsTheGame()
	{
		let menu = scope Showcase();
		menu.Choose("play");
		menu.Frames(3.5);
		let hud = menu.Stack.Top;
		Test.Assert(hud != null);
		let prompt = Showcase.FindPrompt(hud);
		Test.Assert(prompt != null);
		Test.Assert(prompt.BindingName == "escape", scope $"the prompt shows {prompt.BindingName}");
		menu.D.InputKind = .Pad;
		menu.Frame(0.0);
		Test.Assert(prompt.BindingName == "pad-start", scope $"the prompt shows {prompt.BindingName}");

		// The score: points every 1.4 s, counted up through a data tween, never a fraction on the way.
		bool sawRising = false;
		for (int i = 0; i < 80; i++)
		{
			menu.Frame(0.05);
			let score = menu.Data("score");
			Test.Assert(score.VariantType == typeof(double), "the score is a number");
			let n = score.Get<double>();
			Test.Assert(n == (double)(int64)n, scope $"a whole number: {n}");
			sawRising = sawRising || ((n > 0.0) && (((int64)n % 10) != 0));
		}
		Test.Assert(sawRising, "it passed numbers between the tens: it counted, not jumped");
		Test.Assert(menu.Data("score").Get<double>() >= 20.0);

		// Escape pauses: the pause screen over the HUD, the game's clock standing still.
		menu.Key(.Escape);
		Test.Assert(menu.Stack.Count == 2);
		Test.Assert(menu.Stack.IsPaused);
		Test.Assert(menu.Focused == "resume");
		let clock = scope String(TextOf(menu.Data("clock")));
		menu.Frames(2.0);
		Test.Assert(TextOf(menu.Data("clock")) == clock, "the clock stands still");
		menu.D.InjectPadButton(.Start); // Start resumes
		menu.Frame(0.0);
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(!menu.Stack.IsPaused);
		menu.Frames(2.0);
		Test.Assert(TextOf(menu.Data("clock")) != clock, "and runs again");

		// Paused again, To menu: the title, alone.
		menu.D.InjectPadButton(.Start);
		menu.Frames(0.5);
		Test.Assert(menu.Stack.IsPaused);
		menu.Choose("to-menu");
		Test.Assert(menu.Stack.Count == 1);
		Test.Assert(menu.StageShown);
		Test.Assert(menu.Stack.Top.FindElement("play") != null, "the title");
		Test.Assert(menu.Vm.Problems.IsEmpty);
	}
}
