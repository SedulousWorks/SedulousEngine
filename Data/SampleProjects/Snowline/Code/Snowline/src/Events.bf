using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Snowline;

// What the course's pieces and the game tell one another, each posted to the run (Post) and heard
// at the run's drain, at the end of the frame, by whoever listens: the game (SnowlineGame), the
// board, the ghosts, the camera, the gates, the gems, the kickers, the gap, the finish and the
// avalanche.

/// The rider's first frame (the board's start): the clock and the medal ghosts count from here,
/// and the player's ghost starts recording.
struct RunStarted
{
	public EntityHandle Rider;

	public this(EntityHandle rider)
	{
		Rider = rider;
	}
}

/// The game starts the next run on the same course (`Course`, its place in the title's list): the
/// rider back at the top at rest, the gates, the finish, the kickers and the gap waiting, the gems
/// back, the ghosts at the top and the avalanche parked.
struct RunRestart
{
	public int32 Course;

	public this(int32 course)
	{
		Course = course;
	}
}

/// The rider crossed the finish line (`Line`): the run is over.
struct RunFinished
{
	public EntityHandle Line;

	public this(EntityHandle line)
	{
		Line = line;
	}
}

/// The course's medal times (s, penalties included), from its finish line as it starts.
struct MedalTimes
{
	public float Gold;
	public float Silver;
	public float Bronze;

	public this(float gold, float silver, float bronze)
	{
		Gold = gold;
		Silver = silver;
		Bronze = bronze;
	}
}

/// A gate (its place down the course, `Index`) is on the course: the game counts it.
struct GateRegistered
{
	public int32 Index;

	public this(int32 index)
	{
		Index = index;
	}
}

/// The rider crossed gate `Index` between its poles.
struct GatePassed
{
	public int32 Index;

	public this(int32 index)
	{
		Index = index;
	}
}

/// The rider went round the outside of gate `Index`: a penalty, and the combo is gone.
struct GateMissed
{
	public int32 Index;

	public this(int32 index)
	{
		Index = index;
	}
}

/// A gem worth `Value` is on the course: the game counts it.
struct GemRegistered
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// A gem worth `Value` was taken.
struct GemCollected
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// A landing after real air: how long the rider was in the air (s), its spin (degrees, in whole
/// half turns), how long it held a grab (s), and whether the landing was clean (a crash follows
/// one that was not).
struct TrickLanded
{
	public float Air;
	public int32 Spin;
	public float Grab;
	public bool Clean;

	public this(float air, int32 spin, float grab, bool clean)
	{
		Air = air;
		Spin = spin;
		Grab = grab;
		Clean = clean;
	}
}

/// The rider went down in the snow at `At`: a landing across the path, a tree or a rock, a gap
/// fallen short or the avalanche. The combo is gone and the camera shakes.
struct RiderCrashed
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}

/// The rider passed close and fast by the trunk at `Trunk` without touching it.
struct NearMiss
{
	public Float3 Trunk;

	public this(Float3 trunk)
	{
		Trunk = trunk;
	}
}

/// The rider flew over a crevasse and came down `Distance` metres past its lip.
struct GapCleared
{
	public float Distance;

	public this(float distance)
	{
		Distance = distance;
	}
}

/// The avalanche broke loose `Metres` behind the rider: the HUD shows the gap from now on.
struct AvalancheReleased
{
	public int32 Metres;

	public this(int32 metres)
	{
		Metres = metres;
	}
}

/// The avalanche's gap to the rider changed, in whole metres.
struct AvalancheGap
{
	public int32 Metres;

	public this(int32 metres)
	{
		Metres = metres;
	}
}

/// The avalanche caught the rider at `At` (the board crashes); it is spent.
struct AvalancheCaught
{
	public Float3 At;

	public this(Float3 at)
	{
		At = at;
	}
}

/// The run that just finished, `Seconds` long with its penalties, is the course's best: the
/// player's ghost keeps its recording.
struct NewBest
{
	public float Seconds;

	public this(float seconds)
	{
		Seconds = seconds;
	}
}
