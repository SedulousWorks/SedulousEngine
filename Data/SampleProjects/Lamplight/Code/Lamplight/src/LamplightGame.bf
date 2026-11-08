using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// The run: the title and its levels, and in a level the clock, the HUD's target and loot, the
/// pause menu, and the results.
///
/// The title lists the levels with the best taken on each (from the save); a level opens once the
/// one before it is done. Picking one loads its scene afresh under the HUD. In a level the scene's
/// pieces report what happens, as the run's events: loot taken (LootTaken, its value), the target
/// taken (TargetTaken), a guard giving chase (ThiefSpotted), the thief caught (ThiefCaught: he is
/// back at his checkpoint, the level goes on), the alarm (AlarmRung), and the thief at the exit
/// (ThiefEscaped): with the target, the level is done; without it, the HUD says what he is there
/// for. Pause (Escape or Start) holds the level still under the pause menu.
///
/// The results: the time, the loot, how often seen and caught, and the ghost medal for a level done
/// without a guard ever giving chase. The save keeps, per level, that it is done, the best time,
/// the most loot and whether it was ghosted ("done.<level>", "best.<level>", "loot.<level>",
/// "ghost.<level>").
///
/// The screens are the GUI documents Tools/importui.py imports, pushed on the run GUI's screen
/// stack by id; a screen is loaded fresh each time it is pushed, so its buttons are wired again
/// each time, and the handlers go with its nodes.
[Game]
class LamplightGame : Game
{
	private const int32 cLevelCount = 5;
	/// How long the controls show as a level starts (s).
	private const float cControlsShown = 6.0f;
	/// How long the HUD's word shows (s).
	private const float cNoteShown = 2.5f;

	/// A level is being played (not the title, not the results).
	private bool mInLevel = false;
	private bool mPaused = false;
	private int32 mLevel = 0;
	private float mTime = 0.0f;
	private int32 mLoot = 0;
	private bool mHaveTarget = false;
	private int32 mSeen = 0;
	private int32 mCaught = 0;
	/// How long the HUD's word shows yet.
	private float mNote = 0.0f;
	/// How long the controls panel shows yet.
	private float mControlsShow = 0.0f;

	// ---- the run's services; null outside a run that has them ----
	private InputFacade Controls => (Instance != null) ? Instance.Get<InputFacade>() : null;
	private SaveFacade Save => (Instance != null) ? Instance.Get<SaveFacade>() : null;

	protected override void OnLaunch()
	{
		Listen<LootTaken>(new [=this] (evt) => OnLoot(evt.Value));
		Listen<TargetTaken>(new [=this] (evt) => OnTaken(evt.Value));
		Listen<ThiefSpotted>(new [=this] (evt) => { mSeen++; });
		Listen<AlarmRung>(new [=this] (evt) => Note("The alarm! Every guard is coming"));
		Listen<ThiefCaught>(new [=this] (evt) => OnCaught());
		Listen<ThiefEscaped>(new [=this] (evt) => OnEscaped());
		ShowTitle();
	}

	/// The game updates at time scale 0 too, so the Pause action is read here while paused.
	protected override void OnUpdate(float dt)
	{
		if (!mInLevel)
			return;
		let input = Controls;
		if ((input != null) && input.WasPressed("Pause"))
		{
			if (mPaused)
				Resume();
			else
				Pause();
			return;
		}
		if (mPaused)
			return;
		mTime += dt;
		if (mControlsShow > 0.0f)
		{
			mControlsShow -= dt;
			if (mControlsShow <= 0.0f)
				Hud.Fade(Find("hud-controls"), "opacity", "0", 0.6f, "ease");
		}
		SetText("hud-time", Clock(mTime, .. scope .()));
		if (mNote > 0.0f)
		{
			mNote -= dt;
			if (mNote <= 0.0f)
				Hud.Fade(Find("hud-note"), "opacity", "0", 0.5f, "ease");
		}
	}

	protected override void OnExit()
	{
		// The screens' handlers call into this game: they go with it.
		if (let stack = Hud.Screens(Run))
			stack.Clear();
	}

	// ---- the levels: their scenes, names and what each is for ----

	private static Guid LevelScene(int32 index)
	{
		switch (index)
		{
		case 0: return Assets.Gardens;
		case 1: return Assets.StableYard;
		case 2: return Assets.GroundFloor;
		case 3: return Assets.Cellars;
		default: return Assets.UpperFloor;
		}
	}

	/// The level's name in the save's keys.
	private static StringView LevelName(int32 index)
	{
		switch (index)
		{
		case 0: return "Gardens";
		case 1: return "StableYard";
		case 2: return "GroundFloor";
		case 3: return "Cellars";
		default: return "UpperFloor";
		}
	}

