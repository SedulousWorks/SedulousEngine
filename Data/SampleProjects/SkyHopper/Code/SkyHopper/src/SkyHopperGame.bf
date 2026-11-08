using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.GUI;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// The run: the title screen, the levels in order with an intro and a clear tally each, the pause
/// menu, the fades between them, the HUD, and the stakes.
///
/// The stakes: a run has three lives. A fall or a hit costs one; a heart found in a level gives one
/// back, and so does every 50th coin. The last life lost is the game over, and trying again starts
/// the run over from the first level.
///
/// The score: a coin is 100, a stomped enemy 200, a level's gem 500, and a clear adds a bonus for
/// every second under the level's par time and 1000 for a level without a fall. Each clear earns
/// up to three stars: all the coins, no falls, under par. A level's best score, stars and time,
/// and the best run, are saved (SaveFacade) and shown on the title.
///
/// The flow is one state machine on the run's REAL clock (GameInstance.RealDeltaTime), because the
/// game holds its scenes at time scale 0 on every screen but play: the title, an intro, a pause, a
/// clear.
///
/// A level's behaviours report to it through the run's events: coins announce themselves
/// (CoinRegistered) and their pickups (CoinCollected), enemies their stomps (EnemyDefeated),
/// pickups hearts and gems (LifeCollected, GemCollected), the player its falls (PlayerDied), and
/// the flag ends the level (GoalReached).
///
/// The screens are the GUI documents Tools/importui.py imports, pushed on the run GUI's screen
/// stack by id; a screen is loaded fresh each time it is pushed, so its buttons are wired again
/// each time, and the handlers go with its nodes.
[Game]
class SkyHopperGame : Game
{
	private enum Phase
	{
		Title,
		Settings,
		FadingOut,
		FadingIn,
		Intro,
		Playing,
		Paused,
		Dying,
		GameOver,
		Cleared,
		Victory
	}

	private const int32 cLevelCount = 5;
	private const int32 cStartLives = 3;
	private const int32 cMaxLives = 9;
	private const int32 cCoinsPerLife = 50;
	private const int32 cCoinPoints = 100;
	private const int32 cStompPoints = 200;
	private const int32 cGemPoints = 500;
	private const int32 cSecondPoints = 20;
	private const int32 cFlawlessPoints = 1000;
	private const float cMusicVolume = 0.55f;
	private const float cFadeSeconds = 0.45f;
	/// After the last life goes, the poof plays out before the game over card.
	private const float cDyingSeconds = 1.1f;
	/// How long the clear card waits once its tally is done before the next level comes on its own.
	private const float cClearHoldSeconds = 4.0f;
	/// The clear tally's steps: its five rows, the total, then the three stars.
	private const int32 cTallySteps = 9;

	private Phase mPhase = .Title;
	/// Real seconds in the current phase.
	private float mTimer = 0.0f;
	/// Where a fade out lands: the title, or level mNextLevel.
	private bool mToTitle = false;
	private int32 mNextLevel = 0;
	/// The phase a fade in reveals.
	private Phase mAfterFade = .Intro;
	/// The track playing: 0 none, 1 the menu's, 2 + n level n's. A track asked for again keeps
	/// playing rather than restarting.
	private int32 mTrack = 0;

	// ---- the run ----
	private int32 mLives = cStartLives;
	/// Points banked by the levels cleared so far.
	private int32 mScore = 0;
	/// Coins toward the next extra life.
	private int32 mLifeCoins = 0;
	private int32 mRunStars = 0;
	private int32 mAllCoins = 0;
	private int32 mAllCoinTotal = 0;
	private int32 mAllFalls = 0;
	private float mAllTime = 0.0f;
	/// The score the HUD shows, rolling up toward the real one.
	private float mShownScore = 0.0f;

	// ---- this level ----
	private int32 mLevel = 0;
	private int32 mCoins = 0;
	private int32 mCoinTotal = 0;
	private int32 mFalls = 0;
	private int32 mStomps = 0;
	private bool mGem = false;
	private float mTime = 0.0f;

