// Masquerade - the game's orchestrator (the reserved class Game): the title, a round at the ball
// under its HUD, the pause menu, and the results.
//
// The title offers play alone, host, join or quit; the first two choose a map (Maps), then play it
// alone or host it (the server on `kPort`, waiting for each joiner's ready, then the map); or joins
// a host: the connection first, from the title, then the host's map (named in its welcome) loads,
// and the joiner says it is ready, so the map's networked entities are in place for the host's
// first snapshot. The round itself is the scene's (Ball.as): this hears it. "InReach" (someone to
// tag in front of you, or no longer), "HunterNear" (the hunter whose mark you are, near, or no
// longer), "Hud" (four times a second: your points, the seconds left, your target's costume, your
// place), "Note" (something happened to you, or a mask flared), "RoundOver" (everyone's points) and
// "RoundStart" (the host began another round). Pause (Escape or Start) shows the pause menu,
// holding the round still when playing alone (a networked round goes on). The title picks the map;
// the save keeps each map's best round ("best.Palace", "best.Canal", "best.Gardens").
//
// The game compiles into the run's one module with the behaviours, so its own names for Ball.as's
// notes carry the game's name.

const float kControlsShown = 7.0f; // how long the controls show as a round starts (s)
// The screens, on the engine GUI's screen stack (pushed by their documents' ids).
const string kTitleDoc = "{476521d2-c645-7b45-9047-d276ed406b3c}";
const string kMapsDoc = "{625415a9-2561-2245-8b31-9312518bb7de}";
const string kJoinDoc = "{bb3b6bce-e2d1-214d-b6af-da38adc2842b}";
const string kControlsDoc = "{5b9f9c58-643b-7c44-91b1-002b1aa7dbb3}";
// Each costume's portrait (Tools/portraits.py), in the costumes' order (rose, teal and gold gowns,
// black, plum and ivory coats), as the HUD's Image takes a texture: "{id}".
array<string> kPortraits = {"{945248b7-f0f2-ce41-99cf-1747ad8b2660}", "{c05268f7-d4d7-b445-a07f-be5ed42cd7fa}",
                            "{20815dca-35ab-a34d-b010-f24c7e118938}", "{0ce689e3-b625-de43-8b2b-f32369887966}",
                            "{87083e18-ffd5-3b4d-bcca-088c15c5be36}", "{e606123c-613d-e145-8c54-002ac4650e8e}"};