	private static StringView LevelTitle(int32 index)
	{
		switch (index)
		{
		case 0: return "The Gardens";
		case 1: return "The Stable Yard";
		case 2: return "The Ground Floor";
		case 3: return "The Cellars";
		default: return "The Upper Floor";
		}
	}

	private static StringView TargetName(int32 index)
	{
		switch (index)
		{
		case 0: return "the gardener's key";
		case 1: return "the stable ledger";
		case 2: return "the butler's keys";
		case 3: return "the steward's letter";
		default: return "the family jewels";
		}
	}

	/// A level opens once the one before it is done; the first is always open, one not built yet
	/// never.
	private bool Unlocked(int32 index)
	{
		if (LevelScene(index) == Guid())
			return false;
		return (index == 0) || (SavedInt("done", index - 1, 0) == 1);
	}

	/// The title's line under a level: its best, or why it cannot be played yet.
	private void BestLine(int32 index, String outLine)
	{
		if (LevelScene(index) == Guid())
		{
			outLine.Append("Not open yet");
			return;
		}
		if (!Unlocked(index))
		{
			outLine.AppendF("Locked: get away from {}", LevelTitle(index - 1));
			return;
		}
		let best = SavedFloat("best", index, -1.0f);
		if (best < 0.0f)
		{
			outLine.Append("Not yet done");
			return;
		}
		let time = Clock(best, .. scope .());
		outLine.AppendF("best {}   loot {}", time, SavedInt("loot", index, 0));
		if (SavedInt("ghost", index, 0) == 1)
			outLine.Append("   ghost");
	}

	// ---- the title ----