	// ---- the clear tally ----
	private int32 mTimeBonus = 0;
	private int32 mFlawless = 0;
	private int32 mLevelScore = 0;
	private int32 mStars = 0;
	private bool mNewBest = false;
	/// The tally's steps done so far, and whether it is done (counted up, or skipped to the end).
	private int32 mTallyStep = 0;
	private bool mTallyDone = false;

	// ---- the run's services; null outside a run that has them ----
	private InputFacade Controls => (Instance != null) ? Instance.Get<InputFacade>() : null;
	private AudioFacade Sound => (Instance != null) ? Instance.Get<AudioFacade>() : null;
	private SaveFacade Save => (Instance != null) ? Instance.Get<SaveFacade>() : null;

	/// Plays `clip` once, on `bus`; nothing in a run without audio.
	private void PlayOneShot(Guid clip, AudioBus bus = .Effects, float volume = 1.0f, float pitch = 1.0f)
	{
		if (let audio = Sound)
			audio.PlayOneShot(clip, bus, volume, pitch);
	}

	protected override void OnLaunch()
	{
		Listen<CoinRegistered>(new [=this] (evt) => OnCoinRegistered(evt.Count));
		Listen<CoinCollected>(new [=this] (evt) => OnCoinCollected(evt.Value));
		Listen<EnemyDefeated>(new [=this] (evt) => OnEnemyDefeated(evt.Count));
		Listen<GemCollected>(new [=this] (evt) => OnGemCollected());
		Listen<LifeCollected>(new [=this] (evt) => OnLifeCollected());
		Listen<PlayerDied>(new [=this] (evt) => OnPlayerDied());
		Listen<GoalReached>(new [=this] (evt) => OnGoalReached());
		// The default scene is the title's backdrop, frozen behind the menu.
		Instance.InstanceTimeScale = 0.0f;
		ShowTitle();
	}

	protected override void OnUpdate(float dt)
	{
		let real = Instance.RealDeltaTime;
		let input = Controls;
		mTimer += real;
		switch (mPhase)
		{
		case .FadingOut:
			if (mTimer >= cFadeSeconds)
				Arrive();
		case .FadingIn:
			if (mTimer >= cFadeSeconds)
			{
				Pop(); // the fade layer, on top since the fade began
				Enter(mAfterFade);
				if (mAfterFade == .Intro)
				{
					// The level's card drops in from above and settles with a bounce.
					if (let card = Find("intro-card"))
					{
						card.Animate("transform", "translateY(0px)", 0.55f, "ease-out-back").From("translateY(-260px)").ReleaseRef();
						card.Animate("opacity", "1", 0.25f, "linear").From("0").ReleaseRef();
					}
				}
			}
		case .Intro:
			// On the RELEASE: the press lands while the level is still frozen, so the player never
			// sees it and does not jump the moment play starts.
			if ((input != null) && input.WasReleased("Jump"))
			{
				Pop(); // the intro banner
				Instance.InstanceTimeScale = 1.0f;
				Enter(.Playing);
			}
		case .Playing:
			mTime += dt;
			SetText("hud-time", Clock(mTime, .. scope .()));
			RollScore(real, mScore + LevelPoints());
			if ((input != null) && input.WasPressed("Pause"))
				Pause();
		case .Dying:
			RollScore(real, mScore + LevelPoints());
			if (mTimer >= cDyingSeconds)
				ShowGameOver();
		case .Settings:
			if ((input != null) && input.WasPressed("Pause"))
				SettingsBack();
		case .Paused:
			if ((input != null) && input.WasPressed("Pause"))
				Resume();
		case .Cleared:
			RollScore(real, mScore); // the clear's points are banked: the HUD catches up under the card
			UpdateTally();
		default:
		}
	}

	protected override void OnExit()
	{
		if (let stack = Screens)
			stack.Clear();
	}

	// ---- the level's reports ----

