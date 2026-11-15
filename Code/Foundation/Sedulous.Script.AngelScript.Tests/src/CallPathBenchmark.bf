using System;
using System.Diagnostics;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// A benchmark of the script call path: handler calls, value math in a script loop, waiting
/// coroutines, and objects left for the collector, timed so a change to the call path is
/// measured before and after. Ignored in a test run; run it on purpose, from an optimised build
/// (a Debug build's times say little). It prints `[bench] angelscript <measure> <value> <unit>`.
static class CallPathBenchmark
{
	private const String cBench = """
		class Holder { Holder@ self; Vec2 at; }
		class Bench
		{
			double total = 0;
			void tick(double dt) { total += dt; }
			double math(int n)
			{
				Vec2 a = Vec2(1, 2);
				Vec2 b = Vec2(0.5f, 0.25f);
				double sum = 0;
				for (int i = 0; i < n; i++)
				{
					Vec2 d = Vec2(a.X + b.X * 2.0f, a.Y + b.Y * 2.0f);
					sum += Vec2::Dot(d, a);
				}
				return sum;
			}
			void Sleeper() { wait(1000.0f); }
			void spawn(int n) { for (int i = 0; i < n; i++) startCoroutine(ScriptCoroutine(this.Sleeper)); }
			void churn(int n)
			{
				for (int i = 0; i < n; i++) { Holder h; @h.self = h; h.at = Vec2(1, 2); }
			}
		}
		""";

	private static void Report(StringView measure, double value, StringView unit)
	{
		Console.WriteLine("[bench] angelscript {} {:F3} {}", measure, value, unit);
	}

	[Test(Ignore=true)]
	public static void TheCallPath()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(vm.Compile("bench", "bench.as", cBench), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		let bench = vm.Instantiate("bench", "Bench");
		Test.Assert(bench != null);
		var r = ScriptValue.Nil;

		// A handler call: the cost of crossing into script and back.
		{
			const int cCalls = 100000;
			var dt = ScriptValue[1](.FromFloat(0.016));
			let clock = scope Stopwatch(true);
			for (int i < cCalls)
				Test.Assert(vm.Invoke(bench, "tick", dt, ref r));
			Report("handler-call", clock.Elapsed.TotalMilliseconds * 1e6 / cCalls, "ns/call");
		}

		// Value math in a script loop.
		{
			const int cIterations = 100000;
			var n = ScriptValue[1](.FromInt(cIterations));
			let clock = scope Stopwatch(true);
			Test.Assert(vm.Invoke(bench, "math", n, ref r));
			Report("math-iteration", clock.Elapsed.TotalMilliseconds * 1e6 / cIterations, "ns/iteration");
		}

		// Waiting coroutines: what a frame's scheduler pays for them.
		{
			const int cFrames = 1000;
			var n = ScriptValue[1](.FromInt(100));
			Test.Assert(vm.Invoke(bench, "spawn", n, ref r));
			let clock = scope Stopwatch(true);
			for (int i < cFrames)
				vm.AdvanceCoroutines(0.016);
			Report("coroutines-100-frame", clock.Elapsed.TotalMilliseconds * 1e3 / cFrames, "us/frame");
		}

		// Garbage only the collector frees: objects that refer to themselves.
		{
			const int cObjects = 10000;
			var n = ScriptValue[1](.FromInt(cObjects));
			let clock = scope Stopwatch(true);
			Test.Assert(vm.Invoke(bench, "churn", n, ref r));
			Report("churn-object", clock.Elapsed.TotalMilliseconds * 1e6 / cObjects, "ns/object");
		}
		vm.Release(bench);
	}
}
