using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.GUI;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The run: the title and its courses, and in a run the clock, the gates and their penalties, the
/// gems, the tricks, the HUD, and the results.
///
/// The title lists the courses with the best medal and time won on each (from the save); a course
/// opens with a bronze on the one before it. Picking one loads its scene afresh. Pause (Escape or
/// Start) in a run holds it still under the pause menu: Resume (or Pause, or Grab, B on a pad)
/// rides on, Restart run starts it over, Courses goes back to the title. On the results, Pause goes
/// back to the title.
///
/// The course's pieces report what happens, as the run's events: the gates announce themselves
/// (GateRegistered) and each crossing (GatePassed, GateMissed: round the outside costs
/// cMissPenalty seconds); the finish line holds the course's medal times (MedalTimes) and ends the
/// run (RunFinished). The clock starts when the rider does (RunStarted, from the Board), with the
/// medal ghosts, not while the scene is still coming in. The gems announce themselves too
/// (GemRegistered) and report being taken (GemCollected), each with how many it counts for. The
/// board tells each landing after real air (TrickLanded): a clean one scores its air, its half
/// turns and its grab, times the combo, which a clean landing or a near miss past a tree
/// (NearMiss) raises and a crash (RiderCrashed) or a missed gate ends. Clearing a crevasse
/// (GapCleared) scores too and raises the combo. On a course with an avalanche, the HUD shows how
/// far behind it is from the moment it breaks loose (AvalancheReleased, AvalancheGap); catching
/// the rider (AvalancheCaught) is a crash, and it is spent.
///
/// The results tally the run a row at a time (the ride, the gates, the gems, the tricks, the time
/// bonus), then land the final time with the medal it earned, the score and the course's best. The
/// best time and the best medal are kept in the save ("best.<scene>", "medal.<scene>"), and a run
/// that beats the best is told (NewBest) so the PlayerGhost keeps it as the course's ghost. Jump
/// skips to the end, then starts the next run (RunRestart puts the rider back at the top, the gates
/// back to waiting and the gems back in place).
///
/// A run that wins a better medal on the last course (Ridge) than it had is followed by the
/// ending: the best medal and time on every course, their total and the medals won. Jump from it
/// goes back to the title.
///
/// The screens are the GUI documents Tools/setup.py imports, pushed on the run GUI's screen stack
/// by id; a screen is loaded fresh each time it is pushed, so its buttons are wired again each
/// time, and the handlers go with its nodes.
[Game]
class SnowlineGame : Game
{
	private const int32 cCourseCount = 3;
	private const float cMusicVolume = 0.55f;
	private const float cMissPenalty = 2.0f;
	/// A gem's worth.
	private const int32 cGemPoints = 100;
	/// Each second under the bronze time.
	private const int32 cBonusPerSecond = 100;
	/// The five rows, then the final time and medal, then the score.
	private const int32 cTallySteps = 7;
	/// A second in the air.
	private const int32 cAirPoints = 200;
	/// A half turn.
	private const int32 cSpinPoints = 250;
	/// A second holding a grab.
	private const int32 cGrabPoints = 400;
	/// The highest combo multiplier.
	private const int32 cComboMost = 5;
	/// A trunk passed close, fast.
	private const int32 cNearMissPoints = 100;
	/// A crevasse cleared.
	private const int32 cGapPoints = 500;
	/// How long a landed trick shows (s).
	private const float cTrickShown = 1.6f;
	/// The first row's moment after the finish (s).
	private const float cTallyFirst = 0.5f;
	/// Between the rows (s).
	private const float cTallyGap = 0.45f;
	/// How long the controls show as a course starts (s).
	private const float cControlsShown = 6.0f;

