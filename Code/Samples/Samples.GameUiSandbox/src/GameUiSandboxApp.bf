using System;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.GUI;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Input;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;

namespace Samples.GameUiSandbox;

/// A game's screens on the engine GUI (Engine.GUI, GUI.Gamekit): two screens built from markup and
/// pushed on the GUI's screen stack.
///   - a HUD: a menu of buttons (the arrows or the pad move through it, Enter or South presses), a
///     health bar that drains and heals with a tween, a score that rolls up through a data tween (a
///     whole number, so it rolls in whole steps), a prompt naming the key or button bound to the
///     "Deliver" action, and toasts on "Show toast";
///   - a pause menu pushed over it, blocking it, which back (Escape) pops.
/// The old game kit's MenuList, Bar and Ticker have no widget here (Raptor's gui-lab-evolution-3
/// spec, section K): markup, navigation and commands make the menu, a progress bar and a tween the
/// bar, a data tween the ticker. Escape on the HUD exits.
class GameUiSandboxApp : DefaultApplication
{
	/// The HUD: the title, the prompt, the score and the health (bound to the GUI's data), the menu.
	private const String cHudMarkup = """
		<Panel flex-direction="column" gap="16" padding="40 48" flex-grow="1" background-color="rgb(18, 20, 26)">
		  <Label text="Game UI Sandbox" font-size="28"/>
		  <Panel flex-direction="row" align-items="center" gap="8">
		    <Prompt action="Deliver"/><Label text="Deliver"/>
		  </Panel>
		  <Panel flex-direction="row" align-items="center" gap="8">
		    <Label text="Score" width="64"/><Label text="{{score}}" font-size="20"/>
		  </Panel>
		  <Panel flex-direction="row" align-items="center" gap="8">
		    <Label text="Health" width="64"/><ProgressBar id="health" width="220" value="{{health}}"/>
		  </Panel>
		  <Panel flex-direction="column" gap="6" width="240">
		    <Button id="menu-score" text="Score +250"/>
		    <Button id="menu-damage" text="Take damage"/>
		    <Button id="menu-heal" text="Heal"/>
		    <Button id="menu-toast" text="Show toast"/>
		    <Button id="menu-pause" text="Pause menu"/>
		    <Button id="menu-quit" text="Quit"/>
		  </Panel>
		</Panel>
		""";

	/// The pause menu: a scrim over the HUD, a card in its middle.
	private const String cPauseMarkup = """
		<Panel background-color="rgba(0, 0, 0, 0.55)" justify-content="center" align-items="center">
		  <Panel flex-direction="column" align-items="center" gap="16" padding="28 40"
		         background-color="rgba(31, 33, 43, 0.98)" border-radius="8">
		    <Label text="Paused" font-size="26"/>
		    <Button id="pause-resume" text="Resume" width="200"/>
		    <Button id="pause-quit" text="Quit" width="200"/>
		  </Panel>
		</Panel>
		""";

	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	/// BORROWED: the context's.
	private GuiSubsystem mGui = null;
	/// A reference of the app's own (the screen root holds another).
	private ToastHost mToasts = null ~ { if (_ != null) _.ReleaseRef(); };
	private GuiDocument mHudDocument = null ~ delete _;
	private GuiDocument mPauseDocument = null ~ delete _;
	private InputMap mMap = new .() ~ delete _;
	private int64 mScore = 0;
	private float mHealth = 1.0f;
	private bool mQuit = false;

	public override void OnLaunch(IApplicationHost host)
	{
		base.OnLaunch(host);

		// A minimal scene and camera so a frame renders; the HUD covers it.
		mScene = PrimaryScenes.CreateScene("gameui");
		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera);
		mScene.Start();

		mGui = host.Context.GetSubsystem<GuiSubsystem>();
		if ((mGui == null) || (mGui.ScreenRoot == null) || (mGui.Screens == null))
			return;

		// The game's bindings, which the prompt names (the engine's GUI reads the game's runtime).
		BuildInputMap();
		Instance.InputRuntime.SetMap(mMap);

		// The values the HUD shows: a whole score (so its tween rolls in whole steps), the health.
		let data = mGui.GuiContext.Data;
		data.Set("score", System.Variant.Create((int64)0));
		data.Set("health", System.Variant.Create(1.0));

