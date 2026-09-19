using System;

namespace Sedulous.Scripting;

/// The arguments in and the result out of one thunk call.
///
/// Self is what the member is called on: the object for a class, the value or storage
/// pointer for a struct, the entity for a component; nothing for a static or a scene
/// system, which the thunk resolves itself. A failed call sets Error and leaves Result nil.
struct ScriptCallFrame
{
	public ScriptCallContext Context;
	public ScriptValue Self = .Nil;
	public Span<ScriptValue> Args;
	public ScriptValue Result = .Nil;
	public StringView Error = default;

	public this(ScriptCallContext context, Span<ScriptValue> args)
	{
		Context = context;
		Args = args;
	}

	public bool Failed => !Error.IsEmpty;

	public void Fail(StringView error) mut
	{
		Error = error;
		Result = .Nil;
	}

	/// Places a struct result in context storage.
	public void SetStruct<T>(T value) mut where T : struct
	{
		let p = Context.AllocStruct(typeof(T), sizeof(T), alignof(T));
		*(T*)p = value;
		Result = .FromStruct(p, typeof(T));
	}
}
