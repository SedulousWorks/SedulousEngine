using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// A block's rules and numbers: the countdown, the papers, the deliveries toward the quota. Each
/// block's scene turns it on and sets its numbers in its settings block, so each block carries its
/// own.
///
/// It hears the block's behaviours through the run's events, as the game does: a subscriber's
/// Delivered and the bike's PaperThrown and BikeCrashed. It turns them into the block's outcome,
/// QuotaMet (with the whole seconds left, the game's time bonus) or LevelFailed (with the reason),
/// tells the bike how many papers are left (PapersLeft), and writes the HUD's time, papers and
/// deliveries. A crash costs time.
///
/// The block's traffic is set here too: on its first frame (every behaviour has started by the
/// time the events arrive) it tells the cars and walkers their speeds, and the walkers where the
/// ring road runs.
///
/// The clock's tells: "Hurry up!" once at 15 s left, when the block's music also speeds up (the
/// arcade hurry-up: its playback rate eased up, tempo and pitch together; the next block's track
/// starts at its own speed), a tick every second of the last 10 while the HUD's time blinks, and
/// "Time over!" when it runs out. All on scene time, so a pause stops them.
[Level("paperkid.level")]
[DisplayName("Block"), Category("PaperKid")]
[Description("A block's rules: its clock, papers and quota, the traffic's pace, and the outcome it tells the game.")]
class Block : Level
{
	private const float cHurryAt = 15.0f;
	/// The music 20% faster, reached over cHurryMusicEase seconds.
	private const float cHurryMusicRate = 1.2f;
	private const float cHurryMusicEase = 0.6f;
	private const float cTicksFrom = 10.0f;

	[Description("Time limit (s)")]
	public float TimeLimit = 120.0f;
	[Description("Deliveries to clear the block")]
	public int32 Quota = 4;
	[Description("Papers for the block")]
	public int32 Papers = 8;
	[Description("After the last paper, how long it may still land (s)")]
	public float PaperGrace = 3.0f;
	[Description("Car speed (m/s)")]
	public float TrafficSpeed = 6.0f;
	[Description("Pedestrian walking speed (m/s)")]
	public float PedestrianSpeed = 1.6f;
	[Description("Seconds a crash costs")]
	public float CrashPenalty = 5.0f;
	[Description("The ring road's distance from the middle (m)")]
	public float Ring = 24.0f;

	private float mTimeLeft = 0.0f;
	private int32 mPapersLeft = 0;
	private int32 mDelivered = 0;
	private bool mEnded = false;
	/// Counting down once the last paper is thrown; below 0 before.
	private float mGraceLeft = -1.0f;
	private bool mTrafficSet = false;
	private bool mHurried = false;
	/// The whole second last ticked.
	private int32 mLastTick = -1;
	/// The clock dimmed by the blink.
	private bool mDimmed = false;

	protected override void OnStart()
	{
		mTimeLeft = TimeLimit;
		mPapersLeft = Papers;
		mDelivered = 0;
		mEnded = false;
		mGraceLeft = -1.0f;
		mTrafficSet = false;
		mHurried = false;
		mLastTick = -1;
		mDimmed = false;
		Listen<BikeCrashed>(new [=this] (evt) => OnBikeCrashed());
		Listen<PaperThrown>(new [=this] (evt) => OnPaperThrown());
		Listen<Delivered>(new [=this] (evt) => OnDelivered());
		Post(PapersLeft(mPapersLeft));
		UpdateHud();
	}

	protected override void OnUpdate(float dt)
	{
		if (!mTrafficSet)
		{
			mTrafficSet = true;
			Post(TrafficSpeedChanged(TrafficSpeed));
			Post(PedestrianSpeedChanged(PedestrianSpeed));
			Post(BlockRingChanged(Ring));
		}
		if (mEnded)
			return;
		mTimeLeft -= dt;
		if (mTimeLeft <= 0.0f)
		{
			mTimeLeft = 0.0f;
			Feedback.Play(Run, Assets.TimeOverSound);
			Fail(.OutOfTime);
			return;
		}
		ClockTells();
		if (mGraceLeft >= 0.0f)
		{
			mGraceLeft -= dt;
			if (mGraceLeft < 0.0f)
			{
				Fail(.OutOfPapers);
				return;
			}
		}
		UpdateHud();
	}

	private void OnBikeCrashed()
	{
		if (mEnded)
			return;
		mTimeLeft -= CrashPenalty;
		UpdateHud();
	}

	private void OnPaperThrown()
	{
		if (mEnded || (mPapersLeft <= 0))
			return;
		mPapersLeft -= 1;
		Post(PapersLeft(mPapersLeft));
		if (mPapersLeft == 0)
			mGraceLeft = PaperGrace;
		UpdateHud();
	}

	private void OnDelivered()
	{
		if (mEnded)
			return;
		mDelivered += 1;
		UpdateHud();
		if (mDelivered >= Quota)
			Clear();
	}

	private void ClockTells()
	{
		if (!mHurried && (mTimeLeft <= cHurryAt))
		{
			mHurried = true;
			Feedback.Play(Run, Assets.HurrySound);
			if (let audio = RunServices.Get<AudioFacade>(Run))
				audio.SetVoicePitch(audio.MusicVoice(), cHurryMusicRate, cHurryMusicEase);
		}
		if (mTimeLeft > cTicksFrom)
		{
			Blink(false);
			return;
		}
		let second = (int32)mTimeLeft;
		if (second != mLastTick)
		{
			mLastTick = second;
			Feedback.Play(Run, Assets.TickSound, .Effects, 0.7f);
		}
		// Dim for the second half of every second: a blink in step with the ticks.
		Blink((mTimeLeft - (float)second) < 0.5f);
	}

	/// The clock dimmed or not, set when it changes.
	private void Blink(bool dim)
	{
		let time = Hud.Find(Run, "hud-time");
		if ((time == null) || (dim == mDimmed))
			return;
		mDimmed = dim;
		Hud.Snap(time, "opacity", dim ? "0.35" : "1");
	}

	/// The quota is met: the outcome goes out to the run, where the game and the bike hear it.
	private void Clear()
	{
		StopClock();
		Post(QuotaMet((int32)mTimeLeft));
	}

	/// The block is failed, for `reason`: the game hears it.
	private void Fail(FailReason reason)
	{
		StopClock();
		Post(LevelFailed(reason));
	}

	/// The clock stops, with the HUD left showing where it stopped.
	private void StopClock()
	{
		mEnded = true;
		Blink(false); // not left dim by the blink
		UpdateHud();
	}

	private void UpdateHud()
	{
		if (Hud.Find(Run, "hud-time") == null)
			return; // the HUD is not up
		Hud.SetText(Run, "hud-time", scope $"{(int32)(mTimeLeft + 0.99f)}");
		Hud.SetText(Run, "hud-papers", scope $"{mPapersLeft}");
		Hud.SetText(Run, "hud-deliveries", scope $"{mDelivered} / {Quota}");
	}
}
