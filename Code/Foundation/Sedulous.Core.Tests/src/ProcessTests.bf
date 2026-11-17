using System;
using System.Collections;
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

	/// Every argument reaches the child, all its output is kept (past 64 KiB it was cut, keeping the
	/// start and losing a build's errors at the end), and a hung tool no longer holds the caller.
	[Test]
	public static void RunPassesEveryArgumentKeepsAllItsOutputAndStopsARunPastItsTimeout()
	{
		let args = scope List<StringView>();
		args.Add("-c");
		args.Add("echo $# \"${100}\"");
		args.Add("sh"); // $0
		let words = scope List<String>();
		defer { ClearAndDeleteItems!(words); }
		for (int i < 100)
		{
			let word = new String()..AppendF("a{}", i);
			words.Add(word);
			args.Add(word);
		}
		let many = scope ProcessResult();
		Process.Run("/bin/sh", args, many);
		Test.Assert(many.Ok);
		Test.Assert(many.Output.StartsWith("100 a99"), many.Output);

		// About 200 KiB of output, its last line kept.
		let loud = scope ProcessResult();
		Process.Run("/bin/sh", scope StringView[]("-c", "i=0; while [ $i -lt 4000 ]; do echo 'line of fifty characters to fill the output ......'; i=$((i+1)); done; echo END"), loud);
		Test.Assert(loud.Ok);
		Test.Assert(loud.Output.Length > 128 * 1024, scope $"{loud.Output.Length} bytes");
		Test.Assert(loud.Output.EndsWith("END\n"));

		// A run past its timeout is killed and says so.
		let late = scope ProcessResult();
		let started = DateTime.UtcNow;
		Process.Run("/bin/sh", scope StringView[]("-c", "sleep 30"), late, 300);
		Test.Assert(late.TimedOut);
		Test.Assert(!late.Ran);
		Test.Assert((DateTime.UtcNow - started).TotalMilliseconds < 10000.0);
	}
#endif
}