	private void OnCoinRegistered(int32 count)
	{
		mCoinTotal += count;
		RefreshHud();
	}

	private void OnCoinCollected(int32 value)
	{
		if (mPhase != .Playing)
			return;
		mCoins += value;
		Popup(scope $"+{value * cCoinPoints}");
		Pulse("hud-coin", 1.35f, 0.25f);
		mLifeCoins += value;
		if (mLifeCoins >= cCoinsPerLife)
		{
			mLifeCoins -= cCoinsPerLife;
			GainLife();
		}
		RefreshHud();
	}

	private void OnEnemyDefeated(int32 count)
	{
		if (mPhase != .Playing)
			return;
		mStomps += count;
		Popup(scope $"+{count * cStompPoints}");
		RefreshHud();
	}

	private void OnGemCollected()
	{
		if (mPhase != .Playing)
			return;
		mGem = true;
		Popup(scope $"+{cGemPoints}");
		RefreshHud(); // shows it
		if (let gem = Find("hud-gem"))
			gem.Animate("transform", "scale(1)", 0.45f, "ease-out-back").From("scale(0)").ReleaseRef();
	}

	private void OnLifeCollected()
	{
		if (mPhase != .Playing)
			return;
		GainLife();
	}

	private void OnPlayerDied()
	{
		if (mPhase != .Playing)
			return;
		mFalls += 1;
		mLives -= 1;
		Pulse("hud-heart", 0.6f, 0.35f); // the heart shrinks and comes back: a life gone
		RefreshHud();
		if (mLives <= 0)
		{
			// The poof plays out, the pad gives a long low rumble, then the card.
			Controls?.Rumble(0.9f, 0.2f, 0.6f);
			if (let audio = Sound)
				audio.SetVoiceVolume(audio.MusicVoice(), 0.15f, 0.8f);
			Enter(.Dying);
		}
	}

	private void OnGoalReached()
	{
		if (mPhase != .Playing)
			return;
		// Time runs on under the card: the confetti flies and the player stands and watches.
		let par = LevelPar(mLevel);
		mTimeBonus = (mTime < par) ? (int32)(par - mTime) * cSecondPoints : 0;
		mFlawless = (mFalls == 0) ? cFlawlessPoints : 0;
		mLevelScore = LevelPoints() + mTimeBonus + mFlawless;
		mStars = 0;
		if (mCoins >= mCoinTotal)
			mStars += 1;
		if (mFalls == 0)
			mStars += 1;
		if (mTime <= par)
			mStars += 1;
		mNewBest = SaveLevel(mLevel, mLevelScore, StarMask(), mTime);

		mScore += mLevelScore;
		mRunStars += mStars;
		mAllCoins += mCoins;
		mAllCoinTotal += mCoinTotal;
		mAllFalls += mFalls;
		mAllTime += mTime;
		PlayOneShot(Assets.ClearJingle);
		Push(Assets.ClearDoc);
		SetText("star-3-caption", scope $"Under {Clock(par, .. scope .())}");
		SetText("tally-total", "0");
		SetText("clear-best", "");
		SetText("clear-next", "");
		mTallyStep = 0;
		mTallyDone = false;
		Enter(.Cleared);
	}

	// ---- the flow ----

	private void Enter(Phase phase)
	{
		mPhase = phase;
		mTimer = 0.0f;
	}

	private void StartRun()
	{
		mLives = cStartLives;
		mScore = 0;
		mShownScore = 0.0f;
		mLifeCoins = 0;
		mRunStars = 0;
		mAllCoins = 0;
		mAllCoinTotal = 0;
		mAllFalls = 0;
		mAllTime = 0.0f;
		FadeToLevel(0);
	}

