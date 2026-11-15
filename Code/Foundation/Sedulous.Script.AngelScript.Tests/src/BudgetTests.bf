using System;
using System.Diagnostics;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// The call budget: a call that runs past its seconds is stopped and fails alone, recursion
/// that never ends fails at the depth limit, and a global initializer runs at load under the
/// budget and never in a compile that does not run script.
static class BudgetTests
{
	private static AngelScriptRuntime Bound(ScriptSurface surface)
	{
		let vm = new AngelScriptRuntime();
		vm.Bind(surface);
		return vm;
	}

	private static bool AnyProblem(ScriptRuntime vm, StringView needle)
	{
		for (let p in vm.Problems)
		{
			if (p.Contains(needle))
				return true;
		}
		return false;
	}

	/// A script loop that never ended hung the game.
	[Test]
	public static void ACallPastItsTimeBudgetIsStoppedAndTheRuntimeGoesOn()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;
		vm.Budget = .() { CallSeconds = 0.5 };
		Test.Assert(vm.Compile("budget", "budget.as", """
			class Probe
			{
				void forever() { int i = 0; while (true) { i++; } }
				int deep(int n) { return deep(n + 1) + 1; }
				double fine() { return 7; }
			}
			"""), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		let probe = vm.Instantiate("budget", "Probe");
		Test.Assert(probe != null, "instantiated");

		var r = ScriptValue.Nil;
		let clock = scope Stopwatch()..Start();
		Test.Assert(!vm.Invoke(probe, "forever", default, ref r), "the endless call failed");
		let took = clock.Elapsed.TotalSeconds;
		Test.Assert((took >= 0.5) && (took < 2.0), scope $"stopped after {took} s");
		Test.Assert(AnyProblem(vm, "budget"), "the stop is said");
		Test.Assert(vm.Invoke(probe, "fine", default, ref r) && (r.AsNumber == 7), "the runtime goes on");

		// Recursion that never ends fails its call at the stack limit instead of taking memory.
		// The time budget is raised first: a sanitizer build is slow enough to reach it before
		// the limit.
		vm.Budget = .() { CallSeconds = 60.0 };
		var zero = ScriptValue[1](.FromInt(0));
		Test.Assert(!vm.Invoke(probe, "deep", zero, ref r), "the endless recursion failed");
		Test.Assert(AnyProblem(vm, "Stack overflow"), "at the stack limit");
		Test.Assert(vm.Invoke(probe, "fine", default, ref r) && (r.AsNumber == 7), "the runtime goes on");
	}

	/// The build ran the global initializers, where nothing could stop one that never returned,
	/// and the cook's compile ran them too.
	[Test]
	public static void AGlobalInitializerRunsAtLoadUnderTheBudgetNeverInACompileThatDoesNotRun()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;
		vm.Budget = .() { CallSeconds = 0.5 };
		let looping = "int forever() { while (true) {} return 1; }\nint x = forever();\n";

		// The cook's compile and a check build it without running a line of it.
		let compileClock = scope Stopwatch()..Start();
		Test.Assert(vm.Compile("cooked", "globals.as", looping, false), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		Test.Assert(vm.Check("globals.as", looping));
		Test.Assert(compileClock.Elapsed.TotalSeconds < 0.4, scope $"the compiles took {compileClock.Elapsed.TotalSeconds} s");

		// A load runs the initializer, and stops it at the budget.
		Test.Assert(!vm.Compile("loaded", "globals.as", looping), "the endless initializer failed the load");
		Test.Assert(AnyProblem(vm, "budget"), "the stop is said");

		// An initializer that returns still sets its global.
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(vm.Compile("fine", "fine.as", "int seven() { return 7; }\nint x = seven();\ndouble read() { return x; }\n"));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("fine", "double read()", default, ref r) && (r.AsNumber == 7), "the global was set");
	}
}
