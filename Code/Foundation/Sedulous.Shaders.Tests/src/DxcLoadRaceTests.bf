using System;
using System.Collections;
using System.Threading;
using Sedulous.Shaders;
using Dxc_Beef;
using internal Dxc_Beef;

namespace Sedulous.Shaders.Tests;

/// Compilers started on several threads at once, as a cook's workers start them: each must
/// find dxcompiler, not only the first to ask for it.
class DxcLoadRaceTests
{
	private const int cThreads = 8;
	private const int cRounds = 50;

	private static bool sGate;
	private static int32 sWaiting;
	private static int32 sFailed;

#if !BF_PLATFORM_WINDOWS
	[Test]
	public static void CompilersStartedTogetherAllFindDxc()
	{
		for (int round < cRounds)
		{
			// The library stays loaded; the resolve runs again, with every worker asking.
			DxcLibrary.Forget();
			RaceOneRound();
			Test.Assert(Volatile.Read(ref sFailed) == 0, scope $"round {round}: {sFailed} compiler(s) found no dxcompiler");
		}
	}
#endif

	/// Every worker starts its compiler at once. The GATE is the whole point: started without
	/// one, each thread finishes before the next is created and the resolve never overlaps.
	private static void RaceOneRound()
	{
		Volatile.Write(ref sGate, false);
		Volatile.Write(ref sWaiting, 0);
		Volatile.Write(ref sFailed, 0);

		let threads = scope List<Thread>();
		for (int t < cThreads)
		{
			let thread = new Thread(new () =>
				{
					Interlocked.Increment(ref sWaiting);
					while (!Volatile.Read(ref sGate))
						Thread.SpinWait(1);

					let compiler = scope ShaderCompiler();
					if (compiler.Initialize() case .Err)
						Interlocked.Increment(ref sFailed);
				});
			threads.Add(thread);
			thread.Start(false);
		}

		while (Volatile.Read(ref sWaiting) < cThreads)
			Thread.SpinWait(1);
		Volatile.Write(ref sGate, true);

		for (let thread in threads)
		{
			thread.Join();
			delete thread;
		}
	}
}
