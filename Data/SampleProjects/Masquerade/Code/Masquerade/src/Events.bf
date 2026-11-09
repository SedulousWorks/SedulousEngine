using System;
using Sedulous.Core;

namespace Masquerade;

// What the ball tells the rest of the run, each posted to the run (Post) and heard at the run's
// drain, at the end of the frame, by whoever listens: the game (MasqueradeGame) hears the round
// from this peer's player's side, and the guests and the ball hear the orchestra's cue.

/// The orchestra's cue changed to `Cue` (Cues: stroll, gather, dance), on every peer: the guests
/// follow it, and the ball judges who stands out by it.
struct CueChanged
{
	public int32 Cue;

	public this(int32 cue)
	{
		Cue = cue;
	}
}

/// What happened to this peer's player, or that a mask flared: the game says so on the HUD with
/// its sound.
enum NoteKind : int32
{
	/// You tagged your target.
	GotTarget = 1,
	/// You tagged the wrong person: your mask flares.
	Missed = 2,
	/// Your hunter tagged you: a new costume, somewhere else.
	Tagged = 3,
	/// Someone's mask flares: a hunter, there.
	Flare = 4,
	/// Every seat is a player's: you watch.
	Full = 6
}

/// A note for this peer's player (NoteKind).
struct RoundNote
{
	public NoteKind What;

	public this(NoteKind what)
	{
		What = what;
	}
}

/// Four times a second: this peer's player's points, the seconds left in the round, the costume
/// its target wears and its place (1 the lead; ties share it).
struct HudReport
{
	public int32 Score;
	public float TimeLeft;
	public int32 TargetCostume;
	public int32 Rank;

	public this(int32 score, float timeLeft, int32 targetCostume, int32 rank)
	{
		Score = score;
		TimeLeft = timeLeft;
		TargetCostume = targetCostume;
		Rank = rank;
	}
}

/// Someone to tag in front of this peer's hunter (`Yes`), or no longer: the HUD shows Tag's prompt
/// while there is.
struct InReach
{
	public bool Yes;

	public this(bool yes)
	{
		Yes = yes;
	}
}

/// The hunter whose mark this peer's player is stands near (`Yes`), or no longer.
struct HunterNear
{
	public bool Yes;

	public this(bool yes)
	{
		Yes = yes;
	}
}

/// The round is over: this peer's player's points (`Yours`, nought when it holds no seat), then
/// the other three seats' in seat order.
struct RoundOver
{
	public int32 Yours;
	public int32 Other1;
	public int32 Other2;
	public int32 Other3;

	public this(int32 yours, int32 other1, int32 other2, int32 other3)
	{
		Yours = yours;
		Other1 = other1;
		Other2 = other2;
		Other3 = other3;
	}
}

/// A new round began in the scene that is already running (the host started another), with
/// `TimeLeft` seconds on its clock: a joiner leaves its results for it.
struct RoundStarted
{
	public float TimeLeft;

	public this(float timeLeft)
	{
		TimeLeft = timeLeft;
	}
}
