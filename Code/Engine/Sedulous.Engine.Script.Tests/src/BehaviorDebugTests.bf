using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// The debugger against a running scene: a breakpoint in a behaviour pauses the run's
/// script tick as a whole, nothing faults, and a continue lets the frame finish.
static class BehaviorDebugTests
{
	private const String cTicker = """
		class Ticker
		{
			int updates = 0;
			int marks = 0;
			void onUpdate(float dt)
			{
				updates++;
				marks++;
			}
		}
		""";

	[Test]
	public static void ABreakpointHoldsTheSceneScriptTickAndResumes()
	{
		let play = scope ScriptPlayScene();
		let ticker = play.Class("Ticker", cTicker);
		let a = play.AddBehavior(ticker, "a");
		let b = play.AddBehavior(ticker, "b");
		play.Start();
		play.Step();
		Test.Assert((play.PropInt(a, "updates") == 1) && (play.PropInt(b, "updates") == 1));

		// The debugger, requested through the host with its breakpoint: line 8 is `marks++`.
		IScriptDebugger captured = null;
		play.Host.RequestDebugger(new [&] (debugger) =>
			{
				debugger.SetBreakpoint("Test.as", 8);
				captured = debugger;
			});
		Test.Assert((captured != null) && (play.Host.Debugger === captured), "attached to the live runtime");

		// The next tick: a's update hits the breakpoint mid call. The frame ends there for
		// scripts: b is not ticked, nothing faulted, and the run is paused.
		play.Step();
		Test.Assert(play.Host.IsDebugPaused);
		Test.Assert(play.PropInt(a, "updates") == 2);
		Test.Assert(play.PropInt(a, "marks") == 1, "held before marks++");
		Test.Assert(play.PropInt(b, "updates") == 1, "b waits for the pause to lift");
		Test.Assert(!play.BehaviorOf(a).Faulted && !play.BehaviorOf(b).Faulted);

		// Held: further ticks do nothing to the scripts, and no breakpoint re-hits.
		play.Step(3);
		Test.Assert(play.PropInt(a, "updates") == 2);
		Test.Assert(play.PropInt(b, "updates") == 1);

		// The paused frame is inspectable, and the held call is a's update.
		let frames = scope List<ScriptStackFrame>();
		defer { ClearAndDeleteItems(frames); }
		captured.CaptureStackFrames(frames);
		Test.Assert((frames.Count == 1) && frames[0].Function.Contains("onUpdate") && (frames[0].Line == 8));
		let locals = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(locals); }
		captured.CaptureLocals(0, locals);
		Test.Assert((locals.Count >= 2) && (locals[0].Name == "this") && (locals[0].ObjectRef != 0), "this, expandable");
		let members = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(members); }
		captured.CaptureObject(locals[0].ObjectRef, members);
		Test.Assert((members.Count == 2) && (members[0].Value == "2") && (members[1].Value == "1"));

		// Continue: the held call completes, the run is live again, and the next tick
		// stops again at the same line, this time in a's call once more.
		captured.Continue();
		Test.Assert(!play.Host.IsDebugPaused);
		Test.Assert(play.PropInt(a, "marks") == 2);
		captured.RemoveBreakpoint("Test.as", 8);
		play.Step();
		Test.Assert((play.PropInt(a, "updates") == 3) && (play.PropInt(b, "updates") == 2), "both tick again");
		Test.Assert(!play.BehaviorOf(a).Faulted && !play.BehaviorOf(b).Faulted);
	}
}
