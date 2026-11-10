using System;
using System.Collections;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// The game menu's behaviour, over the gamekit (Data/Samples/UI/showcase: menu.xml the frame,
/// screens/ a document per screen, menu.css their looks, entrances and exits). It pushes and pops
/// the screens on the gamekit's stack, wires each screen's buttons as it is pushed (fresh each
/// time), runs the loading bar and, once loading is done, a stand-in game under the HUD: the score
/// counting up, health draining and healing, the run's clock, and a pause screen on Escape, a pad's
/// East or Start. Back (Escape, East) is the stack's: it pops the top screen, and the title keeps
/// it. The host calls Start once the menu is built, Enter each time it shows it, and Update each
/// frame while it is shown.
///
/// The handlers it gives the screens capture it: the host deletes it after the GUI's root.
class GameMenu
{
	public const String cScreens = "Samples/UI/showcase/screens/";

	/// The actions on the Controls screen, each bound to `game.<action>` in the `game` key context.
	private static StringView[4] sActions = .("jump", "dash", "interact", "map");

	/// Borrowed: the host's, over the sandbox's root.
	private GuiFacade mGui;
	/// The menu's frame (the tree's; the host holds it while the menu lives).
	private Node mMenu;
	/// The game's screens and the title over the menu's pages: the frame's, found once.
	private ScreenStack mStack = null;
	private Node mStage = null;
	/// The HUD while a game runs; null otherwise.
	private Element<Screen> mHud = null ~ delete _;
	/// The Controls screen while it is up (its buttons light while listening).
	private Element<Screen> mControls = null ~ delete _;

	/// Each action's key, as a binding names it ("space", "leftshift").
	private List<String> mKeys = new .() ~ DeleteContainerAndItems!(_);
	/// The action waiting for its key (-1: none).
	private int mListening = -1;

	private bool mLoading = false;
	private double mLoadTime = 0.0;
	/// Seconds from "Ready" to the HUD (-1: not waiting).
	private double mUntilGame = -1.0;
	private double mGameTime = 0.0;
	private double mNextPoint = 0.0;
	private int mScore = 0;
	/// Which of the score's two pop classes goes on next, so each point replays it.
	private bool mPopTurn = false;

	public this(GuiFacade gui, Node menu)
	{
		mGui = gui;
		mMenu = menu;
		StringView[4] keys = .("space", "leftshift", "e", "m");
		for (let key in keys)
			mKeys.Add(new String(key));
	}

	/// Finds the frame's parts and wires what lasts: Start pauses in the game, handled by the menu
	/// itself, since it is a modal layer of the sandbox's root and a command from inside it stops
	/// at its edge. Then the title, as the menu opens.
	public void Start()
	{
		mStack = mMenu.FindElement("screens") as ScreenStack;
		mStage = mMenu.FindElement("stage");
		if ((mStack == null) || (mStage == null))
		{
			Console.Error.WriteLine("GUISandbox: the game menu has no screens or no stage");
			return;
		}
		if (let showcase = mMenu.FindElement("showcase"))
			showcase.OnCommand("pause", new (command) => { command.Propagate = Pause(); });
		mGui.BindKey("pad-start", "pause", "");
		Enter();
	}

	/// The menu as it opens: the title screen alone, nothing left over from the last visit.
	public void Enter()
	{
		if (mStack == null)
			return;
		mLoading = false;
		mUntilGame = -1.0;
		DeleteAndNullify!(mHud);
		if (let showcase = mMenu.FindElement("showcase") as UIWidget)
			showcase.RemoveClass("closing");
		mStack.Clear();
		ShowTitle();
	}

	/// The loading bar fills over two and a half seconds, then the game runs while it is not
	/// paused.
	public void Update(double deltaTime)
	{
		if (mStack == null)
			return;
		if (mUntilGame >= 0.0)
		{
			mUntilGame -= deltaTime;
			if (mUntilGame < 0.0)
				StartGame();
		}
		if ((Hud != null) && !mStack.IsPaused)
			RunGame(deltaTime);
		if (mLoading)
		{
			mLoadTime += deltaTime;
			double progress = mLoadTime / 2.5;
			if (progress >= 1.0)
			{
				progress = 1.0;
				mLoading = false;
				mGui.SetText("status", mGui.Translate("loading.ready"));
				mUntilGame = 0.6; // a moment on "Ready", then the game
			}
			mGui.SetNumber("progress", progress);
		}
	}