	/// The title is up: nothing runs behind it.
	private bool mOnTitle = false;
	/// The ending is up.
	private bool mOnEnding = false;
	/// This run won a better medal on the last course.
	private bool mEndingDue = false;
	/// The pause menu is up over the run.
	private bool mPaused = false;
	/// The track playing (nil for none).
	private Guid mMusic = Guid();
	/// The course ridden (its place in the title's list).
	private int32 mCourse = 0;
	private bool mRunning = true;
	/// The rider's first frame has come (the clock runs from it).
	private bool mStarted = false;
	/// Seconds on the clock this run.
	private float mTime = 0.0f;
	/// Seconds added for missed gates.
	private float mPenalty = 0.0f;
	/// How many gates the course has.
	private int32 mGates = 0;
	private int32 mPassed = 0;
	private int32 mMissed = 0;
	/// How long the "+2 s" shows yet.
	private float mFlash = 0.0f;
	/// How many gems the course has.
	private int32 mGems = 0;
	private int32 mTaken = 0;

	// Tricks: the one landing now (its parts as the board reports them), the combo, the points.
	private float mTrickAir = 0.0f;
	private int32 mTrickSpin = 0;
	private float mTrickGrab = 0.0f;
	private int32 mCombo = 1;
	/// Trick points this run.
	private int32 mTricks = 0;
	/// How long the landed trick shows yet.
	private float mTrickShow = 0.0f;
	/// How long the controls panel shows yet.
	private float mControlsShow = 0.0f;
	/// The avalanche has just caught the rider (its crash follows).
	private bool mCaught = false;

	// The course's medal times (s, penalties included), from the finish line.
	private float mGold = 0.0f;
	private float mSilver = 0.0f;
	private float mBronze = 0.0f;

	// The results: the tally's steps shown so far, the time since the finish, and the course's
	// best before this run (-1 for none).
	private int32 mTallyStep = 0;
	private float mTallyTime = 0.0f;
	private float mPreviousBest = -1.0f;

	// ---- the run's services; null outside a run that has them ----
	private InputFacade Controls => (Instance != null) ? Instance.Get<InputFacade>() : null;
	private SaveFacade Save => (Instance != null) ? Instance.Get<SaveFacade>() : null;
	private AudioFacade Sound => (Instance != null) ? Instance.Get<AudioFacade>() : null;

	protected override void OnLaunch()
	{
		Listen<GateRegistered>(new [=this] (evt) =>
			{
				mGates += 1;
				ShowGates();
			});
		Listen<GatePassed>(new [=this] (evt) => OnGatePassed());
		Listen<GateMissed>(new [=this] (evt) => OnGateMissed());
		Listen<GemRegistered>(new [=this] (evt) =>
			{
				mGems += evt.Value;
				ShowGems();
			});
		Listen<GemCollected>(new [=this] (evt) =>
			{
				mTaken += evt.Value;
				ShowGems();
			});
		Listen<TrickLanded>(new [=this] (evt) => OnTrickLanded(evt));
		Listen<NearMiss>(new [=this] (evt) => OnNearMiss());
		Listen<GapCleared>(new [=this] (evt) => OnGapCleared(evt.Distance));
		Listen<RiderCrashed>(new [=this] (evt) => OnRiderCrashed());
		Listen<AvalancheReleased>(new [=this] (evt) => OnAvalancheReleased(evt.Metres));
		Listen<AvalancheGap>(new [=this] (evt) => OnAvalancheGap(evt.Metres));
		Listen<AvalancheCaught>(new [=this] (evt) => OnAvalancheCaught());
		Listen<MedalTimes>(new [=this] (evt) =>
			{
				mGold = evt.Gold;
				mSilver = evt.Silver;
				mBronze = evt.Bronze;
			});
		Listen<RunStarted>(new [=this] (evt) => { mStarted = true; });
		Listen<RunFinished>(new [=this] (evt) => OnRunFinished());
		ShowTitle();
	}

	protected override void OnExit()
	{
		// The screens' handlers call into this game: they go with it.
		if (let stack = Screens())
			stack.Clear();
	}

	// ---- the title: a course to ride, each with the best won on it, or what unlocks it ----