	private void ShowTitle()
	{
		Music(1);
		if (let stack = Screens)
			stack.Clear();
		Push(Assets.TitleDoc);
		Wire("play-btn", "click", new [=this] (e) =>
			{
				Click();
				StartRun();
				return true;
			});
		Wire("settings-btn", "click", new [=this] (e) =>
			{
				Click();
				ShowSettings();
				return true;
			});
		Wire("quit-btn", "click", new [=this] (e) =>
			{
				Click();
				Instance.RequestExit(0);
				return true;
			});
		SetText("title-stars", scope $"{SavedStars()} / {cLevelCount * 3}");
		let best = (Save != null) ? Save.GetInt("best.run", 0) : 0;
		let bestText = scope String();
		if (best > 0)
			bestText.AppendF("Best {}", Points(best, .. scope .()));
		SetText("title-best", bestText);
		Enter(.Title);
	}

	/// The volumes, on the audio buses the player saves when it exits, so a change made here is
	/// there next time without the game storing anything itself.
	private void ShowSettings()
	{
		Push(Assets.SettingsDoc);
		BindVolume("master", .Master, false);
		BindVolume("music", .Music, false);
		// Hear the level being set; the music is heard anyway.
		BindVolume("effects", .Effects, true);
		Wire("settings-back-btn", "click", new [=this] (e) =>
			{
				SettingsBack();
				return true;
			});
		Enter(.Settings);
	}

	private void SettingsBack()
	{
		Click();
		Pop(); // the settings screen; the title is under it
		Enter(.Title);
	}

	private void Pause()
	{
		Instance.InstanceTimeScale = 0.0f;
		Push(Assets.PauseDoc);
		Wire("resume-btn", "click", new [=this] (e) =>
			{
				Resume();
				return true;
			});
		// The level again from its start, with the score it started with and the lives left now
		// (a restart is no way to win lives back).
		Wire("restart-btn", "click", new [=this] (e) =>
			{
				Click();
				FadeToLevel(mLevel);
				return true;
			});
		WireQuitToTitle("title-btn");
		Enter(.Paused);
	}

	private void Resume()
	{
		Click();
		Pop(); // the pause menu
		Instance.InstanceTimeScale = 1.0f;
		Enter(.Playing);
	}

	private void ShowGameOver()
	{
		Instance.InstanceTimeScale = 0.0f;
		let total = mScore + LevelPoints();
		let best = SaveRun(total);
		Push(Assets.GameOverDoc);
		SetText("gameover-reached", scope $"Reached level {mLevel + 1}, {LevelName(mLevel)}");
		SetText("gameover-score", Points(total, .. scope .()));
		SetBestRun("gameover-best", best);
		Wire("gameover-retry-btn", "click", new [=this] (e) =>
			{
				Click();
				StartRun();
				return true;
			});
		WireQuitToTitle("gameover-title-btn");
		Enter(.GameOver);
	}

	private void ShowVictory()
	{
		Pop(); // the clear card
		PlayOneShot(Assets.VictoryJingle);
		let best = SaveRun(mScore);
		Push(Assets.VictoryDoc);
		SetText("victory-summary", scope $"Coins {mAllCoins} / {mAllCoinTotal}    Falls {mAllFalls}    Time {Clock(mAllTime, .. scope .())}");
		SetText("victory-score", Points(mScore, .. scope .()));
		SetText("victory-stars", scope $"{mRunStars} / {cLevelCount * 3}");
		SetBestRun("victory-best", best);
		WireQuitToTitle("victory-title-btn");
		Enter(.Victory);
	}

	/// The run's best on a card: a new one said so, else the best kept.
	private void SetBestRun(StringView id, bool best)
	{
		if (best)
		{
			SetText(id, "New best run!");
			return;
		}
		let kept = (Save != null) ? Save.GetInt("best.run", 0) : 0;
		SetText(id, scope $"Best {Points(kept, .. scope .())}");
	}

	private void WireQuitToTitle(StringView id)
	{
		Wire(id, "click", new [=this] (e) =>
			{
				Click();
				FadeToTitle();
				return true;
			});
	}

	private void FadeToLevel(int32 index)
	{
		mToTitle = false;
		mNextLevel = index;
		FadeOut();
	}

	private void FadeToTitle()
	{
		mToTitle = true;
		FadeOut();
	}