	/// What a handler on a screen's widget `id` hears of `eventName`; the handler deleted unused
	/// when the screen has no such widget.
	public static void Listen(Node under, StringView id, StringView eventName, delegate bool(Event e) handler)
	{
		let node = (under != null) ? under.FindElement(id) : null;
		if (node != null)
			node.On(eventName, handler);
		else
			delete handler;
	}

	private Screen Hud => (mHud != null) ? mHud.Get() : null;

	/// The screen `name` (screens/<name>.xml), pushed fresh; null when it does not load.
	private Screen Push(StringView name) => mStack.PushDocument(scope $"{cScreens}{name}.xml");

	/// Back on a screen's own button: the top screen goes.
	private void ListenPop(Node screen, StringView id)
	{
		Listen(screen, id, "click", new (e) =>
			{
				mStack.Pop();
				return false;
			});
	}

	// === The menu ===

	private void ShowTitle()
	{
		mStage.Displayed = true;
		let title = Push("title");
		Listen(title, "play", "click", new (e) => { Play(); return false; });
		Listen(title, "settings-btn", "click", new (e) => { ShowSettings(); return false; });
		Listen(title, "controls-btn", "click", new (e) => { ShowControls(); return false; });
		Listen(title, "quit", "click", new (e) => { AskQuit(); return false; });
	}

	private void ShowSettings()
	{
		let page = Push("settings");
		if (page == null)
			return;
		ListenPop(page, "settings-back");
		// Labels that follow the data through functions of it: no handler updates them.
		if (let volume = page.FindElement("volume-text"))
			volume.BindText("text", new (outText) => { outText.AppendF("{}%", (int)(mGui.GetNumber("volume") * 100.0 + 0.5)); });
		if (let music = page.FindElement("music-text"))
			music.BindText("text", new (outText) => { outText.Append(mGui.Translate(mGui.GetBool("music") ? "settings.on" : "settings.off")); });
	}

	// === Controls ===
	// Each action's key, bound to its command in the game's key context. Choosing one listens for
	// the next key or pad button (CaptureKey, before the keymap and navigation see it); a key
	// another action had swaps over to it; Escape cancels.

	private void ShowControls()
	{
		let page = Push("controls");
		DeleteAndNullify!(mControls);
		if (page == null)
			return;
		mControls = new Element<Screen>(page);
		for (int i < sActions.Count)
		{
			let action = i;
			Listen(page, scope $"bind-{sActions[i]}", "click", new (e) =>
				{
					ListenForKey(action);
					return false;
				});
		}
		ListenPop(page, "controls-back");
		mGui.SetText("controls-hint", mGui.Translate("controls.choose"));
		ShowKeys();
	}

	private void ShowKeys()
	{
		for (int i < sActions.Count)
		{
			mGui.SetText(scope $"key-{sActions[i]}", mGui.KeyText(mKeys[i]));
			mGui.BindKey(mKeys[i], scope $"game.{sActions[i]}", "game");
		}
	}

	/// The button of action `action` on the Controls screen, while it is up.
	private UIWidget BindButton(int action)
	{
		let controls = (mControls != null) ? mControls.Get() : null;
		return (controls != null) ? (controls.FindElement(scope $"bind-{sActions[action]}") as UIWidget) : null;
	}

	private void ListenForKey(int action)
	{
		if (mListening >= 0)
			return;
		mListening = action;
		if (let button = BindButton(action))
			button.AddClass("listening");
		mGui.SetText(scope $"key-{sActions[action]}", mGui.Translate("controls.press"));
		let keep = scope String(mGui.Translate("controls.keep"));
		keep.Append(mGui.KeyText(mKeys[action]));
		mGui.SetText("controls-hint", keep);
		mGui.CaptureKey(new (pressed) => { KeyCaptured(pressed); });
	}

	/// The key pressed for the action listening (empty: Escape cancelled).
	private void KeyCaptured(StringView pressed)
	{
		let action = mListening;
		mListening = -1;
		if (action < 0)
			return;
		if (let button = BindButton(action))
			button.RemoveClass("listening");
		mGui.SetText("controls-hint", mGui.Translate("controls.choose"));
		if (!pressed.IsEmpty)
		{
			for (int i < sActions.Count)
			{
				if ((i != action) && (mKeys[i] == pressed))
				{
					mKeys[i].Set(mKeys[action]); // taken: the two swap
					let swapped = scope String(mGui.Translate("controls.swapped"));
					swapped.Append(mGui.Translate(scope $"controls.{sActions[i]}"));
					mGui.SetText("controls-hint", swapped);
				}
			}
			mGui.BindKey(mKeys[action], "", "game"); // the old key unbound there
			mKeys[action].Set(pressed);
		}
		ShowKeys();
	}

