// Lamplight - the game's orchestrator (the reserved class Game): the title and its levels, and in
// a level the clock, the HUD's target and loot, the pause menu, and the results.
//
// The title lists the levels with the best taken on each (from the save); a level opens once the
// one before it is done. Picking one loads its scene afresh under the HUD. In a level the scene's
// pieces report what happens: loot taken ("Loot", its value), the target taken ("Taken"), a guard
// giving chase ("Spotted"), the thief caught ("Caught": he is back at his checkpoint, the level
// goes on), and the thief at the exit ("Escaped"): with the target, the level is done; without
// it, the HUD says what he is there for. Pause (Escape or Start) holds the level still under the
// pause menu.
//
// The results: the time, the loot, how often seen and caught, and the ghost medal for a level done
// without a guard ever giving chase. The save keeps, per level, that it is done, the best time,
// the most loot and whether it was ghosted ("done.<level>", "best.<level>", "loot.<level>",
// "ghost.<level>").

const int kLevelCount = 5;
const float kControlsShown = 6.0f; // how long the controls show as a level starts (s)
Guid kTitleDoc = Guid::FromString("fa43f9fb-2c29-ac49-aca0-77d26e942e93");
Guid kHudDoc = Guid::FromString("843e11cc-ec0d-f942-8def-e1277fb7f326");
Guid kPauseDoc = Guid::FromString("9ea69377-b400-2c48-a510-84aa59b14525");
Guid kResultsDoc = Guid::FromString("28d7ef2b-3e8e-d64b-99e7-7852f517ac09");

class Game
{
	private bool m_inLevel = false;  // a level is being played (not the title, not the results)
	private bool m_paused = false;
	private int m_level = 0;
	private float m_time = 0.0f;
	private int m_loot = 0;
	private bool m_haveTarget = false;
	private int m_seen = 0;
	private int m_caught = 0;
	private float m_note = 0.0f; // how long the HUD's word shows yet
	private float m_controlsShow = 0.0f; // how long the controls panel shows yet

	void launch()
	{
		showTitle();
	}

	// ---- the levels: their scenes, names and what each is for ----
	private Guid levelScene(int i)
	{
		if (i == 0) return Guid::FromString("5fa1899e-3821-bd48-8496-af9ac424f3af");
		if (i == 1) return Guid::FromString("9eb240a8-1932-5c41-ab85-32dce8316311");
		if (i == 2) return Guid::FromString("ea1b9d4f-e046-6a4d-9a9d-81f3009cdff1");
		if (i == 3) return Guid::FromString("14a2028d-8afd-f04f-a8ab-db225cd000ab");
		return Guid::FromString("820e413e-b99e-8948-8662-503d1d009645");
	}
	private string levelName(int i)
	{
		return i == 0 ? "Gardens" : (i == 1 ? "StableYard" : (i == 2 ? "GroundFloor" : (i == 3 ? "Cellars" : "UpperFloor")));
	}
	private string levelTitle(int i)
	{
		return i == 0 ? "The Gardens"
					  : (i == 1 ? "The Stable Yard" : (i == 2 ? "The Ground Floor" : (i == 3 ? "The Cellars" : "The Upper Floor")));
	}
	private string targetName(int i)
	{
		return i == 0 ? "the gardener's key"
					  : (i == 1 ? "the stable ledger"
								: (i == 2 ? "the butler's keys" : (i == 3 ? "the steward's letter" : "the family jewels")));
	}

	// A level opens once the one before it is done; the first is always open, one not built yet never.
	private bool unlocked(int i)
	{
		if (levelScene(i).IsNil)
		{
			return false;
		}
		return i == 0 || Save.GetInt("done." + levelName(i - 1), 0) == 1;
	}

