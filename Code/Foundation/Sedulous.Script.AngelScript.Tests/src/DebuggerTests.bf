using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// The suspension debugger: a breakpoint pauses the call and reports it paused rather
/// than failed, the paused context is inspectable, the steps and the continue run it on,
/// and the held call terminates cleanly.
static class DebuggerTests
{
	private class StateLog : IScriptDebuggerListener
	{
		public List<ScriptDebuggerState> States = new .() ~ delete _;
		public void OnDebuggerStateChanged(ScriptDebuggerState state) => States.Add(state);
	}

	private const String cSource = """
		class Walker
		{
			int steps = 0;
			Vec2 at;
		}
		int helper(int x)
		{
			int doubled = x * 2;
			return doubled + 1;
		}
		int walk(Thing@ t)
		{
			Walker w;
			w.steps = 3;
			w.at = Vec2(1, 2);
			int a = helper(w.steps);
			string name = "walker";
			t.Count = a;
			a = a + 1;
			return a;
		}
		""";

	private static void Locals(IScriptDebugger debugger, uint32 depth, List<ScriptVariable> outLocals, String outNames)
	{
		debugger.CaptureLocals(depth, outLocals);
		for (let v in outLocals)
		{
			if (!outNames.IsEmpty)
				outNames.Append(",");
			outNames.Append(v.Name);
		}
	}

	private static ScriptVariable Find(List<ScriptVariable> locals, StringView name)
	{
		for (let v in locals)
			if (v.Name == name)
				return v;
		return null;
	}

	[Test]
	public static void ABreakpointPausesTheCallAndTheStackAndLocalsAreCaptured()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		Test.Assert(vm.HasDebugger);
		Test.Assert(vm.Compile("t", "walker.as", cSource), "compiled");

		let debugger = vm.CreateDebugger();
		Test.Assert(debugger != null);
		defer delete debugger;
		Test.Assert(vm.CreateDebugger() == null, "one at a time");
		let log = scope StateLog();
		debugger.SetListener(log);
		debugger.SetBreakpoint("walker.as", 9); // inside helper: `return doubled + 1;`

		let thing = scope Thing();
		var arg = ScriptValue[1](.FromObject(thing));
		var r = ScriptValue.Nil;
		// Paused, not failed: the call answers false and the runtime says why.
		Test.Assert(!vm.Call("t", "int walk(Thing@)", arg, ref r));
		Test.Assert(vm.IsDebugPaused && debugger.IsPaused);
		Test.Assert(debugger.State == .Breakpoint);
		Test.Assert(vm.Problems.IsEmpty, "a pause is not a problem");
		Test.Assert(thing.Count == 0, "the call has not reached the assignment");

		// The stack, innermost first.
		let frames = scope List<ScriptStackFrame>();
		defer { ClearAndDeleteItems(frames); }
		debugger.CaptureStackFrames(frames);
		Test.Assert(frames.Count == 2, scope $"{frames.Count} frames");
		Test.Assert((frames[0].File == "walker.as") && (frames[0].Line == 9) && frames[0].Function.Contains("helper"), scope $"{frames[0].Function} at {frames[0].Line}");
		Test.Assert(frames[1].Function.Contains("walk") && (frames[1].Line == 16), scope $"{frames[1].Function} at {frames[1].Line}");

