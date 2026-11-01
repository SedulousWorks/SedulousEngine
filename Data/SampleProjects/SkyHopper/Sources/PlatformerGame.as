// PlatformerGame - the run's orchestrator (the reserved class Game): the title screen, the
// levels in order with an intro and a clear tally each, the pause menu, the fades between them,
// the HUD, and the stakes.
//
// The stakes: a run has three lives. A fall or a hit costs one; a heart found in a level gives
// one back, and so does every 50th coin. The last life lost is the game over, and trying again
// starts the run over from the first level.
//
// The score: a coin is 100, a stomped enemy 200, a level's gem 500, and a clear adds a bonus for
// every second under the level's par time and 1000 for a level without a fall. Each clear earns
// up to three stars: all the coins, no falls, under par. A level's best score, stars and time,
// and the best run, are saved (the Save service) and shown on the title.
//
// The flow is one state machine on the run's REAL clock (Run.RealDeltaTime), because the
// game sits at TimeScale 0 on every screen but play: the title, an intro, a pause, a clear.
//
// A level's coins announce themselves ("CoinRegistered") and report pickups
// ("CoinCollected"), enemies report stomps ("EnemyDefeated"), pickups report hearts and gems
// ("LifeCollected", "GemCollected"), the player reports falls ("PlayerDied"), and the goal flag
// ends the level ("GoalReached"). In a run the scene bus IS the run bus, so all of them reach
// this class.

// The screens, on the engine GUI (Tools/ui, imported by Tools/importui.py): their documents by asset
// id, as importui.py made them (a re-import keeps them).
const string kHudDoc = "{e09972b0-43f3-034d-9760-b3f74dcf11ad}";
const string kTitleDoc = "{5fd73dbe-154b-db49-8901-6ce2c3b20a02}";
const string kIntroDoc = "{a5c33950-5d25-514a-ac27-86c20e332525}";
const string kPauseDoc = "{bdc6be12-9060-8042-bf90-2946b0423368}";
const string kClearDoc = "{bc75d2d9-8afe-7f4a-a5b0-bbdb84695c53}";
const string kVictoryDoc = "{b64e0bde-4209-304d-a9ab-8d9fc79d3e67}";
const string kFadeDoc = "{f41b5031-33c0-d142-8f7b-24950e820278}";
const string kSettingsDoc = "{d9a81097-a913-b84d-8b2f-73d02e45cc44}";
const string kGameOverDoc = "{824cdd2c-b9b9-d94d-bdd2-5b628b5131b8}";

Guid kLevel1 = Guid::FromString("d54b3804-21ff-724a-a076-4e971ef6b238");     // Scenes/Level1
Guid kLevel2 = Guid::FromString("d56e307e-8751-4241-a1ff-565b483b2cf1");     // Scenes/Level2
Guid kLevel3 = Guid::FromString("e8094435-4425-034d-b972-6bca7668b14d");     // Scenes/Level3
Guid kLevel4 = Guid::FromString("e4fe9908-429b-3c4f-9257-95cddc58d7d6");     // Scenes/Level4
Guid kLevel5 = Guid::FromString("ea16b013-ac16-8a4f-9281-f8ebcb5d94f1");     // Scenes/Level5

