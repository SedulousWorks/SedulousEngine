using System;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Cancelling: a source's token sees its Cancel, which stays; a token outlives its source; null
/// never cancels; work on another thread stops at its next check.
class CancelTests
{
	[Test]
	public static void ANullTokenNeverCancelsASourcesTokenSeesItsCancelWhichStays()
	{
		Test.Assert(!CancelToken.Requested(null));

		let source = scope CancelSource();
		let token = source.Token;
		Test.Assert(!token.IsCancelled);
		Test.Assert(!CancelToken.Requested(token));
		source.Cancel();
		Test.Assert(source.IsCancelled);
		Test.Assert(token.IsCancelled);
		Test.Assert(CancelToken.Requested(token));
		source.Cancel(); // twice is once
		Test.Assert(token.IsCancelled);
		Test.Assert(source.Token.IsCancelled, "a token taken after still sees it");
	}

	[Test]
	public static void ATokenOutlivesItsSourceKeepingWhatItLastSaw()
	{
		CancelToken kept;
		CancelToken cancelled;
		{
			let quiet = scope CancelSource();
			kept = quiet.Token;
			kept.AddRef();
			let loud = scope CancelSource();
			cancelled = loud.Token;
			cancelled.AddRef();
			loud.Cancel();
		}
		Test.Assert(!kept.IsCancelled);
		Test.Assert(cancelled.IsCancelled);
		kept.ReleaseRef();
		cancelled.ReleaseRef();
	}

	[Test]
	public static void CancelledIsAnErrorCodeOfItsOwn()
	{
		Result<void, ErrorCode> status = .Err(.Cancelled);
		Test.Assert(status case .Err(.Cancelled));
		Test.Assert(ErrorCode.Cancelled != ErrorCode.Unknown);
	}

	[Test]
	public static void WorkOnAnotherThreadStopsAtItsNextCheckOnceItsSourceCancels()
	{
		let source = scope CancelSource();
		let token = source.Token;
		token.AddRef(); // the worker's
		int steps = 0;
		bool started = false;
		bool stopped = false;
		let worker = scope Thread(new [&]() =>
			{
				Volatile.Write(ref started, true);
				for (int i < 100000000)
				{
					if (CancelToken.Requested(token))
					{
						stopped = true;
						break;
					}
					steps++;
					Thread.Yield();
				}
				token.ReleaseRef();
			});
		worker.Start(false);
		while (!Volatile.Read(ref started))
			Thread.Yield();
		source.Cancel();
		worker.Join();
		Test.Assert(stopped);
		Test.Assert(steps < 100000000);
	}
}