	private string bestLine(int i)
	{
		if (levelScene(i).IsNil)
		{
			return "Not open yet";
		}
		if (!unlocked(i))
		{
			return "Locked: get away from " + levelTitle(i - 1);
		}
		float best = Save.GetFloat("best." + levelName(i), -1.0f);
		if (best < 0.0f)
		{
			return "Not yet done";
		}
		string line = "best " + clock(best) + "   loot " + Save.GetInt("loot." + levelName(i), 0);
		return Save.GetInt("ghost." + levelName(i), 0) == 1 ? line + "   ghost" : line;
	}

	// ---- the title ----
	private void showTitle()
	{
		m_inLevel = false;
		m_paused = false;
		Run.TimeScale = 0.0f; // whatever is behind the title holds still
		Ui.Clear();
		UIScreen s = Ui.Push(kTitleDoc);
		s.FindButton("level-0").OnClick(ScriptCallback(this.onLevel0));
		s.FindButton("level-1").OnClick(ScriptCallback(this.onLevel1));
		s.FindButton("level-2").OnClick(ScriptCallback(this.onLevel2));
		s.FindButton("level-3").OnClick(ScriptCallback(this.onLevel3));
		s.FindButton("level-4").OnClick(ScriptCallback(this.onLevel4));
		s.FindButton("quit-btn").OnClick(ScriptCallback(this.onQuit));
		for (int i = 0; i < kLevelCount; ++i)
		{
			s.FindButton("level-" + i).SetEnabled(unlocked(i));
			s.FindLabel("level-" + i + "-best").SetText(bestLine(i));
		}
	}

	private void onLevel0() { startLevel(0); }
	private void onLevel1() { startLevel(1); }
	private void onLevel2() { startLevel(2); }
	private void onLevel3() { startLevel(3); }
	private void onLevel4() { startLevel(4); }
	private void onQuit() { Run.RequestExit(0); }

	// ---- a level ----
	private void startLevel(int i)
	{
		m_level = i;
		m_time = 0.0f;
		m_loot = 0;
		m_haveTarget = false;
		m_seen = 0;
		m_caught = 0;
		m_note = 0.0f;
		m_paused = false;
		m_inLevel = true;
		Ui.Clear();
		Ui.Push(kHudDoc);
		showHud();
		// The controls, keyboard and pad, for the first seconds of the level (the pause menu has them too).
		UIView controls = Ui.Find("hud-controls");
		controls.SetVisible(true);
		controls.SetOpacity(0.0f);
		controls.FadeTo(1.0f, 0.3f);
		m_controlsShow = kControlsShown;
		Run.TimeScale = 1.0f;
		Run.LoadScene(levelScene(i));
	}

	void update(float dt)
	{
		if (!m_inLevel)
		{
			return;
		}
		if (Input.WasPressed("Pause"))
		{
			if (m_paused)
			{
				onResume();
			}
			else
			{
				pause();
			}
			return;
		}
		if (m_paused)
		{
			return;
		}
		m_time += dt;
		if (m_controlsShow > 0.0f)
		{
			m_controlsShow -= dt;
			if (m_controlsShow <= 0.0f)
			{
				Ui.Find("hud-controls").FadeTo(0.0f, 0.6f);
			}
		}
		Ui.FindLabel("hud-time").SetText(clock(m_time));
		if (m_note > 0.0f)
		{
			m_note -= dt;
			if (m_note <= 0.0f)
			{
				Ui.Find("hud-note").FadeTo(0.0f, 0.5f);
			}
		}
	}

	private void showHud()
	{
		Ui.FindLabel("hud-target").SetText(m_haveTarget ? "Got " + targetName(m_level) + ": get out"
														: "Find " + targetName(m_level));
		Ui.FindLabel("hud-loot").SetText("Loot " + m_loot);
	}

	private void note(string text)
	{
		UILabel label = Ui.FindLabel("hud-note");
		label.SetText(text);
		label.SetOpacity(1.0f);
		label.SetVisible(true);
		m_note = 2.5f;
	}