const float kLateSeconds = 30.0f; // the clock warms for the round's last half minute
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
const int kGameNoteFull = 6;
const int kPort = 7777;
const int kAlone = 0;
const float kJoinSeconds = 8.0f; // how long a joiner waits for the host's welcome
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
	private float m_delta = 0.0f;        // how long the points' change shows yet
	private int m_shownScore = 0;        // the points the HUD shows
	private int m_shownCostume = -1;     // the mark whose portrait the HUD shows
	private bool m_late = false;         // the clock in the round's last half minute
	private float m_roundSeconds = 0.0f; // the round's length, as its first report gave the time
	private bool m_inputHeld = false;    // the "Menu" set pushed (holdInput)
	private float m_controlsShow = 0.0f; // how long the controls panel shows yet
	private bool m_onTitle = false;      // the title (or a page over it) is up: the camera sweeps before the dais
	private int m_map = 0;               // 0 the Palace, 1 the Canal, 2 the Gardens
	private int m_mode = kAlone;
	private string m_address = "127.0.0.1";
	private float m_readyIn = -1.0f;     // a joiner: until it tells the host it is ready, once the host's map has loaded
	private float m_joinWait = -1.0f;    // a joiner on the title: how long until it gives up on the host

	void launch()
	{
		// A joiner hears the host's map in its welcome (Ball.as's onJoined), here rather than in a
		// scene's behaviour, as it arrives while the title's scene is the one loaded.
		Net.OnText("map", NetTextHandler(this.onHostMap));
		showTitle();
	}

	// ---- the title ----
	private void showTitle()
	{
		m_inRound = false;
		m_onTitle = true;
		m_paused = false;
		m_controlsOpen = false; // the stack is cleared below
		Run.TimeScale = 0.0f; // whatever is behind the title holds still
		holdInput();
		screens().Clear();
		screens().Push(kTitleDoc);
		wire("solo-btn", EventHandler(this.onSolo));
		wire("host-btn", EventHandler(this.onHost));
		if (!Net.CanHost)
			UIWidget::Of(find("host-btn")).AddClass("gone"); // a browser cannot host; it joins a host's ball
		wire("join-btn", EventHandler(this.onJoin));
		wire("controls-btn", EventHandler(this.onControls));
		wire("quit-btn", EventHandler(this.onQuit));
	}

	// ---- the controls page, over the title or the pause menu ----
	private bool m_controlsOpen = false;

	private bool onControls(GuiEvent@ e)
	{
		sound(kClick);
		screens().Push(kControlsDoc);
		wire("controls-back", EventHandler(this.onControlsBack));
		m_controlsOpen = true;
		return true;
	}

	private bool onControlsBack(GuiEvent@ e)
	{
		closeControls();
		return true;
	}

	// Its Back, or the game's Pause (Escape, Start): the screen stack's own back would also reach
	// the pause menu under it, as Escape is the game's Pause too.
	private void closeControls()
	{
		if (!m_controlsOpen)
			return;
		sound(kClick);
		m_controlsOpen = false;
		screens().Pop();
	}

	// ---- the map, to play alone or to host: a card each, the chosen one lit, then Start ----
	private bool m_hostChosen = false; // the map page's Start hosts (else it plays alone)

	private void showMaps(bool host)
	{
		m_hostChosen = host;
		screens().Push(kMapsDoc);
		setText("maps-heading", host ? "Host a ball" : "Play alone");
		Button::Of(find("maps-start")).Text = host ? "Host" : "Play";
		wire("map-0", EventHandler(this.onMap0));
		wire("map-1", EventHandler(this.onMap1));
		wire("map-2", EventHandler(this.onMap2));
		find("map-1").Enabled = !kCanal.IsNil;
		find("map-2").Enabled = !kGardens.IsNil;
		for (int map = 0; map < 3; ++map)
			setText("map-best-" + map, bestLine(map));
		wire("maps-start", EventHandler(this.onStart));
		wire("maps-back", EventHandler(this.onBack));
		setText("net-status", "");
		choose(m_map, false);
	}

	private bool onMap0(GuiEvent@ e) { choose(0, true); return true; }
	private bool onMap1(GuiEvent@ e) { choose(1, true); return true; }
	private bool onMap2(GuiEvent@ e) { choose(2, true); return true; }

	// The chosen card lit; a click on it chooses, Start then plays or hosts it.
	private void choose(int map, bool click)
	{
		if (click)
			sound(kClick);
		m_map = map;
		for (int i = 0; i < 3; ++i)
		{
			UIWidget@ card = UIWidget::Of(find("map-" + i));
			if (i == map)
				card.AddClass("chosen");
			else
				card.RemoveClass("chosen");
		}
	}

	private bool onBack(GuiEvent@ e)
	{
		sound(kClick);
		screens().Pop();
		return true;
	}

	private string mapTitle(int map)
	{
		return map == 0 ? "the Palace" : (map == 1 ? "the Canal" : "the Gardens");
	}

	private bool onSolo(GuiEvent@ e)
	{
		sound(kClick);
		showMaps(false);
		return true;
	}

	private bool onHost(GuiEvent@ e)
	{
		sound(kClick);
		showMaps(true);
		return true;
	}

	// The map page's Start: play the chosen map alone, or host it.
	private bool onStart(GuiEvent@ e)
	{
		sound(kClick);
		if (!m_hostChosen)
		{
			m_mode = kAlone;
			startRound();
			return true;
		}
		if (!Net.StartServer(kPort))
		{
			setText("net-status", "Could not host on port " + kPort);
			return true;
		}
		m_mode = kHosting;
		Net.WaitForReady(true); // a joiner hears no state until it has loaded this map
		startRound();
		return true;
	}

	// ---- joining: the address, then Join; the map is the host's ----
	private bool onJoin(GuiEvent@ e)
	{
		sound(kClick);
		screens().Push(kJoinDoc);
		TextField::Of(find("address")).Text = m_address;
		wire("join-go", EventHandler(this.onJoinGo));
		wire("join-back", EventHandler(this.onBack));
		setText("net-status", "");
		return true;
	}

	private bool onJoinGo(GuiEvent@ e)
	{
		sound(kClick);
		if (m_joinWait >= 0.0f)
			return true; // already waiting for the host
		string typed = TextField::Of(find("address")).Text;
		m_address = typed.length() > 0 ? typed : "127.0.0.1";
		// Connect from the title; the host's welcome names its map, which then loads (onHostMap).
		if (!Net.Connect(m_address, kPort))
		{
			setText("net-status", "Could not reach " + m_address);
			return true;
		}
		m_mode = kJoining;
		m_joinWait = kJoinSeconds;
		setText("net-status", "Joining " + m_address + "...");
		return true;
	}

	// A joiner: the host's map. It loads, and once it is ready the host's state begins.
	void onHostMap(int sender, const string &in name)
	{
		if (!Net.IsClient || m_mode != kJoining || m_joinWait < 0.0f)
			return;
		m_joinWait = -1.0f;
		m_map = name == "Canal" ? 1 : (name == "Gardens" ? 2 : 0);
		setText("net-status", "Joining " + mapTitle(m_map) + "...");
		startRound();
		m_readyIn = 0.2f; // once the map has loaded, a moment more for its first frame
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
		leaveTitle();
		m_paused = false;
		m_inRound = true;
		m_note = 0.0f;
		screens().Clear();
		screens().Push(kHudDoc);
		setText("hud-target", "");
		setText("hud-score", "0");
		m_shownScore = 0;
		m_shownCostume = -1;
		m_roundSeconds = 0.0f;
		m_late = false;
		find("hud-controls").Tween("opacity", "1", 0.3f, "ease"); // from the sheet's 0
		m_controlsShow = kControlsShown;
		letGo(); // time again, and the player's input: a round may start from any menu
		Run.LoadScene(m_map == 0 ? kPalace : (m_map == 1 ? kCanal : kGardens));
	}

	// The camera back behind the player (CameraRig) as the title gives way to a round.
	private void leaveTitle()
	{
		if (m_onTitle)
		{
			m_onTitle = false;
			Run.Emit("TitleView", -1.0f);
		}
	}

	void update(float dt)
	{
		if (m_controlsOpen && Input.WasPressed("Pause"))
		{
			closeControls();
			return;
		}
		// A joiner on the title, waiting for the host's welcome.
		if (m_joinWait >= 0.0f)
		{
			m_joinWait -= dt;
			if (m_joinWait < 0.0f)
			{
				Net.Disconnect();
				m_mode = kAlone;
				setText("net-status", "Could not reach " + m_address);
			}
		}
		if (!m_inRound)
		{
			if (m_onTitle)
				Run.Emit("TitleView", dt); // CameraRig sweeps before the dais
			return;
		}
		if (m_readyIn >= 0.0f && Run.SceneReady)
		{
			m_readyIn -= dt;
			if (m_readyIn < 0.0f)
				Net.Ready();
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
		if (m_delta > 0.0f)
		{
			m_delta -= dt;
			if (m_delta <= 0.0f)
				find("hud-delta").Tween("opacity", "0", 0.6f, "ease");
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
		// Only as the mark changes: setting the picture again would load it again, blank meanwhile.
		if (costume != m_shownCostume && costume >= 0 && costume < int(kPortraits.length()))
		{
			m_shownCostume = costume;
			Image::Of(find("hud-portrait")).Source = kPortraits[costume];
		}
		// The points, and each change floating beside them a moment, gold up, red down.
		int score = int(hud.X);
		if (score != m_shownScore)
		{
			int change = score - m_shownScore;
			m_shownScore = score;
			setText("hud-score", "" + score);
			setText("hud-delta", (change > 0 ? "+" : "") + change);
			UIWidget@ delta = UIWidget::Of(find("hud-delta"));
			delta.RemoveClass(change > 0 ? "loss" : "gain");
			delta.AddClass(change > 0 ? "gain" : "loss");
			find("hud-delta").Tween("opacity", "1", 0.15f, "ease");
			m_delta = 1.4f;
		}
		// The time over a bar of the round left (the round's length: the first time it reports).
		m_roundSeconds = Max(m_roundSeconds, hud.Y);
		setText("hud-time", clock(hud.Y));
		ProgressBar::Of(find("hud-timebar")).Value = m_roundSeconds > 0.0f ? hud.Y / m_roundSeconds : 0.0f;
		// Only as it changes: the class set again each report would start its pulse over.
		bool late = hud.Y <= kLateSeconds && hud.Y > 0.0f;
		if (late != m_late)
		{
			m_late = late;
			UIWidget@ clockCard = UIWidget::Of(find("hud-clock"));
			if (late)
				clockCard.AddClass("late");
			else
				clockCard.RemoveClass("late");
		}
		setText("hud-rank", place(int(hud.W)) + " of 4");
	}

	// The hunter whose mark you are, near (Ball.as): a quiet line under your mark while it is.
	void onHunterNear(int yes)
	{
		if (m_inRound)
			find("hud-near").Tween("opacity", yes != 0 ? "1" : "0", yes != 0 ? 0.3f : 0.8f, "ease");
	}

	// Someone to tag in front of you (Ball.as): Tag's prompt shows by your hunter's line of sight.
	void onInReach(int yes)
	{
		if (m_inRound)
			find("hud-tag").Tween("opacity", yes != 0 ? "1" : "0", 0.15f, "ease");
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
		// Every hunter by points, the most first (yours first among equals), your row lit.
		array<string> names = {"You", "Hunter 1", "Hunter 2", "Hunter 3"};
		array<int> points = {you, int(scores.Y), int(scores.Z), int(scores.W)};
		array<int> order = {0, 1, 2, 3};
		for (int i = 1; i < 4; ++i)
		{
			for (int j = i; j > 0 && points[order[j]] > points[order[j - 1]]; --j)
			{
				int t = order[j];
				order[j] = order[j - 1];
				order[j - 1] = t;
			}
		}
		for (int row = 0; row < 4; ++row)
		{
			int who = order[row];
			setText("rank-place-" + row, place(row + 1));
			setText("rank-name-" + row, names[who]);
			setText("rank-points-" + row, "" + points[who]);
			UIWidget@ line = UIWidget::Of(find("rank-" + row));
			if (who == 0)
				line.AddClass("you");
			else
				line.RemoveClass("you");
		}
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
		wire("pause-controls-btn", EventHandler(this.onControls));
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

	// Under any menu the player's actions read released: the input map's "Menu" set (Pause alone)
	// is pushed as the only one in effect, and a press already held when it opens or closes stays
	// latched until let go, so the press that works a menu's button is never a Tag. Once, however
	// many menus ask.
	private void holdInput()
	{
		if (!m_inputHeld)
		{
			Input.PushSet("Menu");
			m_inputHeld = true;
		}
	}

	private void releaseInput()
	{
		if (m_inputHeld)
		{
			Input.PopSet();
			m_inputHeld = false;
		}
	}

	// Alone, the scene stops behind a menu too. In a networked round it goes on (the host runs
	// the world for everyone, and a joiner's scene must keep hearing the host: a new round, say).
	private void holdStill()
	{
		holdInput();
		if (m_mode == kAlone)
			Run.TimeScale = 0.0f;
	}

	private void letGo()
	{
		Run.TimeScale = 1.0f;
		releaseInput();
	}

	// The HUD over the scene that is already running.
	private void enterRound()
	{
		leaveTitle();
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
		m_readyIn = -1.0f;
		m_joinWait = -1.0f;
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
