using System;
using System.Threading;
using Sedulous.Http;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

/// `Http` to a game script: Http.Get goes through the client the run makes on its first
/// request, and the answer reaches the handler on the run's tick. Stopping the script drops what
/// is still under way: its handler is never called.
class HttpFacadeRunTests
{
	[Test]
	public static void AGameScriptFetchesOverTheRunsClientStoppingDropsWhatWaits()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		server.SetHandler(new (request) =>
			{
				if (StringView(request.Target) == "/slow")
					return null; // never answered
				return HttpResponse.Text(200, "text/plain", "best: 12.5");
			});

		let run = scope GameRun("scratch_http_run");
		Test.Assert(run.Instance.Http.Pending == 0);
		let game = run.Class("Game", scope $$"""
			class Game
			{
				string got = "";
				int late = 0;
				void launch()
				{
					Http.Get("http://127.0.0.1:{{server.BoundPort}}/best", HttpHandler(this.onBest));
					Http.Get("http://127.0.0.1:{{server.BoundPort}}/slow", HttpHandler(this.onSlow));
				}
				void onBest(int status, const string &in body, const string &in error) { got = "" + status + " " + body; }
				void onSlow(int status, const string &in body, const string &in error) { late = 1; }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		for (int i < 5000)
		{
			if (!run.Prop("got").AsString.IsEmpty)
				break;
			server.Pump();
			run.Step();
			Thread.Sleep(1);
		}
		Test.Assert(run.Prop("got").AsString == "200 best: 12.5", scope String(run.Prop("got").AsString));
		Test.Assert(run.Instance.Http.Pending == 1, "the slow one");
		run.Instance.StopScript();
		Test.Assert(run.Instance.Http.Pending == 0);
		Test.Assert(run.PropInt("late") == 0);
	}

	/// Native code's Get over the run's client: the answer reaches its handler on the run's
	/// tick. The session's stop drops what is still under way, its handler deleted and never
	/// called.
	[Test]
	public static void NativeCodeFetchesOverTheRunsClientTheSessionsStopDropsWhatWaits()
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
			instance.TickScript(0.016f, 1.0f);
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
			instance.TickScript(0.016f, 1.0f);
			Thread.Sleep(1);
		}
		Test.Assert(late == 0, "never called");
	}
}
