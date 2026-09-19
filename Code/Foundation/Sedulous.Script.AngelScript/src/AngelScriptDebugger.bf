using System;
using System.Collections;
using AngelScript;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The suspension based step debugger.
///
/// A breakpoint is a line callback that suspends the executing context, which unwinds
/// back to the runtime's Execute as SUSPENDED; the debugger ADOPTS that context, held out
/// of the pool and fully inspectable, and Continue and the steps execute the same held
/// context on. Single threaded and non blocking: the frame that hit the breakpoint reports
/// its call as paused, and the run around it keeps going. One held call at a time: a
/// re-entrant call while paused, an event handler firing during the pause, runs through
/// without suspending, since adopting a second context would orphan the held one.
class AngelScriptDebugger : IScriptDebugger
{
	private enum StepMode { None, Into, Over }
	private enum Cause { Breakpoint, Step }

	private struct Breakpoint
	{
		public String File;
		public int32 Line;
	}

	/// What a capture handed out as expandable: a script object by address, or an engine
	/// value the surface describes. Refs are valid within one break.
	private class CapturedObject
	{
		public uint64 Ref;
		public void* ScriptObject = null;
		public ScriptValue Value = .Nil;
	}

	/// BORROWED; null once the runtime detached.
	private AngelScriptRuntime mRuntime;
	private List<Breakpoint> mBreakpoints = new .() ~ { for (var b in _) delete b.File; delete _; };
	private IScriptDebuggerListener mListener = null;
	private ScriptDebuggerState mState = .Running;

	private AS.Context* mPausedContext = null;
	private bool mPaused = false;
	private Cause mCause = .Breakpoint;
	private bool mBreakNext = false;
	private bool mStepArmed = false;
	private StepMode mStepMode = .None;
	private int32 mStepFromLine = -1;
	private int32 mStepFromDepth = 0;
	private int32 mStepBaseDepth = 0;

	/// The held call's argument copies, alive until it terminates.
	private List<void*> mHeldCopies = new .() ~ delete _;
	private List<void*> mHeldStrings = new .() ~ delete _;
	private AS.Function* mHeldFunction = null;
	private String mHeldWhat = new .() ~ delete _;

	private List<CapturedObject> mObjects = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mNextObjectRef = 1;

	public this(AngelScriptRuntime runtime)
	{
		mRuntime = runtime;
		mRuntime.[Friend]AttachDebugger(this);
	}

	public ~this()
	{
		if (mRuntime != null)
		{
			DropHeld(true);
			mRuntime.[Friend]DetachDebugger(this);
		}
	}

	/// The runtime is going: nothing it owns may be touched from here on.
	public void RuntimeGone()
	{
		mPausedContext = null;
		mPaused = false;
		mRuntime = null;
	}

	// ---- IScriptDebugger ----

	public void SetBreakpoint(StringView file, int32 line)
	{
		for (let b in mBreakpoints)
		{
			if ((b.Line == line) && (b.File == file))
				return;
		}
		var b = Breakpoint();
		b.File = new String(file);
		b.Line = line;
		mBreakpoints.Add(b);
	}

	public void RemoveBreakpoint(StringView file, int32 line)
	{
		for (int i = mBreakpoints.Count - 1; i >= 0; i--)
		{
			if ((mBreakpoints[i].Line == line) && (mBreakpoints[i].File == file))
			{
				delete mBreakpoints[i].File;
				mBreakpoints.RemoveAt(i);
			}
		}
	}

	public void ClearBreakpoints()
	{
		for (var b in mBreakpoints)
			delete b.File;
		mBreakpoints.Clear();
	}

	public void Break() => mBreakNext = true;
	public void Continue() => Resume(.None);
	public void StepInto() => Resume(.Into);
	public void StepOver() => Resume(.Over);

	public bool IsPaused => mPaused;
	public ScriptDebuggerState State => mState;

