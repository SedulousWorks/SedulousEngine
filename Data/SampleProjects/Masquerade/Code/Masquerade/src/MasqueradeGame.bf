using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// The run: the title, a round at the ball under its HUD, the pause menu, and the results.
///
/// The title offers play alone, host, join or quit; the first two choose a map (Maps), then play it
/// alone or host it (the server on cPort, waiting for each joiner's ready, then the map); or joins
/// a host: the connection first, from the title, then the host's map (named in its welcome) loads,
/// and the joiner says it is ready, so the map's networked entities are in place for the host's
/// first snapshot. The round itself is the scene's (Ball): this hears it, as the run's events:
/// InReach (someone to tag in front of you, or no longer), HunterNear (the hunter whose mark you
/// are, near, or no longer), HudReport (four times a second: your points, the seconds left, your
/// target's costume, your place), RoundNote (something happened to you, or a mask flared),
/// RoundOver (everyone's points) and RoundStarted (the host began another round). Pause (Escape or
/// Start) shows the pause menu, holding the round still when playing alone (a networked round goes
/// on). The title picks the map; the save keeps each map's best round ("best.Palace",
/// "best.Canal", "best.Gardens").
///
/// The screens are the GUI documents Tools/importui.py imports, pushed on the run GUI's screen
/// stack by id; a screen is loaded fresh each time it is pushed, so its buttons are wired again
/// each time, and the handlers go with its nodes.
[Game]
class MasqueradeGame : Game
{
	/// How long the controls show as a round starts (s).
	private const float cControlsShown = 7.0f;
	/// The clock warms for the round's last half minute.
	private const float cLateSeconds = 30.0f;
	private const int32 cPort = 7777;
	/// How long a joiner waits for the host's welcome (s).
	private const float cJoinSeconds = 8.0f;
	/// A map's best round in the save before one is played.
	private const int32 cNoBest = -100000;

	/// Alone, hosting or joining.
	private enum Mode
	{
		Alone,
		Hosting,
		Joining
	}

	private bool mInRound = false;
	private bool mPaused = false;
	/// How long the HUD's word shows yet.
	private float mNote = 0.0f;
	/// How long the points' change shows yet.
	private float mDelta = 0.0f;
	/// The points the HUD shows.
	private int32 mShownScore = 0;
	/// The mark whose portrait the HUD shows.
	private int32 mShownCostume = -1;
	/// The clock in the round's last half minute.
	private bool mLate = false;
	/// The round's length, as its first report gave the time.
	private float mRoundSeconds = 0.0f;
	/// The "Menu" set pushed (HoldInput).
	private bool mInputHeld = false;
	/// How long the controls panel shows yet.
	private float mControlsShow = 0.0f;
	/// The title (or a page over it) is up: the camera sweeps before the dais.
	private bool mOnTitle = false;
	/// 0 the Palace, 1 the Canal, 2 the Gardens.
	private int32 mMap = 0;
	private Mode mMode = .Alone;
	private String mAddress = new .("127.0.0.1") ~ delete _;
	/// A joiner: until it tells the host it is ready, once the host's map has loaded.
	private float mReadyIn = -1.0f;
	/// A joiner on the title: how long until it gives up on the host.
	private float mJoinWait = -1.0f;
	/// The controls page is up, over the title or the pause menu.
	private bool mControlsOpen = false;
	/// The map page's Start hosts (else it plays alone).
	private bool mHostChosen = false;

	// ---- the run's services; null outside a run that has them ----
	private InputFacade Controls => (Instance != null) ? Instance.Get<InputFacade>() : null;
	private SaveFacade Save => (Instance != null) ? Instance.Get<SaveFacade>() : null;
	private AudioFacade Sound => (Instance != null) ? Instance.Get<AudioFacade>() : null;
	private NetFacade Net => (Instance != null) ? Instance.Get<NetFacade>() : null;

	private bool IsClient => (Net != null) && Net.IsClient;

	protected override void OnLaunch()
	{
		Listen<HudReport>(new [=this] (evt) => OnHud(evt));
		Listen<HunterNear>(new [=this] (evt) => OnHunterNear(evt.Yes));
		Listen<InReach>(new [=this] (evt) => OnInReach(evt.Yes));
		Listen<RoundNote>(new [=this] (evt) => OnNote(evt.What));
		Listen<RoundOver>(new [=this] (evt) => OnRoundOver(evt));
		Listen<RoundStarted>(new [=this] (evt) => OnRoundStarted());
		// A joiner hears the host's map in its welcome (the Ball's OnJoined), here rather than in a
		// scene's behaviour, as it arrives while the title's scene is the one loaded.
		if (let net = Net)
			net.OnText("map", new [=this] (player, text) => OnHostMap(text));
		ShowTitle();
	}