	/// Black over everything, then Arrive swaps what is under it.
	private void FadeOut()
	{
		if ((mPhase == .FadingOut) || (mPhase == .FadingIn))
			return;
		Push(Assets.FadeDoc);
		if (let fade = Find("fade"))
			fade.Animate("opacity", "1", cFadeSeconds, "linear").From("0").ReleaseRef();
		Enter(.FadingOut);
	}

	/// Under the black: the new scene and its screens, then the black fades away.
	private void Arrive()
	{
		if (let stack = Screens)
			stack.Clear();
		Instance.InstanceTimeScale = 0.0f;
		if (mToTitle)
		{
			Instance.LoadScene(Assets.Level1);
			ShowTitle();
			mAfterFade = .Title;
		}
		else
		{
			mLevel = mNextLevel;
			mCoins = 0;
			mCoinTotal = 0; // the new level's coins register again
			mFalls = 0;
			mStomps = 0;
			mGem = false;
			mTime = 0.0f;
			Instance.LoadScene(LevelScene(mLevel));
			mTrack = 0; // the level's music from its start, at full volume after a game over
			Music(2 + mLevel);
			Push(Assets.HudDoc);
			mShownScore = (float)mScore;
			RefreshHud();
			Push(Assets.IntroDoc);
			SetText("intro-number", scope $"Level {mLevel + 1}");
			SetText("intro-name", LevelName(mLevel));
			Show("intro-card", false); // waiting above for the fade to clear
			mAfterFade = .Intro;
		}
		Push(Assets.FadeDoc);
		if (let fade = Find("fade"))
			fade.Animate("opacity", "0", cFadeSeconds, "linear").From("1").ReleaseRef();
		Enter(.FadingIn);
	}

	// ---- the clear tally: one row at a time, each counting up with a tick ----

	private void UpdateTally()
	{
		let input = Controls;
		let jump = (input != null) && input.WasPressed("Jump");
		if (!mTallyDone && jump)
		{
			// Skip to the end: every row, the total and the stars at once.
			while (mTallyStep < cTallySteps)
			{
				TallyStep(mTallyStep, true);
				mTallyStep += 1;
			}
			FinishTally();
			return;
		}
		if (!mTallyDone)
		{
			// Step n lands at 0.45 s, then every 0.4 s.
			while ((mTallyStep < cTallySteps) && (mTimer >= 0.45f + 0.4f * (float)mTallyStep))
			{
				TallyStep(mTallyStep, false);
				mTallyStep += 1;
			}
			if (mTallyStep >= cTallySteps)
				FinishTally();
			return;
		}
		let more = mLevel + 1 < cLevelCount;
		let left = (int32)(cClearHoldSeconds - mTimer + 0.999f);
		let lead = more ? "Next level in " : "Results in ";
		SetText("clear-next", scope $"{lead}{left}    (Space or A to go on)");
		if ((mTimer >= cClearHoldSeconds) || jump)
		{
			if (more)
				FadeToLevel(mLevel + 1);
			else
				ShowVictory();
		}
	}