	// === Loading ===

	private void Play()
	{
		let loading = Push("loading");
		if (loading == null)
			return;
		ListenPop(loading, "loading-back");
		// Back, or the game starting.
		loading.On("screenleave", new (e) =>
			{
				mLoading = false;
				mUntilGame = -1.0;
				mStage.Displayed = (Hud == null); // back on the menu, unless the game took over
				return false;
			});
		mStage.Displayed = false; // the loading screen replaces the menu
		mGui.SetText("status", mGui.Translate("loading.loading"));
		mGui.SetNumber("progress", 0.0);
		mLoadTime = 0.0;
		mLoading = true;
	}

	// === Quit ===
	// The question opens over the menu, which stays where it is behind the dimmed glass; Stay and
	// Back pop it, the focus back on Quit.

	private void AskQuit()
	{
		let question = Push("quit");
		Listen(question, "confirm-yes", "click", new (e) =>
			{
				// The whole menu fades out; once `quit` is set and the fade has run, the host takes
				// the player back to where they came from (the sandbox).
				if (let showcase = mMenu.FindElement("showcase") as UIWidget)
					showcase.AddClass("closing");
				mGui.SetBool("quit", true);
				return false;
			});
		ListenPop(question, "confirm-no");
	}

	// === The game ===

	private void StartGame()
	{
		mUntilGame = -1.0;
		mScore = 0;
		mGameTime = 0.0;
		mNextPoint = 1.2;
		mGui.SetNumber("score", 0.0);
		mGui.SetNumber("health", 1.0);
		mGui.SetText("clock", "0:00");
		DeleteAndNullify!(mHud);
		mStack.Clear(); // the menu and the loading screen leave as the HUD comes in
		let hud = Push("hud");
		mStage.Displayed = false;
		if (hud == null)
			return;
		mHud = new Element<Screen>(hud);
		hud.OnCommand(cBackCommand, new (command) => { command.Propagate = Pause(); }); // in the game, Back pauses
	}

	/// Pause (Back in the game, and Start): opens the pause screen over the HUD, or closes it.
	/// True when there is no game: the command is someone else's.
	private bool Pause()
	{
		if (Hud == null)
			return true;
		if (mStack.IsPaused)
		{
			mStack.Pop();
			return false;
		}
		let pause = Push("pause");
		ListenPop(pause, "resume");
		Listen(pause, "to-menu", "click", new (e) => { Enter(); return false; });
		return false;
	}

	/// A step of the stand-in game: a point now and then (the number counts up and pops), health
	/// draining and, low, warning, then healed by a point.
	private void RunGame(double deltaTime)
	{
		let hud = Hud;
		if (hud == null)
			return;
		mGameTime += deltaTime;
		let seconds = (int)mGameTime;
		mGui.SetText("clock", scope String()..AppendF("{}:{:D2}", seconds / 60, seconds % 60));
		double health = mGui.GetNumber("health") - deltaTime * 0.06;
		mNextPoint -= deltaTime;
		if (mNextPoint <= 0.0)
		{
			mNextPoint = 1.4;
			mScore += 10;
			// The data counts up in whole numbers: no widget drives it.
			if (let tween = mGui.TweenData("score", (double)mScore, 0.35f, "ease-out"))
			{
				tween.Whole(true);
				tween.ReleaseRef();
			}
			if (let number = hud.FindElement("hud-score") as UIWidget)
			{
				number.RemoveClass(mPopTurn ? "pop-a" : "pop-b");
				number.AddClass(mPopTurn ? "pop-b" : "pop-a");
			}
			mPopTurn = !mPopTurn;
			if (health < 0.3)
				health = 1.0; // a light gathered heals
		}
		if (health < 0.0)
			health = 0.0;
		mGui.SetNumber("health", health);
		if (let bar = hud.FindElement("hud-health") as UIWidget)
		{
			if (health < 0.3)
				bar.AddClass("hp-low");
			else
				bar.RemoveClass("hp-low");
		}
	}
}