// Music: CodeManu's Platformer Game Music Pack (CC-BY 3.0) and Juhani Junkala's Chiptune
// Adventures (CC0); see CREDITS.md.
Guid kMenuMusic = Guid::FromString("3d2725e8-4b25-6a40-944d-57f5060a741d");    // Audio/Music-IntroTheme
Guid kLevel1Music = Guid::FromString("220216e9-ce96-e34d-9ff3-d6f2644ff9a4");  // Audio/Music-GrasslandsTheme
Guid kLevel2Music = Guid::FromString("b90d9d25-b608-4643-9ce2-19bd3e5a9ded");  // Audio/Music-Stage1
Guid kLevel3Music = Guid::FromString("852aeb40-1328-374e-9bb8-76663e55f695");  // Audio/Music-Stage2
Guid kButtonSound = Guid::FromString("d85b7392-aa68-0144-a40a-830d4e32079b"); // Audio/button-maximize_007
Guid kClearJingle = Guid::FromString("26864262-5533-b442-8d38-b77aeaa1ce30"); // Audio/jingles_NES13
Guid kVictoryJingle = Guid::FromString("a8c66ad5-4705-ae4e-af1e-ca70bb89e446"); // Audio/jingles_NES00
// Audio/powerUp7 (Kenney, CC0): the tally's tick and a star landing, pitched up as they go.
Guid kChime = Guid::FromString("cd3e0197-ff26-a740-8ad2-a7774508f0f8");
const float kMusicVolume = 0.55f;

const int kLevelCount = 5;
const int kStartLives = 3;
const int kMaxLives = 9;
const int kCoinsPerLife = 50;
const int kCoinPoints = 100;
const int kStompPoints = 200;
const int kGemPoints = 500;
const int kSecondPoints = 20;
const int kFlawlessPoints = 1000;
const float kFadeSeconds = 0.45f;
/// After the last life goes, the poof plays out before the game over card.
const float kDyingSeconds = 1.1f;
/// How long the clear card waits once its tally is done before the next level comes on its own.
const float kClearHoldSeconds = 4.0f;

ScreenStack@ screens() { return ScreenStack::Of(Gui.Root().Find("screens")); }
// The top screen first: one just cleared or popped away is still in the tree while its exit plays,
// with the same ids, and would be found first. Null when there is none: a level's coins and
// enemies report while the title is up, before there is a HUD.
Node@ find(string id)
{
	Screen@ top = screens().Top;
	Node@ n = top !is null ? top.Find(id) : null;
	return n !is null ? n : Gui.Root().Find(id);
}
void wire(string id, string event, EventHandler@ handler) { find(id).On(event, handler); } // `on*` names are the engine's handlers
void setText(string id, string text)
{
	Node@ n = find(id);
	if (n !is null)
	{
		Label::Of(n).Text = text;
	}
}
// Shown or hidden at once (the sheet starts what waits for its moment at opacity 0).
void show(string id, bool shown)
{
	Node@ n = find(id);
	if (n !is null)
	{
		n.Tween("opacity", shown ? "1" : "0", 0.0f, "linear"); // a tween of no length replaces the last
	}
}
// Grows to `scale` and back over `seconds`: a counter that just changed.
void pulse(string id, float scale, float seconds)
{
	Node@ n = find(id);
	if (n !is null)
	{
		n.Tween("transform", "scale(" + scale + ")", seconds * 0.5f, "ease-out").From("scale(1)").Repeats(2).PingPong();
	}
}

Guid levelScene(int index)
{
	switch (index)
	{
	case 1: return kLevel2;
	case 2: return kLevel3;
	case 3: return kLevel4;
	case 4: return kLevel5;
	}
	return kLevel1;
}

/// The later levels reuse the first ones' tracks.
Guid levelMusic(int index)
{
	switch (index)
	{
	case 1: return kLevel2Music;
	case 2: return kLevel3Music;
	case 3: return kLevel1Music;
	case 4: return kLevel2Music;
	}
	return kLevel1Music;
}

string levelName(int index)
{
	switch (index)
	{
	case 1: return "Crab Crossing";
	case 2: return "Sky Climb";
	case 3: return "Bee Meadow";
	case 4: return "Cloud Fortress";
	}
	return "Grassy Hills";
}

/// A clear in this many seconds or fewer earns the time star, and every second under it scores.
float levelPar(int index)
{
	switch (index)
	{
	case 1: return 50.0f;
	case 2: return 60.0f;
	case 3: return 70.0f;
	case 4: return 85.0f;
	}
	return 40.0f;
}

