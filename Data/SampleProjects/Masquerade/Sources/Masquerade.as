// Masquerade - the game's orchestrator (the reserved class Game): the title, a round at the ball
// under its HUD, the pause menu, and the results.
//
// The title picks a map, then plays it alone, hosts it (the server on `kPort`, then the map) or
// joins a host (the map first, then the connection, so the map's networked entities are in place
// for the host's first snapshot). The round itself is the scene's (Ball.as): this hears it. "Hud"
// (four times a second: your points, the seconds left, your target's costume, your place), "Note"
// (something happened to you, or a mask flared), "RoundOver" (everyone's points) and "RoundStart"
// (the host began another round). Pause (Escape or Start) shows the pause menu, holding the round
// still when playing alone (a networked round goes on). The title picks the map; the save keeps
// each map's best round ("best.Palace", "best.Canal", "best.Gardens").
//
// The game compiles into the run's one module with the behaviours, so its own names for Ball.as's
// notes carry the game's name.

const float kControlsShown = 7.0f; // how long the controls show as a round starts (s)
// The screens, on the engine GUI's screen stack (pushed by their documents' ids).
const string kTitleDoc = "{476521d2-c645-7b45-9047-d276ed406b3c}";
const string kHudDoc = "{17588a14-e4fa-d84b-aa8d-e694112dcfec}";
const string kPauseDoc = "{7c0427df-ebc1-5b44-b3ca-59e7665a9d7d}";
const string kResultsDoc = "{d57cac1f-5cf9-af40-99a7-8d600b9d0424}";
Guid kPalace = Guid::FromString("9f75a606-4c88-6646-8c10-0f79b1ec6760");
Guid kCanal = Guid::FromString("1ee1e11f-2825-0d4d-8e7a-71f2e7f7b797");
Guid kGardens = Guid::FromString("4b1f85c8-28ad-ed4a-bb1c-83fbab825359");
// sounds.py's: what the round says to the player, and the buttons.
Guid kTagSound = Guid::FromString("2dfbc8dd-48c8-6b43-af44-b28b868fb846");
Guid kMissSound = Guid::FromString("2fb079ad-e813-2347-b18b-340c653452d7");
Guid kFlareSound = Guid::FromString("d71ba43c-28b2-9c4f-992b-c9b6d6a33789");
Guid kChimeSound = Guid::FromString("e3f71e41-2fd3-2b4b-96a2-4c556549fadd");
Guid kFanfare = Guid::FromString("2b90c687-05c3-7243-8fbe-b2fd4ec41c82");
Guid kClick = Guid::FromString("d778e0c8-c359-f042-b872-894ef2584857");

// Ball.as's notes.
const int kGameNoteGotTarget = 1;
const int kGameNoteMissed = 2;
const int kGameNoteTagged = 3;
const int kGameNoteFlare = 4;
const int kGameNoteWrongMap = 5;
const int kGameNoteFull = 6;
const int kPort = 7777;
const int kAlone = 0;
const int kHosting = 1;
const int kJoining = 2;

// The GUI's screen stack, and a node of the screens by its id.
ScreenStack@ screens() { return ScreenStack::Of(Gui.Root().Find("screens")); }
// The top screen first: one just cleared or popped away is still in the tree while its exit plays,
// with the same ids, and would be found first.
Node@ find(string id)
{
	Screen@ top = screens().Top;
	Node@ n = top !is null ? top.Find(id) : null;
	return n !is null ? n : Gui.Root().Find(id);
}
void wire(string id, EventHandler@ handler) { find(id).On("click", handler); } // `on*` names are the engine's handlers
void setText(string id, string text) { Label::Of(find(id)).Text = text; }

class Game
{
	private bool m_inRound = false;
	private bool m_paused = false;
	private float m_note = 0.0f;         // how long the HUD's word shows yet
	private float m_controlsShow = 0.0f; // how long the controls panel shows yet
	private int m_map = 0;               // 0 the Palace, 1 the Canal, 2 the Gardens
	private int m_mode = kAlone;
	private string m_address = "127.0.0.1";
	private float m_connectIn = -1.0f;   // a joiner: until it connects, once its map has loaded

	void launch()
	{
		showTitle();
	}

	// ---- the title ----
	private void showTitle()
	{
		m_inRound = false;
		m_paused = false;
		Run.TimeScale = 0.0f; // whatever is behind the title holds still
		screens().Clear();
		screens().Push(kTitleDoc);
		wire("play-btn", EventHandler(this.onPalace));
		wire("canal-btn", EventHandler(this.onCanal));
		wire("solo-btn", EventHandler(this.onSolo));
		wire("host-btn", EventHandler(this.onHost));
		wire("join-btn", EventHandler(this.onJoin));
		setText("map-choice", "The map: " + mapTitle(m_map));
		setText("net-status", "");
		find("canal-btn").Enabled = !kCanal.IsNil;
		wire("gardens-btn", EventHandler(this.onGardens));
		find("gardens-btn").Enabled = !kGardens.IsNil;
		wire("quit-btn", EventHandler(this.onQuit));
		setText("palace-best", bestLine(0));
		setText("canal-best", bestLine(1));
		setText("gardens-best", bestLine(2));
	}