	private void ShowTitle()
	{
		mOnTitle = true;
		Music(Assets.MusicTitle);
		Instance.InstanceTimeScale = 0.0f; // the scene behind the title holds still
		if (let stack = Screens())
		{
			stack.Clear();
			stack.PushDocument(Assets.TitleDoc);
		}
		for (int32 i < cCourseCount)
		{
			let course = i;
			Wire(scope $"course-{i}", new [=this, =course] (e) =>
				{
					StartCourse(course);
					return true;
				});
		}
		Wire("quit-btn", new [=this] (e) =>
			{
				Play(Assets.Click, .Effects, 0.7f);
				Instance.RequestExit(0);
				return true;
			});
		for (int32 i < cCourseCount)
		{
			let open = Unlocked(i);
			if (let button = Find(scope $"course-{i}"))
				button.Enabled = open;
			if (open)
				SetText(scope $"course-{i}-best", BestLine(i, .. scope .()));
			else
				SetText(scope $"course-{i}-best", scope $"Locked: {CourseName(i - 1)} bronze");
		}
	}

	// ---- the pause menu: the run holds still under it ----

	private void Pause()
	{
		mPaused = true;
		Play(Assets.Click, .Effects, 0.7f);
		mControlsShow = 0.0f;
		Show("hud-controls", false); // the menu shows them itself
		Instance.InstanceTimeScale = 0.0f;
		if (let stack = Screens())
			stack.PushDocument(Assets.PauseDoc);
		Wire("resume-btn", new [=this] (e) =>
			{
				Resume();
				return true;
			});
		Wire("restart-btn", new [=this] (e) =>
			{
				Play(Assets.Click, .Effects, 0.7f);
				Resume();
				Restart();
				return true;
			});
		Wire("courses-btn", new [=this] (e) =>
			{
				Play(Assets.Click, .Effects, 0.7f);
				mPaused = false;
				ShowTitle();
				return true;
			});
	}

	private void Resume()
	{
		if (!mPaused)
			return;
		Play(Assets.Back, .Effects, 0.7f);
		mPaused = false;
		if (let stack = Screens())
			stack.Pop(); // the pause menu
		Instance.InstanceTimeScale = 1.0f;
	}

	/// A course opens with a bronze or better on the one before it; the first is always open.
	private bool Unlocked(int32 index)
	{
		return (index == 0) || (SavedInt("medal", CourseName(index - 1), 0) >= 1);
	}

	/// The best medal and time won on a course, from the save.
	private void BestLine(int32 index, String outLine)
	{
		let best = SavedFloat("best", CourseName(index), -1.0f);
		if (best < 0.0f)
		{
			outLine.Append("Not ridden yet");
			return;
		}
		let time = Clock(best, .. scope .());
		outLine.AppendF("{}   best {}", MedalTitle(SavedInt("medal", CourseName(index), 0)), time);
	}

	/// A course from its top: everything the last run counted starts over, and the scene loads
	/// afresh (its gates, gems and finish announce themselves again).
	private void StartCourse(int32 index)
	{
		if (!Unlocked(index))
			return;
		Play(Assets.Click, .Effects, 0.7f);
		Music(Assets.MusicRun);
		mCourse = index;
		mOnTitle = false;
		mStarted = false;
		mGates = 0;
		mGems = 0;
		mGold = 0.0f;
		mSilver = 0.0f;
		mBronze = 0.0f;
		if (let stack = Screens())
		{
			stack.Clear();
			stack.PushDocument(Assets.HudDoc);
		}
		ResetRun();
		// The controls, keyboard and pad, along the bottom for the first seconds of the course
		// (and always in the pause menu): faded in from the sheet's 0.
		Fade(Find("hud-controls"), "opacity", "1", 0.3f, "ease");
		mControlsShow = cControlsShown;
		Instance.InstanceTimeScale = 1.0f;
		Instance.LoadScene(CourseScene(index));
	}

