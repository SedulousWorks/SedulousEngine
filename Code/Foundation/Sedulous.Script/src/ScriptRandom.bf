using System;
using Sedulous.Core;

namespace Sedulous.Script;

/// A run's random numbers, `Random.Value()` to a script: one generator per run host, so a
/// run replays from a seed whatever else is drawing numbers in the process, which is the
/// determinism seam a replay or a test wants.
[Scriptable, ScriptService, DisplayName("Random")]
class ScriptRandom
{
	private Sedulous.Core.Random mRandom = .();

	/// Restarts the sequence from a seed.
	[Scriptable]
	public void Seed(int64 seed) => mRandom = Sedulous.Core.Random((uint64)seed);

	/// In [0, 1).
	[Scriptable]
	public float Value() => mRandom.NextFloat();

	/// In [min, max).
	[Scriptable]
	public float Range(float min, float max) => mRandom.NextFloat(min, max);

	/// In [min, max], min when the range is empty.
	[Scriptable]
	public int32 IntRange(int32 min, int32 max) => (max >= min) ? mRandom.NextInt(min, max) : min;

	[Scriptable]
	public bool Bool() => mRandom.NextBool();
}
