using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.GUI;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// The run: the screens, the blocks, the score and the lives.
///
/// The block's code (Block) owns a block's rules and tells the game how it ended (QuotaMet with the
/// whole seconds left, or LevelFailed with the reason); every delivery (Delivered, from a
/// Subscriber) scores here. All of them are the run's events, heard at the end of the frame.
///
/// A run is the blocks in order. A cleared block banks its score (deliveries plus a time bonus); a
/// failed one spends a life and replays from the banked score; no lives left, or the last block
/// cleared, is the Game over screen. Pause (the Pause action) freezes the block under a menu;
/// Settings, from the title or the pause menu, sets the audio buses' volumes, which the player saves
/// when it exits, and goes back to whichever opened it.
///
/// A cleared block is celebrated before its screen: the clock stops, a banner drops in, the world
/// eases into slow motion under a fanfare while the music fades, and only then does the Block
/// cleared screen come up and the block freeze. A failed block cuts straight to its screen.
///
/// The sound: the title's music on the menus, a track per block, a fanfare when a block is cleared
/// and a jingle when one is failed, and the fanfare and a voice over the final screen before the
/// ending's music. Buttons click, and a delivery's points rise from under the score and fade. The
/// pad cheers a cleared block and slumps on a failed one (the bike and porches rumble their own).
///
/// The screens are the GUI documents Tools/importui.py imports, pushed on the run GUI's screen
/// stack by id; a screen is loaded fresh each time it is pushed, so its buttons are wired again
/// each time, and the handlers go with its nodes.
[Game]
class PaperKidGame : Game
{
	private enum Phase
	{
		Title,
		Playing,
		Paused,
		Settings,
		Celebrating,
		Ended
	}

	private const int32 cBlockCount = 5;
	private const int32 cStartLives = 3;
	private const int32 cTimeBonusPerSecond = 5;
	private const float cMusicVolume = 0.5f;
	/// A delivery's points rise from under the HUD's score (cPopX, cPopY) over cPopSeconds.
	private const float cPopSeconds = 0.9f;
	private const float cPopX = 262.0f;
	private const float cPopY = 96.0f;
	/// The celebration of a cleared block: the world slows to cCelebrateSlowest of real time over
	/// cCelebrateEase seconds (easing out), and the Block cleared screen comes up at
	/// cCelebrateSeconds.
	private const float cCelebrateEase = 1.1f;
	private const float cCelebrateSlowest = 0.12f;
	private const float cCelebrateSeconds = 1.9f;
	/// Seconds for the banner to drop into place.
	private const float cBannerDrop = 0.35f;

	private Phase mPhase = .Title;
	private int32 mLevel = 0;
	private int32 mLives = cStartLives;
	private int32 mScore = 0;
	/// The score when the current block started.
	private int32 mBanked = 0;
	private int32 mDelivered = 0;
	/// Where Settings goes back to.
	private Phase mSettingsFrom = .Title;
	/// Seconds until the ending's music, after the final screen's voice; below 0 when none waits.
	private float mEndingIn = -1.0f;
	/// Seconds into a cleared block's celebration.
	private float mCelebrated = 0.0f;
	/// The clock when the block was cleared (its time bonus).
	private int32 mSecondsLeft = 0;

	// ---- the run's services; null outside a run that has them ----
	private InputFacade Controls => (Instance != null) ? Instance.Get<InputFacade>() : null;
	private AudioFacade Sound => (Instance != null) ? Instance.Get<AudioFacade>() : null;

	protected override void OnLaunch()
	{
		Listen<Delivered>(new [=this] (evt) => OnDelivered(evt.Points));
		Listen<QuotaMet>(new [=this] (evt) => OnQuotaMet(evt.SecondsLeft));
		Listen<LevelFailed>(new [=this] (evt) => OnLevelFailed(evt.Reason));
		// The default scene is the title's backdrop: the street goes about its day behind the menu.
		Instance.InstanceTimeScale = 1.0f;
		ShowTitle();
	}