	/// The game updates at time scale 0 too, so the Pause action is read here while paused.
	protected override void OnUpdate(float dt)
	{
		if (mOnTitle)
			return;
		if (mOnEnding)
		{
			if (Pressed("Jump") || Pressed("Pause"))
			{
				mOnEnding = false;
				ShowTitle();
			}
			return;
		}
		if (mPaused)
		{
			// Back out of the menu the way it came in, or with B (the Grab button) on a pad.
			if (Pressed("Pause") || Pressed("Grab"))
				Resume();
			return;
		}
		if (Pressed("Pause"))
		{
			if (mRunning)
				Pause();
			else
				ShowTitle(); // on the results: back to the courses
			return;
		}
		if (mRunning)
		{
			if (!mStarted)
				return;
			mTime += dt;
			SetText("hud-time", Clock(mTime + mPenalty, .. scope .()));
			let real = Instance.RealDeltaTime;
			if (mFlash > 0.0f)
			{
				mFlash -= real;
				if (mFlash <= 0.0f)
					Show("hud-penalty", false);
			}
			if (mControlsShow > 0.0f)
			{
				mControlsShow -= real;
				if (mControlsShow <= 0.0f)
					Fade(Find("hud-controls"), "opacity", "0", 0.6f, "ease");
			}
			if (mTrickShow > 0.0f)
			{
				mTrickShow -= real;
				if (mTrickShow <= 0.0f)
					Show("hud-trick", false);
			}
			return;
		}
		UpdateResults(dt);
	}

	// ---- what the course's pieces report ----

	private void OnGatePassed()
	{
		Play(Assets.GatePass, .Effects, 0.5f);
		mPassed += 1;
		ShowGates();
	}

	private void OnGateMissed()
	{
		Play(Assets.GateMiss, .Effects, 0.6f);
		EndCombo();
		mMissed += 1;
		mPenalty += cMissPenalty;
		mFlash = 1.2f;
		Show("hud-penalty", true);
		ShowGates();
	}

	/// A trick landed: clean, it scores and the combo grows; crashed, the combo is gone (the crash,
	/// RiderCrashed, ends it).
	private void OnTrickLanded(TrickLanded trick)
	{
		mTrickAir = trick.Air;
		mTrickSpin = trick.Spin;
		mTrickGrab = trick.Grab;
		if (!mRunning || !trick.Clean)
			return;
		var points = (int32)(mTrickAir * (float)cAirPoints) + (mTrickSpin / 180) * cSpinPoints
			+ (int32)(mTrickGrab * (float)cGrabPoints);
		points *= mCombo;
		mTricks += points;
		ShowTrick(TrickName(.. scope .()), scope $"+{points}");
		RaiseCombo();
	}

	/// A trunk passed close and fast: points, and the combo grows, as a clean landing's does.
	private void OnNearMiss()
	{
		if (!mRunning)
			return;
		let points = cNearMissPoints * mCombo;
		mTricks += points;
		ShowTrick("Near miss", scope $"+{points}");
		RaiseCombo();
	}

	/// The avalanche: its gap on the HUD, red and beating as it closes.
	private void OnAvalancheReleased(int32 metres)
	{
		if (!mRunning)
			return;
		Display("hud-avalanche-panel", true);
		OnAvalancheGap(metres);
	}

	private void OnAvalancheGap(int32 metres)
	{
		let gap = Find("hud-avalanche") as UIWidget;
		if (!mRunning || (gap == null))
			return;
		SetText("hud-avalanche", scope $"{metres} m");
		if (metres < 15)
		{
			gap.AddClass("close");
			if (metres % 2 == 0)
			{
				// A beat: up and back down.
				if (let panel = Find("hud-avalanche-panel"))
					panel.Animate("transform", "scale(1.12)", 0.09f, "ease-out").From("scale(1)").Repeat(2).PingPong().ReleaseRef();
			}
		}
		else
		{
			gap.RemoveClass("close");
		}
	}

