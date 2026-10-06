// Snowline - the game's orchestrator (the reserved class Game): the title and its courses, and in
// a run the clock, the gates and their penalties, the gems, the tricks, the HUD, and the results.
//
// The title lists the courses with the best medal and time won on each (from the save); a course
// opens with a bronze on the one before it. Picking one loads its scene afresh. Pause (Escape or
// Start) in a run holds it still under the pause menu: Resume (or Pause, or Grab, B on a pad) rides
// on, Restart run starts it over, Courses goes back to the title. On the results, Pause goes back
// to the title.
//
// The gates announce themselves ("GateRegistered") and report each crossing ("GatePassed",
// "GateMissed": round the outside costs kMissPenalty seconds); the finish line holds the course's
// medal times ("MedalGold", "MedalSilver", "MedalBronze", in hundredths) and ends the run
// ("RunFinished"). The clock starts when the rider does ("RunStarted", from Board.as), with the
// medal ghosts, not while the scene is still coming in. The gems announce themselves too ("GemRegistered") and report being taken
// ("GemCollected"), each with how many it counts for. The board announces each trick as it lands
// ("TrickAir", "TrickSpin", "TrickGrab", then "TrickLanded"): a clean one scores its air, its half
// turns and its grab, times the combo, which a clean landing or a near miss past a tree
// ("NearMiss") raises and a crash ("RiderCrashed") or a missed gate ends. Clearing a crevasse
// ("GapCleared", from Gap.as) scores too and raises the combo. On a course with an avalanche, the
// HUD shows how far behind it is from the moment it breaks loose ("AvalancheReleased",
// "AvalancheGap"); catching the rider ("AvalancheCaught") is a crash, and it is spent.
//
// The results tally the run a row at a time (the ride, the gates, the gems, the tricks, the time
// bonus), then
// land the final time with the medal it earned, the score and the course's best. The best time and
// the best medal are kept in the save ("best.<scene>", "medal.<scene>"), and a run that beats the
// best is announced ("NewBest", in hundredths) so PlayerGhost.as keeps it as the course's ghost. Jump
// skips to the end, then starts the next run ("RunRestart" puts the rider back at the top, the
// gates back to waiting and the gems back in place).
//
// A run that wins a better medal on the last course (Ridge) than it had is followed by the ending:
// the best medal and time on every course, their total and the medals won. Jump from it goes back
// to the title.

Guid kHudDoc = Guid::FromString("d9bf0289-e31c-f14d-a647-26169f04e05a");    // UI/Hud
Guid kFinishDoc = Guid::FromString("8038f3db-396a-ce4c-a5ce-45329e0f9d34"); // UI/Finish
Guid kTitleDoc = Guid::FromString("0fd52a3d-d1ce-744d-bd5f-afbc2ab249f2");  // UI/Title
Guid kEndingDoc = Guid::FromString("f7d32a05-810a-2144-bad1-531d9f88fdbb"); // UI/Ending
Guid kPauseDoc = Guid::FromString("454e44ed-867b-224d-8a69-5f2f1d0f4cee");  // UI/Pause

// The courses, in order: each unlocked by a bronze on the one before it.
const int kCourseCount = 3;
Guid kMeadow = Guid::FromString("3bf5f9c4-b106-8e4a-b815-0cfd3bfabdf0"); // Scenes/Meadow
Guid kForest = Guid::FromString("7d1a37c1-3b59-b640-a61f-3928be5a2179"); // Scenes/Forest
Guid kRidge = Guid::FromString("44874676-6ba8-b84a-84d8-8fee02fef806"); // Scenes/Ridge

Guid courseScene(int i) { return i == 2 ? kRidge : (i == 1 ? kForest : kMeadow); }
string courseName(int i) { return i == 2 ? "Ridge" : (i == 1 ? "Forest" : "Meadow"); }