	public void CaptureStackFrames(List<ScriptStackFrame> outFrames)
	{
		if (!mPaused || (mPausedContext == null))
			return;
		let size = AS.asc_context_get_callstack_size(mPausedContext);
		for (uint32 level = 0; level < size; level++)
		{
			let frame = new ScriptStackFrame();
			char8* section = null;
			frame.Line = AS.asc_context_get_line_number(mPausedContext, level, null, &section);
			if (section != null)
				frame.File.Set(StringView(section));
			let fn = AS.asc_context_get_function(mPausedContext, level);
			frame.Function.Set((fn != null) ? StringView(AS.asc_function_get_declaration(fn, 1, 0, 1)) : "?");
			outFrames.Add(frame);
		}
	}

	public void CaptureLocals(uint32 depth, List<ScriptVariable> outLocals)
	{
		if (!mPaused || (mPausedContext == null) || (mRuntime == null))
			return;
		// `this` first, when the frame has one.
		let thisTypeId = AS.asc_context_get_this_type_id(mPausedContext, depth);
		if (thisTypeId > 0)
		{
			var self = AS.asc_context_get_this_pointer(mPausedContext, depth);
			if (self != null)
			{
				let variable = new ScriptVariable();
				variable.Name.Set("this");
				variable.TypeName.Set(TypeNameOf(thisTypeId));
				DescribeAddress(variable, thisTypeId | AS.asTYPEID_OBJHANDLE, &self);
				outLocals.Add(variable);
			}
		}
		let count = AS.asc_context_get_var_count(mPausedContext, depth);
		for (int32 i = 0; i < count; i++)
		{
			char8* name = null;
			int32 typeId = 0;
			if (AS.asc_context_get_var(mPausedContext, (uint32)i, depth, &name, &typeId) < 0)
				continue;
			if ((name == null) || (name[0] == '\0'))
				continue; // an unnamed temporary
			if (AS.asc_context_is_var_in_scope(mPausedContext, (uint32)i, depth) == 0)
				continue;
			let variable = new ScriptVariable();
			variable.Name.Set(StringView(name));
			let declaration = AS.asc_context_get_var_declaration(mPausedContext, (uint32)i, depth);
			variable.TypeName.Set((declaration != null) ? StringView(declaration) : TypeNameOf(typeId));
			let address = AS.asc_context_get_address_of_var(mPausedContext, (uint32)i, depth);
			if (address == null)
				variable.Value.Set("<uninitialized>");
			else
				DescribeAddress(variable, typeId, address);
			outLocals.Add(variable);
		}
	}

	public void CaptureObject(uint64 objectRef, List<ScriptVariable> outMembers)
	{
		if (mRuntime == null)
			return;
		let captured = FindObject(objectRef);
		if (captured == null)
			return;
		if (captured.ScriptObject != null)
		{
			// A script class: its declared properties, by address.
			let object = (AS.ScriptObject*)captured.ScriptObject;
			let count = AS.asc_object_get_property_count(object);
			for (uint32 i = 0; i < count; i++)
			{
				let variable = new ScriptVariable();
				variable.Name.Set(StringView(AS.asc_object_get_property_name(object, i)));
				let typeId = AS.asc_object_get_property_type_id(object, i);
				variable.TypeName.Set(TypeNameOf(typeId));
				DescribeAddress(variable, typeId, AS.asc_object_get_address_of_property(object, i));
				outMembers.Add(variable);
			}
			return;
		}
		// An engine object or value: the surface's fields, read through their thunks.
		let type = mRuntime.[Friend]TypeOfValue(captured.Value);
		if (type == null)
			return;
		var frame = ScriptCallFrame(mRuntime.Context, default);
		for (let field in type.Fields)
		{
			if (field.IsStatic || (field.Get == null))
				continue;
			frame.Begin();
			frame.Self = captured.Value;
			field.Get(ref frame);
			let variable = new ScriptVariable();
			variable.Name.Set(field.ScriptName);
			variable.TypeName.Set(field.TypeName);
			if (frame.Failed)
				variable.Value.Set("<unreadable>");
			else
				DescribeValue(variable, frame.Result);
			outMembers.Add(variable);
		}
	}