	/// Steps 0-4 are the rows, 5 the total, 6-8 the stars.
	private void TallyStep(int32 step, bool quiet)
	{
		if (step <= 4)
		{
			StringView key;
			let value = scope String();
			switch (step)
			{
			case 0:
				key = "coins";
				value.AppendF("{} / {}    +{}", mCoins, mCoinTotal, Points(mCoins * cCoinPoints, .. scope .()));
			case 1:
				key = "stomps";
				value.AppendF("{}    +{}", mStomps, Points(mStomps * cStompPoints, .. scope .()));
			case 2:
				key = "gem";
				if (mGem)
					value.AppendF("Found    +{}", Points(cGemPoints, .. scope .()));
				else
					value.Append("Not found");
			case 3:
				key = "time";
				value.AppendF("{}    +{}", Clock(mTime, .. scope .()), Points(mTimeBonus, .. scope .()));
			default:
				key = "flawless";
				if (mFlawless > 0)
					value.AppendF("+{}", Points(mFlawless, .. scope .()));
				else
					value.Append("-");
			}
			SetText(scope $"tally-{key}", value);
			let rowId = scope $"tally-{key}-row";
			if (quiet)
			{
				Show(rowId, true);
			}
			else if (let row = Find(rowId))
			{
				row.Animate("opacity", "1", 0.2f, "linear").From("0").ReleaseRef();
				row.Animate("transform", "translateX(0px)", 0.25f, "ease-out").From("translateX(-24px)").ReleaseRef();
				PlayOneShot(Assets.Chime, .Effects, 0.35f, 0.9f + 0.08f * (float)step);
			}
			return;
		}
		if (step == 5)
		{
			SetText("tally-total", Points(mLevelScore, .. scope .()));
			if (!quiet)
				Pulse("tally-total", 1.4f, 0.35f);
			return;
		}
		let star = step - 5; // 1 to 3
		if ((StarMask() & (1 << (star - 1))) == 0)
			return;
		let starId = scope $"star-{star}";
		Show(starId, true);
		if (quiet)
			return;
		if (let filled = Find(starId))
		{
			filled.Animate("transform", "scale(1) rotate(0deg)", 0.4f, "ease-out-back").From("scale(0) rotate(-40deg)").ReleaseRef();
			PlayOneShot(Assets.Chime, .Effects, 0.7f, 1.0f + 0.15f * (float)star);
			Controls?.Rumble(0.0f, 0.3f, 0.06f);
		}
	}

	private void FinishTally()
	{
		mTallyDone = true;
		if (mNewBest)
		{
			SetText("clear-best", "New best!");
			if (let best = Find("clear-best"))
				best.Animate("transform", "scale(1)", 0.4f, "ease-out-back").From("scale(0)").ReleaseRef();
		}
		else
		{
			let kept = (Save != null) ? Save.GetInt(scope $"best.score.{mLevel}", 0) : 0;
			SetText("clear-best", scope $"Best {Points(kept, .. scope .())}");
		}
		Enter(.Cleared); // the hold before the next level starts now
	}

	// ---- the save: per level its best score, stars and time; the best run ----

	/// Bit 0 all coins, bit 1 no falls, bit 2 under par: the stars this clear earned.
	private int32 StarMask()
	{
		int32 mask = 0;
		if (mCoins >= mCoinTotal)
			mask |= 1;
		if (mFalls == 0)
			mask |= 2;
		if (mTime <= LevelPar(mLevel))
			mask |= 4;
		return mask;
	}

	/// Keeps the level's best score, every star ever earned there and its best time; true when the
	/// score is a new best.
	private bool SaveLevel(int32 level, int32 score, int32 stars, float seconds)
	{
		let save = Save;
		if (save == null)
			return false;
		let scoreKey = scope $"best.score.{level}";
		let starsKey = scope $"best.stars.{level}";
		let timeKey = scope $"best.time.{level}";
		let best = score > save.GetInt(scoreKey, 0);
		if (best)
			save.SetInt(scoreKey, score);
		save.SetInt(starsKey, save.GetInt(starsKey, 0) | stars);
		let bestTime = save.GetFloat(timeKey, 0.0f);
		if ((bestTime <= 0.0f) || (seconds < bestTime))
			save.SetFloat(timeKey, seconds);
		save.Flush(); // a clear is a moment worth keeping, whatever happens next
		return best;
	}

	private bool SaveRun(int32 score)
	{
		let save = Save;
		if (save == null)
			return false;
		let best = score > save.GetInt("best.run", 0);
		if (best)
		{
			save.SetInt("best.run", score);
			save.Flush();
		}
		return best;
	}

	/// Every star earned on every level, over all runs.
	private int32 SavedStars()
	{
		let save = Save;
		if (save == null)
			return 0;
		int32 total = 0;
		for (int32 level < cLevelCount)
		{
			let mask = save.GetInt(scope $"best.stars.{level}", 0);
			for (int32 bit < 3)
			{
				if ((mask & (1 << bit)) != 0)
					total += 1;
			}
		}
		return total;
	}

