using System;

namespace Sedulous.Core;

/// The calling thread's name ("Main", "Worker 3"), for the profiler's lanes and anything else
/// that shows threads. Each thread starts unnamed and names only itself; the first 31 bytes
/// are kept, in a fixed buffer, so naming a thread allocates nothing.
static class ThreadNames
{
	public const int cCapacity = 32;

	[ThreadStatic] private static char8[cCapacity] sName;
	[ThreadStatic] private static int32 sLength;

	/// Names the calling thread, keeping the first 31 bytes.
	public static void SetCurrent(StringView name)
	{
		let length = Math.Min(name.Length, cCapacity - 1);
		for (int i < length)
			sName[i] = name[i];
		sName[length] = 0;
		sLength = (int32)length;
	}

	/// The calling thread's name: empty until it is named. Valid until the thread names itself
	/// again.
	public static StringView Current => StringView(&sName[0], sLength);
}