	/// Caught: the board crashes, and the avalanche, spent, rolls on past.
	private void OnAvalancheCaught()
	{
		if (!mRunning)
			return;
		ShowTrick("Caught by the avalanche", "");
		Display("hud-avalanche-panel", false);
		mCaught = true;
	}

	/// Over a crevasse and down past it, `distance` metres from its lip: points, and the combo
	/// grows.
	private void OnGapCleared(float distance)
	{
		if (!mRunning)
			return;
		let points = cGapPoints * mCombo;
		mTricks += points;
		let metres = (int32)distance;
		ShowTrick(scope $"Gap {metres} m", scope $"+{points}");
		RaiseCombo();
	}

	/// Down in the snow off a landing or into a tree: the combo is gone.
	private void OnRiderCrashed()
	{
		if (!mRunning)
			return;
		EndCombo();
		if (!mCaught)
			ShowTrick("Crash", ""); // a catch's crash keeps its own message
		mCaught = false;
	}

	private void RaiseCombo()
	{
		if (mCombo < cComboMost)
			mCombo += 1;
		SetText("hud-combo", scope $"Combo x{mCombo}");
		Show("hud-combo", true);
	}

	/// "360 Grab", "180", "Air": the spin if any, then the grab if held a while, else just air.
	private void TrickName(String outName)
	{
		if (mTrickSpin > 0)
			outName.AppendF("{}", mTrickSpin);
		if (mTrickGrab >= 0.2f)
		{
			if (!outName.IsEmpty)
				outName.Append(" ");
			outName.Append("Grab");
		}
		if (outName.IsEmpty)
			outName.Append("Air");
	}

	private void ShowTrick(StringView name, StringView points)
	{
		let trick = Find("hud-trick");
		if (trick == null)
			return;
		if (points.IsEmpty)
			SetText("hud-trick", name);
		else
			SetText("hud-trick", scope $"{name}   {points}");
		trick.Animate("opacity", "1", 0.15f, "ease").From("0").ReleaseRef();
		mTrickShow = cTrickShown;
	}

	private void EndCombo()
	{
		mCombo = 1;
		Show("hud-combo", false);
	}

	private void OnRunFinished()
	{
		mRunning = false;
		Display("hud-avalanche-panel", false);
		mTallyStep = 0;
		mTallyTime = 0.0f;
		KeepBest(mTime + mPenalty);
		if (let stack = Screens())
			stack.PushDocument(Assets.FinishDoc);
	}

	/// The course's best time and medal, kept in the save; a new best is told at once, so the
	/// ghost keeps this run before the next one starts recording.
	private void KeepBest(float total)
	{
		let course = scope String();
		if (let scene = CurrentScene)
			course.Append(scene.Name);
		mPreviousBest = SavedFloat("best", course, -1.0f);
		let save = Save;
		if ((mPreviousBest < 0.0f) || (total < mPreviousBest))
		{
			if (save != null)
				save.SetFloat(scope $"best.{course}", total);
			Post(NewBest(total));
		}
		let rank = MedalRank(total);
		if (rank > SavedInt("medal", course, 0))
		{
			if (save != null)
				save.SetInt(scope $"medal.{course}", rank);
			mEndingDue = StringView(course) == CourseName(cCourseCount - 1);
		}
		if (save != null)
			save.Flush();
	}

	// ---- the results: one row at a time, then the final time and its medal, then the score ----

	private void UpdateResults(float dt)
	{
		mTallyTime += dt;
		if (mTallyStep < cTallySteps)
		{
			if (Pressed("Jump"))
			{
				// Skip to the end: everything at once, quietly.
				while (mTallyStep < cTallySteps)
				{
					TallyStep(mTallyStep, true);
					mTallyStep += 1;
				}
				return;
			}
			while ((mTallyStep < cTallySteps) && (mTallyTime >= cTallyFirst + cTallyGap * (float)mTallyStep))
			{
				TallyStep(mTallyStep, false);
				mTallyStep += 1;
			}
			return;
		}
		if (Pressed("Jump"))
		{
			if (let stack = Screens())
				stack.Pop(); // the results
			if (mEndingDue)
			{
				mEndingDue = false;
				ShowEnding();
				return;
			}
			Restart();
		}
	}

