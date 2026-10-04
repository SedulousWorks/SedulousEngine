// PaperKidGame - the run's orchestrator (the reserved class Game): the screens, the levels, the
// score and the lives.
//
// The Level script owns a block's rules and tells this class how it ended ("QuotaMet" with the
// whole seconds left, or "LevelFailed" with 0 for time, 1 for papers); every delivery
// ("Delivered", from a Subscriber) scores here. In a run the scene bus IS the run bus, so all of
// them reach this class.
//
// A run is the blocks in order. A cleared block banks its score (deliveries plus a time bonus); a
// failed one spends a life and replays from the banked score; no lives left, or the last block
// cleared, is the Game over screen. Pause (the Pause action) freezes the block under a menu;
// Settings, from the title or the pause menu, sets the audio buses' volumes, which the player saves
// when it exits, and goes back to whichever opened it.
//
// A cleared block is celebrated before its screen: the clock stops, a banner drops in, the world
// eases into slow motion under a fanfare while the music fades, and only then does the Block
// cleared screen come up and the block freeze. A failed block cuts straight to its screen.
//
// The sound: the title's music on the menus, a track per block, a fanfare when a block is cleared
// and a jingle when one is failed, and the fanfare and a voice over the final screen before the
// ending's music. Buttons click, and a delivery's points rise from under the score and fade. The
// pad cheers a cleared block and slumps on a failed one (the bike and porches rumble their own).

Guid kTitleDoc = Guid::FromString("{{Title}}");
Guid kHudDoc = Guid::FromString("{{Hud}}");
Guid kClearedDoc = Guid::FromString("{{Cleared}}");
Guid kFailedDoc = Guid::FromString("{{Failed}}");
Guid kGameOverDoc = Guid::FromString("{{GameOver}}");
Guid kPauseDoc = Guid::FromString("{{Pause}}");
Guid kSettingsDoc = Guid::FromString("{{Settings}}");

Guid kTitleMusic = Guid::FromString("{{MusicTitle}}");
Guid kEndingMusic = Guid::FromString("{{MusicEnding}}");
Guid kClearedFanfare = Guid::FromString("{{ClearedFanfare}}");
Guid kFailedJingle = Guid::FromString("{{FailedJingle}}");
Guid kCongratulations = Guid::FromString("{{Congratulations}}");
Guid kGameOverVoice = Guid::FromString("{{GameOverVoice}}");
Guid kClickSound = Guid::FromString("{{Click}}");
Guid kSliderSound = Guid::FromString("{{Slider}}");

const float kMusicVolume = 0.5f;
const float kPopSeconds = 0.9f;
const float kPopX = 262.0f; // under the HUD's score
const float kPopY = 96.0f;
// The celebration of a cleared block: the world slows to kCelebrateSlowest of real time over
// kCelebrateEase seconds (easing out), and the Block cleared screen comes up at kCelebrateSeconds.
const float kCelebrateEase = 1.1f;
const float kCelebrateSlowest = 0.12f;
const float kCelebrateSeconds = 1.9f;
const float kBannerDrop = 0.35f; // seconds for the banner to drop into place
Guid kStart = Guid::FromString("{{Start}}");

const int kStartLives = 3;
const int kTimeBonusPerSecond = 5;

enum Phase
{
	Title,
	Playing,
	Paused,
	Settings,
	Celebrating,
	Ended
}

class Game
{
	private Phase m_phase = Phase::Title;
	private array<Guid> m_levels;
	private int m_level = 0;
	private int m_lives = kStartLives;
	private int m_score = 0;
	private int m_banked = 0; // the score when the current block started
	private int m_delivered = 0;
	private Phase m_settingsFrom = Phase::Title; // where Settings goes back to
	private array<Guid> m_blockMusic;
	private float m_endingIn = -1.0f; // seconds until the ending's music, after the final screen's voice
	private float m_pop = 0.0f;       // seconds left of the points rising from the score
	private float m_celebrated = 0.0f; // seconds into a cleared block's celebration
	private int m_secondsLeft = 0;     // the clock when the block was cleared (its time bonus)