	/// The game updates at time scale 0 too, so the Pause action is read here in every phase.
	protected override void OnUpdate(float dt)
	{
		if (mPhase == .Celebrating)
			TickCelebration(dt);
		if (mEndingIn >= 0.0f)
		{
			mEndingIn -= dt;
			if (mEndingIn < 0.0f)
				PlayMusic(Assets.EndingMusic, 1.0f);
		}
		let input = Controls;
		if ((input == null) || !input.WasPressed("Pause"))
			return;
		switch (mPhase)
		{
		case .Playing: PauseBlock();
		case .Paused: ResumeBlock();
		case .Settings: SettingsBack();
		default:
		}
	}

	protected override void OnExit()
	{
		// The screens' handlers call into this game: they go with it.
		if (let stack = Hud.Screens(Run))
			stack.Clear();
	}

	// ---- what the block reports ----

	private void OnDelivered(int32 points)
	{
		if (mPhase != .Playing)
			return;
		mDelivered += 1;
		mScore += points;
		SetText("hud-score", scope $"{mScore}");
		// The points: up 36 px from under the score over the pop's time, fading out late.
		if (let pop = Find("hud-pop"))
		{
			if (let label = pop as Label)
				label.Text = scope $"+{points}";
			pop.Animate("transform", scope $"translate({cPopX}px, {cPopY - 36.0f}px)", cPopSeconds, "linear")
				.From(scope $"translate({cPopX}px, {cPopY}px)").ReleaseRef();
			pop.Animate("opacity", "0", cPopSeconds, "ease-in").From("1").ReleaseRef();
		}
	}

	private void OnQuotaMet(int32 secondsLeft)
	{
		if (mPhase != .Playing)
			return;
		mPhase = .Celebrating;
		mCelebrated = 0.0f;
		mSecondsLeft = secondsLeft;
		Controls?.Rumble(0.3f, 0.6f, 0.45f); // the cheer of a cleared block
		Sound?.StopMusic(1.2f);
		PlayOneShot(Assets.ClearedFanfare, .Music);
		// The banner drops in over cBannerDrop, easing out.
		if (let banner = Find("hud-banner"))
		{
			banner.Animate("opacity", "1", cBannerDrop, "ease-out").From("0").ReleaseRef();
			banner.Animate("transform", "translateY(0px)", cBannerDrop, "ease-out").From("translateY(-60px)").ReleaseRef();
		}
	}

	/// The block winds down under the banner, then its screen comes up and it freezes.
	private void TickCelebration(float dt)
	{
		mCelebrated += dt;
		var eased = mCelebrated / cCelebrateEase;
		if (eased > 1.0f)
			eased = 1.0f;
		eased = 1.0f - (1.0f - eased) * (1.0f - eased);
		Instance.InstanceTimeScale = 1.0f + (cCelebrateSlowest - 1.0f) * eased;
		if (mCelebrated >= cCelebrateSeconds)
		{
			Hud.Snap(Run, "hud-banner", "opacity", "0");
			ShowCleared();
		}
	}

	private void ShowCleared()
	{
		mPhase = .Ended;
		Instance.InstanceTimeScale = 0.0f;
		let earned = mScore - mBanked;
		let bonus = mSecondsLeft * cTimeBonusPerSecond;
		mScore += bonus;
		mBanked = mScore;
		SetText("hud-score", scope $"{mScore}");
		Push(Assets.ClearedDoc);
		SetText("cleared-summary", scope $"{mDelivered} delivered, {earned} points + {bonus} time bonus");
		if (mLevel + 1 >= cBlockCount)
		{
			if (let button = Find("continue-btn") as Button)
				button.Text = "Finish";
		}
		Wire("continue-btn", new [=this] (e) =>
			{
				ContinueRun();
				return true;
			});
	}