// Audio/GemChime (sounds.py): the tally's tick, pitched up row by row.
Guid kChime = Guid::FromString("64c88944-0a22-4e45-8af5-39858c0ada37");
// The rest of the game's sounds (sounds.py; CREDITS.md): the music on the title and in a run, a gate
// passed and missed, the menus' click and back, and the stings for a medal won or not.
Guid kMusicTitle = Guid::FromString("63a38c8d-9801-2d4f-bc6c-6d0edcf1b6fe"); // Audio/MusicTitle
Guid kMusicRun = Guid::FromString("2fabcfe4-fe0e-9c45-834d-425e928a8892");   // Audio/MusicRun
Guid kGatePass = Guid::FromString("36c2b160-0b76-8045-9951-b6b7d8f1f299");   // Audio/GatePass
Guid kGateMiss = Guid::FromString("19153965-5a29-6044-8bce-29e0c5a196ee");   // Audio/GateMiss
Guid kClick = Guid::FromString("df75216e-ec15-6342-b049-77fc8c92ae7b");      // Audio/Click
Guid kBack = Guid::FromString("c66c58dc-4f57-854f-a287-00e4b0c52e07");       // Audio/Back
Guid kMedalSting = Guid::FromString("20c7ac1f-31ea-ee4d-9584-fec06d7bcdc7"); // Audio/Medal
Guid kNoMedalSting = Guid::FromString("ac6923f0-a216-e64f-b42c-7159db62047f"); // Audio/NoMedal
const float kMusicVolume = 0.55f;

const float kMissPenalty = 2.0f;
const int kGemPoints = 100;       // a gem's worth
const int kBonusPerSecond = 100;  // each second under the bronze time
const int kTallySteps = 7;        // the five rows, then the final time and medal, then the score
const int kAirPoints = 200;       // a second in the air
const int kSpinPoints = 250;      // a half turn
const int kGrabPoints = 400;      // a second holding a grab
const int kComboMost = 5;         // the highest combo multiplier
const int kNearMissPoints = 100;  // a trunk passed close, fast
const int kGapPoints = 500;       // a crevasse cleared
const float kTrickShown = 1.6f;   // how long a landed trick shows (s)
const float kTallyFirst = 0.5f;   // the first row's moment after the finish (s)
const float kTallyGap = 0.45f;    // between the rows (s)
const float kControlsShown = 6.0f; // how long the controls show as a course starts (s)

class Game
{
	private bool m_onTitle = false; // the title is up: nothing runs behind it
	private bool m_onEnding = false; // the ending is up
	private bool m_endingDue = false; // this run won a better medal on the last course
	private bool m_paused = false;    // the pause menu is up over the run
	private Guid m_music;             // the track playing (nil for none)
	private bool m_running = true;
	private bool m_started = false; // the rider's first frame has come (the clock runs from it)
	private float m_time = 0.0f;    // seconds on the clock this run
	private float m_penalty = 0.0f; // seconds added for missed gates
	private int m_gates = 0;        // how many the course has
	private int m_passed = 0;
	private int m_missed = 0;
	private float m_flash = 0.0f;   // how long the "+2 s" shows yet
	private int m_gems = 0;         // how many the course has
	private int m_taken = 0;

	// Tricks: the one landing now (its parts as the board reports them), the combo, the points.
	private float m_trickAir = 0.0f;
	private int m_trickSpin = 0;
	private float m_trickGrab = 0.0f;
	private int m_combo = 1;
	private int m_tricks = 0;        // trick points this run
	private float m_trickShow = 0.0f; // how long the landed trick shows yet
	private float m_controlsShow = 0.0f; // how long the controls panel shows yet
	private bool m_caught = false;    // the avalanche has just caught the rider (its crash follows)

	// The course's medal times (s, penalties included), from the finish line.
	private float m_gold = 0.0f;
	private float m_silver = 0.0f;
	private float m_bronze = 0.0f;

	// The results: the tally's steps shown so far, the time since the finish, and the course's best
	// before this run (-1 for none).
	private int m_tallyStep = 0;
	private float m_tallyTime = 0.0f;
	private float m_previousBest = -1.0f;

	void launch()
	{
		showTitle();
	}