	/// The game updates at time scale 0 too, so the title's sweep and the Pause action run here
	/// while the scene holds still.
	protected override void OnUpdate(float dt)
	{
		let input = Controls;
		if (mControlsOpen && (input != null) && input.WasPressed("Pause"))
		{
			CloseControls();
			return;
		}
		// A joiner on the title, waiting for the host's welcome.
		if (mJoinWait >= 0.0f)
		{
			mJoinWait -= dt;
			if (mJoinWait < 0.0f)
			{
				if (let net = Net)
					net.Disconnect();
				mMode = .Alone;
				SetText("net-status", scope $"Could not reach {mAddress}");
			}
		}
		if (!mInRound)
		{
			if (mOnTitle)
				TitleView(dt); // the camera sweeps before the dais
			return;
		}
		if ((mReadyIn >= 0.0f) && Instance.SceneReady)
		{
			mReadyIn -= dt;
			if (mReadyIn < 0.0f)
			{
				if (let net = Net)
					net.Ready();
			}
		}
		if ((input != null) && input.WasPressed("Pause"))
		{
			if (mPaused)
				Resume();
			else
				Pause();
			return;
		}
		if (mPaused)
			return;
		if (mControlsShow > 0.0f)
		{
			mControlsShow -= dt;
			if (mControlsShow <= 0.0f)
				Hud.Fade(Find("hud-controls"), "opacity", "0", 0.6f, "ease");
		}
		if (mNote > 0.0f)
		{
			mNote -= dt;
			if (mNote <= 0.0f)
				Hud.Fade(Find("hud-note"), "opacity", "0", 0.5f, "ease");
		}
		if (mDelta > 0.0f)
		{
			mDelta -= dt;
			if (mDelta <= 0.0f)
				Hud.Fade(Find("hud-delta"), "opacity", "0", 0.6f, "ease");
		}
	}

	protected override void OnExit()
	{
		// The screens' handlers call into this game: they go with it.
		if (let stack = Hud.Screens(Run))
			stack.Clear();
	}

	// ---- the title ----

