namespace Sedulous.Materials;

/// Which of a material's properties an instance has overridden.
///
/// A 128 bit set rather than a list, because the question asked of it is "is this one
/// overridden" on every property of every instance the renderer touches, and that wants to
/// be a shift and a test.
///
/// A property past 128 cannot be recorded and reads as NOT overridden, so it falls back to
/// the material's default. A material with that many properties is a different problem.
struct PropertyOverrideMask
{
	public uint64 Low = 0;
	public uint64 High = 0;

	public this() {}

	public void Set(int index) mut
	{
		if (index < 64)
			Low |= (1UL << index);
		else if (index < 128)
			High |= (1UL << (index - 64));
	}

	public void Clear(int index) mut
	{
		if (index < 64)
			Low &= ~(1UL << index);
		else if (index < 128)
			High &= ~(1UL << (index - 64));
	}

	public bool IsSet(int index)
	{
		if (index < 0)
			return false;
		if (index < 64)
			return (Low & (1UL << index)) != 0;
		if (index < 128)
			return (High & (1UL << (index - 64))) != 0;
		return false;
	}

	public void Reset() mut
	{
		Low = 0;
		High = 0;
	}

	public bool HasAny => (Low != 0) || (High != 0);
}