enum Phase
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

class Game
{
	private Phase m_phase = Phase::Title;
	/// Real seconds in the current phase.
	private float m_timer = 0.0f;
	/// Where a fade out lands: the title, or level m_nextLevel.
	private bool m_toTitle = false;
	private int m_nextLevel = 0;
	/// The phase a fade in reveals.
	private Phase m_afterFade = Phase::Intro;
	private Node@ m_fade;
	/// The track playing: 0 none, 1 the menu's, 2 + n level n's. A track asked for again keeps
	/// playing rather than restarting.
	private int m_track = 0;

	// ---- the run ----
	private int m_lives = kStartLives;
	/// Points banked by the levels cleared so far.
	private int m_score = 0;
	/// Coins toward the next extra life.
	private int m_lifeCoins = 0;
	private int m_runStars = 0;
	private int m_allCoins = 0;
	private int m_allCoinTotal = 0;
	private int m_allFalls = 0;
	private float m_allTime = 0.0f;
	/// The score the HUD shows, rolling up toward the real one.
	private float m_shownScore = 0.0f;

	// ---- this level ----
	private int m_level = 0;
	private int m_coins = 0;
	private int m_coinTotal = 0;
	private int m_falls = 0;
	private int m_stomps = 0;
	private bool m_gem = false;
	private float m_time = 0.0f;

	// ---- the clear tally ----
	private int m_timeBonus = 0;
	private int m_flawless = 0;
	private int m_levelScore = 0;
	private int m_stars = 0;
	private bool m_newBest = false;
	/// The tally's steps done so far, and whether the player skipped to the end.
	private int m_tallyStep = 0;
	private bool m_tallyDone = false;

	void launch()
	{
		// The default scene is the title's backdrop, frozen behind the menu.
		Run.TimeScale = 0.0f;
		showTitle();
	}

	void update(float dt)
	{
		float real = Run.RealDeltaTime;
		m_timer += real;
		switch (m_phase)
		{
		case Phase::FadingOut:
			if (m_timer >= kFadeSeconds)
			{
				arrive();
			}
			break;
		case Phase::FadingIn:
			if (m_timer >= kFadeSeconds)
			{
				screens().Pop(); // the fade layer, on top since the fade began
				enter(m_afterFade);
				if (m_afterFade == Phase::Intro)
				{
					// The level's card drops in from above and settles with a bounce.
					Node@ card = find("intro-card");
					card.Tween("transform", "translateY(0px)", 0.55f, "ease-out-back").From("translateY(-260px)");
					card.Tween("opacity", "1", 0.25f, "linear").From("0");
				}
			}
			break;
		case Phase::Intro:
			// On the RELEASE: the press lands while the level is still frozen, so the player
			// never sees it and does not jump the moment play starts.
			if (Input.WasReleased("Jump"))
			{
				screens().Pop(); // the intro banner
				Run.TimeScale = 1.0f;
				enter(Phase::Playing);
			}
			break;
		case Phase::Playing:
			m_time += dt;
			setText("hud-time", clock(m_time));
			rollScore(real, m_score + levelPoints());
			if (Input.WasPressed("Pause"))
			{
				pause();
			}
			break;
		case Phase::Dying:
			rollScore(real, m_score + levelPoints());
			if (m_timer >= kDyingSeconds)
			{
				showGameOver();
			}
			break;
		case Phase::Settings:
			if (Input.WasPressed("Pause"))
			{
				settingsBack();
			}
			break;
		case Phase::Paused:
			if (Input.WasPressed("Pause"))
			{
				resume();
			}
			break;
		case Phase::Cleared:
			rollScore(real, m_score); // the clear's points are banked: the HUD catches up under the card
			updateTally();
			break;
		default:
			break;
		}
	}

	void exit()
	{
		screens().Clear();
	}

	// ---- run events ----
	void onCoinRegistered(int count)
	{
		m_coinTotal += count;
		refreshHud();
	}