	public void SetListener(IScriptDebuggerListener listener) => mListener = listener;

	// ---- the runtime's side ----

	/// Arms the line callback on a context about to execute.
	public void Arm(AS.Context* ctx)
	{
		AS.asc_context_set_line_callback(ctx, => OnLineCallback, Internal.UnsafeCastToPtr(this));
	}

	/// True, and the context is adopted, when this debugger's line callback suspended it.
	/// The call's argument copies pass to the debugger, alive until the call terminates.
	public bool Adopt(AS.Context* ctx, AS.Function* fn, StringView what, List<void*> copies, List<void*> strings)
	{
		if (mPausedContext != ctx)
			return false;
		mPaused = true;
		mHeldFunction = fn;
		mHeldWhat.Set(what);
		mHeldCopies.AddRange(copies);
		mHeldStrings.AddRange(strings);
		copies.Clear();
		strings.Clear();
		FireState((mCause == .Step) ? .Stepped : .Breakpoint);
		return true;
	}

	private static void OnLineCallback(AS.Context* ctx, void* user)
	{
		let self = Internal.UnsafeCastToObject(user) as AngelScriptDebugger;
		self.OnLine(ctx);
	}

	/// Control is INSIDE Execute here: suspends when the line is a breakpoint, a satisfied
	/// step, or a pending manual break.
	private void OnLine(AS.Context* ctx)
	{
		if ((mPausedContext != null) && (mPausedContext != ctx))
			return;
		char8* section = null;
		let line = AS.asc_context_get_line_number(ctx, 0, null, &section);
		var cause = Cause.Breakpoint;
		bool suspend = false;
		if (mBreakNext)
		{
			suspend = true;
			cause = .Step;
			mBreakNext = false;
		}
		else if (mStepArmed)
		{
			let depth = (int32)AS.asc_context_get_callstack_size(ctx);
			let depthOk = (mStepMode == .Into) || (depth <= mStepBaseDepth);
			let moved = (line != mStepFromLine) || (depth != mStepFromDepth);
			if (depthOk && moved)
			{
				suspend = true;
				cause = .Step;
			}
		}
		if (!suspend && IsBreakpoint((section != null) ? StringView(section) : default, line))
		{
			suspend = true;
			cause = .Breakpoint;
		}
		if (!suspend)
			return;
		mPausedContext = ctx;
		mCause = cause;
		mStepArmed = false;
		AS.asc_context_suspend(ctx);
	}

	private bool IsBreakpoint(StringView section, int32 line)
	{
		for (let b in mBreakpoints)
		{
			if ((b.Line == line) && (b.File == section))
				return true;
		}
		return false;
	}

	/// Executes the held context on: to the next breakpoint or completion, or one line
	/// into or over.
	private void Resume(StepMode mode)
	{
		if (!mPaused || (mPausedContext == null) || (mRuntime == null))
			return;
		let ctx = mPausedContext;
		if (mode == .None)
		{
			mStepArmed = false;
		}
		else
		{
			mStepArmed = true;
			mStepMode = mode;
			mStepFromDepth = (int32)AS.asc_context_get_callstack_size(ctx);
			mStepBaseDepth = mStepFromDepth;
			mStepFromLine = AS.asc_context_get_line_number(ctx, 0, null, null);
		}
		mPaused = false;
		mPausedContext = null; // set again by the line callback if it suspends again
		ClearAndDeleteItems!(mObjects); // refs live within one break
		mNextObjectRef = 1;
		FireState(.Running);

		let state = AS.asc_context_execute(ctx);
		if ((state == AS.asEXECUTION_SUSPENDED) && (mPausedContext == ctx))
		{
			mPaused = true;
			FireState((mCause == .Step) ? .Stepped : .Breakpoint);
			return;
		}
		// Ran to completion, or faulted: the call is over.
		if (state == AS.asEXECUTION_EXCEPTION)
			mRuntime.[Friend]ReportExecution(ctx, state, mHeldWhat);
		ReleaseHeld(ctx);
		FireState(.Terminated);
	}