	// ---- the ending: every course's best, their total, the medals ----

	private void ShowEnding()
	{
		mOnEnding = true;
		Play(Assets.MedalSting, .Music, 0.9f);
		Music(Assets.MusicTitle);
		Instance.InstanceTimeScale = 0.0f; // the course behind it holds still
		if (let stack = Screens())
		{
			stack.Clear();
			stack.PushDocument(Assets.EndingDoc);
		}
		let last = CourseName(cCourseCount - 1);
		let headline = MedalTitle(SavedInt("medal", last, 0));
		SetText("end-headline", scope $"{headline} on {last}");
		float total = 0.0f;
		bool allRidden = true;
		int32 golds = 0;
		int32 silvers = 0;
		int32 bronzes = 0;
		for (int32 i < cCourseCount)
		{
			let best = SavedFloat("best", CourseName(i), -1.0f);
			let rank = SavedInt("medal", CourseName(i), 0);
			SetMedal(scope $"end-{i}-medal", rank);
			if (best < 0.0f)
			{
				SetText(scope $"end-{i}-best", "not ridden");
				allRidden = false;
			}
			else
			{
				let time = Clock(best, .. scope .());
				let title = MedalTitle(rank);
				SetText(scope $"end-{i}-best", scope $"{title}   {time}");
				total += best;
			}
			golds += (rank == 3) ? 1 : 0;
			silvers += (rank == 2) ? 1 : 0;
			bronzes += (rank == 1) ? 1 : 0;
		}
		let totalText = scope String();
		if (allRidden)
			Clock(total, totalText);
		SetText("end-total", totalText);
		SetText("end-medals", scope $"{golds} gold   {silvers} silver   {bronzes} bronze");
		SetText("end-closing", (golds == cCourseCount) ? "Gold on every course. Thanks for riding."
			: "Thanks for riding. There is gold still out there.");
	}

	/// The music: switched only when the track changes, so the title's keeps playing across menus.
	private void Music(Guid track)
	{
		if (mMusic == track)
			return;
		mMusic = track;
		if (let audio = Sound)
			audio.PlayMusic(track, 1.0f, cMusicVolume);
	}

	private static StringView MedalTitle(int32 rank)
	{
		switch (rank)
		{
		case 3: return "Gold";
		case 2: return "Silver";
		case 1: return "Bronze";
		default: return "No medal";
		}
	}