	private void ShowTitle()
	{
		mInLevel = false;
		mPaused = false;
		Instance.InstanceTimeScale = 0.0f; // whatever is behind the title holds still
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.TitleDoc);
		for (int32 i < cLevelCount)
		{
			let level = i;
			Wire(scope $"level-{i}", new [=this, =level] (e) =>
				{
					StartLevel(level);
					return true;
				});
		}
		Wire("quit-btn", new [=this] (e) =>
			{
				Instance.RequestExit(0);
				return true;
			});
		for (int32 i < cLevelCount)
		{
			if (let button = Find(scope $"level-{i}"))
				button.Enabled = Unlocked(i);
			SetText(scope $"level-{i}-best", BestLine(i, .. scope .()));
		}
	}

	// ---- a level ----

	private void StartLevel(int32 index)
	{
		mLevel = index;
		mTime = 0.0f;
		mLoot = 0;
		mHaveTarget = false;
		mSeen = 0;
		mCaught = 0;
		mNote = 0.0f;
		mPaused = false;
		mInLevel = true;
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.HudDoc);
		if (let prompt = Find("hud-prompt-panel"))
			prompt.Visible = false; // until a lamp or a door is in reach
		ShowHud();
		// The controls, keyboard and pad, for the first seconds of the level (the pause menu has
		// them too): faded in from the sheet's 0.
		Hud.Fade(Find("hud-controls"), "opacity", "1", 0.3f, "ease");
		mControlsShow = cControlsShown;
		Instance.InstanceTimeScale = 1.0f;
		Instance.LoadScene(LevelScene(index));
	}

	private void ShowHud()
	{
		if (mHaveTarget)
			SetText("hud-target", scope $"Got {TargetName(mLevel)}: get out");
		else
			SetText("hud-target", scope $"Find {TargetName(mLevel)}");
		SetText("hud-loot", scope $"Loot {mLoot}");
	}

	/// The HUD's word, shown at once and faded out after a while.
	private void Note(StringView text)
	{
		let label = Find("hud-note");
		if (label == null)
			return;
		Hud.SetText(label, text);
		Hud.Fade(label, "opacity", "1", 0.0f, "linear");
		mNote = cNoteShown;
	}

	// ---- what the level's pieces report ----

	private void OnLoot(int32 value)
	{
		mLoot += value;
		ShowHud();
	}

	private void OnTaken(int32 value)
	{
		mLoot += value;
		mHaveTarget = true;
		ShowHud();
		Note(scope $"Got {TargetName(mLevel)}");
	}

	private void OnCaught()
	{
		mCaught++;
		Note("Caught: back to the checkpoint");
	}

	private void OnEscaped()
	{
		if (!mInLevel)
			return;
		if (!mHaveTarget)
		{
			Note(scope $"Not without {TargetName(mLevel)}");
			return;
		}
		Finish();
	}

	// ---- the pause menu ----

	private void Pause()
	{
		mPaused = true;
		Instance.InstanceTimeScale = 0.0f;
		mControlsShow = 0.0f;
		Hud.Fade(Find("hud-controls"), "opacity", "0", 0.0f, "linear"); // the menu shows them itself
		Push(Assets.PauseDoc);
		Wire("resume-btn", new [=this] (e) =>
			{
				Resume();
				return true;
			});
		WireRestart();
		WireTitle();
	}

	private void Resume()
	{
		if (!mPaused)
			return;
		mPaused = false;
		if (let stack = Hud.Screens(Run))
			stack.Pop();
		Instance.InstanceTimeScale = 1.0f;
	}

	/// The top screen's restart-btn (the pause menu's) or again-btn (the results') plays the level
	/// again from its start.
	private void WireRestart(StringView id = "restart-btn")
	{
		Wire(id, new [=this] (e) =>
			{
				StartLevel(mLevel);
				return true;
			});
	}

	/// The top screen's title-btn goes back to the title.
	private void WireTitle()
	{
		Wire("title-btn", new [=this] (e) =>
			{
				ShowTitle();
				return true;
			});
	}

	// ---- the results ----

	private void Finish()
	{
		mInLevel = false;
		Instance.InstanceTimeScale = 0.0f;
		let ghost = mSeen == 0;
		if (let save = Save)
		{
			let level = LevelName(mLevel);
			let previous = save.GetFloat(scope $"best.{level}", -1.0f);
			save.SetInt(scope $"done.{level}", 1);
			if ((previous < 0.0f) || (mTime < previous))
				save.SetFloat(scope $"best.{level}", mTime);
			if (mLoot > save.GetInt(scope $"loot.{level}", 0))
				save.SetInt(scope $"loot.{level}", mLoot);
			if (ghost)
				save.SetInt(scope $"ghost.{level}", 1);
			save.Flush();
		}

		Push(Assets.ResultsDoc);
		let last = mLevel + 1 >= cLevelCount;
		StringView title = ghost ? "Away like a ghost" : ((mCaught == 0) ? "Away clean" : "Away");
		if (last)
			SetText("res-title", scope $"The jewels are yours. {title}");
		else
			SetText("res-title", title);
		let time = Clock(mTime, .. scope .());
		SetText("res-time", scope $"Time   {time}");
		SetText("res-loot", scope $"Loot   {mLoot}");
		StringView times = (mSeen == 1) ? "time" : "times";
		SetText("res-seen", scope $"Seen {mSeen} {times}, caught {mCaught}");
		if (last)
			SetText("res-medal", ghost ? "The Lamplight heist is done. Ghost: never seen" : "The Lamplight heist is done");
		else
			SetText("res-medal", ghost ? "Ghost: never seen" : "");
		let best = Clock(SavedFloat("best", mLevel, mTime), .. scope .());
		let mostLoot = SavedInt("loot", mLevel, mLoot);
		SetText("res-best", scope $"Best on {LevelTitle(mLevel)}: {best}, loot {mostLoot}");
		let canGoOn = (mLevel + 1 < cLevelCount) && Unlocked(mLevel + 1);
		if (let button = Find("next-btn"))
			button.Enabled = canGoOn;
		Wire("next-btn", new [=this] (e) =>
			{
				StartLevel(mLevel + 1);
				return true;
			});
		WireRestart("again-btn");
		WireTitle();
	}

	/// `seconds` as minutes and seconds, 1:05.
	private static void Clock(float seconds, String outText)
	{
		let whole = (int32)seconds;
		outText.AppendF("{}:{}{}", whole / 60, ((whole % 60) < 10) ? "0" : "", whole % 60);
	}

	// ---- the save ----

	/// The save's `key`.<level> whole number, `fallback` without one (or without a save).
	private int32 SavedInt(StringView key, int32 level, int32 fallback)
	{
		let save = Save;
		return (save != null) ? save.GetInt(scope $"{key}.{LevelName(level)}", fallback) : fallback;
	}

	private float SavedFloat(StringView key, int32 level, float fallback)
	{
		let save = Save;
		return (save != null) ? save.GetFloat(scope $"{key}.{LevelName(level)}", fallback) : fallback;
	}

	// ---- the screens ----

	/// Pushes the GUI document `document` (its asset id) on the screen stack.
	private void Push(StringView document)
	{
		if (let stack = Hud.Screens(Run))
			stack.PushDocument(document);
	}

	/// The element `id`, the top screen first.
	private Node Find(StringView id) => Hud.FindOnTop(Run, id);

	private void SetText(StringView id, StringView text) => Hud.SetText(Find(id), text);

	/// Calls `handler` on a click of the element `id`. The element's own to delete: it goes with
	/// the screen. Deleted at once when there is no such element.
	private void Wire(StringView id, delegate bool(Sedulous.GUI.Event e) handler)
	{
		let node = Find(id);
		if (node == null)
		{
			delete handler;
			return;
		}
		node.On("click", handler);
	}
}
