using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Starting a child process and not waiting for it, and running one with its output streamed.
class ProcessTests
{
#if !BF_PLATFORM_WINDOWS
	/// A started child runs on its own: Start returns once it is up, whatever it does after.
	[Test]
	public static void AStartedChildRunsOnItsOwn()
	{
		Test.Assert(Sedulous.Core.Process.Start("/bin/sh", scope StringView[]("-c", "exit 0")));
	}

	/// A streamed run hands each line on as the child prints it, from both pipes, in order: the
	/// last line comes well after the first, as the child slept between them, so they were not
	/// held back to the end.
	[Test]
	public static void StreamedLinesArriveInOrderAsPrinted()
	{
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		let arrivals = scope List<int64>();
		let clock = scope Stopwatch(true);
		let result = Sedulous.Core.Process.RunStreaming("/bin/sh", scope StringView[]("-c", "echo one; sleep 0.3; echo two 1>&2; sleep 0.3; printf 'three\\r\\nfour'"),
			scope [&](line) =>
			{
				lines.Add(new .(line));
				arrivals.Add(clock.ElapsedMilliseconds);
			});
		Test.Assert((result case .Ok(let code)) && (code == 0), "it exited 0");
		Test.Assert(lines.Count == 4, scope String()..AppendF("{} lines: ", lines.Count)..Join("|", lines.GetEnumerator()));
		Test.Assert((lines[0] == "one") && (lines[1] == "two") && (lines[2] == "three") && (lines[3] == "four"), "in order, the endings dropped, the last unended line kept");
		Test.Assert(arrivals[2] - arrivals[0] >= 400, scope String()..AppendF("the first line came at {} ms, the third at {} ms", arrivals[0], arrivals[2]));
	}

	/// An argument reaches the child as written, its backslashes and quotes included: a doubled
	/// escape once handed a printf "\\r" where "\r" was meant. (Off Windows, a backslash just
	/// before the argument's end cannot be passed: the runtime reads it as an escaped quote.)
	[Test]
	public static void AnArgumentReachesTheChildAsWritten()
	{
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		let argument = "a\\b \"c\" d";
		let result = Sedulous.Core.Process.RunStreaming("/bin/echo", scope StringView[](argument), scope [&](line) => lines.Add(new .(line)));
		Test.Assert(result case .Ok(0));
		Test.Assert((lines.Count == 1) && (lines[0] == argument), scope String()..Join("|", lines.GetEnumerator()));
	}

	/// The child's own exit code comes back.
	[Test]
	public static void AStreamedRunReturnsTheExitCode()
	{
		let result = Sedulous.Core.Process.RunStreaming("/bin/sh", scope StringView[]("-c", "echo failing; exit 3"), scope (line) => { });
		Test.Assert((result case .Ok(let code)) && (code == 3), "its exit code");
	}

	/// A cancel kills a child that prints nothing, and what it started, promptly: the run ends
	/// Cancelled long before the child's sleep would.
	[Test]
	public static void ACancelKillsASilentChildPromptly()
	{
		let clock = scope Stopwatch(true);
		let result = Sedulous.Core.Process.RunStreaming("/bin/sh", scope StringView[]("-c", "sleep 30; echo late"), scope (line) => { },
			scope () => clock.ElapsedMilliseconds >= 200);
		Test.Assert(result case .Err(.Cancelled));
		Test.Assert(clock.ElapsedMilliseconds < 5000, scope String()..AppendF("ended after {} ms", clock.ElapsedMilliseconds));
	}

	/// A cancel token works as the check: one cancelled already ends the run at once.
	[Test]
	public static void ACancelledTokenEndsAStreamedRun()
	{
		let source = scope CancelSource();
		source.Cancel();
		let clock = scope Stopwatch(true);
		let result = Sedulous.Core.Process.RunStreaming("/bin/sh", scope StringView[]("-c", "sleep 30"), scope (line) => { }, source.Token);
		Test.Assert(result case .Err(.Cancelled));
		Test.Assert(clock.ElapsedMilliseconds < 5000, scope String()..AppendF("ended after {} ms", clock.ElapsedMilliseconds));
	}
#endif
}
