using System;
using System.Reflection;

namespace Sedulous.Resource;

/// A reference-shaped value, a Ref<T> whatever T: its identity is a Guid, and generic tooling
/// (an agent's entity_inspect and component_set) reads and writes THAT instead of the value,
/// through Ref<T>'s run time reflection, never naming T. Each call takes the value's type and
/// its address, as a component field is reached: an address inside a pool plus the field's
/// type.
static class ReferenceShape
{
	public static bool Is(Type type)
	{
		let generic = type as SpecializedGenericType;
		return (generic != null) && (generic.UnspecializedType == typeof(Ref<>));
	}

	/// The type the reference points at: T for a Ref<T>, the runtime type the resource manager
	/// keys its factories with. What a schema or a picker needs to say WHAT kind of thing the
	/// guid names, without naming the reference template. Null for a type that is no reference.
	public static Type Target(Type type)
	{
		if (!Is(type))
			return null;
		return ((SpecializedGenericType)type).GetGenericArg(0);
	}

	/// The identity inside the reference at `value`.
	public static Result<Guid> Id(Type type, void* value)
	{
		if (!Is(type))
			return .Err;
		if (!(type.GetField("Id") case .Ok(let field)))
			return .Err;
		return *(Guid*)((uint8*)value + field.MemberOffset);
	}

	/// Points the reference at `id`, then binds it through `resources` (Rebind), or, with no
	/// manager, drops the stale binding so the next resolve binds the new id (ClearBinding).
	public static Result<void> Assign(Type type, void* value, Guid id, ResourceManager resources)
	{
		if (!Is(type))
			return .Err;
		if (!(type.GetField("Id") case .Ok(let field)))
			return .Err;
		*(Guid*)((uint8*)value + field.MemberOffset) = id;
		let target = Variant.CreateReference(type, value);
		if (resources != null)
		{
			if (!(type.GetMethod("Rebind") case .Ok(let rebind)))
				return .Err;
			if (rebind.Invoke(target, Variant.Create(resources)) case .Err)
				return .Err;
			return .Ok;
		}
		if (!(type.GetMethod("ClearBinding") case .Ok(let clear)))
			return .Err;
		if (clear.Invoke(target) case .Err)
			return .Err;
		return .Ok;
	}
}