	private bool onPalace(GuiEvent@ e) { choose(0); return true; }
	private bool onCanal(GuiEvent@ e) { choose(1); return true; }
	private bool onGardens(GuiEvent@ e) { choose(2); return true; }

	private void choose(int map)
	{
		sound(kClick);
		m_map = map;
		setText("map-choice", "The map: " + mapTitle(map));
	}

	private string mapTitle(int map)
	{
		return map == 0 ? "the Palace" : (map == 1 ? "the Canal" : "the Gardens");
	}

	private bool onSolo(GuiEvent@ e)
	{
		sound(kClick);
		m_mode = kAlone;
		startRound();
		return true;
	}

	private bool onHost(GuiEvent@ e)
	{
		sound(kClick);
		if (!Net.StartServer(kPort))
		{
			setText("net-status", "Could not host on port " + kPort);
			return true;
		}
		m_mode = kHosting;
		startRound();
		return true;
	}

	private bool onJoin(GuiEvent@ e)
	{
		sound(kClick);
		string typed = TextField::Of(find("address")).Text;
		m_address = typed.length() > 0 ? typed : "127.0.0.1";
		m_mode = kJoining;
		startRound();
		m_connectIn = 0.2f; // once the map has loaded
		return true;
	}

	private string mapName(int map) { return map == 0 ? "Palace" : (map == 1 ? "Canal" : "Gardens"); }

	private string bestLine(int map)
	{
		int best = Save.GetInt("best." + mapName(map), -100000);
		return best == -100000 ? "No round played yet" : "Best round: " + best + " points";
	}

	private bool onQuit(GuiEvent@ e)
	{
		sound(kClick);
		Run.RequestExit(0);
		return true;
	}

	// ---- a round ----
	private void startRound()
	{
		m_paused = false;
		m_inRound = true;
		m_note = 0.0f;
		screens().Clear();
		screens().Push(kHudDoc);
		setText("hud-target", "");
		setText("hud-score", "Points 0");
		find("hud-controls").Tween("opacity", "1", 0.3f, "ease"); // from the sheet's 0
		m_controlsShow = kControlsShown;
		Run.TimeScale = 1.0f;
		Run.LoadScene(m_map == 0 ? kPalace : (m_map == 1 ? kCanal : kGardens));
	}

	void update(float dt)
	{
		if (!m_inRound)
			return;
		if (m_connectIn >= 0.0f && Run.SceneReady)
		{
			m_connectIn -= dt; // a moment more, for the scene's first frame
			if (m_connectIn < 0.0f && !Net.Connect(m_address, kPort))
				note("Could not reach " + m_address);
		}
		if (Input.WasPressed("Pause"))
		{
			if (m_paused)
				resume();
			else
				pause();
			return;
		}
		if (m_paused)
			return;
		if (m_controlsShow > 0.0f)
		{
			m_controlsShow -= dt;
			if (m_controlsShow <= 0.0f)
				find("hud-controls").Tween("opacity", "0", 0.6f, "ease");
		}
		if (m_note > 0.0f)
		{
			m_note -= dt;
			if (m_note <= 0.0f)
				find("hud-note").Tween("opacity", "0", 0.5f, "ease");
		}
	}

	// ---- what the round reports ----
	void onHud(Float4 hud)
	{
		if (!m_inRound)
			return;
		int costume = int(hud.Z);
		setText("hud-target", costumeName(costume));
		// In its colour: the sheet's class for the costume.
		UIWidget@ mark = UIWidget::Of(find("hud-target"));
		for (int c = 0; c < 6; ++c)
			mark.RemoveClass("costume-" + c);
		mark.AddClass("costume-" + costume);
		setText("hud-score", "Points " + int(hud.X));
		setText("hud-time", clock(hud.Y));
		setText("hud-rank", place(int(hud.W)) + " of 4");
	}

	void onNote(int what)
	{
		if (!m_inRound)
			return;
		if (what == kGameNoteGotTarget)
		{
			sound(kTagSound);
			note("Your mark is tagged. They will be back, dressed anew");
		}
		else if (what == kGameNoteMissed)
		{
			sound(kMissSound);
			note("Wrong guest! Your mask flares");
		}
		else if (what == kGameNoteTagged)
		{
			sound(kMissSound);
			note("Tagged! A new costume, somewhere else");
		}
		else if (what == kGameNoteFlare)
		{
			sound(kFlareSound);
			note("A mask flares: a hunter, there");
		}
		else if (what == kGameNoteWrongMap)
		{
			sound(kChimeSound);
			note("The host is at another map: choose it and join again");
		}
		else if (what == kGameNoteFull)
		{
			sound(kChimeSound);
			note("Every seat is taken: you are watching");
		}
	}

