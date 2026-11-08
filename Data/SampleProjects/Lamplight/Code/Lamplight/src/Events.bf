using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Lamplight;

// What a level's pieces tell the rest of the run, each posted to the run (Post) and heard at the
// run's drain, at the end of the frame, by whoever listens: the game (LamplightGame), the thief,
// the guards and the alarm.

/// Loot taken, worth `Value`: the game counts it.
struct LootTaken
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// The level's target taken, worth `Value`: the game counts it, and the thief may now leave by the
/// exit.
struct TargetTaken
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// A guard (`By`) gave chase: the game counts it (a level done without one is a ghost), and the
/// upper floor's alarm rings.
struct ThiefSpotted
{
	public EntityHandle By;

	public this(EntityHandle by)
	{
		By = by;
	}
}

/// A guard caught the thief at `At`: the thief goes back to his checkpoint, every guard stands down
/// for a while, and the game counts it.
struct ThiefCaught
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}

/// A noise at `At`, as loud as `Loudness` (a step's 0 to 1; a loudness of 1 is heard as far as a
/// guard's hearing): a guard who hears it goes to look.
struct Noise
{
	public Float3 At;
	public float Loudness;

	public this(Float3 at, float loudness)
	{
		At = at;
		Loudness = loudness;
	}
}

/// The alarm rang where the thief was seen (`At`): the game says so.
struct AlarmRung
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}

/// The thief reached a checkpoint at `At`: a catch now sends him back there.
struct CheckpointReached
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}

/// The thief walked into the exit at `At`: with the target the level is done, without it the HUD
/// says what he is there for.
struct ThiefEscaped
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}
