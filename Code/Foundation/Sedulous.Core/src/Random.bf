namespace Sedulous.Core;

/// PCG32: a seedable generator with a reproducible stream.
///
/// Deterministic on purpose. A replay, a seeded test, and a procedural level all need the
/// same seed to give the same sequence on every platform and every run, which a
/// system generator does not promise. The constants are PCG's and the stream must not be
/// changed: content generated from a seed today has to come out the same next year.
struct Random
{
	private uint64 mState;
	private uint64 mInc;

	public this() : this(0x853c49e6748fea9bUL, 0xda3e39cb94b95bdbUL) {}

	/// The sequence selects one of PCG's independent streams, so two generators seeded the
	/// same but sequenced differently do not walk in step.
	public this(uint64 seed, uint64 sequence = 0xda3e39cb94b95bdbUL)
	{
		mState = 0;
		// Always odd, which is what makes the increment coprime with the modulus and gives
		// the stream its full period.
		mInc = (sequence << 1) | 1;
		NextU32();
		mState &+= seed;
		NextU32();
	}

	/// The whole generator: a wrapping multiply and add for the state, then a shift and
	/// rotate of the OLD state to produce the output. The output function is why PCG
	/// passes tests that a plain congruential generator fails.
	public uint32 NextU32() mut
	{
		let old = mState;
		// &* and &+ because the arithmetic is modulo 2^64 by definition. Plain operators
		// trap on overflow wherever those checks are on.
		mState = old &* 6364136223846793005UL &+ mInc;
		let xorshifted = (uint32)(((old >> 18) ^ old) >> 27);
		let rot = (uint32)(old >> 59);
		// The mask keeps the second shift from being a full width shift when rot is zero,
		// which is undefined rather than a no-op.
		return (xorshifted >> rot) | (xorshifted << ((32 - rot) & 31));
	}

	public uint64 NextU64() mut
	{
		let high = (uint64)NextU32();
		let low = (uint64)NextU32();
		return (high << 32) | low;
	}

	/// Uniform in [0, 1).
	///
	/// Twenty four bits over two to the twenty four: exactly the float mantissa, so every
	/// value is representable and none is favoured by rounding.
	public float NextFloat() mut => (float)(NextU32() >> 8) * (1.0f / 16777216.0f);

	public float NextFloat(float min, float max) mut => min + NextFloat() * (max - min);

	/// Uniform in [min, max], INCLUSIVE of both.
	public int32 NextInt(int32 min, int32 max) mut
	{
		let range = (uint32)(max - min) + 1;
		return min + (int32)(NextU32() % range);
	}

	public bool NextBool() mut => (NextU32() & 1) != 0;
}