	void onRoundOver(Float4 scores)
	{
		if (!m_inRound)
			return;
		m_inRound = false;
		holdStill();
		sound(kFanfare);
		int you = int(scores.X);
		string key = "best." + mapName(m_map);
		int best = Save.GetInt(key, -100000);
		bool record = you > best;
		if (record)
		{
			Save.SetInt(key, you);
			Save.Flush();
		}
		int rank = 1;
		if (scores.Y > scores.X) ++rank;
		if (scores.Z > scores.X) ++rank;
		if (scores.W > scores.X) ++rank;
		screens().Push(kResultsDoc);
		setText("res-title", rank == 1 ? "The ball is yours" : "The music stops");
		setText("res-you", "You came " + place(rank) + " with " + you + " points");
		setText("res-0", "You        " + you);
		setText("res-1", "Hunter 1   " + int(scores.Y));
		setText("res-2", "Hunter 2   " + int(scores.Z));
		setText("res-3", "Hunter 3   " + int(scores.W));
		setText("res-best", record ? "Your best round yet" : "Your best: " + best + " points");
		wire("again-btn", EventHandler(this.onAgain));
		find("again-btn").Visible = m_mode != kJoining; // the host starts the next round
		wire("title-btn", EventHandler(this.onTitle));
	}

	// The host started another round in the same scene: a joiner leaves its results for it.
	void onRoundStart(int unused)
	{
		if (m_inRound || m_mode != kJoining)
			return;
		enterRound();
	}

	// ---- the pause menu ----
	private void pause()
	{
		m_paused = true;
		holdStill();
		m_controlsShow = 0.0f;
		find("hud-controls").Tween("opacity", "0", 0.0f, "ease"); // the menu shows them itself
		screens().Push(kPauseDoc);
		wire("resume-btn", EventHandler(this.onResume));
		wire("restart-btn", EventHandler(this.onAgain));
		find("restart-btn").Visible = m_mode != kJoining; // the host's to start over
		wire("title-btn", EventHandler(this.onTitle));
	}

	private bool onResume(GuiEvent@ e)
	{
		resume();
		return true;
	}

	private void resume()
	{
		if (!m_paused)
			return;
		m_paused = false;
		screens().Pop();
		sound(kClick);
		letGo();
	}

	// Another round: alone, the map afresh; hosting, the same scene goes on (the players' hunters
	// with it) and the Ball starts over ("Restart").
	private bool onAgain(GuiEvent@ e)
	{
		sound(kClick);
		if (m_mode == kHosting)
		{
			enterRound();
			Run.Emit("Restart", 0); // Ball.as starts over
			return true;
		}
		startRound();
		return true;
	}

	// Alone, the scene stops behind a menu. In a networked round it goes on (the host runs the
	// world for everyone, and a joiner's scene must keep hearing the host: a new round, say), so
	// the player hears "Menu" instead and stands still under it.
	private void holdStill()
	{
		if (m_mode == kAlone)
			Run.TimeScale = 0.0f;
		else
			Run.Emit("Menu", 1);
	}

	private void letGo()
	{
		Run.TimeScale = 1.0f;
		if (m_mode != kAlone)
			Run.Emit("Menu", 0);
	}

	// The HUD over the scene that is already running.
	private void enterRound()
	{
		screens().Clear();
		screens().Push(kHudDoc);
		m_inRound = true;
		m_paused = false;
		m_note = 0.0f;
		letGo();
	}

	private bool onTitle(GuiEvent@ e)
	{
		sound(kClick);
		if (m_mode != kAlone)
		{
			Net.Disconnect();
			m_mode = kAlone;
		}
		m_connectIn = -1.0f;
		showTitle();
		return true;
	}

	private void sound(Guid clip)
	{
		Audio.PlayOneShot(clip, AudioBus::Effects, 0.8f);
	}

	private void note(string text)
	{
		setText("hud-note", text);
		find("hud-note").Tween("opacity", "1", 0.15f, "ease"); // from the sheet's 0, or a fade going
		m_note = 3.0f;
	}

	// In blender/guest.py's costume order, which the crowd and the looks follow.
	private string costumeName(int costume)
	{
		if (costume == 0) return "a rose gown";
		if (costume == 1) return "a teal gown";
		if (costume == 2) return "a gold gown";
		if (costume == 3) return "a black coat";
		if (costume == 4) return "a plum coat";
		return "an ivory coat";
	}

	private string place(int p)
	{
		return p == 1 ? "1st" : (p == 2 ? "2nd" : (p == 3 ? "3rd" : "4th"));
	}

	private string clock(float seconds)
	{
		int s = int(seconds);
		int m = s / 60;
		s = s % 60;
		return m + ":" + (s < 10 ? "0" : "") + s;
	}
}