	void launch()
	{
		m_levels.insertLast(Guid::FromString("{{Block1}}"));
		m_levels.insertLast(Guid::FromString("{{Block2}}"));
		m_levels.insertLast(Guid::FromString("{{Block3}}"));
		m_levels.insertLast(Guid::FromString("{{Block4}}"));
		m_levels.insertLast(Guid::FromString("{{Block5}}"));
		m_blockMusic.insertLast(Guid::FromString("{{MusicBlockA}}"));
		m_blockMusic.insertLast(Guid::FromString("{{MusicBlockB}}"));
		m_blockMusic.insertLast(Guid::FromString("{{MusicBlockC}}"));
		// The default scene is the title's backdrop, frozen behind the menu.
		Run.TimeScale = 0.0f;
		showTitle();
	}

	// The Game tier ticks at time scale 0 too, so the Pause action is read here in every phase.
	void update(float dt)
	{
		tickPop(dt);
		if (m_phase == Phase::Celebrating)
		{
			tickCelebration(dt);
		}
		if (m_endingIn >= 0.0f)
		{
			m_endingIn -= dt;
			if (m_endingIn < 0.0f)
			{
				Audio.PlayMusic(kEndingMusic, 1.0f, kMusicVolume);
			}
		}
		if (!Input.WasPressed("Pause"))
		{
			return;
		}
		if (m_phase == Phase::Playing)
		{
			pause();
		}
		else if (m_phase == Phase::Paused)
		{
			onResume();
		}
		else if (m_phase == Phase::Settings)
		{
			onSettingsBack();
		}
	}

	void exit() {}

	// ---- what the level reports ----

