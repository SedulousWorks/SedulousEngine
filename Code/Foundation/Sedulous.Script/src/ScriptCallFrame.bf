using System;

namespace Sedulous.Script;

/// The arguments in and the result out of one thunk call.
///
/// Self is what the member is called on: the object for a class, the value or storage
/// pointer for a struct, the entity for a component; nothing for a static or a scene
/// system, which the thunk resolves itself. A failed call sets Failed, leaves Result nil,
/// and puts the message in the context's LastError, which outlives the frame.
struct ScriptCallFrame
{
	public ScriptCallContext Context;
	public ScriptValue Self = .Nil;
	public Span<ScriptValue> Args;
	public ScriptValue Result = .Nil;
	public bool Failed = false;

	public this(ScriptCallContext context, Span<ScriptValue> args)
	{
		Context = context;
		Args = args;
	}

	/// A thunk's first act: a frame may be reused across calls, and each starts clean.
	public void Begin() mut
	{
		Failed = false;
		Result = .Nil;
	}

	/// The message of the last failure, on the context.
	public StringView Error => Failed ? Context.LastError : default;

	public void Fail(StringView error) mut
	{
		Failed = true;
		Context.LastError.Set(error);
		Result = .Nil;
	}

	/// At least `count` arguments, or a failure naming the shortfall.
	public bool ExpectArgs(int count) mut
	{
		if (Args.Length >= count)
			return true;
		Fail(scope $"expected at least {count} arguments, got {Args.Length}");
		return false;
	}

	/// Argument `i` fills a slot of `kind` (`typeName` for a class or struct), or a failure
	/// naming the mismatch. A missing optional argument passes; the thunk takes its default.
	public bool Expect(int i, ScriptValueKind kind, StringView typeName = default) mut
	{
		if (i >= Args.Length)
			return true;
		if (Args[i].Matches(kind, typeName, var exact))
			return true;
		Fail(scope $"argument {i}: expected {kind}{(typeName.IsEmpty ? "" : " ")}{typeName}, got {Args[i].Kind}");
		return false;
	}

	/// Argument `i`, an entity, belongs to `owner`, or a failure. An entity that names no
	/// owner is taken to be in it, and a call in none (a service with no scene now) takes any.
	public bool ExpectEntityIn(int i, Object owner) mut
	{
		if (i >= Args.Length)
			return true;
		let named = Args[i].AsEntityOwner;
		if ((named == null) || (owner == null) || (named === owner))
			return true;
		Fail(scope $"argument {i}: the entity belongs to another scene");
		return false;
	}

	/// Places a struct result in context storage.
	public void SetStruct<T>(T value) mut where T : struct
	{
		let p = Context.AllocStruct(typeof(T), sizeof(T), alignof(T));
		*(T*)p = value;
		Result = .FromStruct(p, typeof(T));
	}

	/// A struct value in scratch, for a list element or an argument written back: never
	/// the VM's result place, which SetStruct alone may take.
	public ScriptValue PackStruct<T>(T value) where T : struct
	{
		let p = Context.AllocScratch(sizeof(T), alignof(T));
		*(T*)p = value;
		return .FromStruct(p, typeof(T));
	}
}
