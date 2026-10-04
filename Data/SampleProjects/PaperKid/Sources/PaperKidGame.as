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

Guid kTitleDoc = Guid::FromString("fe1f3877-b6eb-ef43-8fba-f73add0b4d79");
Guid kHudDoc = Guid::FromString("d544f8b1-309d-d342-be81-0e5db70589e9");
Guid kClearedDoc = Guid::FromString("1a8b784d-a0bb-5041-ab52-0220e9674eca");
Guid kFailedDoc = Guid::FromString("cb529d09-1aba-ba48-ae47-0b963765b35b");
Guid kGameOverDoc = Guid::FromString("9a2304de-0e82-2846-af90-39b94b5cfe02");
Guid kPauseDoc = Guid::FromString("d8ce1390-43fe-2c46-a1a2-f6132354621f");
Guid kSettingsDoc = Guid::FromString("acf4c08b-a9b7-c84b-829f-3e8b2daca1fc");

Guid kTitleMusic = Guid::FromString("92494f18-c682-6d47-8bbc-fa49f6917d4e");
Guid kEndingMusic = Guid::FromString("eaa4c451-d3a3-ac4b-bccc-890a0ecec6e3");
Guid kClearedFanfare = Guid::FromString("e9d46ca7-2060-844b-b8c3-555510d06481");
Guid kFailedJingle = Guid::FromString("994964a2-ab5c-9042-95a1-bf0a2760a186");
Guid kCongratulations = Guid::FromString("f99a33d8-a955-614b-82c2-615c51c94615");
Guid kGameOverVoice = Guid::FromString("f2867be6-7007-9348-9a64-fca3a00e6fe5");
Guid kClickSound = Guid::FromString("df6ebf4a-2bbf-5646-938d-4aa110b96a78");
Guid kSliderSound = Guid::FromString("d3cef52a-509c-e240-94e2-ecb446665285");

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
Guid kStart = Guid::FromString("abf41c6a-3a62-4a4f-830f-47fb88f610ff");

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
		m_levels.insertLast(Guid::FromString("252c2c2a-4795-6a4d-bafb-95001f747b70"));
		m_levels.insertLast(Guid::FromString("5e9597f2-196d-1f42-b917-366eb2b6c2b1"));
		m_levels.insertLast(Guid::FromString("12f0e95d-f5cd-7f4f-b5d4-5e2194dd3413"));
		m_levels.insertLast(Guid::FromString("8eaa0f69-9e48-c248-a145-168e61e26a79"));
		m_levels.insertLast(Guid::FromString("16eed323-f9a4-5e44-b9f7-50514bdd6aa0"));
		m_blockMusic.insertLast(Guid::FromString("859ea749-874f-414e-8bba-2ae82b7bfbfd"));
		m_blockMusic.insertLast(Guid::FromString("9d7a0b20-f4b0-5c44-ac6d-ffe78caf041e"));
		m_blockMusic.insertLast(Guid::FromString("4bf0e18f-ab1c-9e4e-a3b8-2361247c2309"));
		// The default scene is the title's backdrop: the street goes about its day behind the menu.
		Run.TimeScale = 1.0f;
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
		Run.TimeScale = 1.0f; // the title's street moves (an ended block stopped the clock)
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