		// The innermost frame's locals: the argument and the local, with their values.
		let inner = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(inner); }
		let innerNames = scope String();
		Locals(debugger, 0, inner, innerNames);
		Test.Assert(Find(inner, "x") != null, innerNames);
		Test.Assert(Find(inner, "x").Value == "3");
		Test.Assert(Find(inner, "doubled").Value == "6");
		Test.Assert(Find(inner, "doubled").TypeName.Contains("int"));

		// The caller's frame: a script object expands to its properties, and an engine
		// object to its surface fields.
		let outer = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(outer); }
		let outerNames = scope String();
		Locals(debugger, 1, outer, outerNames);
		let w = Find(outer, "w");
		Test.Assert((w != null) && (w.ObjectRef != 0), scope $"w expandable: {outerNames}");
		let members = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(members); }
		debugger.CaptureObject(w.ObjectRef, members);
		Test.Assert((Find(members, "steps") != null) && (Find(members, "steps").Value == "3"));
		let at = Find(members, "at");
		Test.Assert((at != null) && (at.ObjectRef != 0), "a surface struct expands too");
		let atMembers = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(atMembers); }
		debugger.CaptureObject(at.ObjectRef, atMembers);
		Test.Assert((Find(atMembers, "X") != null) && (Find(atMembers, "X").Value == "1"));
		let t = Find(outer, "t");
		Test.Assert((t != null) && (t.ObjectRef != 0), "an engine object handle expands");
		let tMembers = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(tMembers); }
		debugger.CaptureObject(t.ObjectRef, tMembers);
		Test.Assert((Find(tMembers, "Count") != null) && (Find(tMembers, "Count").Value == "0"));
		Test.Assert(Find(outer, "name") == null || Find(outer, "name").Value == "<uninitialized>", "not yet in scope, or unset");

		// Continue: the held call finishes, the side effect lands, and the listener saw the
		// whole story.
		debugger.Continue();
		Test.Assert(!vm.IsDebugPaused && !debugger.IsPaused);
		Test.Assert(debugger.State == .Terminated);
		Test.Assert(thing.Count == 7, scope $"count {thing.Count}");
		Test.Assert(log.States.Count == 3, scope $"{log.States.Count} states");
		Test.Assert((log.States[0] == .Breakpoint) && (log.States[1] == .Running) && (log.States[2] == .Terminated));

		// And the runtime is whole: the next call runs through, the breakpoint hit again.
		Test.Assert(!vm.Call("t", "int walk(Thing@)", arg, ref r));
		Test.Assert(debugger.IsPaused);
		debugger.RemoveBreakpoint("walker.as", 9);
		debugger.Continue();
		Test.Assert(vm.Call("t", "int walk(Thing@)", arg, ref r), "no breakpoint, no pause");
		Test.Assert(r.AsInt == 8);
	}

	[Test]
	public static void StepsMoveOneLineAndBreakPausesTheNextCall()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		Test.Assert(vm.Compile("t", "walker.as", cSource));
		let debugger = vm.CreateDebugger();
		defer delete debugger;
		let thing = scope Thing();
		var arg = ScriptValue[1](.FromObject(thing));
		var r = ScriptValue.Nil;

		// A manual break: the next call stops at its first line.
		debugger.Break();
		Test.Assert(!vm.Call("t", "int walk(Thing@)", arg, ref r));
		Test.Assert(debugger.IsPaused && (debugger.State == .Stepped));
		let frames = scope List<ScriptStackFrame>();
		debugger.CaptureStackFrames(frames);
		let firstLine = frames[0].Line;
		ClearAndDeleteItems(frames);

		// Step over: the next line of the same frame, a call stepped across whole.
		debugger.StepOver();
		Test.Assert(debugger.IsPaused);
		debugger.CaptureStackFrames(frames);
		Test.Assert((frames.Count == 1) && (frames[0].Line > firstLine), scope $"line {frames[0].Line} after {firstLine}");
		ClearAndDeleteItems(frames);
		// To the line calling helper, then INTO it.
		while (true)
		{
			debugger.CaptureStackFrames(frames);
			let line = frames[0].Line;
			ClearAndDeleteItems(frames);
			if (line == 16)
				break;
			debugger.StepOver();
			Test.Assert(debugger.IsPaused, "still inside walk");
		}
		debugger.StepInto();
		debugger.CaptureStackFrames(frames);
		Test.Assert((frames.Count == 2) && frames[0].Function.Contains("helper"), scope $"{frames.Count} frames, {frames[0].Function}");
		ClearAndDeleteItems(frames);

		// Continue runs it out.
		debugger.Continue();
		Test.Assert(!debugger.IsPaused && (debugger.State == .Terminated));
		Test.Assert(thing.Count == 7);
	}

	[Test]
	public static void ADeletedDebuggerAbandonsItsHeldCallCleanly()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		Test.Assert(vm.Compile("t", "walker.as", cSource));
		let debugger = vm.CreateDebugger();
		debugger.SetBreakpoint("walker.as", 9);
		let thing = scope Thing();
		var arg = ScriptValue[1](.FromObject(thing));
		var r = ScriptValue.Nil;
		Test.Assert(!vm.Call("t", "int walk(Thing@)", arg, ref r) && vm.IsDebugPaused);
		delete debugger;
		Test.Assert(!vm.IsDebugPaused);
		Test.Assert(thing.Count == 0, "the abandoned call never finished");
		// The context went back to the pool whole: the runtime calls on.
		Test.Assert(vm.Call("t", "int walk(Thing@)", arg, ref r) && (r.AsInt == 8));
		// And a new debugger attaches.
		let again = vm.CreateDebugger();
		Test.Assert(again != null);
		delete again;
	}

	[Test]
	public static void TheSnapshotTypesRoundTrip()
	{
		let frame = scope ScriptStackFrame();
		frame.File.Set("walker.as");
		frame.Function.Set("int helper(int)");
		frame.Line = 9;
		let variable = scope ScriptVariable();
		variable.Name.Set("w");
		variable.TypeName.Set("Walker");
		variable.Value.Set("Walker");
		variable.ObjectRef = 7;
		let object = scope ScriptValueObject();
		object.Ref = 7;
		object.Text.Set("Walker");

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializerContext(buffer, .Write);
			frame.Serialize(writer.Serializer);
			variable.Serialize(writer.Serializer);
			object.Serialize(writer.Serializer);
		}
		buffer.Seek(0, .Begin);
		let frame2 = scope ScriptStackFrame();
		let variable2 = scope ScriptVariable();
		let object2 = scope ScriptValueObject();
		{
			let reader = scope BinarySerializerContext(buffer, .Read);
			frame2.Serialize(reader.Serializer);
			variable2.Serialize(reader.Serializer);
			object2.Serialize(reader.Serializer);
		}
		Test.Assert((frame2.File == "walker.as") && (frame2.Function == "int helper(int)") && (frame2.Line == 9));
		Test.Assert((variable2.Name == "w") && (variable2.TypeName == "Walker") && (variable2.Value == "Walker") && (variable2.ObjectRef == 7));
		Test.Assert((object2.Ref == 7) && (object2.Text == "Walker"));
	}
}
