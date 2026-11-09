using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Gamekit.Tests;

/// What the prompt tests build bindings and sets with.
static class PromptFixtures
{
	public static Sedulous.Input.Binding Key(Sedulous.Shell.KeyCode key)
	{
		Sedulous.Input.Binding b = .();
		b.Source = .Key;
		b.Code = (uint32)key;
		return b;
	}

	public static Sedulous.Input.Binding Pad(Sedulous.Shell.GamepadButton button)
	{
		Sedulous.Input.Binding b = .();
		b.Source = .GamepadButton;
		b.Code = (uint32)button;
		return b;
	}

	/// A set `name` of `priority` with one action `action` bound to `bindings`; the caller owns it
	/// (an InputMap it is added to does).
	public static Sedulous.Input.ActionSet Set(StringView name, int32 priority, StringView action, Span<Sedulous.Input.Binding> bindings)
	{
		let set = new Sedulous.Input.ActionSet();
		set.Name.Set(name);
		set.Priority = priority;
		let a = new Sedulous.Input.InputAction();
		a.Name.Set(action);
		for (let binding in bindings)
			a.Bindings.Add(binding);
		set.Actions.Add(a);
		return set;
	}

	public static Sedulous.Input.ActionSet Set(StringView name, int32 priority, StringView action, Sedulous.Input.Binding binding)
	{
		Sedulous.Input.Binding[1] all = .(binding);
		return Set(name, priority, action, Span<Sedulous.Input.Binding>(&all[0], 1));
	}

	public static Sedulous.Input.ActionSet Set(StringView name, int32 priority, StringView action, Sedulous.Input.Binding first,
		Sedulous.Input.Binding second)
	{
		Sedulous.Input.Binding[2] all = .(first, second);
		return Set(name, priority, action, Span<Sedulous.Input.Binding>(&all[0], 2));
	}
}

/// A GUI with a "jump" prompt, reading a runtime whose Gameplay set binds jump to Space and South.
/// The root, the prompt, the runtime and the prompts go with it.
class PromptBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public Sedulous.GUI.Prompt Prompt = new .() ~ _.ReleaseRef();
	public Sedulous.Input.ActionRuntime Runtime = new .() ~ delete _;
	public InputPrompts Prompts = new .() ~ delete _;

	public this()
	{
		Root = GamekitFixtures.NewScene();
		let map = scope Sedulous.Input.InputMap();
		map.Sets.Add(PromptFixtures.Set("Gameplay", 0, "jump", PromptFixtures.Key(.Space), PromptFixtures.Pad(.South)));
		Runtime.SetMap(map);
		Prompts.SetRuntime(Runtime);
		Prompts.Install(Root.Context);
		Prompt.ActionName = "jump";
		Root.AddChild(Prompt);
		Frame();
	}

	public void Frame()
	{
		Root.Context.Update(TimeSpan(0));
	}

	public void Kind(Sedulous.GUI.InputKind kind)
	{
		Root.EventDispatcher.InputKind = kind;
		Frame();
	}
}

/// Button prompts: a prompt shows the binding of its action for the input kind in use, from the
/// game's runtime after its rebinding and in its enabled sets by priority, labelled by
/// Sedulous.Input's names, with `binding` and `kind` for a sheet's glyphs, and follows the input
/// kind and the bindings as they change.
class PromptTests
{
	[Test]
	public static void TheBindingForTheInputKindInUseLabelledWithItsBindingAndKindForTheSheet()
	{
		let bed = scope PromptBed();
		Test.Assert(bed.Prompt.Text == "Space"); // the GUI starts on the keys
		Test.Assert(bed.Prompt.BindingName == "space");
		Test.Assert(bed.Prompt.BindingKind == "keyboard");
		bed.Kind(.Pad);
		Test.Assert(bed.Prompt.Text == "Pad South");
		Test.Assert(bed.Prompt.BindingName == "pad-south");
		Test.Assert(bed.Prompt.BindingKind == "pad");
		bed.Kind(.Pointer); // a mouse user reads the keys and buttons
		Test.Assert(bed.Prompt.BindingName == "space");
	}

	[Test]
	public static void ASheetDrawsTheGlyphByTheBindingItShows()
	{
		let bed = scope PromptBed();
		let styles = scope StyleManager();
		GamekitFixtures.UseSheet(styles,
			"prompt { opacity: 1; } prompt[binding=\"pad-south\"] { opacity: 0.5; } prompt[kind=\"keyboard\"] { opacity: 0.75; }");
		styles.ApplyTree(bed.Root);
		Test.Assert(GamekitFixtures.Near(bed.Prompt.Alpha, 0.75f));
		bed.Kind(.Pad);
		styles.ApplyTree(bed.Root);
		Test.Assert(GamekitFixtures.Near(bed.Prompt.Alpha, 0.5f));
	}

	[Test]
	public static void ARebindingTheHostAnnouncesShowsWithoutABindingOfTheKindAnyWithoutOneNothing()
	{
		let bed = scope PromptBed();
		bed.Kind(.Pad);
		let rebound = scope Sedulous.Input.InputMap();
		rebound.Sets.Add(PromptFixtures.Set("Gameplay", 0, "jump", PromptFixtures.Key(.Space), PromptFixtures.Pad(.North)));
		bed.Runtime.SetMap(rebound);
		bed.Prompts.NotifyBindingsChanged();
		bed.Frame();
		Test.Assert(bed.Prompt.BindingName == "pad-north");

		let keysOnly = scope Sedulous.Input.InputMap();
		keysOnly.Sets.Add(PromptFixtures.Set("Gameplay", 0, "jump", PromptFixtures.Key(.E)));
		bed.Runtime.SetMap(keysOnly);
		bed.Prompts.NotifyBindingsChanged();
		bed.Frame();
		Test.Assert(bed.Prompt.BindingName == "e"); // a pad in hand, but the action has only a key

		bed.Prompt.ActionName = "fly";
		bed.Frame();
		Test.Assert(bed.Prompt.Text.IsEmpty);
		Test.Assert(bed.Prompt.BindingName.IsEmpty);
	}

