using System;
using System.Threading;
using Sedulous.Http;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameInstance.Tests;

/// The run's HTTP (GameInstance.Http) against a real server on loopback.
class HttpRunTests
{
	/// A game's Get over the run's client: the answer reaches its handler on the run's
	/// tick. The session's stop drops what is still under way, its handler deleted and never
	/// called.
	[Test]
	public static void AGameFetchesOverTheRunsClientTheSessionsStopDropsWhatWaits()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		server.SetHandler(new (request) =>
			{
				if (StringView(request.Target) == "/slow")
					return null; // never answered
				return HttpResponse.Text(200, "text/plain", "best: 12.5");
			});

		let got = scope String();
		int late = 0;
		int deleted = 0;
		let instance = scope GameInstance();
		let http = instance.Http;
		instance.Start();
		let best = http.Get(scope $"http://127.0.0.1:{server.BoundPort}/best", new [&] (status, body, error) =>
			{
				got.AppendF("{} {}", status, body);
			} ~ { deleted++; });
		Test.Assert(best > 0);
		http.Get(scope $"http://127.0.0.1:{server.BoundPort}/slow", new [&] (status, body, error) => { late++; } ~ { deleted++; });
		for (int i < 5000)
		{
			if (!got.IsEmpty)
				break;
			server.Pump();
			instance.TickGame(0.016f, 1.0f);
			Thread.Sleep(1);
		}
		Test.Assert(got == "200 best: 12.5", got);
		Test.Assert(deleted == 1, "the answered one, after its answer");
		Test.Assert(http.Pending == 1, "the slow one");

		instance.Stop();
		Test.Assert(http.Pending == 0, "dropped as the session stopped");
		Test.Assert(deleted == 2, "its handler deleted");
		for (int i < 50)
		{
			server.Pump();
			instance.TickGame(0.016f, 1.0f);
			Thread.Sleep(1);
		}
		Test.Assert(late == 0, "never called");
	}
}