	// ---- the HUD and the sound ----

	private void Music(int32 track)
	{
		if (track == mTrack)
			return;
		mTrack = track;
		if (let audio = Sound)
			audio.PlayMusic((track == 1) ? Assets.MenuMusic : LevelMusic(track - 2), 1.0f, cMusicVolume);
	}

	private void Click()
	{
		PlayOneShot(Assets.ButtonSound);
	}

	private void GainLife()
	{
		if (mLives < cMaxLives)
			mLives += 1;
		Rise("hud-life-popup", 26.0f, 0.9f);
		Pulse("hud-heart", 1.5f, 0.4f);
		RefreshHud();
	}

	/// The points scored in the level so far, before its clear bonuses.
	private int32 LevelPoints()
	{
		return mCoins * cCoinPoints + mStomps * cStompPoints + (mGem ? cGemPoints : 0);
	}

	/// A gain floating up from the score.
	private void Popup(StringView text)
	{
		SetText("hud-popup", text);
		Rise("hud-popup", 22.0f, 0.7f);
	}

	/// The HUD's score rolls up toward `goal`, quickly for a big gain.
	private void RollScore(float real, int32 goal)
	{
		let target = (float)goal;
		if (mShownScore >= target)
			return;
		let step = (target - mShownScore) * 8.0f * real + 40.0f * real;
		mShownScore = (mShownScore + step > target) ? target : mShownScore + step;
		SetText("hud-score", Points((int32)mShownScore, .. scope .()));
		if (mShownScore >= target)
			Pulse("hud-score", 1.2f, 0.2f);
	}

	private void RefreshHud()
	{
		SetText("hud-lives", scope $"x {mLives}");
		SetText("hud-coins", scope $"{mCoins} / {mCoinTotal}");
		SetText("hud-time", Clock(mTime, .. scope .()));
		SetText("hud-level", scope $"{mLevel + 1}  {LevelName(mLevel)}");
		SetText("hud-score", Points((int32)mShownScore, .. scope .()));
		Show("hud-gem", mGem);
	}

	// ---- the levels ----

	private static Guid LevelScene(int32 index)
	{
		switch (index)
		{
		case 1: return Assets.Level2;
		case 2: return Assets.Level3;
		case 3: return Assets.Level4;
		case 4: return Assets.Level5;
		default: return Assets.Level1;
		}
	}

	/// The later levels reuse the first ones' tracks.
	private static Guid LevelMusic(int32 index)
	{
		switch (index)
		{
		case 1: return Assets.Level2Music;
		case 2: return Assets.Level3Music;
		case 3: return Assets.Level1Music;
		case 4: return Assets.Level2Music;
		default: return Assets.Level1Music;
		}
	}

	private static StringView LevelName(int32 index)
	{
		switch (index)
		{
		case 1: return "Crab Crossing";
		case 2: return "Sky Climb";
		case 3: return "Bee Meadow";
		case 4: return "Cloud Fortress";
		default: return "Grassy Hills";
		}
	}

	/// A clear in this many seconds or fewer earns the time star, and every second under it scores.
	private static float LevelPar(int32 index)
	{
		switch (index)
		{
		case 1: return 50.0f;
		case 2: return 60.0f;
		case 3: return 70.0f;
		case 4: return 85.0f;
		default: return 40.0f;
		}
	}

	// ---- text ----

	/// Minutes and seconds: 1:05.
	private static void Clock(float seconds, String outText)
	{
		let whole = (int32)seconds;
		let s = whole % 60;
		outText.AppendF("{}:{}{}", whole / 60, (s < 10) ? "0" : "", s);
	}