	[Test]
	public static void TheHighestPriorityEnabledSetThatHasTheActionOrTheSetNamed()
	{
		let bed = scope PromptBed();
		let map = scope Sedulous.Input.InputMap();
		map.Sets.Add(PromptFixtures.Set("Gameplay", 0, "confirm", PromptFixtures.Key(.E)));
		map.Sets.Add(PromptFixtures.Set("Menu", 10, "confirm", PromptFixtures.Key(.Return)));
		bed.Runtime.SetMap(map);
		bed.Prompts.NotifyBindingsChanged();
		bed.Prompt.ActionName = "confirm";
		bed.Frame();
		Test.Assert(bed.Prompt.BindingName == "return");
		bed.Runtime.DisableSet("Menu");
		bed.Prompts.NotifyBindingsChanged();
		bed.Frame();
		Test.Assert(bed.Prompt.BindingName == "e");
		bed.Prompt.Set = "Menu"; // named: read there, enabled or not
		bed.Frame();
		Test.Assert(bed.Prompt.BindingName == "return");
	}

	[Test]
	public static void NoneUntilTheHostInstallsItsPromptsFromMarkupByAction()
	{
		let root = GamekitFixtures.NewScene();
		defer root.ReleaseRef();
		RegisterGuiElements();
		RegisterGamekitElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		let made = loader.LoadFromString("<Prompt action=\"jump\"/>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let prompt = made as Prompt;
		Test.Assert(prompt != null);
		Test.Assert(prompt.ActionName == "jump");
		root.AddChild(prompt);
		root.Context.Update(TimeSpan(0));
		Test.Assert(prompt.BindingName.IsEmpty);

		let runtime = scope Sedulous.Input.ActionRuntime();
		let map = scope Sedulous.Input.InputMap();
		map.Sets.Add(PromptFixtures.Set("Gameplay", 0, "jump", PromptFixtures.Key(.Space)));
		runtime.SetMap(map);
		let prompts = scope InputPrompts();
		prompts.SetRuntime(runtime);
		prompts.Install(root.Context); // installed later: the prompt follows
		root.Context.Update(TimeSpan(0));
		Test.Assert(prompt.BindingName == "space");
		InputPrompts.Uninstall(root.Context);
		root.Context.Update(TimeSpan(0));
		Test.Assert(prompt.BindingName.IsEmpty);
	}

	// === Behaviour no Raptor test covers ===

	[Test]
	public static void ABindingsTokenIsItsLabelLowerCaseDashedAndItsKindFollowsItsSource()
	{
		Sedulous.Input.Binding mouse = .();
		mouse.Source = .MouseButton;
		mouse.Code = (uint32)Sedulous.Shell.MouseButton.Left;
		let token = scope String();
		BindingToken(mouse, token);
		Test.Assert(token == "mouse-left");
		Test.Assert(Sedulous.Input.ShownBinding.KindOf(mouse) == .Keyboard);

		Sedulous.Input.Binding touch = .();
		touch.Source = .TouchButton;
		Test.Assert(Sedulous.Input.ShownBinding.KindOf(touch) == .Pointer);
		Sedulous.Input.Binding stick = .();
		stick.Source = .GamepadStick;
		Test.Assert(Sedulous.Input.ShownBinding.KindOf(stick) == .Pad);
		token.Clear();
		BindingToken(stick, token);
		Test.Assert(token == "left-stick");
	}

	[Test]
	public static void FindHasNothingWithoutARuntimeAnActionOrABinding()
	{
		let prompts = scope InputPrompts();
		Test.Assert(!prompts.Find("jump", "", .Keyboard).HasValue); // no runtime
		let runtime = scope Sedulous.Input.ActionRuntime();
		let map = scope Sedulous.Input.InputMap();
		map.Sets.Add(PromptFixtures.Set("Gameplay", 0, "idle", Span<Sedulous.Input.Binding>()));
		map.Sets.Add(PromptFixtures.Set("Gameplay2", 0, "jump", PromptFixtures.Pad(.West)));
		runtime.SetMap(map);
		prompts.SetRuntime(runtime);
		Test.Assert(!prompts.Find("", "", .Keyboard).HasValue); // no action
		Test.Assert(!prompts.Find("idle", "", .Keyboard).HasValue); // an action with no binding
		Test.Assert(!prompts.Find("jump", "Elsewhere", .Pad).HasValue); // not in the set named
		let found = prompts.Find("jump", "", .Keyboard); // no key: its first, the pad's
		Test.Assert(found.HasValue);
		Test.Assert(found.Value.Source == .GamepadButton);
	}

	[Test]
	public static void AnEqualPrioritySetLaterInTheMapDoesNotWin()
	{
		let prompts = scope InputPrompts();
		let runtime = scope Sedulous.Input.ActionRuntime();
		let map = scope Sedulous.Input.InputMap();
		map.Sets.Add(PromptFixtures.Set("First", 5, "jump", PromptFixtures.Key(.A)));
		map.Sets.Add(PromptFixtures.Set("Second", 5, "jump", PromptFixtures.Key(.B)));
		runtime.SetMap(map);
		prompts.SetRuntime(runtime);
		let found = prompts.Find("jump", "", .Keyboard);
		Test.Assert(found.HasValue);
		Test.Assert(found.Value.Code == (uint32)Sedulous.Shell.KeyCode.A);
	}
}