	void onCoinCollected(int value)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_coins += value;
		popup("+" + (value * kCoinPoints));
		pulse("hud-coin", 1.35f, 0.25f);
		m_lifeCoins += value;
		if (m_lifeCoins >= kCoinsPerLife)
		{
			m_lifeCoins -= kCoinsPerLife;
			gainLife();
		}
		refreshHud();
	}

	void onEnemyDefeated(int count)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_stomps += count;
		popup("+" + (count * kStompPoints));
		refreshHud();
	}

	void onGemCollected(int unused)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_gem = true;
		popup("+" + kGemPoints);
		refreshHud(); // shows it
		Node@ gem = find("hud-gem");
		if (gem !is null)
		{
			gem.Tween("transform", "scale(1)", 0.45f, "ease-out-back").From("scale(0)");
		}
	}

	void onLifeCollected(int count)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		gainLife();
	}

	void onPlayerDied(int deaths)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		m_falls += 1;
		m_lives -= 1;
		pulse("hud-heart", 0.6f, 0.35f); // the heart shrinks and comes back: a life gone
		refreshHud();
		if (m_lives <= 0)
		{
			// The poof plays out, the pad gives a long low rumble, then the card.
			Input.Rumble(0.9f, 0.2f, 0.6f);
			Audio.SetVoiceVolume(Audio.MusicVoice(), 0.15f, 0.8f);
			enter(Phase::Dying);
		}
	}

	void onGoalReached(int unused)
	{
		if (m_phase != Phase::Playing)
		{
			return;
		}
		// Time runs on under the card: the confetti flies and the player stands and watches.
		float par = levelPar(m_level);
		m_timeBonus = (m_time < par) ? int(par - m_time) * kSecondPoints : 0;
		m_flawless = (m_falls == 0) ? kFlawlessPoints : 0;
		m_levelScore = levelPoints() + m_timeBonus + m_flawless;
		m_stars = 0;
		if (m_coins >= m_coinTotal)
		{
			m_stars += 1;
		}
		if (m_falls == 0)
		{
			m_stars += 1;
		}
		if (m_time <= par)
		{
			m_stars += 1;
		}
		m_newBest = saveLevel(m_level, m_levelScore, starMask(), m_time);

		m_score += m_levelScore;
		m_runStars += m_stars;
		m_allCoins += m_coins;
		m_allCoinTotal += m_coinTotal;
		m_allFalls += m_falls;
		m_allTime += m_time;
		Audio.PlayOneShot(kClearJingle);
		screens().Push(kClearDoc);
		setText("star-3-caption", "Under " + clock(par));
		setText("tally-total", "0");
		setText("clear-best", "");
		setText("clear-next", "");
		m_tallyStep = 0;
		m_tallyDone = false;
		enter(Phase::Cleared);
	}

	// ---- buttons (a GUI event's handlers; what they do, the flow below runs too) ----
	bool onPlay(GuiEvent@ e)
	{
		click();
		startRun();
		return true;
	}

	/// The volumes, on the audio buses the player saves when it exits, so a change made
	/// here is there next time without the game storing anything itself.
	bool onSettings(GuiEvent@ e)
	{
		click();
		screens().Push(kSettingsDoc);
		bindVolume("master", AudioBus::Master, EventHandler(this.onMasterChanged));
		bindVolume("music", AudioBus::Music, EventHandler(this.onMusicChanged));
		bindVolume("effects", AudioBus::Effects, EventHandler(this.onEffectsChanged));
		wire("settings-back-btn", "click", EventHandler(this.onSettingsBack));
		enter(Phase::Settings);
		return true;
	}

	bool onSettingsBack(GuiEvent@ e)
	{
		settingsBack();
		return true;
	}

	bool onMasterChanged(GuiEvent@ e)
	{
		volumeChanged("master", AudioBus::Master);
		return true;
	}

	bool onMusicChanged(GuiEvent@ e)
	{
		volumeChanged("music", AudioBus::Music);
		return true;
	}

	bool onEffectsChanged(GuiEvent@ e)
	{
		volumeChanged("effects", AudioBus::Effects);
		click(); // hear the level being set; the music is heard anyway
		return true;
	}

	bool onQuit(GuiEvent@ e)
	{
		click();
		Run.RequestExit(0);
		return true;
	}

	bool onResume(GuiEvent@ e)
	{
		resume();
		return true;
	}

	/// From the pause menu: the level again from its start, with the score it started with and
	/// the lives left now (a restart is no way to win lives back).
	bool onRestart(GuiEvent@ e)
	{
		click();
		fadeToLevel(m_level);
		return true;
	}

	bool onRetry(GuiEvent@ e)
	{
		click();
		startRun();
		return true;
	}

	bool onQuitToTitle(GuiEvent@ e)
	{
		click();
		fadeToTitle();
		return true;
	}

	// ---- the flow ----
	private void settingsBack()
	{
		click();
		screens().Pop(); // the settings screen; the title is under it
		enter(Phase::Title);
	}

	private void resume()
	{
		click();
		screens().Pop(); // the pause menu
		Run.TimeScale = 1.0f;
		enter(Phase::Playing);
	}
	private void enter(Phase phase)
	{
		m_phase = phase;
		m_timer = 0.0f;
	}

	private void startRun()
	{
		m_lives = kStartLives;
		m_score = 0;
		m_shownScore = 0.0f;
		m_lifeCoins = 0;
		m_runStars = 0;
		m_allCoins = 0;
		m_allCoinTotal = 0;
		m_allFalls = 0;
		m_allTime = 0.0f;
		fadeToLevel(0);
	}

	/// A bound volume row: its slider at the bus's level, its readout, and the handler.
	private void bindVolume(string row, AudioBus bus, EventHandler@ handler)
	{
		Slider@ slider = Slider::Of(find(row + "-slider"));
		slider.Value = Audio.BusVolume(bus);
		showVolume(row, float(slider.Value));
		wire(row + "-slider", "input", handler); // each step as the slider moves
	}

	private void volumeChanged(string row, AudioBus bus)
	{
		float level = float(Slider::Of(find(row + "-slider")).Value);
		Audio.SetBusVolume(bus, level);
		showVolume(row, level);
	}

	private void showVolume(string row, float level)
	{
		setText(row + "-value", "" + int(level * 100.0f + 0.5f) + "%");
	}

	private void showTitle()
	{
		music(1);
		screens().Clear();
		screens().Push(kTitleDoc);
		wire("play-btn", "click", EventHandler(this.onPlay));
		wire("settings-btn", "click", EventHandler(this.onSettings));
		wire("quit-btn", "click", EventHandler(this.onQuit));
		setText("title-stars", "" + savedStars() + " / " + (kLevelCount * 3));
		int best = Save.GetInt("best.run", 0);
		setText("title-best", best > 0 ? "Best " + points(best) : "");
		enter(Phase::Title);
	}

	private void pause()
	{
		Run.TimeScale = 0.0f;
		screens().Push(kPauseDoc);
		wire("resume-btn", "click", EventHandler(this.onResume));
		wire("restart-btn", "click", EventHandler(this.onRestart));
		wire("title-btn", "click", EventHandler(this.onQuitToTitle));
		enter(Phase::Paused);
	}

	private void showGameOver()
	{
		Run.TimeScale = 0.0f;
		int total = m_score + levelPoints();
		bool best = saveRun(total);
		screens().Push(kGameOverDoc);
		setText("gameover-reached", "Reached level " + (m_level + 1) + ", " + levelName(m_level));
		setText("gameover-score", points(total));
		setText("gameover-best", best ? "New best run!" : "Best " + points(Save.GetInt("best.run", 0)));
		wire("gameover-retry-btn", "click", EventHandler(this.onRetry));
		wire("gameover-title-btn", "click", EventHandler(this.onQuitToTitle));
		enter(Phase::GameOver);
	}

	private void showVictory()
	{
		screens().Pop(); // the clear card
		Audio.PlayOneShot(kVictoryJingle);
		bool best = saveRun(m_score);
		screens().Push(kVictoryDoc);
		setText("victory-summary", "Coins " + m_allCoins + " / " + m_allCoinTotal + "    Falls "
			+ m_allFalls + "    Time " + clock(m_allTime));
		setText("victory-score", points(m_score));
		setText("victory-stars", "" + m_runStars + " / " + (kLevelCount * 3));
		setText("victory-best", best ? "New best run!" : "Best " + points(Save.GetInt("best.run", 0)));
		wire("victory-title-btn", "click", EventHandler(this.onQuitToTitle));
		enter(Phase::Victory);
	}

	private void fadeToLevel(int index)
	{
		m_toTitle = false;
		m_nextLevel = index;
		fadeOut();
	}

	private void fadeToTitle()
	{
		m_toTitle = true;
		fadeOut();
	}

	/// Black over everything, then arrive() swaps what is under it.
	private void fadeOut()
	{
		if (m_phase == Phase::FadingOut || m_phase == Phase::FadingIn)
		{
			return;
		}
		screens().Push(kFadeDoc);
		@m_fade = find("fade");
		m_fade.Tween("opacity", "1", kFadeSeconds, "linear").From("0");
		enter(Phase::FadingOut);
	}

	/// Under the black: the new scene and its screens, then the black fades away.
	private void arrive()
	{
		screens().Clear();
		Run.TimeScale = 0.0f;
		if (m_toTitle)
		{
			Run.LoadScene(kLevel1);
			showTitle();
			m_afterFade = Phase::Title;
		}
		else
		{
			m_level = m_nextLevel;
			m_coins = 0;
			m_coinTotal = 0; // the new level's coins register again
			m_falls = 0;
			m_stomps = 0;
			m_gem = false;
			m_time = 0.0f;
			Run.LoadScene(levelScene(m_level));
			m_track = 0; // the level's music from its start, at full volume after a game over
			music(2 + m_level);
			screens().Push(kHudDoc);
			m_shownScore = float(m_score);
			refreshHud();
			screens().Push(kIntroDoc);
			setText("intro-number", "Level " + (m_level + 1));
			setText("intro-name", levelName(m_level));
			show("intro-card", false); // waiting above for the fade to clear
			m_afterFade = Phase::Intro;
		}
		screens().Push(kFadeDoc);
		@m_fade = find("fade");
		m_fade.Tween("opacity", "0", kFadeSeconds, "linear").From("1");
		enter(Phase::FadingIn);
	}

	// ---- the clear tally: one row at a time, each counting up with a tick ----
	private void updateTally()
	{
		if (!m_tallyDone && Input.WasPressed("Jump"))
		{
			// Skip to the end: every row, the total and the stars at once.
			while (m_tallyStep < 9)
			{
				tallyStep(m_tallyStep, true);
				m_tallyStep += 1;
			}
			finishTally();
			return;
		}
		if (!m_tallyDone)
		{
			// Step n lands at 0.45 s, then every 0.4 s.
			while (m_tallyStep < 9 && m_timer >= 0.45f + 0.4f * float(m_tallyStep))
			{
				tallyStep(m_tallyStep, false);
				m_tallyStep += 1;
			}
			if (m_tallyStep >= 9)
			{
				finishTally();
			}
			return;
		}
		bool more = m_level + 1 < kLevelCount;
		int left = int(kClearHoldSeconds - m_timer + 0.999f);
		setText("clear-next", (more ? "Next level in " : "Results in ") + left + "    (Space or A to go on)");
		if (m_timer >= kClearHoldSeconds || Input.WasPressed("Jump"))
		{
			if (more)
			{
				fadeToLevel(m_level + 1);
			}
			else
			{
				showVictory();
			}
		}
	}

	/// Steps 0-4 are the rows, 5 the total, 6-8 the stars.
	private void tallyStep(int step, bool quiet)
	{
		if (step <= 4)
		{
			string key;
			string value;
			if (step == 0)
			{
				key = "coins";
				value = "" + m_coins + " / " + m_coinTotal + "    +" + points(m_coins * kCoinPoints);
			}
			else if (step == 1)
			{
				key = "stomps";
				value = "" + m_stomps + "    +" + points(m_stomps * kStompPoints);
			}
			else if (step == 2)
			{
				key = "gem";
				value = m_gem ? "Found    +" + points(kGemPoints) : "Not found";
			}
			else if (step == 3)
			{
				key = "time";
				value = clock(m_time) + "    +" + points(m_timeBonus);
			}
			else
			{
				key = "flawless";
				value = (m_flawless > 0) ? "+" + points(m_flawless) : "-";
			}
			setText("tally-" + key, value);
			Node@ row = find("tally-" + key + "-row");
			if (quiet)
			{
				show("tally-" + key + "-row", true);
			}
			else if (row !is null)
			{
				row.Tween("opacity", "1", 0.2f, "linear").From("0");
				row.Tween("transform", "translateX(0px)", 0.25f, "ease-out").From("translateX(-24px)");
				Audio.PlayOneShot(kChime, AudioBus::Effects, 0.35f, 0.9f + 0.08f * float(step));
			}
			return;
		}
		if (step == 5)
		{
			setText("tally-total", points(m_levelScore));
			if (!quiet)
			{
				pulse("tally-total", 1.4f, 0.35f);
			}
			return;
		}
		int star = step - 5; // 1 to 3
		if ((starMask() & (1 << (star - 1))) == 0)
		{
			return;
		}
		show("star-" + star, true);
		Node@ filled = find("star-" + star);
		if (!quiet && filled !is null)
		{
			filled.Tween("transform", "scale(1) rotate(0deg)", 0.4f, "ease-out-back").From("scale(0) rotate(-40deg)");
			Audio.PlayOneShot(kChime, AudioBus::Effects, 0.7f, 1.0f + 0.15f * float(star));
			Input.Rumble(0.0f, 0.3f, 0.06f);
		}
	}

	private void finishTally()
	{
		m_tallyDone = true;
		if (m_newBest)
		{
			setText("clear-best", "New best!");
			Node@ best = find("clear-best");
			if (best !is null)
			{
				best.Tween("transform", "scale(1)", 0.4f, "ease-out-back").From("scale(0)");
			}
		}
		else
		{
			setText("clear-best", "Best " + points(Save.GetInt("best.score." + m_level, 0)));
		}
		enter(Phase::Cleared); // the hold before the next level starts now
	}

	// ---- the save: per level its best score, stars and time; the best run ----
	/// Bit 0 all coins, bit 1 no falls, bit 2 under par: the stars this clear earned.
	private int starMask()
	{
		int mask = 0;
		if (m_coins >= m_coinTotal)
		{
			mask |= 1;
		}
		if (m_falls == 0)
		{
			mask |= 2;
		}
		if (m_time <= levelPar(m_level))
		{
			mask |= 4;
		}
		return mask;
	}

	/// Keeps the level's best score, every star ever earned there and its best time; true when
	/// the score is a new best.
	private bool saveLevel(int level, int score, int stars, float seconds)
	{
		string suffix = "." + level;
		bool best = score > Save.GetInt("best.score" + suffix, 0);
		if (best)
		{
			Save.SetInt("best.score" + suffix, score);
		}
		Save.SetInt("best.stars" + suffix, Save.GetInt("best.stars" + suffix, 0) | stars);
		float bestTime = Save.GetFloat("best.time" + suffix, 0.0f);
		if (bestTime <= 0.0f || seconds < bestTime)
		{
			Save.SetFloat("best.time" + suffix, seconds);
		}
		Save.Flush(); // a clear is a moment worth keeping, whatever happens next
		return best;
	}

	private bool saveRun(int score)
	{
		bool best = score > Save.GetInt("best.run", 0);
		if (best)
		{
			Save.SetInt("best.run", score);
			Save.Flush();
		}
		return best;
	}

	/// Every star earned on every level, over all runs.
	private int savedStars()
	{
		int total = 0;
		for (int level = 0; level < kLevelCount; level++)
		{
			int mask = Save.GetInt("best.stars." + level, 0);
			for (int bit = 0; bit < 3; bit++)
			{
				if ((mask & (1 << bit)) != 0)
				{
					total += 1;
				}
			}
		}
		return total;
	}

	// ---- the HUD ----
	private void music(int track)
	{
		if (track == m_track)
		{
			return;
		}
		m_track = track;
		Audio.PlayMusic((track == 1) ? kMenuMusic : levelMusic(track - 2), 1.0f, kMusicVolume);
	}

	private void click()
	{
		Audio.PlayOneShot(kButtonSound);
	}

	private void gainLife()
	{
		if (m_lives < kMaxLives)
		{
			m_lives += 1;
		}
		rise("hud-life-popup", 26.0f, 0.9f);
		pulse("hud-heart", 1.5f, 0.4f);
		refreshHud();
	}

	/// The points scored in the level so far, before its clear bonuses.
	private int levelPoints()
	{
		return m_coins * kCoinPoints + m_stomps * kStompPoints + (m_gem ? kGemPoints : 0);
	}

	/// A gain floating up from the score.
	private void popup(string text)
	{
		setText("hud-popup", text);
		rise("hud-popup", 22.0f, 0.7f);
	}

	/// A label rising `height` pixels from its place as it fades away.
	private void rise(string id, float height, float seconds)
	{
		Node@ n = find(id);
		if (n !is null)
		{
			n.Tween("transform", "translateY(" + (-height) + "px)", seconds, "ease-out").From("translateY(0px)");
			n.Tween("opacity", "0", seconds, "ease-in").From("1");
		}
	}

	/// The HUD's score rolls up toward `goal`, quickly for a big gain.
	private void rollScore(float real, int goal)
	{
		float target = float(goal);
		if (m_shownScore >= target)
		{
			return;
		}
		float step = (target - m_shownScore) * 8.0f * real + 40.0f * real;
		m_shownScore = (m_shownScore + step > target) ? target : m_shownScore + step;
		setText("hud-score", points(int(m_shownScore)));
		if (m_shownScore >= target)
		{
			pulse("hud-score", 1.2f, 0.2f);
		}
	}

	private void refreshHud()
	{
		setText("hud-lives", "x " + m_lives);
		setText("hud-coins", "" + m_coins + " / " + m_coinTotal);
		setText("hud-time", clock(m_time));
		setText("hud-level", "" + (m_level + 1) + "  " + levelName(m_level));
		setText("hud-score", points(int(m_shownScore)));
		show("hud-gem", m_gem);
	}

	private string clock(float seconds)
	{
		int whole = int(seconds);
		int s = whole % 60;
		return "" + (whole / 60) + ":" + (s < 10 ? "0" : "") + s;
	}

	/// A score with its thousands set apart: 12,400.
	private string points(int value)
	{
		string digits = "" + value;
		string grouped = "";
		int count = 0;
		for (int i = int(digits.length()) - 1; i >= 0; i--)
		{
			grouped = digits.substr(i, 1) + grouped;
			count += 1;
			if (count % 3 == 0 && i > 0)
			{
				grouped = "," + grouped;
			}
		}
		return grouped;
	}
}
