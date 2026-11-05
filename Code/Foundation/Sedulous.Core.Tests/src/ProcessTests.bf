using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Starting a child process and not waiting for it.
class ProcessTests
{
#if !BF_PLATFORM_WINDOWS
	/// A started child runs on its own: Start returns once it is up, whatever it does after.
	[Test]
	public static void AStartedChildRunsOnItsOwn()
	{
		Test.Assert(Process.Start("/bin/sh", scope StringView[]("-c", "exit 0")));
	}
#endif
}