	void onDelivered(int points)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_delivered += 1;
		m_score += points;
		Ui.FindLabel("hud-score").SetText("" + m_score);
		Label pop = Ui.FindLabel("hud-pop");
		pop.SetText("+" + points);
		pop.SetOpacity(1.0f);
		pop.SetTranslation(kPopX, kPopY);
		pop.SetVisible(true);
		m_pop = kPopSeconds;
	}

	void onQuotaMet(int secondsLeft)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_phase = Phase::Celebrating;
		m_celebrated = 0.0f;
		m_secondsLeft = secondsLeft;
		Input.Rumble(0.3f, 0.6f, 0.45f); // the cheer of a cleared block
		Audio.StopMusic(1.2f);
		Audio.PlayOneShot(kClearedFanfare, AudioBus::Music);
		Label banner = Ui.FindLabel("hud-banner");
		banner.SetOpacity(0.0f);
		banner.SetVisible(true);
	}

	// The block winds down under the banner, then its screen comes up and it freezes.
	private void tickCelebration(float dt)
	{
		m_celebrated += dt;
		float eased = m_celebrated / kCelebrateEase;
		if (eased > 1.0f)
		{
			eased = 1.0f;
		}
		eased = 1.0f - (1.0f - eased) * (1.0f - eased);
		Run.TimeScale = 1.0f + (kCelebrateSlowest - 1.0f) * eased;

		Label banner = Ui.FindLabel("hud-banner");
		float drop = m_celebrated / kBannerDrop;
		if (drop > 1.0f)
		{
			drop = 1.0f;
		}
		banner.SetOpacity(drop);
		banner.SetTranslation(0.0f, -60.0f * (1.0f - drop) * (1.0f - drop));

		if (m_celebrated >= kCelebrateSeconds)
		{
			banner.SetVisible(false);
			showCleared();
		}
	}

	private void showCleared()
	{
		m_phase = Phase::Ended;
		Run.TimeScale = 0.0f;
		int earned = m_score - m_banked;
		int bonus = m_secondsLeft * kTimeBonusPerSecond;
		m_score += bonus;
		m_banked = m_score;
		Ui.FindLabel("hud-score").SetText("" + m_score);
		Screen s = Ui.Push(kClearedDoc);
		s.FindLabel("cleared-summary").SetText("" + m_delivered + " delivered, " + earned + " points + "
											   + bonus + " time bonus");
		Button next = s.FindButton("continue-btn");
		if (m_level + 1 >= int(m_levels.length()))
		{
			next.SetText("Finish");
		}
		next.OnClick(ScriptCallback(this.onContinue));
	}

	void onLevelFailed(int reason)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_phase = Phase::Ended;
		Run.TimeScale = 0.0f;
		Input.Rumble(0.6f, 0.2f, 0.4f); // the slump of a failed block
		Audio.StopMusic(0.3f);
		Audio.PlayOneShot(kFailedJingle, AudioBus::Music);
		m_lives -= 1;
		Ui.FindLabel("hud-lives").SetText("" + m_lives);
		if (m_lives <= 0)
		{
			showGameOver(false);
			return;
		}
		Screen s = Ui.Push(kFailedDoc);
		s.FindLabel("failed-reason").SetText(reason == 0 ? "Out of time" : "Out of papers");
		s.FindLabel("failed-lives").SetText(m_lives == 1 ? "1 life left" : "" + m_lives + " lives left");
		s.FindButton("retry-btn").OnClick(ScriptCallback(this.onRetry));
		s.FindButton("menu-btn").OnClick(ScriptCallback(this.onToTitle));
	}

	// ---- buttons ----

	void onNewGame()
	{
		click();
		m_level = 0;
		m_lives = kStartLives;
		m_score = 0;
		m_banked = 0;
		startLevel();
	}

	void onRetry()
	{
		click();
		startLevel();
	}

	void onContinue()
	{
		click();
		m_level += 1;
		if (m_level >= int(m_levels.length()))
		{
			m_level = int(m_levels.length()) - 1;
			Ui.Pop(); // the Block cleared screen gives way to the summary
			showGameOver(true);
			return;
		}
		startLevel();
	}

	void onResume()
	{
		click();
		Ui.Pop(); // the pause menu
		Run.TimeScale = 1.0f;
		m_phase = Phase::Playing;
	}

	void onSettings()
	{
		click();
		m_settingsFrom = m_phase;
		Screen s = Ui.Push(kSettingsDoc);
		bindVolume(s, "master", AudioBus::Master, ScriptCallback(this.onMasterChanged));
		bindVolume(s, "music", AudioBus::Music, ScriptCallback(this.onMusicChanged));
		bindVolume(s, "effects", AudioBus::Effects, ScriptCallback(this.onEffectsChanged));
		s.FindButton("settings-back-btn").OnClick(ScriptCallback(this.onSettingsBack));
		m_phase = Phase::Settings;
	}

	void onSettingsBack()
	{
		click();
		Ui.Pop(); // the settings screen; the title or the pause menu is under it
		m_phase = m_settingsFrom;
	}

	void onMasterChanged()
	{
		volumeChanged("master", AudioBus::Master);
	}

	void onMusicChanged()
	{
		volumeChanged("music", AudioBus::Music);
	}

	void onEffectsChanged()
	{
		volumeChanged("effects", AudioBus::Effects);
	}

	void onToTitle()
	{
		click();
		Run.LoadScene(kStart);
		Run.TimeScale = 0.0f;
		showTitle();
	}

	void onQuit()
	{
		click();
		Run.RequestExit(0);
	}

	// ---- screens ----

	// The current block from its start: the score goes back to what was banked before it.
	private void startLevel()
	{
		m_score = m_banked;
		m_delivered = 0;
		Ui.Clear();
		Ui.Push(kHudDoc);
		Ui.FindLabel("hud-score").SetText("" + m_score);
		Ui.FindLabel("hud-lives").SetText("" + m_lives);
		m_pop = 0.0f;
		m_endingIn = -1.0f;
		Audio.PlayMusic(m_blockMusic[m_level % int(m_blockMusic.length())], 0.8f, kMusicVolume);
		Run.TimeScale = 1.0f;
		Run.LoadScene(m_levels[m_level]);
		m_phase = Phase::Playing;
	}

	private void pause()
	{
		Run.TimeScale = 0.0f;
		Screen s = Ui.Push(kPauseDoc);
		s.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		s.FindButton("restart-btn").OnClick(ScriptCallback(this.onRetry));
		s.FindButton("settings-btn").OnClick(ScriptCallback(this.onSettings));
		s.FindButton("menu-btn").OnClick(ScriptCallback(this.onToTitle));
		m_phase = Phase::Paused;
	}

	private void click()
	{
		Audio.PlayOneShot(kClickSound, AudioBus::Effects, 0.7f);
	}

	// The delivery's points: up 36 px from under the score over the pop's time, fading out late.
	private void tickPop(float dt)
	{
		if (m_pop <= 0.0f)
		{
			return;
		}
		m_pop -= dt;
		Label pop = Ui.FindLabel("hud-pop");
		if (!pop.IsValid)
		{
			m_pop = 0.0f;
			return;
		}
		if (m_pop <= 0.0f)
		{
			pop.SetVisible(false);
			return;
		}
		float t = 1.0f - m_pop / kPopSeconds;
		pop.SetTranslation(kPopX, kPopY - 36.0f * t);
		pop.SetOpacity(1.0f - t * t);
	}

	// A volume row: its slider at the bus's level, its readout, and the handler.
	private void bindVolume(Screen s, string row, AudioBus bus, ScriptCallback@ handler)
	{
		Slider slider = s.FindSlider(row + "-slider");
		slider.SetValue(Audio.BusVolume(bus));
		showVolume(row, slider.Value);
		slider.OnChanged(handler);
	}

	private void volumeChanged(string row, AudioBus bus)
	{
		float level = Ui.FindSlider(row + "-slider").Value;
		Audio.SetBusVolume(bus, level);
		showVolume(row, level);
		Audio.PlayOneShot(kSliderSound, AudioBus::Effects, 0.6f); // hear the level being set
	}

	private void showVolume(string row, float level)
	{
		Ui.FindLabel(row + "-value").SetText("" + int(level * 100.0f + 0.5f) + "%");
	}

	private void showGameOver(bool won)
	{
		m_phase = Phase::Ended;
		Audio.StopMusic(0.3f);
		if (won)
		{
			Audio.PlayOneShot(kClearedFanfare, AudioBus::Music);
			Audio.PlayOneShot(kCongratulations, AudioBus::Effects);
		}
		else
		{
			Audio.PlayOneShot(kGameOverVoice, AudioBus::Effects);
		}
		m_endingIn = won ? 4.2f : 2.0f; // the ending's music once the fanfare or the voice is done
		Screen s = Ui.Push(kGameOverDoc);
		s.FindLabel("over-title").SetText(won ? "Route complete!" : "Game over");
		s.FindLabel("over-score").SetText("Score " + m_score);
		s.FindLabel("over-reached").SetText(won ? "Every block delivered"
												: "Reached block " + (m_level + 1) + " of " + m_levels.length());
		s.FindButton("again-btn").OnClick(ScriptCallback(this.onNewGame));
		s.FindButton("menu-btn").OnClick(ScriptCallback(this.onToTitle));
	}

	private void showTitle()
	{
		m_phase = Phase::Title;
		m_endingIn = -1.0f;
		Audio.PlayMusic(kTitleMusic, 0.8f, kMusicVolume);
		Ui.Clear();
		Screen s = Ui.Push(kTitleDoc);
		s.FindButton("play-btn").OnClick(ScriptCallback(this.onNewGame));
		s.FindButton("settings-btn").OnClick(ScriptCallback(this.onSettings));
		s.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuit));
	}
}
