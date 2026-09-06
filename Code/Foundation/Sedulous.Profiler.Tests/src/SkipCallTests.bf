using System;

namespace Sedulous.Profiler.Tests;

/// [SkipCall] is what makes an uninstrumented build free, so it is worth pinning down
/// rather than assuming. It removes the call at the CALL SITE, which means the arguments
/// are never evaluated either, and it holds under defer, which is how a scope is
/// bracketed.
///
/// This tests the compiler feature the gating relies on, not the profiler: the profiler's
/// own frontend is compiled IN for a test build, so its skipped form cannot be observed
/// from here.
class SkipCallTests
{
	public struct SkippedToken : IDisposable
	{
		[SkipCall]
		public void Dispose()
		{
			sCalls++;
		}
	}

	private static int32 sCalls;
	private static int32 sArgEvals;

	[SkipCall]
	private static void Skipped(StringView name)
	{
		sCalls++;
	}

	[SkipCall]
	private static SkippedToken SkippedScope(StringView name)
	{
		sCalls++;
		return .();
	}

	private static StringView AnArgument()
	{
		sArgEvals++;
		return "evaluated";
	}

	[Test]
	public static void ASkippedCallCostsNothingAndNeverEvaluatesItsArguments()
	{
		sCalls = 0;
		sArgEvals = 0;

		Skipped("a literal");
		Skipped(AnArgument());

		let local = scope String("a local");
		Skipped(local);

		{
			Skipped("entering");
			defer Skipped("leaving");
		}

		// The shape instrumentation actually uses. A skipped call still type checks as a
		// value, so the factory, its argument and the Dispose all go and the using
		// statement disappears with them.
		using (SkippedScope(AnArgument()))
		{
		}

		Test.Assert(sCalls == 0, scope $"the body ran {sCalls} times");
		Test.Assert(sArgEvals == 0, scope $"an argument was evaluated {sArgEvals} times");
	}
}