	private void OnLevelFailed(FailReason reason)
	{
		if (mPhase != .Playing)
			return;
		mPhase = .Ended;
		Instance.InstanceTimeScale = 0.0f;
		Controls?.Rumble(0.6f, 0.2f, 0.4f); // the slump of a failed block
		Sound?.StopMusic(0.3f);
		PlayOneShot(Assets.FailedJingle, .Music);
		mLives -= 1;
		SetText("hud-lives", scope $"{mLives}");
		if (mLives <= 0)
		{
			ShowGameOver(false);
			return;
		}
		Push(Assets.FailedDoc);
		SetText("failed-reason", (reason == .OutOfTime) ? "Out of time" : "Out of papers");
		if (mLives == 1)
			SetText("failed-lives", "1 life left");
		else
			SetText("failed-lives", scope $"{mLives} lives left");
		Wire("retry-btn", new [=this] (e) =>
			{
				Retry();
				return true;
			});
		WireToTitle();
	}

	// ---- buttons ----

	private void NewGame()
	{
		Click();
		mLevel = 0;
		mLives = cStartLives;
		mScore = 0;
		mBanked = 0;
		StartLevel();
	}

	private void Retry()
	{
		Click();
		StartLevel();
	}

	private void ContinueRun()
	{
		Click();
		mLevel += 1;
		if (mLevel >= cBlockCount)
		{
			mLevel = cBlockCount - 1;
			Pop(); // the Block cleared screen gives way to the summary
			ShowGameOver(true);
			return;
		}
		StartLevel();
	}

	private void ResumeBlock()
	{
		Click();
		Pop(); // the pause menu
		Instance.InstanceTimeScale = 1.0f;
		mPhase = .Playing;
	}

	private void OpenSettings()
	{
		Click();
		mSettingsFrom = mPhase;
		Push(Assets.SettingsDoc);
		BindVolume("master", .Master);
		BindVolume("music", .Music);
		BindVolume("effects", .Effects);
		Wire("settings-back-btn", new [=this] (e) =>
			{
				SettingsBack();
				return true;
			});
		mPhase = .Settings;
	}

	private void SettingsBack()
	{
		Click();
		Pop(); // the settings screen; the title or the pause menu is under it
		mPhase = mSettingsFrom;
	}

	private void ToTitle()
	{
		Click();
		Instance.LoadScene(Assets.Start);
		Instance.InstanceTimeScale = 1.0f; // the title's street moves (an ended block stopped the clock)
		ShowTitle();
	}

	private void Quit()
	{
		Click();
		Instance.RequestExit(0);
	}

	// ---- screens ----