	/// A score with its thousands set apart: 12,400.
	private static void Points(int32 value, String outText)
	{
		let digits = scope String();
		value.ToString(digits);
		for (int i < digits.Length)
		{
			if ((i > 0) && ((digits.Length - i) % 3 == 0))
				outText.Append(',');
			outText.Append(digits[i]);
		}
	}

	// ---- the screens ----

	/// The run GUI's screen stack; null in a run without a GUI.
	private ScreenStack Screens
	{
		get
		{
			let gui = (Instance != null) ? Instance.Get<GuiFacade>() : null;
			let root = (gui != null) ? gui.Root() : null;
			return (root != null) ? (root.FindElement("screens") as ScreenStack) : null;
		}
	}

	/// Pushes the GUI document `document` (its asset id) on the screen stack.
	private void Push(StringView document)
	{
		if (let stack = Screens)
			stack.PushDocument(document);
	}

	/// Takes the top screen off the stack.
	private void Pop()
	{
		if (let stack = Screens)
			stack.Pop();
	}

	/// The element `id`, the top screen first: one just cleared or popped away is still in the tree
	/// while its exit plays, with the same ids, and would be found first. Null when there is none:
	/// a level's coins report while the title is up, before there is a HUD.
	private Node Find(StringView id)
	{
		let gui = (Instance != null) ? Instance.Get<GuiFacade>() : null;
		let root = (gui != null) ? gui.Root() : null;
		if (root == null)
			return null;
		let stack = root.FindElement("screens") as ScreenStack;
		let top = (stack != null) ? stack.Top : null;
		let found = (top != null) ? top.FindElement(id) : null;
		return (found != null) ? found : root.FindElement(id);
	}

	/// Calls `handler` on the element `id`'s `eventName`. The element's own to delete: it goes
	/// with the screen. Deleted at once when there is no such element.
	private void Wire(StringView id, StringView eventName, delegate bool(Sedulous.GUI.Event e) handler)
	{
		let node = Find(id);
		if (node == null)
		{
			delete handler;
			return;
		}
		node.On(eventName, handler);
	}

	/// A bound volume row: its slider at the bus's level, its readout, and each step as the slider
	/// moves going to the bus (with a click to hear it, when `audible`).
	private void BindVolume(StringView row, AudioBus bus, bool audible)
	{
		let slider = Find(scope $"{row}-slider") as Slider;
		if (slider == null)
			return;
		let audio = Sound;
		slider.Value = (audio != null) ? (double)audio.BusVolume(bus) : 1.0;
		ShowVolume(row, (float)slider.Value);
		let rowName = new String(row);
		slider.On("input", new [=this, =rowName, =bus, =audible] (e) =>
			{
				VolumeChanged(rowName, bus);
				if (audible)
					Click();
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
	}

	private void ShowVolume(StringView row, float level)
	{
		SetText(scope $"{row}-value", scope $"{(int32)(level * 100.0f + 0.5f)}%");
	}

	private void SetText(StringView id, StringView text)
	{
		if (let label = Find(id) as Label)
			label.Text = text;
	}

	/// Shown or hidden at once (the sheet starts what waits for its moment at opacity 0).
	private void Show(StringView id, bool shown)
	{
		// A tween of no length replaces the last.
		if (let node = Find(id))
			node.Animate("opacity", shown ? "1" : "0", 0.0f, "linear").ReleaseRef();
	}

	/// Grows to `scale` and back over `seconds`: a counter that just changed.
	private void Pulse(StringView id, float scale, float seconds)
	{
		if (let node = Find(id))
			node.Animate("transform", scope $"scale({scale})", seconds * 0.5f, "ease-out").From("scale(1)").Repeat(2).PingPong().ReleaseRef();
	}

	/// A label rising `height` pixels from its place as it fades away.
	private void Rise(StringView id, float height, float seconds)
	{
		if (let node = Find(id))
		{
			node.Animate("transform", scope $"translateY({-height}px)", seconds, "ease-out").From("translateY(0px)").ReleaseRef();
			node.Animate("opacity", "0", seconds, "ease-in").From("1").ReleaseRef();
		}
	}
}
