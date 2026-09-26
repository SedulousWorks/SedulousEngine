// PaperKidGame - the Game tier: the screen flow and the score.
//
// The project's startup script: launch() boots it, update(dt) ticks it, exit() tears it down, and
// on<Event> handlers hear what the run emits. It drives the whole flow through the Run and Ui
// services: main menu, playing, pause, settings, and the two end-of-level screens.
//
// Screens are authored UI documents pushed by guid; their id-tagged buttons are wired to handlers
// with OnClick. The playing level is a scene loaded with Run.LoadScene.
//
// Asset guids are spelled out as strings: they MUST match the assets' guids, and a malformed one
// parses to nil and loads nothing.

// --- authored asset guids (keep in sync with the assets) ---
Guid kMainMenuDoc = Guid::FromString("7d0bf2b9-158e-824e-89e6-a3b255cdf445");     // UI/main-menu
Guid kPauseDoc = Guid::FromString("0a72c75e-d7c1-fc45-8165-f9d3803ae103");        // UI/pause
Guid kSettingsDoc = Guid::FromString("20ad8078-f904-7f4a-b127-ad304f2f7cea");     // UI/settings
Guid kLevelClearedDoc = Guid::FromString("cd92506a-c420-904f-8b02-bf38237e4a85"); // UI/level-cleared
Guid kLevelFailedDoc = Guid::FromString("a8ae2a62-37bb-d14e-828e-60ce7fe177a1");  // UI/level-failed
Guid kHudDoc = Guid::FromString("76d478c5-a2d3-484b-9c95-6f495a25a547");          // UI/hud (overlay)
Guid kPlayingLevel = Guid::FromString("1ddb81a9-06fa-f64c-94c1-4dfdb2002a78");    // Scenes/MainScene

enum GameState
{
	Booting,
	MainMenu,
	Playing,
	Paused,
	Settings,
	LevelCleared,
	LevelFailed
}

class Game
{
	private GameState m_state = GameState::Booting;
	// Where Back returns from Settings, which opens from both the main menu and pause.
	private GameState m_settingsReturn = GameState::MainMenu;

	private int m_score = 0;
	private int m_deliveries = 0;

	// ---- lifecycle ----
	void launch()
	{
		// Straight into the main menu. No scene is loaded yet: the Game owns level loading, and
		// does it when the player hits New Game.
		showMainMenu();
	}

	void update(float dt)
	{
		// ESC toggles pause, read through the "Pause" action of the input map.
		if (Input.WasPressed("Pause"))
		{
			if (m_state == GameState::Playing)
			{
				showPause();
			}
			else if (m_state == GameState::Paused)
			{
				onResume();
			}
		}
	}

	void exit()
	{
		Ui.Clear();
	}

	// ---- screens: each clears or stacks one document, then wires its buttons ----
	void showMainMenu()
	{
		Run.TimeScale = 0.0f; // no gameplay behind a menu
		Ui.Clear();
		Screen menu = Ui.Push(kMainMenuDoc);
		menu.FindButton("start-btn").OnClick(ScriptCallback(this.onStartGame));
		menu.FindButton("settings-btn").OnClick(ScriptCallback(this.onOpenSettingsFromMenu));
		menu.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuitGame));
		m_state = GameState::MainMenu;
	}

	void enterPlaying()
	{
		// A fresh score, then the HUD goes up BEFORE the scene starts, so the Level's and the
		// Bike's onStart find its labels to fill. The HUD is an overlay screen: input passes
		// through it to the bike.
		m_score = 0;
		m_deliveries = 0;
		Ui.Clear();
		Ui.Push(kHudDoc);
		Run.LoadScene(kPlayingLevel);
		Run.TimeScale = 1.0f;
		m_state = GameState::Playing;
	}

	void showPause()
	{
		// Pause OVERLAYS the running scene, and a zero time scale freezes it underneath.
		Run.TimeScale = 0.0f;
		Screen pause = Ui.Push(kPauseDoc);
		pause.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		pause.FindButton("settings-btn").OnClick(ScriptCallback(this.onOpenSettingsFromPause));
		pause.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuitToMenu));
		m_state = GameState::Paused;
	}

	void showSettings()
	{
		Screen settings = Ui.Push(kSettingsDoc);
		settings.FindButton("back-btn").OnClick(ScriptCallback(this.onSettingsBack));
		m_state = GameState::Settings;
	}

	// ---- button handlers ----
	void onStartGame() { enterPlaying(); }
	void onQuitGame() { Run.RequestExit(); }

	void onResume()
	{
		Ui.Pop(); // drop the pause overlay
		Run.TimeScale = 1.0f;
		m_state = GameState::Playing;
	}

	void onQuitToMenu() { showMainMenu(); }

	void onOpenSettingsFromMenu()
	{
		m_settingsReturn = GameState::MainMenu;
		showSettings();
	}

	void onOpenSettingsFromPause()
	{
		m_settingsReturn = GameState::Paused;
		showSettings();
	}

	void onSettingsBack()
	{
		if (m_settingsReturn == GameState::Paused)
		{
			Ui.Pop(); // settings sat over the pause overlay
			m_state = GameState::Paused;
		}
		else
		{
			showMainMenu();
		}
	}

	// ---- run events ----
	// A delivery arrived (Subscriber emits the house's points).
	void onDelivered(int points)
	{
		if (m_state != GameState::Playing)
		{
			return;
		}
		m_deliveries += 1;
		m_score += points;
		Print("Delivered");
	}

	// The Level met its quota.
	void onQuotaMet(int deliveries)
	{
		if (m_state != GameState::Playing)
		{
			return;
		}
		showLevelCleared();
	}

	// The Level failed, and says why: 0 is out of time, 1 is out of papers.
	void onLevelFailed(int reason)
	{
		if (m_state != GameState::Playing)
		{
			return;
		}
		showLevelFailed(reason);
	}

	// ---- end of level: a modal over the frozen scene, with the score ----
	void showLevelCleared()
	{
		Run.TimeScale = 0.0f;
		Screen s = Ui.Push(kLevelClearedDoc);
		s.FindLabel("summary").SetText("Delivered " + m_deliveries + " papers    Score " + m_score);
		s.FindButton("play-again-btn").OnClick(ScriptCallback(this.onPlayAgain));
		s.FindButton("menu-btn").OnClick(ScriptCallback(this.onBackToMenu));
		m_state = GameState::LevelCleared;
	}

	void showLevelFailed(int reason)
	{
		Run.TimeScale = 0.0f;
		Screen s = Ui.Push(kLevelFailedDoc);
		s.FindLabel("title").SetText(reason == 1 ? "Out of Papers!" : "Time's Up!");
		s.FindLabel("summary").SetText("Delivered " + m_deliveries + " papers    Score " + m_score);
		s.FindButton("retry-btn").OnClick(ScriptCallback(this.onPlayAgain));
		s.FindButton("menu-btn").OnClick(ScriptCallback(this.onBackToMenu));
		m_state = GameState::LevelFailed;
	}

	void onPlayAgain() { enterPlaying(); }
	void onBackToMenu() { showMainMenu(); }
}
