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
Guid kTitleDoc = Guid::FromString("d59c6b8f-b594-774f-9a6f-44f4b0f1676c");
Guid kHudDoc = Guid::FromString("4ed6efac-4b9f-0d48-b2c3-a98756b51b68");
Guid kPauseDoc = Guid::FromString("5a4eb994-1e3c-464b-89da-8ff682ce56fc");
Guid kResultsDoc = Guid::FromString("d6c7ffc6-d95b-884c-9b20-ecc9ef5dc882");
Guid kPalace = Guid::FromString("9f75a606-4c88-6646-8c10-0f79b1ec6760");
Guid kCanal = Guid::FromString("1ee1e11f-2825-0d4d-8e7a-71f2e7f7b797");
Guid kGardens = Guid::FromString("4b1f85c8-28ad-ed4a-bb1c-83fbab825359");

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
		Ui.Clear();
		Screen s = Ui.Push(kTitleDoc);
		s.FindButton("play-btn").OnClick(ScriptCallback(this.onPalace));
		s.FindButton("canal-btn").OnClick(ScriptCallback(this.onCanal));
		s.FindButton("solo-btn").OnClick(ScriptCallback(this.onSolo));
		s.FindButton("host-btn").OnClick(ScriptCallback(this.onHost));
		s.FindButton("join-btn").OnClick(ScriptCallback(this.onJoin));
		s.FindLabel("map-choice").SetText("The map: " + mapTitle(m_map));
		s.FindLabel("net-status").SetText("");
		s.FindButton("canal-btn").SetEnabled(!kCanal.IsNil);
		s.FindButton("gardens-btn").OnClick(ScriptCallback(this.onGardens));
		s.FindButton("gardens-btn").SetEnabled(!kGardens.IsNil);
		s.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuit));
		s.FindLabel("palace-best").SetText(bestLine(0));
		s.FindLabel("canal-best").SetText(bestLine(1));
		s.FindLabel("gardens-best").SetText(bestLine(2));
	}

	private void onPalace() { choose(0); }
	private void onCanal() { choose(1); }
	private void onGardens() { choose(2); }

	private void choose(int map)
	{
		m_map = map;
		Ui.FindLabel("map-choice").SetText("The map: " + mapTitle(map));
	}

	private string mapTitle(int map)
	{
		return map == 0 ? "the Palace" : (map == 1 ? "the Canal" : "the Gardens");
	}

	private void onSolo()
	{
		m_mode = kAlone;
		startRound();
	}

	private void onHost()
	{
		if (!Net.StartServer(kPort))
		{
			Ui.FindLabel("net-status").SetText("Could not host on port " + kPort);
			return;
		}
		m_mode = kHosting;
		startRound();
	}

	private void onJoin()
	{
		TextBox box = Ui.FindTextBox("address");
		m_address = (box.IsValid && box.Text.length() > 0) ? box.Text : "127.0.0.1";
		m_mode = kJoining;
		startRound();
		m_connectIn = 0.2f; // once the map has loaded
	}

	private string mapName(int map) { return map == 0 ? "Palace" : (map == 1 ? "Canal" : "Gardens"); }

	private string bestLine(int map)
	{
		int best = Save.GetInt("best." + mapName(map), -100000);
		return best == -100000 ? "No round played yet" : "Best round: " + best + " points";
	}

	private void onQuit() { Run.RequestExit(0); }

	// ---- a round ----
	private void startRound()
	{
		m_paused = false;
		m_inRound = true;
		m_note = 0.0f;
		Ui.Clear();
		Ui.Push(kHudDoc);
		Ui.FindLabel("hud-target").SetText("");
		Ui.FindLabel("hud-score").SetText("Points 0");
		View controls = Ui.Find("hud-controls");
		controls.SetVisible(true);
		controls.SetOpacity(0.0f);
		controls.FadeTo(1.0f, 0.3f);
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
				onResume();
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
				Ui.Find("hud-controls").FadeTo(0.0f, 0.6f);
		}
		if (m_note > 0.0f)
		{
			m_note -= dt;
			if (m_note <= 0.0f)
				Ui.Find("hud-note").FadeTo(0.0f, 0.5f);
		}
	}

	// ---- what the round reports ----
	void onHud(Float4 hud)
	{
		if (!m_inRound)
			return;
		Ui.FindLabel("hud-target").SetText("Your mark wears " + costumeName(int(hud.Z)));
		Ui.FindLabel("hud-score").SetText("Points " + int(hud.X));
		Ui.FindLabel("hud-time").SetText(clock(hud.Y));
		Ui.FindLabel("hud-rank").SetText(place(int(hud.W)) + " of 4");
	}

	void onNote(int what)
	{
		if (!m_inRound)
			return;
		if (what == kGameNoteGotTarget)
			note("Your mark is tagged. They will be back, dressed anew");
		else if (what == kGameNoteMissed)
			note("Wrong guest! Your mask flares");
		else if (what == kGameNoteTagged)
			note("Tagged! A new costume, somewhere else");
		else if (what == kGameNoteFlare)
			note("A mask flares: a hunter, there");
		else if (what == kGameNoteWrongMap)
			note("The host is at another map: choose it and join again");
		else if (what == kGameNoteFull)
			note("Every seat is taken: you are watching");
	}

	void onRoundOver(Float4 scores)
	{
		if (!m_inRound)
			return;
		m_inRound = false;
		holdStill();
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
		Screen s = Ui.Push(kResultsDoc);
		s.FindLabel("res-title").SetText(rank == 1 ? "The ball is yours" : "The music stops");
		s.FindLabel("res-you").SetText("You came " + place(rank) + " with " + you + " points");
		s.FindLabel("res-0").SetText("You        " + you);
		s.FindLabel("res-1").SetText("Hunter 1   " + int(scores.Y));
		s.FindLabel("res-2").SetText("Hunter 2   " + int(scores.Z));
		s.FindLabel("res-3").SetText("Hunter 3   " + int(scores.W));
		s.FindLabel("res-best").SetText(record ? "Your best round yet" : "Your best: " + best + " points");
		s.FindButton("again-btn").OnClick(ScriptCallback(this.onAgain));
		s.FindButton("again-btn").SetVisible(m_mode != kJoining); // the host starts the next round
		s.FindButton("title-btn").OnClick(ScriptCallback(this.onTitle));
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
		Ui.Find("hud-controls").SetVisible(false); // the menu shows them itself
		Screen s = Ui.Push(kPauseDoc);
		s.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		s.FindButton("restart-btn").OnClick(ScriptCallback(this.onAgain));
		s.FindButton("restart-btn").SetVisible(m_mode != kJoining); // the host's to start over
		s.FindButton("title-btn").OnClick(ScriptCallback(this.onTitle));
	}

	private void onResume()
	{
		if (!m_paused)
			return;
		m_paused = false;
		Ui.Pop();
		letGo();
	}

	// Another round: alone, the map afresh; hosting, the same scene goes on (the players' hunters
	// with it) and the Ball starts over ("Restart").
	private void onAgain()
	{
		if (m_mode == kHosting)
		{
			enterRound();
			Run.Emit("Restart", 0); // Ball.as starts over
			return;
		}
		startRound();
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
		Ui.Clear();
		Ui.Push(kHudDoc);
		m_inRound = true;
		m_paused = false;
		m_note = 0.0f;
		letGo();
	}

	private void onTitle()
	{
		if (m_mode != kAlone)
		{
			Net.Disconnect();
			m_mode = kAlone;
		}
		m_connectIn = -1.0f;
		showTitle();
	}

	private void note(string text)
	{
		Label label = Ui.FindLabel("hud-note");
		label.SetText(text);
		label.SetOpacity(1.0f);
		label.SetVisible(true);
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