		// Toasts over the screens.
		mToasts = new ToastHost();
		mGui.ScreenRoot.AddChild(mToasts);

		PushHud();
		Console.WriteLine("GameUiSandbox: the arrows (or the pad) move through the menu, Enter or South presses. Escape backs out of the pause menu, else exits.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);
		if (mQuit)
		{
			host.RequestExit(0);
			return;
		}
		let input = (host.Shell != null) ? host.Shell.Input : null;
		if ((input == null) || (mGui == null) || (mGui.Screens == null))
			return;
		// Escape backs out of the pause menu first (the screen stack's back), else exits.
		if (input.Keyboard.IsKeyPressed(.Escape) && (mGui.Screens.Count <= 1))
			host.RequestExit(0);
		// The "Deliver" action the prompt names: E fires it (a toast, for the demo).
		if (input.Keyboard.IsKeyPressed(.E))
			Toast("Delivered!", .Info, 1.5f);
	}

	/// The action the prompt advertises, which is also what the prompt reads its key from: the
	/// binding is stated ONCE and the label follows it.
	private void BuildInputMap()
	{
		let set = new ActionSet();
		set.Name.Set("Gameplay");

		let deliver = new InputAction();
		deliver.Name.Set("Deliver");

		Binding key = .();
		key.Source = .Key;
		key.Code = (uint32)Sedulous.Shell.KeyCode.E;
		deliver.Bindings.Add(key);

		Binding pad = .();
		pad.Source = .GamepadButton;
		pad.Code = (uint32)GamepadButton.South;
		deliver.Bindings.Add(pad);

		set.Actions.Add(deliver);
		mMap.Sets.Add(set);
	}

	/// A screen built from `markup` (into `document`, the app's) and pushed: the pushed screen, or
	/// null.
	private Sedulous.GUI.Screen PushMarkup(StringView markup, ref GuiDocument document)
	{
		delete document;
		document = new GuiDocument();
		document.Markup.Set(markup);
		let tree = mGui.BuildDocument(document);
		if (tree == null)
			return null;
		defer tree.ReleaseRef(); // the stack takes its own
		return mGui.Screens.Push(tree);
	}

	/// The button `id` on `screen` runs `click`. OWNERSHIP of `click` transfers.
	private static void OnClick(Node screen, StringView id, delegate void() click)
	{
		if (let button = screen.FindElement(id) as Sedulous.GUI.Button)
			button.SetOnClick(click);
		else
			delete click;
	}

	private void PushHud()
	{
		let hud = PushMarkup(cHudMarkup, ref mHudDocument);
		if (hud == null)
			return;
		hud.Covers = true; // over the scene, whole
		hud.Back = "none"; // back on the HUD is the host's (Escape exits)
		OnClick(hud, "menu-score", new () =>
			{
				mScore += 250;
				mGui.GuiContext.AnimateData("score", (double)mScore, 0.6f).ReleaseRef();
			});
		OnClick(hud, "menu-damage", new () =>
			{
				mHealth = Math.Max(0.0f, mHealth - 0.2f);
				mGui.GuiContext.AnimateData("health", mHealth, 0.35f).ReleaseRef();
			});
		OnClick(hud, "menu-heal", new () =>
			{
				mHealth = Math.Min(1.0f, mHealth + 0.3f);
				mGui.GuiContext.AnimateData("health", mHealth, 0.35f).ReleaseRef();
			});
		OnClick(hud, "menu-toast", new () => { Toast("Objective complete!", .Success, 3.0f); });
		OnClick(hud, "menu-pause", new () => { PushPause(); });
		OnClick(hud, "menu-quit", new () => { mQuit = true; });
	}

	private void PushPause()
	{
		let pause = PushMarkup(cPauseMarkup, ref mPauseDocument);
		if (pause == null)
			return;
		pause.Blocks = true; // the HUD under it shows, and takes no input
		OnClick(pause, "pause-resume", new () => { mGui.Screens.Pop(); });
		OnClick(pause, "pause-quit", new () => { mQuit = true; });
	}

	private void Toast(StringView message, ToastSeverity severity, float seconds)
	{
		if (mToasts == null)
			return;
		let request = scope ToastRequest();
		request.Title = message;
		request.Severity = severity;
		request.Duration = seconds;
		mToasts.Post(request);
	}
}