	/// Steps 0-4 are the rows, 5 the final time with its medal, 6 the score and the best.
	private void TallyStep(int32 step, bool quiet)
	{
		let total = mTime + mPenalty;
		if (step <= 4)
		{
			StringView key;
			let value = scope String();
			switch (step)
			{
			case 0:
				key = "ride";
				Clock(mTime, value);
			case 1:
				key = "gates";
				value.AppendF("{} / {}", mPassed, mGates);
				if (mMissed != 0)
					value.AppendF("    +{} s", (int32)mPenalty);
			case 2:
				key = "gems";
				value.AppendF("{} / {}    +{}", mTaken, mGems, mTaken * cGemPoints);
			case 3:
				key = "tricks";
				value.AppendF("+{}", mTricks);
			default:
				key = "bonus";
				value.AppendF("+{}", TimeBonus(total));
			}
			SetText(scope $"value-{key}", value);
			let rowId = scope $"row-{key}";
			if (quiet)
			{
				Show(rowId, true);
			}
			else if (let row = Find(rowId))
			{
				// In from the left as it fades in.
				row.Animate("opacity", "1", 0.2f, "ease").From("0").ReleaseRef();
				row.Animate("transform", "translateX(0px)", 0.25f, "ease-out").From("translateX(-24px)").ReleaseRef();
				Play(Assets.GemChime, .Effects, 0.3f, 0.8f + 0.08f * (float)step);
			}
			return;
		}
		if (step == 5)
		{
			SetText("final-time", Clock(total, .. scope .()));
			let rank = MedalRank(total);
			SetText("final-medal", MedalLine(total, .. scope .()));
			SetMedal("medal", rank);
			Show("medal", true);
			if (quiet)
				return;
			if (rank == 0)
			{
				Play(Assets.NoMedalSting, .Music, 0.8f);
			}
			else
			{
				Fade(Find("medal"), "transform", "scale(1)", 0.3f, "ease-out", "scale(1.6)");
				Play(Assets.MedalSting, .Music, 0.9f);
			}
			return;
		}
		Show("row-score", true);
		SetText("final-score", scope $"{mTaken * cGemPoints + mTricks + TimeBonus(total)}");
		if (mPreviousBest < 0.0f)
		{
			SetText("final-best", "Your ghost will ride this run");
		}
		else if (total < mPreviousBest)
		{
			let was = Clock(mPreviousBest, .. scope .());
			SetText("final-best", scope $"New best!  (was {was})");
		}
		else
		{
			let best = Clock(mPreviousBest, .. scope .());
			SetText("final-best", scope $"Best {best}");
		}
		SetText("final-prompt", "to ride again"); // after the prompt beside it: the control Jump takes
	}

	/// The medal `total` earns: 3 gold, 2 silver, 1 bronze, 0 none.
	private int32 MedalRank(float total)
	{
		if ((mGold > 0.0f) && (total <= mGold))
			return 3;
		if ((mSilver > 0.0f) && (total <= mSilver))
			return 2;
		if ((mBronze > 0.0f) && (total <= mBronze))
			return 1;
		return 0;
	}

	/// The medal earned and the next one's time to beat.
	private void MedalLine(float total, String outLine)
	{
		if (mBronze <= 0.0f)
			return;
		switch (MedalRank(total))
		{
		case 3:
			outLine.Append("Gold");
		case 2:
			outLine.AppendF("Silver.  Gold at {}", Clock(mGold, .. scope .()));
		case 1:
			outLine.AppendF("Bronze.  Silver at {}", Clock(mSilver, .. scope .()));
		default:
			outLine.AppendF("No medal.  Bronze at {}", Clock(mBronze, .. scope .()));
		}
	}

	/// Points for each second under the bronze time.
	private int32 TimeBonus(float total)
	{
		let under = mBronze - total;
		return (under > 0.0f) ? (int32)(under * (float)cBonusPerSecond) : 0;
	}

	private void Restart()
	{
		ResetRun();
		Post(RunRestart(mCourse));
	}

	/// What a run counts, back to its start (the course's own counts stay: its gates and gems).
	private void ResetRun()
	{
		mRunning = true;
		mTime = 0.0f;
		mPenalty = 0.0f;
		mPassed = 0;
		mMissed = 0;
		mFlash = 0.0f;
		mTaken = 0;
		mTricks = 0;
		mTrickShow = 0.0f;
		EndCombo();
		Show("hud-trick", false);
		Show("hud-penalty", false);
		Display("hud-avalanche-panel", false);
		ShowGates();
		ShowGems();
	}

	private void ShowGates()
	{
		SetText("hud-gates", scope $"{mPassed} / {mGates}");
	}

	private void ShowGems()
	{
		SetText("hud-gems", scope $"{mTaken} / {mGems}");
	}

	/// `seconds` as m:ss.cc.
	private static void Clock(float seconds, String outText)
	{
		let whole = (int32)seconds;
		let hundredths = (int32)((seconds - (float)whole) * 100.0f);
		let s = whole % 60;
		outText.AppendF("{}:{}{}.{}{}", whole / 60, (s < 10) ? "0" : "", s, (hundredths < 10) ? "0" : "", hundredths);
	}

	// ---- the courses ----