	// ---- what the level's pieces report ----
	void onLoot(int value)
	{
		m_loot += value;
		showHud();
	}

	void onTaken(int value)
	{
		m_loot += value;
		m_haveTarget = true;
		showHud();
		note("Got " + targetName(m_level));
	}

	void onSpotted(int unused)
	{
		m_seen++;
	}

	void onAlarm(Float3 at)
	{
		note("The alarm! Every guard is coming");
	}

	void onCaught(Float3 at)
	{
		m_caught++;
		note("Caught: back to the checkpoint");
	}

	void onEscaped(Float3 at)
	{
		if (!m_inLevel)
		{
			return;
		}
		if (!m_haveTarget)
		{
			note("Not without " + targetName(m_level));
			return;
		}
		finish();
	}

	// ---- the pause menu ----
	private void pause()
	{
		m_paused = true;
		Run.TimeScale = 0.0f;
		m_controlsShow = 0.0f;
		Ui.Find("hud-controls").SetVisible(false); // the menu shows them itself
		UIScreen s = Ui.Push(kPauseDoc);
		s.FindButton("resume-btn").OnClick(ScriptCallback(this.onResume));
		s.FindButton("restart-btn").OnClick(ScriptCallback(this.onRestart));
		s.FindButton("title-btn").OnClick(ScriptCallback(this.onTitle));
	}

	private void onResume()
	{
		if (!m_paused)
		{
			return;
		}
		m_paused = false;
		Ui.Pop();
		Run.TimeScale = 1.0f;
	}

	private void onRestart() { startLevel(m_level); }
	private void onTitle() { showTitle(); }

	// ---- the results ----
	private void finish()
	{
		m_inLevel = false;
		Run.TimeScale = 0.0f;
		string level = levelName(m_level);
		bool ghost = m_seen == 0;
		float previous = Save.GetFloat("best." + level, -1.0f);
		Save.SetInt("done." + level, 1);
		if (previous < 0.0f || m_time < previous)
		{
			Save.SetFloat("best." + level, m_time);
		}
		if (m_loot > Save.GetInt("loot." + level, 0))
		{
			Save.SetInt("loot." + level, m_loot);
		}
		if (ghost)
		{
			Save.SetInt("ghost." + level, 1);
		}
		Save.Flush();

		UIScreen s = Ui.Push(kResultsDoc);
		bool last = m_level + 1 >= kLevelCount;
		string title = ghost ? "Away like a ghost" : (m_caught == 0 ? "Away clean" : "Away");
		s.FindLabel("res-title").SetText(last ? "The jewels are yours. " + title : title);
		s.FindLabel("res-time").SetText("Time   " + clock(m_time));
		s.FindLabel("res-loot").SetText("Loot   " + m_loot);
		s.FindLabel("res-seen").SetText("Seen " + m_seen + (m_seen == 1 ? " time" : " times") + ", caught " + m_caught);
		s.FindLabel("res-medal").SetText(last ? "The Lamplight heist is done" + (ghost ? ". Ghost: never seen" : "")
											  : (ghost ? "Ghost: never seen" : ""));
		s.FindLabel("res-best").SetText("Best on " + levelTitle(m_level) + ": " + clock(Save.GetFloat("best." + level, m_time))
										+ ", loot " + Save.GetInt("loot." + level, m_loot));
		bool next = m_level + 1 < kLevelCount && unlocked(m_level + 1);
		s.FindButton("next-btn").SetEnabled(next);
		s.FindButton("next-btn").OnClick(ScriptCallback(this.onNext));
		s.FindButton("again-btn").OnClick(ScriptCallback(this.onRestart));
		s.FindButton("title-btn").OnClick(ScriptCallback(this.onTitle));
	}

	private void onNext() { startLevel(m_level + 1); }

	private string clock(float seconds)
	{
		int s = int(seconds);
		int m = s / 60;
		s = s % 60;
		return m + ":" + (s < 10 ? "0" : "") + s;
	}
}