	private void ShowTitle()
	{
		mInRound = false;
		mOnTitle = true;
		mPaused = false;
		mControlsOpen = false; // the stack is cleared below
		Instance.InstanceTimeScale = 0.0f; // whatever is behind the title holds still
		HoldInput();
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.TitleDoc);
		Wire("solo-btn", new [=this] (e) =>
			{
				Play(Assets.Click);
				ShowMaps(false);
				return true;
			});
		Wire("host-btn", new [=this] (e) =>
			{
				Play(Assets.Click);
				ShowMaps(true);
				return true;
			});
		if ((Net == null) || !Net.CanHost)
			(Find("host-btn") as UIWidget)?.AddClass("gone"); // a browser cannot host; it joins a host's ball
		Wire("join-btn", new [=this] (e) => OnJoin());
		Wire("controls-btn", new [=this] (e) => OnControls());
		Wire("quit-btn", new [=this] (e) =>
			{
				Play(Assets.Click);
				Instance.RequestExit(0);
				return true;
			});
	}

	// ---- the controls page, over the title or the pause menu ----

	private bool OnControls()
	{
		Play(Assets.Click);
		Push(Assets.ControlsDoc);
		Wire("controls-back", new [=this] (e) =>
			{
				CloseControls();
				return true;
			});
		mControlsOpen = true;
		return true;
	}

	/// Its Back, or the game's Pause (Escape, Start): the screen stack's own back would also reach
	/// the pause menu under it, as Escape is the game's Pause too.
	private void CloseControls()
	{
		if (!mControlsOpen)
			return;
		Play(Assets.Click);
		mControlsOpen = false;
		if (let stack = Hud.Screens(Run))
			stack.Pop();
	}

	// ---- the map, to play alone or to host: a card each, the chosen one lit, then Start ----

	private void ShowMaps(bool host)
	{
		mHostChosen = host;
		Push(Assets.MapsDoc);
		SetText("maps-heading", host ? "Host a ball" : "Play alone");
		if (let start = Find("maps-start") as Button)
			start.Text = host ? "Host" : "Play";
		for (int32 i < 3)
		{
			let map = i;
			Wire(scope $"map-{i}", new [=this, =map] (e) =>
				{
					Choose(map, true);
					return true;
				});
		}
		if (let card = Find("map-1"))
			card.Enabled = Assets.Canal != Guid();
		if (let card = Find("map-2"))
			card.Enabled = Assets.Gardens != Guid();
		for (int32 map < 3)
			SetText(scope $"map-best-{map}", BestLine(map, .. scope .()));
		Wire("maps-start", new [=this] (e) => StartChosen());
		Wire("maps-back", new [=this] (e) => OnBack());
		SetText("net-status", "");
		Choose(mMap, false);
	}

	/// The chosen card lit; a click on it chooses, Start then plays or hosts it.
	private void Choose(int32 map, bool click)
	{
		if (click)
			Play(Assets.Click);
		mMap = map;
		for (int32 i < 3)
		{
			let card = Find(scope $"map-{i}") as UIWidget;
			if (card == null)
				continue;
			if (i == map)
				card.AddClass("chosen");
			else
				card.RemoveClass("chosen");
		}
	}

	private bool OnBack()
	{
		Play(Assets.Click);
		if (let stack = Hud.Screens(Run))
			stack.Pop();
		return true;
	}

	private static StringView MapTitle(int32 map)
	{
		return (map == 0) ? "the Palace" : ((map == 1) ? "the Canal" : "the Gardens");
	}

	/// The map's name in the save's keys, and in the host's welcome.
	private static StringView MapName(int32 map)
	{
		return (map == 0) ? "Palace" : ((map == 1) ? "Canal" : "Gardens");
	}

	private static Guid MapScene(int32 map)
	{
		return (map == 0) ? Assets.Palace : ((map == 1) ? Assets.Canal : Assets.Gardens);
	}

	/// The map page's Start: play the chosen map alone, or host it.
	private bool StartChosen()
	{
		Play(Assets.Click);
		if (!mHostChosen)
		{
			mMode = .Alone;
			StartRound();
			return true;
		}
		let net = Net;
		if ((net == null) || !net.StartServer(cPort))
		{
			SetText("net-status", scope $"Could not host on port {cPort}");
			return true;
		}
		mMode = .Hosting;
		net.WaitForReady(true); // a joiner hears no state until it has loaded this map
		StartRound();
		return true;
	}

	// ---- joining: the address, then Join; the map is the host's ----

	private bool OnJoin()
	{
		Play(Assets.Click);
		Push(Assets.JoinDoc);
		if (let field = Find("address") as TextField)
			field.Text = mAddress;
		Wire("join-go", new [=this] (e) => OnJoinGo());
		Wire("join-back", new [=this] (e) => OnBack());
		SetText("net-status", "");
		return true;
	}

	private bool OnJoinGo()
	{
		Play(Assets.Click);
		if (mJoinWait >= 0.0f)
			return true; // already waiting for the host
		let field = Find("address") as TextField;
		let typed = (field != null) ? field.Text : StringView();
		mAddress.Set((typed.Length > 0) ? typed : "127.0.0.1");
		// Connect from the title; the host's welcome names its map, which then loads (OnHostMap).
		let net = Net;
		if ((net == null) || !net.Connect(mAddress, cPort))
		{
			SetText("net-status", scope $"Could not reach {mAddress}");
			return true;
		}
		mMode = .Joining;
		mJoinWait = cJoinSeconds;
		SetText("net-status", scope $"Joining {mAddress}...");
		return true;
	}

	/// A joiner: the host's map. It loads, and once it is ready the host's state begins.
	private void OnHostMap(StringView name)
	{
		if (!IsClient || (mMode != .Joining) || (mJoinWait < 0.0f))
			return;
		mJoinWait = -1.0f;
		mMap = (name == "Canal") ? 1 : ((name == "Gardens") ? 2 : 0);
		SetText("net-status", scope $"Joining {MapTitle(mMap)}...");
		StartRound();
		mReadyIn = 0.2f; // once the map has loaded, a moment more for its first frame
	}

	private void BestLine(int32 map, String outLine)
	{
		let best = SavedBest(map);
		if (best == cNoBest)
			outLine.Append("No round played yet");
		else
			outLine.AppendF("Best round: {} points", best);
	}

	// ---- a round ----

	private void StartRound()
	{
		LeaveTitle();
		mPaused = false;
		mInRound = true;
		mNote = 0.0f;
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.HudDoc);
		SetText("hud-target", "");
		SetText("hud-score", "0");
		mShownScore = 0;
		mShownCostume = -1;
		mRoundSeconds = 0.0f;
		mLate = false;
		Hud.Fade(Find("hud-controls"), "opacity", "1", 0.3f, "ease"); // from the sheet's 0
		mControlsShow = cControlsShown;
		LetGo(); // time again, and the player's input: a round may start from any menu
		Instance.LoadScene(MapScene(mMap));
	}

	/// The camera back behind the player (CameraRig) as the title gives way to a round.
	private void LeaveTitle()
	{
		if (mOnTitle)
		{
			mOnTitle = false;
			TitleView(-1.0f);
		}
	}

	/// The title's frame to the current scene's camera rigs (CameraRig.TitleView).
	private void TitleView(float dt)
	{
		let scene = CurrentScene;
		let rigs = (scene != null) ? scene.GetSystem<BehaviourManager<CameraRig>>() : null;
		if (rigs == null)
			return;
		for (let rig in rigs.Instances)
		{
			if (rig.IsActive)
				rig.TitleView(dt);
		}
	}

	// ---- what the round reports ----

	private void OnHud(HudReport hud)
	{
		if (!mInRound)
			return;
		let costume = hud.TargetCostume;
		SetText("hud-target", CostumeName(costume));
		// In its colour: the sheet's class for the costume.
		if (let mark = Find("hud-target") as UIWidget)
		{
			for (int32 c < 6)
				mark.RemoveClass(scope $"costume-{c}");
			mark.AddClass(scope $"costume-{costume}");
		}
		// Only as the mark changes: setting the picture again would load it again, blank meanwhile.
		if ((costume != mShownCostume) && (costume >= 0) && (costume < 6))
		{
			mShownCostume = costume;
			if (let portrait = Find("hud-portrait") as Sedulous.GUI.Image)
				portrait.Source = Assets.Portrait(costume);
		}
		// The points, and each change floating beside them a moment, gold up, red down.
		let score = hud.Score;
		if (score != mShownScore)
		{
			let change = score - mShownScore;
			mShownScore = score;
			SetText("hud-score", scope $"{score}");
			let shown = scope String();
			if (change > 0)
				shown.Append("+");
			shown.AppendF("{}", change);
			SetText("hud-delta", shown);
			if (let delta = Find("hud-delta") as UIWidget)
			{
				delta.RemoveClass((change > 0) ? "loss" : "gain");
				delta.AddClass((change > 0) ? "gain" : "loss");
			}
			Hud.Fade(Find("hud-delta"), "opacity", "1", 0.15f, "ease");
			mDelta = 1.4f;
		}
		// The time over a bar of the round left (the round's length: the first time it reports).
		mRoundSeconds = Max(mRoundSeconds, hud.TimeLeft);
		SetText("hud-time", Clock(hud.TimeLeft, .. scope .()));
		if (let bar = Find("hud-timebar") as ProgressBar)
			bar.Value = (mRoundSeconds > 0.0f) ? (hud.TimeLeft / mRoundSeconds) : 0.0f;
		// Only as it changes: the class set again each report would start its pulse over.
		let late = (hud.TimeLeft <= cLateSeconds) && (hud.TimeLeft > 0.0f);
		if (late != mLate)
		{
			mLate = late;
			if (let clockCard = Find("hud-clock") as UIWidget)
			{
				if (late)
					clockCard.AddClass("late");
				else
					clockCard.RemoveClass("late");
			}
		}
		SetText("hud-rank", scope $"{Place(hud.Rank)} of 4");
	}

	/// The hunter whose mark you are, near (the Ball): a quiet line under your mark while it is.
	private void OnHunterNear(bool yes)
	{
		if (mInRound)
			Hud.Fade(Find("hud-near"), "opacity", yes ? "1" : "0", yes ? 0.3f : 0.8f, "ease");
	}

	/// Someone to tag in front of you (the Ball): Tag's prompt shows by your hunter's line of sight.
	private void OnInReach(bool yes)
	{
		if (mInRound)
			Hud.Fade(Find("hud-tag"), "opacity", yes ? "1" : "0", 0.15f, "ease");
	}

	private void OnNote(NoteKind what)
	{
		if (!mInRound)
			return;
		switch (what)
		{
		case .GotTarget:
			Play(Assets.TagSound);
			Note("Your mark is tagged. They will be back, dressed anew");
		case .Missed:
			Play(Assets.MissSound);
			Note("Wrong guest! Your mask flares");
		case .Tagged:
			Play(Assets.MissSound);
			Note("Tagged! A new costume, somewhere else");
		case .Flare:
			Play(Assets.FlareSound);
			Note("A mask flares: a hunter, there");
		case .Full:
			Play(Assets.ChimeSound);
			Note("Every seat is taken: you are watching");
		}
	}

	private void OnRoundOver(RoundOver scores)
	{
		if (!mInRound)
			return;
		mInRound = false;
		HoldStill();
		Play(Assets.Fanfare);
		let you = scores.Yours;
		let best = SavedBest(mMap);
		let record = you > best;
		if (record)
		{
			if (let save = Save)
			{
				save.SetInt(scope $"best.{MapName(mMap)}", you);
				save.Flush();
			}
		}
		int32 rank = 1;
		if (scores.Other1 > you)
			rank++;
		if (scores.Other2 > you)
			rank++;
		if (scores.Other3 > you)
			rank++;
		Push(Assets.ResultsDoc);
		SetText("res-title", (rank == 1) ? "The ball is yours" : "The music stops");
		SetText("res-you", scope $"You came {Place(rank)} with {you} points");
		// Every hunter by points, the most first (yours first among equals), your row lit.
		StringView[4] names = .("You", "Hunter 1", "Hunter 2", "Hunter 3");
		int32[4] points = .(you, scores.Other1, scores.Other2, scores.Other3);
		int32[4] order = .(0, 1, 2, 3);
		for (int i = 1; i < 4; i++)
		{
			for (int j = i; (j > 0) && (points[order[j]] > points[order[j - 1]]); j--)
			{
				let t = order[j];
				order[j] = order[j - 1];
				order[j - 1] = t;
			}
		}
		for (int32 row < 4)
		{
			let who = order[row];
			SetText(scope $"rank-place-{row}", Place(row + 1));
			SetText(scope $"rank-name-{row}", names[who]);
			SetText(scope $"rank-points-{row}", scope $"{points[who]}");
			if (let line = Find(scope $"rank-{row}") as UIWidget)
			{
				if (who == 0)
					line.AddClass("you");
				else
					line.RemoveClass("you");
			}
		}
		if (record)
			SetText("res-best", "Your best round yet");
		else
			SetText("res-best", scope $"Your best: {best} points");
		Wire("again-btn", new [=this] (e) => OnAgain());
		if (let again = Find("again-btn"))
			again.Visible = mMode != .Joining; // the host starts the next round
		WireTitle();
	}

	/// The host started another round in the same scene: a joiner leaves its results for it.
	private void OnRoundStarted()
	{
		if (mInRound || (mMode != .Joining))
			return;
		EnterRound();
	}

	// ---- the pause menu ----

	private void Pause()
	{
		mPaused = true;
		HoldStill();
		mControlsShow = 0.0f;
		Hud.Fade(Find("hud-controls"), "opacity", "0", 0.0f, "ease"); // the menu shows them itself
		Push(Assets.PauseDoc);
		Wire("resume-btn", new [=this] (e) =>
			{
				Resume();
				return true;
			});
		Wire("restart-btn", new [=this] (e) => OnAgain());
		if (let restart = Find("restart-btn"))
			restart.Visible = mMode != .Joining; // the host's to start over
		WireTitle();
		Wire("pause-controls-btn", new [=this] (e) => OnControls());
	}

	private void Resume()
	{
		if (!mPaused)
			return;
		mPaused = false;
		if (let stack = Hud.Screens(Run))
			stack.Pop();
		Play(Assets.Click);
		LetGo();
	}

	/// Another round: alone, the map afresh; hosting, the same scene goes on (the players' hunters
	/// with it) and the Ball starts over (Ball.Restart).
	private bool OnAgain()
	{
		Play(Assets.Click);
		if (mMode == .Hosting)
		{
			EnterRound();
			let scene = CurrentScene;
			if (let balls = (scene != null) ? scene.GetSystem<BehaviourManager<Ball>>() : null)
			{
				for (let ball in balls.Instances)
				{
					if (ball.IsActive)
						ball.Restart();
				}
			}
			return true;
		}
		StartRound();
		return true;
	}

	/// The top screen's title-btn (the pause menu's or the results') goes back to the title,
	/// leaving the network.
	private void WireTitle()
	{
		Wire("title-btn", new [=this] (e) =>
			{
				Play(Assets.Click);
				if (mMode != .Alone)
				{
					if (let net = Net)
						net.Disconnect();
					mMode = .Alone;
				}
				mReadyIn = -1.0f;
				mJoinWait = -1.0f;
				ShowTitle();
				return true;
			});
	}

	// ---- input and time under the menus ----

	/// Under any menu the player's actions read released: the input map's "Menu" set (Pause alone)
	/// is pushed as the only one in effect, and a press already held when it opens or closes stays
	/// latched until let go, so the press that works a menu's button is never a Tag. Once, however
	/// many menus ask.
	private void HoldInput()
	{
		if (!mInputHeld)
		{
			if (let input = Controls)
				input.PushSet("Menu");
			mInputHeld = true;
		}
	}

	private void ReleaseInput()
	{
		if (mInputHeld)
		{
			if (let input = Controls)
				input.PopSet();
			mInputHeld = false;
		}
	}

	/// Alone, the scene stops behind a menu too. In a networked round it goes on (the host runs
	/// the world for everyone, and a joiner's scene must keep hearing the host: a new round, say).
	private void HoldStill()
	{
		HoldInput();
		if (mMode == .Alone)
			Instance.InstanceTimeScale = 0.0f;
	}

	private void LetGo()
	{
		Instance.InstanceTimeScale = 1.0f;
		ReleaseInput();
	}

	/// The HUD over the scene that is already running.
	private void EnterRound()
	{
		LeaveTitle();
		if (let stack = Hud.Screens(Run))
			stack.Clear();
		Push(Assets.HudDoc);
		mInRound = true;
		mPaused = false;
		mNote = 0.0f;
		LetGo();
	}

	// ---- what the HUD says ----

	private void Play(Guid clip)
	{
		if (let audio = Sound)
			audio.PlayOneShot(clip, .Effects, 0.8f);
	}

	/// The HUD's word, faded in (from the sheet's 0, or a fade going) and out after a while.
	private void Note(StringView text)
	{
		SetText("hud-note", text);
		Hud.Fade(Find("hud-note"), "opacity", "1", 0.15f, "ease");
		mNote = 3.0f;
	}

	/// In blender/guest.py's costume order, which the crowd and the looks follow.
	private static StringView CostumeName(int32 costume)
	{
		switch (costume)
		{
		case 0: return "a rose gown";
		case 1: return "a teal gown";
		case 2: return "a gold gown";
		case 3: return "a black coat";
		case 4: return "a plum coat";
		default: return "an ivory coat";
		}
	}

	private static StringView Place(int32 p)
	{
		return (p == 1) ? "1st" : ((p == 2) ? "2nd" : ((p == 3) ? "3rd" : "4th"));
	}

	/// `seconds` as minutes and seconds, 1:05.
	private static void Clock(float seconds, String outText)
	{
		let whole = (int32)seconds;
		outText.AppendF("{}:{}{}", whole / 60, ((whole % 60) < 10) ? "0" : "", whole % 60);
	}

	/// The save's best round on `map`, cNoBest without one (or without a save).
	private int32 SavedBest(int32 map)
	{
		let save = Save;
		return (save != null) ? save.GetInt(scope $"best.{MapName(map)}", cNoBest) : cNoBest;
	}

	// ---- the screens ----

	/// Pushes the GUI document `document` (its asset id) on the screen stack.
	private void Push(StringView document)
	{
		if (let stack = Hud.Screens(Run))
			stack.PushDocument(document);
	}

	/// The element `id`, the top screen first.
	private Node Find(StringView id) => Hud.FindOnTop(Run, id);

	private void SetText(StringView id, StringView text) => Hud.SetText(Find(id), text);

	/// Calls `handler` on a click of the element `id`. The element's own to delete: it goes with
	/// the screen. Deleted at once when there is no such element.
	private void Wire(StringView id, delegate bool(Sedulous.GUI.Event e) handler)
	{
		let node = Find(id);
		if (node == null)
		{
			delete handler;
			return;
		}
		node.On("click", handler);
	}
}