	private static Guid CourseScene(int32 index)
	{
		switch (index)
		{
		case 2: return Assets.Ridge;
		case 1: return Assets.Forest;
		default: return Assets.Meadow;
		}
	}

	/// The course's name: its scene's, and its keys' in the save.
	private static StringView CourseName(int32 index)
	{
		switch (index)
		{
		case 2: return "Ridge";
		case 1: return "Forest";
		default: return "Meadow";
		}
	}

	// ---- the save ----

	/// The save's `key`.<course> whole number, `fallback` without one (or without a save).
	private int32 SavedInt(StringView key, StringView course, int32 fallback)
	{
		let save = Save;
		return (save != null) ? save.GetInt(scope $"{key}.{course}", fallback) : fallback;
	}

	private float SavedFloat(StringView key, StringView course, float fallback)
	{
		let save = Save;
		return (save != null) ? save.GetFloat(scope $"{key}.{course}", fallback) : fallback;
	}

	// ---- sound ----

	/// Plays `clip` once on `bus`.
	private void Play(Guid clip, AudioBus bus, float volume, float pitch = 1.0f)
	{
		if (let audio = Sound)
			audio.PlayOneShot(clip, bus, volume, pitch);
	}

	/// Whether `action` was pressed this frame.
	private bool Pressed(StringView action)
	{
		let input = Controls;
		return (input != null) && input.WasPressed(action);
	}

	// ---- the screens ----

	/// The run GUI's screen stack; null without one.
	private ScreenStack Screens()
	{
		let gui = (Instance != null) ? Instance.Get<GuiFacade>() : null;
		let root = (gui != null) ? gui.Root() : null;
		return (root != null) ? (root.FindElement("screens") as ScreenStack) : null;
	}

	/// The element `id`, the top screen first: a screen just cleared or popped away is still in
	/// the tree while its exit plays, with the same ids, and would be found first.
	private Node Find(StringView id)
	{
		let gui = (Instance != null) ? Instance.Get<GuiFacade>() : null;
		let root = (gui != null) ? gui.Root() : null;
		if (root == null)
			return null;
		let stack = root.FindElement("screens") as ScreenStack;
		let top = (stack != null) ? stack.Top : null;
		let found = (top != null) ? top.FindElement(id) : null;
		return (found != null) ? found : root.FindElement(id);
	}

	/// The element `id`'s text, when it is a label; nothing when the screens up now do not have
	/// it (a course's gates and gems announce themselves behind the title, before the HUD is up).
	private void SetText(StringView id, StringView text)
	{
		if (let label = Find(id) as Label)
			label.Text = text;
	}

	/// Shown at once, or hidden (a sheet's opacity 0 keeps its place in the layout).
	private void Show(StringView id, bool shown)
	{
		Fade(Find(id), "opacity", shown ? "1" : "0", 0.0f, "linear");
	}

	/// In the layout, or out of it.
	private void Display(StringView id, bool shown)
	{
		if (let node = Find(id))
			node.Visible = shown;
	}

	/// `node`'s `property` eased to `value` over `seconds` (nought sets it at once), from `from`
	/// when one is given.
	private static void Fade(Node node, StringView property, StringView value, float seconds, StringView easing, StringView from = default)
	{
		if (node == null)
			return;
		let tween = node.Animate(property, value, seconds, easing);
		if (!from.IsEmpty)
			tween.From(from);
		tween.ReleaseRef();
	}

	/// The medal's disc: its colour by class, rank 0 (none) to 3 (gold).
	private void SetMedal(StringView id, int32 rank)
	{
		let disc = Find(id) as UIWidget;
		if (disc == null)
			return;
		disc.RemoveClass("medal-bronze");
		disc.RemoveClass("medal-silver");
		disc.RemoveClass("medal-gold");
		if (rank > 0)
			disc.AddClass((rank == 3) ? "medal-gold" : ((rank == 2) ? "medal-silver" : "medal-bronze"));
	}

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
