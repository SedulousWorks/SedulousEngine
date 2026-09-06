using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// A shared object that records its own destruction, so a test can tell the difference
/// between an object that is gone and one that merely cannot be reached.
class SharedProbe : SharedObject
{
	public static int Destroyed;

	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}

	public ~this()
	{
		Destroyed++;
	}
}