	// ---- the title: a course to ride, each with the best won on it, or what unlocks it ----
	private void showTitle()
	{
		m_onTitle = true;
		music(kMusicTitle);
		Run.TimeScale = 0.0f; // the scene behind the title holds still
		Ui.Clear();
		Screen s = Ui.Push(kTitleDoc);
		s.FindButton("course-0").OnClick(ScriptCallback(this.onMeadow));
		s.FindButton("course-1").OnClick(ScriptCallback(this.onForest));
		s.FindButton("course-2").OnClick(ScriptCallback(this.onRidge));
		s.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuit));
		for (int i = 0; i < kCourseCount; ++i)
		{
			bool open = unlocked(i);
			s.FindButton("course-" + i).SetEnabled(open);
			s.FindLabel("course-" + i + "-best").SetText(open ? bestLine(i)
														   : "Locked: " + courseName(i - 1) + " bronze");
		}
	}

	// ---- the pause menu: the run holds still under it ----
	private void pause()
	{
		m_paused = true;
		Audio.PlayOneShot(kClick, AudioBus::Effects, 0.7f);
		m_controlsShow = 0.0f;
		Ui.Find("hud-controls").SetVisible(false); // the menu shows them itself
		Run.TimeScale = 0.0f;
		Screen s = Ui.Push(kPauseDoc);
		s.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		s.FindButton("restart-btn").OnClick(ScriptCallback(this.onRestartRun));
		s.FindButton("courses-btn").OnClick(ScriptCallback(this.onCourses));
	}

	private void onResume()
	{
		if (!m_paused)
		{
			return;
		}
		Audio.PlayOneShot(kBack, AudioBus::Effects, 0.7f);
		m_paused = false;
		Ui.Pop(); // the pause menu
		Run.TimeScale = 1.0f;
	}

	private void onRestartRun()
	{
		Audio.PlayOneShot(kClick, AudioBus::Effects, 0.7f);
		onResume();
		restart();
	}

	private void onCourses()
	{
		Audio.PlayOneShot(kClick, AudioBus::Effects, 0.7f);
		m_paused = false;
		showTitle();
	}

	private void onMeadow() { startCourse(0); }
	private void onForest() { startCourse(1); }
	private void onRidge() { startCourse(2); }

	private void onQuit()
	{
		Audio.PlayOneShot(kClick, AudioBus::Effects, 0.7f);
		Run.RequestExit(0);
	}

	// A course opens with a bronze or better on the one before it; the first is always open.
	private bool unlocked(int i)
	{
		return i == 0 || Save.GetInt("medal." + courseName(i - 1), 0) >= 1;
	}

	// The best medal and time won on a course, from the save.
	private string bestLine(int i)
	{
		float best = Save.GetFloat("best." + courseName(i), -1.0f);
		if (best < 0.0f)
		{
			return "Not ridden yet";
		}
		return medalTitle(Save.GetInt("medal." + courseName(i), 0)) + "   best " + clock(best);
	}

	// A course from its top: everything the last run counted starts over, and the scene loads afresh
	// (its gates, gems and finish announce themselves again).
	private void startCourse(int i)
	{
		if (!unlocked(i))
		{
			return;
		}
		Audio.PlayOneShot(kClick, AudioBus::Effects, 0.7f);
		music(kMusicRun);
		m_onTitle = false;
		m_started = false;
		m_gates = 0;
		m_gems = 0;
		m_gold = 0.0f;
		m_silver = 0.0f;
		m_bronze = 0.0f;
		Ui.Clear();
		Ui.Push(kHudDoc);
		resetRun();
		// The controls, keyboard and pad, along the bottom for the first seconds of the course
		// (and always in the pause menu).
		View controls = Ui.Find("hud-controls");
		controls.SetVisible(true);
		controls.SetOpacity(0.0f);
		controls.FadeTo(1.0f, 0.3f);
		m_controlsShow = kControlsShown;
		Run.TimeScale = 1.0f;
		Run.LoadScene(courseScene(i));
	}

	void update(float dt)
	{
		if (m_onTitle)
		{
			return;
		}
		if (m_onEnding)
		{
			if (Input.WasPressed("Jump") || Input.WasPressed("Pause"))
			{
				m_onEnding = false;
				showTitle();
			}
			return;
		}
		if (m_paused)
		{
			// Back out of the menu the way it came in, or with B (the Grab button) on a pad.
			if (Input.WasPressed("Pause") || Input.WasPressed("Grab"))
			{
				onResume();
			}
			return;
		}
		if (Input.WasPressed("Pause"))
		{
			if (m_running)
			{
				pause();
			}
			else
			{
				showTitle(); // on the results: back to the courses
			}
			return;
		}
		if (m_running)
		{
			if (!m_started)
			{
				return;
			}
			m_time += dt;
			Ui.FindLabel("hud-time").SetText(clock(m_time + m_penalty));
			if (m_flash > 0.0f)
			{
				m_flash -= Run.RealDeltaTime;
				if (m_flash <= 0.0f)
				{
					Ui.Find("hud-penalty").SetVisible(false);
				}
			}
			if (m_controlsShow > 0.0f)
			{
				m_controlsShow -= Run.RealDeltaTime;
				if (m_controlsShow <= 0.0f)
				{
					Ui.Find("hud-controls").FadeTo(0.0f, 0.6f);
				}
			}
			if (m_trickShow > 0.0f)
			{
				m_trickShow -= Run.RealDeltaTime;
				if (m_trickShow <= 0.0f)
				{
					Ui.Find("hud-trick").SetVisible(false);
				}
			}
			return;
		}
		updateResults(dt);
	}

	void onGateRegistered(int index)
	{
		m_gates += 1;
		showGates();
	}

	void onGatePassed(int index)
	{
		Audio.PlayOneShot(kGatePass, AudioBus::Effects, 0.5f);
		m_passed += 1;
		showGates();
	}

	void onGateMissed(int index)
	{
		Audio.PlayOneShot(kGateMiss, AudioBus::Effects, 0.6f);
		endCombo();
		m_missed += 1;
		m_penalty += kMissPenalty;
		m_flash = 1.2f;
		View penalty = Ui.Find("hud-penalty");
		penalty.SetVisible(true);
		showGates();
	}

	void onGemRegistered(int value)
	{
		m_gems += value;
		showGems();
	}

	void onGemCollected(int value)
	{
		m_taken += value;
		showGems();
	}

	void onTrickAir(int centiseconds) { m_trickAir = float(centiseconds) / 100.0f; }
	void onTrickSpin(int degrees) { m_trickSpin = degrees; }
	void onTrickGrab(int centiseconds) { m_trickGrab = float(centiseconds) / 100.0f; }

	// A trick landed: clean, it scores and the combo grows; crashed, the combo is gone.
	void onTrickLanded(int clean)
	{
		if (!m_running)
		{
			return;
		}
		if (clean == 0)
		{
			return; // the crash (RiderCrashed) ends the combo
		}
		int points = int(m_trickAir * float(kAirPoints)) + (m_trickSpin / 180) * kSpinPoints
					 + int(m_trickGrab * float(kGrabPoints));
		points *= m_combo;
		m_tricks += points;
		showTrick(trickName(), "+" + points);
		raiseCombo();
	}

	// A trunk passed close and fast: points, and the combo grows, as a clean landing's does.
	void onNearMiss(int unused)
	{
		if (!m_running)
		{
			return;
		}
		int points = kNearMissPoints * m_combo;
		m_tricks += points;
		showTrick("Near miss", "+" + points);
		raiseCombo();
	}

	// The avalanche: its gap on the HUD, red and beating as it closes.
	void onAvalancheReleased(int metres)
	{
		if (m_running)
		{
			Ui.Find("hud-avalanche-panel").SetVisible(true);
			onAvalancheGap(metres);
		}
	}

	void onAvalancheGap(int metres)
	{
		if (!m_running)
		{
			return;
		}
		Label gap = Ui.FindLabel("hud-avalanche");
		gap.SetText("" + metres + " m");
		if (metres < 15)
		{
			gap.SetTextColor(Color(1.0f, 0.45f, 0.4f, 1.0f));
			if (metres % 2 == 0)
			{
				Ui.Find("hud-avalanche-panel").Pulse(1.12f, 0.18f);
			}
		}
		else
		{
			gap.ClearTextColor();
		}
	}

	// Caught: the board crashes (Board.as), and the avalanche, spent, rolls on past.
	void onAvalancheCaught(int unused)
	{
		if (m_running)
		{
			showTrick("Caught by the avalanche", "");
			Ui.Find("hud-avalanche-panel").SetVisible(false);
			m_caught = true;
		}
	}

	// Over a crevasse and down past it: points, and the combo grows.
	void onGapCleared(int centimetres)
	{
		if (!m_running)
		{
			return;
		}
		int points = kGapPoints * m_combo;
		m_tricks += points;
		showTrick("Gap " + (centimetres / 100) + " m", "+" + points);
		raiseCombo();
	}

	// Down in the snow off a landing or into a tree: the combo is gone.
	void onRiderCrashed(int unused)
	{
		if (m_running)
		{
			endCombo();
			if (!m_caught)
			{
				showTrick("Crash", ""); // a catch's crash keeps its own message
			}
			m_caught = false;
		}
	}

	private void raiseCombo()
	{
		if (m_combo < kComboMost)
		{
			m_combo += 1;
		}
		View combo = Ui.Find("hud-combo");
		Ui.FindLabel("hud-combo").SetText("Combo x" + m_combo);
		combo.SetVisible(true);
	}

	// "360 Grab", "180", "Air": the spin if any, then the grab if held a while, else just air.
	private string trickName()
	{
		string name = m_trickSpin > 0 ? "" + m_trickSpin : "";
		if (m_trickGrab >= 0.2f)
		{
			name += (name == "" ? "" : " ") + "Grab";
		}
		return name == "" ? "Air" : name;
	}

	private void showTrick(string name, string points)
	{
		Label trick = Ui.FindLabel("hud-trick");
		trick.SetText(points == "" ? name : name + "   " + points);
		trick.SetVisible(true);
		trick.SetOpacity(0.0f);
		trick.FadeTo(1.0f, 0.15f);
		m_trickShow = kTrickShown;
	}

	private void endCombo()
	{
		m_combo = 1;
		Ui.Find("hud-combo").SetVisible(false);
	}

	void onMedalGold(int hundredths) { m_gold = float(hundredths) / 100.0f; }
	void onMedalSilver(int hundredths) { m_silver = float(hundredths) / 100.0f; }
	void onMedalBronze(int hundredths) { m_bronze = float(hundredths) / 100.0f; }

	void onRunStarted(int unused)
	{
		m_started = true;
	}

	void onRunFinished(int unused)
	{
		m_running = false;
		Ui.Find("hud-avalanche-panel").SetVisible(false);
		m_tallyStep = 0;
		m_tallyTime = 0.0f;
		keepBest(m_time + m_penalty);
		Ui.Push(kFinishDoc);
	}

	// The course's best time and medal, kept in the save; a new best is announced at once, so the
	// ghost keeps this run before the next one starts recording.
	private void keepBest(float total)
	{
		string course = Run.CurrentScene.Name;
		m_previousBest = Save.GetFloat("best." + course, -1.0f);
		if (m_previousBest < 0.0f || total < m_previousBest)
		{
			Save.SetFloat("best." + course, total);
			Run.Emit("NewBest", int(total * 100.0f + 0.5f));
		}
		int rank = medalRank(medalName(total));
		if (rank > Save.GetInt("medal." + course, 0))
		{
			Save.SetInt("medal." + course, rank);
			m_endingDue = course == courseName(kCourseCount - 1);
		}
		Save.Flush();
	}

	// 3 gold, 2 silver, 1 bronze, 0 none.
	private int medalRank(string medal)
	{
		if (medal == "gold")
		{
			return 3;
		}
		if (medal == "silver")
		{
			return 2;
		}
		return medal == "bronze" ? 1 : 0;
	}

	// ---- the results: one row at a time, then the final time and its medal, then the score ----
	private void updateResults(float dt)
	{
		m_tallyTime += dt;
		if (m_tallyStep < kTallySteps)
		{
			if (Input.WasPressed("Jump"))
			{
				// Skip to the end: everything at once, quietly.
				while (m_tallyStep < kTallySteps)
				{
					tallyStep(m_tallyStep, true);
					m_tallyStep += 1;
				}
				return;
			}
			while (m_tallyStep < kTallySteps && m_tallyTime >= kTallyFirst + kTallyGap * float(m_tallyStep))
			{
				tallyStep(m_tallyStep, false);
				m_tallyStep += 1;
			}
			return;
		}
		if (Input.WasPressed("Jump"))
		{
			Ui.Pop(); // the results
			if (m_endingDue)
			{
				m_endingDue = false;
				showEnding();
				return;
			}
			restart();
		}
	}

	// ---- the ending: every course's best, their total, the medals ----
	private void showEnding()
	{
		m_onEnding = true;
		Audio.PlayOneShot(kMedalSting, AudioBus::Music, 0.9f);
		music(kMusicTitle);
		Run.TimeScale = 0.0f; // the course behind it holds still
		Ui.Clear();
		Ui.Push(kEndingDoc);
		string last = courseName(kCourseCount - 1);
		Ui.FindLabel("end-headline").SetText(medalTitle(Save.GetInt("medal." + last, 0)) + " on " + last);
		float total = 0.0f;
		bool allRidden = true;
		int golds = 0;
		int silvers = 0;
		int bronzes = 0;
		for (int i = 0; i < kCourseCount; ++i)
		{
			float best = Save.GetFloat("best." + courseName(i), -1.0f);
			int rank = Save.GetInt("medal." + courseName(i), 0);
			Ui.Find("end-" + i + "-" + (rank == 3 ? "gold" : (rank == 2 ? "silver" : (rank == 1 ? "bronze" : "none"))))
				.SetVisible(true);
			Ui.FindLabel("end-" + i + "-best").SetText(best < 0.0f ? "not ridden" : medalTitle(rank) + "   " + clock(best));
			if (best < 0.0f)
			{
				allRidden = false;
			}
			else
			{
				total += best;
			}
			golds += rank == 3 ? 1 : 0;
			silvers += rank == 2 ? 1 : 0;
			bronzes += rank == 1 ? 1 : 0;
		}
		Ui.FindLabel("end-total").SetText(allRidden ? clock(total) : "");
		Ui.FindLabel("end-medals").SetText("" + golds + " gold   " + silvers + " silver   " + bronzes + " bronze");
		Ui.FindLabel("end-closing").SetText(golds == kCourseCount ? "Gold on every course. Thanks for riding."
																  : "Thanks for riding. There is gold still out there.");
	}

	// The music: switched only when the track changes, so the title's keeps playing across menus.
	private void music(Guid track)
	{
		if (m_music == track)
		{
			return;
		}
		m_music = track;
		Audio.PlayMusic(track, 1.0f, kMusicVolume);
	}

	private string medalTitle(int rank)
	{
		return rank == 3 ? "Gold" : (rank == 2 ? "Silver" : (rank == 1 ? "Bronze" : "No medal"));
	}

	// Steps 0-4 are the rows, 5 the final time with its medal, 6 the score and the best.
	private void tallyStep(int step, bool quiet)
	{
		float total = m_time + m_penalty;
		if (step <= 4)
		{
			string key;
			string value;
			if (step == 0)
			{
				key = "ride";
				value = clock(m_time);
			}
			else if (step == 1)
			{
				key = "gates";
				value = "" + m_passed + " / " + m_gates
						+ (m_missed == 0 ? "" : "    +" + int(m_penalty) + " s");
			}
			else if (step == 2)
			{
				key = "gems";
				value = "" + m_taken + " / " + m_gems + "    +" + (m_taken * kGemPoints);
			}
			else if (step == 3)
			{
				key = "tricks";
				value = "+" + m_tricks;
			}
			else
			{
				key = "bonus";
				value = "+" + timeBonus(total);
			}
			View row = Ui.Find("row-" + key);
			row.SetVisible(true);
			Ui.FindLabel("value-" + key).SetText(value);
			if (!quiet)
			{
				row.SetOpacity(0.0f);
				row.FadeTo(1.0f, 0.2f);
				row.SetTranslation(-24.0f, 0.0f);
				row.MoveTo(0.0f, 0.0f, 0.25f, Ease::Out);
				Audio.PlayOneShot(kChime, AudioBus::Effects, 0.3f, 0.8f + 0.08f * float(step));
			}
			return;
		}
		if (step == 5)
		{
			Ui.FindLabel("final-time").SetText(clock(total));
			string medal = medalName(total);
			Ui.FindLabel("final-medal").SetText(medalLine(total));
			if (medal == "")
			{
				Ui.Find("medal-none").SetVisible(true);
				if (!quiet)
				{
					Audio.PlayOneShot(kNoMedalSting, AudioBus::Music, 0.8f);
				}
			}
			else
			{
				View disc = Ui.Find("medal-" + medal);
				disc.SetVisible(true);
				if (!quiet)
				{
					disc.SetScale(1.6f);
					disc.ScaleTo(1.0f, 0.3f, Ease::Out);
					Audio.PlayOneShot(kMedalSting, AudioBus::Music, 0.9f);
				}
			}
			return;
		}
		Ui.Find("row-score").SetVisible(true);
		Ui.FindLabel("final-score").SetText("" + (m_taken * kGemPoints + m_tricks + timeBonus(total)));
		string best;
		if (m_previousBest < 0.0f)
		{
			best = "Your ghost will ride this run";
		}
		else if (total < m_previousBest)
		{
			best = "New best!  (was " + clock(m_previousBest) + ")";
		}
		else
		{
			best = "Best " + clock(m_previousBest);
		}
		Ui.FindLabel("final-best").SetText(best);
		Ui.FindLabel("final-prompt").SetText("Jump to ride again");
	}

	// "gold", "silver", "bronze", or "" for none.
	private string medalName(float total)
	{
		if (m_gold > 0.0f && total <= m_gold)
		{
			return "gold";
		}
		if (m_silver > 0.0f && total <= m_silver)
		{
			return "silver";
		}
		if (m_bronze > 0.0f && total <= m_bronze)
		{
			return "bronze";
		}
		return "";
	}

	// The medal earned and the next one's time to beat.
	private string medalLine(float total)
	{
		if (m_bronze <= 0.0f)
		{
			return "";
		}
		string medal = medalName(total);
		if (medal == "gold")
		{
			return "Gold";
		}
		if (medal == "silver")
		{
			return "Silver.  Gold at " + clock(m_gold);
		}
		if (medal == "bronze")
		{
			return "Bronze.  Silver at " + clock(m_silver);
		}
		return "No medal.  Bronze at " + clock(m_bronze);
	}

	// Points for each second under the bronze time.
	private int timeBonus(float total)
	{
		float under = m_bronze - total;
		return under > 0.0f ? int(under * float(kBonusPerSecond)) : 0;
	}

	private void restart()
	{
		resetRun();
		Run.Emit("RunRestart", 0); // in a run the scene bus is the run bus
	}

	// What a run counts, back to its start (the course's own counts stay: its gates and gems).
	private void resetRun()
	{
		m_running = true;
		m_time = 0.0f;
		m_penalty = 0.0f;
		m_passed = 0;
		m_missed = 0;
		m_flash = 0.0f;
		m_taken = 0;
		m_tricks = 0;
		m_trickShow = 0.0f;
		endCombo();
		Ui.Find("hud-trick").SetVisible(false);
		Ui.Find("hud-penalty").SetVisible(false);
		Ui.Find("hud-avalanche-panel").SetVisible(false);
		showGates();
		showGems();
	}

	private void showGates()
	{
		Ui.FindLabel("hud-gates").SetText("" + m_passed + " / " + m_gates);
	}

	private void showGems()
	{
		Ui.FindLabel("hud-gems").SetText("" + m_taken + " / " + m_gems);
	}

	// m:ss.cc
	private string clock(float seconds)
	{
		int whole = int(seconds);
		int hundredths = int((seconds - float(whole)) * 100.0f);
		int s = whole % 60;
		return "" + (whole / 60) + ":" + (s < 10 ? "0" : "") + s + "." + (hundredths < 10 ? "0" : "")
			   + hundredths;
	}
}
