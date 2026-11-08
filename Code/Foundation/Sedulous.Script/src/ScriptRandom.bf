using System;
using Sedulous.Core;

namespace Sedulous.Script;

/// A run's random numbers, `Random.Value()` to a script: a facade over a RunRandom, the run's
/// own when the host belongs to a run (Use), so its scripts and its native code draw from one
/// sequence; otherwise one of its own, which a host outside every run (the editor's scenes)
/// seeds and restarts alone. Either way one generator per run host, so a run replays from a
/// seed whatever else is drawing numbers in the process.
[Scriptable, ScriptService, DisplayName("Random")]
class ScriptRandom
{
	/// OWNED: the generator when no run's is in use.
	private RunRandom mOwn = new .() ~ delete _;
	/// BORROWED, or mOwn: where the numbers come from.
	private RunRandom mSource;

	public this()
	{
		mSource = mOwn;
	}

	/// The generator its numbers come from.
	public RunRandom Source => mSource;
	/// Whether that is its own rather than a run's.
	public bool OwnsSource => mSource === mOwn;

	/// Draws from `source` from now on, BORROWED (it must outlive this, or be replaced first);
	/// null goes back to its own.
	public void Use(RunRandom source)
	{
		mSource = (source != null) ? source : mOwn;
	}

	/// Restarts the sequence from a seed.
	[Scriptable]
	public void Seed(int64 seed) => mSource.Seed((uint64)seed);

	/// In [0, 1).
	[Scriptable]
	public float Value() => mSource.Value();

	/// In [min, max).
	[Scriptable]
	public float Range(float min, float max) => mSource.Range(min, max);

	/// In [min, max], min when the range is empty.
	[Scriptable]
	public int32 IntRange(int32 min, int32 max) => mSource.IntRange(min, max);

	[Scriptable]
	public bool Bool() => mSource.Bool();
}
