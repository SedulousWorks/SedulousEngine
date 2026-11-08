using System;

namespace PaperKid;

// What a block's code tells the rest of the run, each posted to the run (Post) and heard at the
// run's drain, at the end of the frame, by whoever listens: the block (Block), the game
// (PaperKidGame) and the behaviours.

/// The block's papers left, after its start and after each throw: the bike stops aiming at none.
struct PapersLeft
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// The bike threw `Count` papers: the block takes them off its stock.
struct PaperThrown
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// The bike crashed `Count` times: the block takes its time penalty, the camera shakes.
struct BikeCrashed
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// A subscriber took its paper, worth `Points`: the game scores it, the block counts it.
struct Delivered
{
	public int32 Points;

	public this(int32 points)
	{
		Points = points;
	}
}

/// The block's quota is met with `SecondsLeft` whole seconds on the clock (the game's time
/// bonus): the game celebrates and the bike throws confetti.
struct QuotaMet
{
	public int32 SecondsLeft;

	public this(int32 secondsLeft)
	{
		SecondsLeft = secondsLeft;
	}
}

/// Why a block was failed.
enum FailReason : uint8
{
	/// The clock ran out.
	case OutOfTime = 0;
	/// The last paper was thrown, and the grace for it to land ran out.
	case OutOfPapers = 1;
}

/// The block is failed, for `Reason`: the game spends a life.
struct LevelFailed
{
	public FailReason Reason;

	public this(FailReason reason)
	{
		Reason = reason;
	}
}

/// The block's cars drive at `Speed` m/s.
struct TrafficSpeedChanged
{
	public float Speed;

	public this(float speed)
	{
		Speed = speed;
	}
}

/// The block's walkers walk at `Speed` m/s.
struct PedestrianSpeedChanged
{
	public float Speed;

	public this(float speed)
	{
		Speed = speed;
	}
}

/// The block's ring road runs `Ring` metres from the middle: the walkers keep to the band round it.
struct BlockRingChanged
{
	public float Ring;

	public this(float ring)
	{
		Ring = ring;
	}
}