	/// The held context back to the pool, its callback and the call's copies gone.
	private void ReleaseHeld(AS.Context* ctx)
	{
		AS.asc_context_clear_line_callback(ctx);
		mRuntime.[Friend]FreeArgCopies(mHeldCopies, mHeldStrings);
		mHeldFunction = null;
		mRuntime.[Friend]ReleaseContext(ctx);
	}

	/// Drops a held call without finishing it: the debugger is going away.
	private void DropHeld(bool abort)
	{
		if (mPausedContext == null)
			return;
		let ctx = mPausedContext;
		mPausedContext = null;
		mPaused = false;
		if (abort)
			AS.asc_context_abort(ctx);
		ReleaseHeld(ctx);
		ClearAndDeleteItems!(mObjects);
	}

	private void FireState(ScriptDebuggerState state)
	{
		mState = state;
		if (mListener != null)
			mListener.OnDebuggerStateChanged(state);
	}

	// ---- values ----

	private StringView TypeNameOf(int32 typeId)
	{
		let type = AS.asc_engine_get_type_info_by_id(mRuntime.[Friend]mEngine, typeId & ~AS.asTYPEID_OBJHANDLE);
		if (type != null)
			return StringView(AS.asc_typeinfo_get_name(type));
		switch (typeId & ~AS.asTYPEID_OBJHANDLE)
		{
		case AS.asTYPEID_BOOL: return "bool";
		case AS.asTYPEID_INT8: return "int8";
		case AS.asTYPEID_INT16: return "int16";
		case AS.asTYPEID_INT32: return "int";
		case AS.asTYPEID_INT64: return "int64";
		case AS.asTYPEID_UINT8: return "uint8";
		case AS.asTYPEID_UINT16: return "uint16";
		case AS.asTYPEID_UINT32: return "uint";
		case AS.asTYPEID_UINT64: return "uint64";
		case AS.asTYPEID_FLOAT: return "float";
		case AS.asTYPEID_DOUBLE: return "double";
		default: return "?";
		}
	}

	/// A variable's text and expandability from the AngelScript typed memory: a script
	/// object is expanded by address, an engine value through the surface.
	private void DescribeAddress(ScriptVariable variable, int32 typeId, void* address)
	{
		if ((typeId & AS.asTYPEID_SCRIPTOBJECT) != 0)
		{
			// A handle slot holds the pointer; a value declared object IS the object.
			let object = ((typeId & AS.asTYPEID_OBJHANDLE) != 0) ? *(void**)address : address;
			if (object == null)
			{
				variable.Value.Set("null");
				return;
			}
			let captured = new CapturedObject();
			captured.Ref = mNextObjectRef++;
			captured.ScriptObject = object;
			mObjects.Add(captured);
			variable.ObjectRef = captured.Ref;
			variable.Value.Set(TypeNameOf(typeId));
			return;
		}
		DescribeValue(variable, mRuntime.[Friend]ReadTyped(typeId, address));
	}

	private void DescribeValue(ScriptVariable variable, ScriptValue value)
	{
		AngelScriptRuntime.ValueText(value, variable.Value);
		let expandable = ((value.Kind == .Object) && (mRuntime.[Friend]TypeOfValue(value) != null))
			|| ((value.Kind == .Struct) && (mRuntime.[Friend]TypeOfValue(value) != null));
		if (!expandable)
			return;
		let captured = new CapturedObject();
		captured.Ref = mNextObjectRef++;
		captured.Value = value;
		mObjects.Add(captured);
		variable.ObjectRef = captured.Ref;
	}

	private CapturedObject FindObject(uint64 objectRef)
	{
		for (let o in mObjects)
		{
			if (o.Ref == objectRef)
				return o;
		}
		return null;
	}
}