	/// The current block from its start: the score goes back to what was banked before it.
	private void StartLevel()
	{
		mScore = mBanked;
		mDelivered = 0;
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.HudDoc);
		SetText("hud-score", scope $"{mScore}");
		SetText("hud-lives", scope $"{mLives}");
		mEndingIn = -1.0f;
		PlayMusic(BlockMusic(mLevel), 0.8f);
		Instance.InstanceTimeScale = 1.0f;
		Instance.LoadScene(BlockScene(mLevel));
		mPhase = .Playing;
	}

	private void PauseBlock()
	{
		Instance.InstanceTimeScale = 0.0f;
		Push(Assets.PauseDoc);
		Wire("resume-btn", new [=this] (e) =>
			{
				ResumeBlock();
				return true;
			});
		Wire("restart-btn", new [=this] (e) =>
			{
				Retry();
				return true;
			});
		WireSettings();
		WireToTitle();
		mPhase = .Paused;
	}

	private void ShowGameOver(bool won)
	{
		mPhase = .Ended;
		Sound?.StopMusic(0.3f);
		if (won)
		{
			PlayOneShot(Assets.ClearedFanfare, .Music);
			PlayOneShot(Assets.Congratulations, .Effects);
		}
		else
		{
			PlayOneShot(Assets.GameOverVoice, .Effects);
		}
		mEndingIn = won ? 4.2f : 2.0f; // the ending's music once the fanfare or the voice is done
		Push(Assets.GameOverDoc);
		SetText("over-title", won ? "Route complete!" : "Game over");
		SetText("over-score", scope $"Score {mScore}");
		if (won)
			SetText("over-reached", "Every block delivered");
		else
			SetText("over-reached", scope $"Reached block {mLevel + 1} of {cBlockCount}");
		Wire("again-btn", new [=this] (e) =>
			{
				NewGame();
				return true;
			});
		WireToTitle();
	}

	private void ShowTitle()
	{
		mPhase = .Title;
		mEndingIn = -1.0f;
		PlayMusic(Assets.TitleMusic, 0.8f);
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.TitleDoc);
		Wire("play-btn", new [=this] (e) =>
			{
				NewGame();
				return true;
			});
		WireSettings();
		Wire("quit-btn", new [=this] (e) =>
			{
				Quit();
				return true;
			});
	}

	/// The top screen's settings-btn (the title's or the pause menu's) opens Settings.
	private void WireSettings()
	{
		Wire("settings-btn", new [=this] (e) =>
			{
				OpenSettings();
				return true;
			});
	}

	/// The top screen's menu-btn goes back to the title.
	private void WireToTitle()
	{
		Wire("menu-btn", new [=this] (e) =>
			{
				ToTitle();
				return true;
			});
	}

	// ---- the blocks ----

	private static Guid BlockScene(int32 index)
	{
		switch (index)
		{
		case 1: return Assets.Block2;
		case 2: return Assets.Block3;
		case 3: return Assets.Block4;
		case 4: return Assets.Block5;
		default: return Assets.Block1;
		}
	}

	/// The blocks' tracks in turn, the fourth block on the first's.
	private static Guid BlockMusic(int32 index)
	{
		switch (index % 3)
		{
		case 1: return Assets.BlockMusicB;
		case 2: return Assets.BlockMusicC;
		default: return Assets.BlockMusicA;
		}
	}

	// ---- the sound ----

	private void PlayMusic(Guid clip, float crossFadeSeconds)
	{
		if (let audio = Sound)
			audio.PlayMusic(clip, crossFadeSeconds, cMusicVolume);
	}

	private void PlayOneShot(Guid clip, AudioBus bus, float volume = 1.0f)
	{
		if (let audio = Sound)
			audio.PlayOneShot(clip, bus, volume);
	}

	private void Click()
	{
		PlayOneShot(Assets.ClickSound, .Effects, 0.7f);
	}

	/// A volume row: its slider at the bus's level, its readout, and each step as the slider moves
	/// going to the bus.
	private void BindVolume(StringView row, AudioBus bus)
	{
		let slider = Find(scope $"{row}-slider") as Slider;
		if (slider == null)
			return;
		let audio = Sound;
		slider.Value = (audio != null) ? (double)audio.BusVolume(bus) : 1.0;
		ShowVolume(row, (float)slider.Value);
		let rowName = new String(row);
		slider.On("input", new [=this, =rowName, =bus] (e) =>
			{
				VolumeChanged(rowName, bus);
				return true;
			} ~ delete rowName);
	}

	private void VolumeChanged(StringView row, AudioBus bus)
	{
		let slider = Find(scope $"{row}-slider") as Slider;
		if (slider == null)
			return;
		let level = (float)slider.Value;
		Sound?.SetBusVolume(bus, level);
		ShowVolume(row, level);
		PlayOneShot(Assets.SliderSound, .Effects, 0.6f); // hear the level being set
	}

	private void ShowVolume(StringView row, float level)
	{
		SetText(scope $"{row}-value", scope $"{(int32)(level * 100.0f + 0.5f)}%");
	}

	// ---- the screens ----

	/// Pushes the GUI document `document` (its asset id) on the screen stack.
	private void Push(StringView document)
	{
		if (let stack = Hud.Screens(Run))
			stack.PushDocument(document);
	}

	/// Takes the top screen off the stack.
	private void Pop()
	{
		if (let stack = Hud.Screens(Run))
			stack.Pop();
	}

	private Node Find(StringView id) => Hud.Find(Run, id);

	private void SetText(StringView id, StringView text) => Hud.SetText(Run, id, text);

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
