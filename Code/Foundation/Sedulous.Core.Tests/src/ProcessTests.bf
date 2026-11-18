using System;
using System.Collections;
using System.IO;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;

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

	/// LaunchDetached starts a script that writes its arguments to a file, one per line, and
	/// returns before they are read back: each argument arrives whole, spaces and all.
	[Test]
	public static void LaunchDetachedStartsAProgramWithItsArgumentsAndDoesNotWait()
	{
		let folder = GetCurrentDirectory(.. scope String());
		let record = PathJoin(folder, "scratch_launch_record.txt", .. scope String());
#if BF_PLATFORM_WINDOWS
		let script = PathJoin(folder, "scratch_launch.cmd", .. scope String());
		let body = "@echo off\r\n(echo %~2& echo %~3)> \"%~1\"\r\n";
#else
		let script = PathJoin(folder, "scratch_launch.sh", .. scope String());
		let body = "#!/bin/sh\nout=\"$1\"; shift\nprintf '%s\\n' \"$@\" > \"$out.part\"\nmv \"$out.part\" \"$out\"\n";
#endif
		File.Delete(record).IgnoreError();
		Test.Assert(File.WriteAllText(script, body) case .Ok);
#if !BF_PLATFORM_WINDOWS
		Test.Assert(chmod(script, 0x1ED) == 0); // 0755
#endif
		Test.Assert(Process.LaunchDetached(script, scope StringView[](record, "two words", "plain")));

		let recorded = scope String();
		for (int attempt = 0; (attempt < 500) && recorded.IsEmpty; attempt++)
		{
			if (File.Exists(record))
				File.ReadAllText(record, recorded).IgnoreError();
			if (recorded.IsEmpty)
				Thread.Sleep(10);
		}
		Test.Assert(recorded.StartsWith("two words"), recorded);
		Test.Assert(recorded.Contains("plain"), recorded);
		File.Delete(record).IgnoreError();
		File.Delete(script).IgnoreError();
	}

	[Test]
	public static void LaunchDetachedReportsAProgramItCannotFind()
	{
		Test.Assert(!Process.LaunchDetached("scratch-no-such-program-anywhere", .()));
		Test.Assert(!Process.LaunchDetached("", .()));
	}

#if !BF_PLATFORM_WINDOWS
	[CLink]
	private static extern int32 chmod(char8* path, uint32 mode);
#endif
}
