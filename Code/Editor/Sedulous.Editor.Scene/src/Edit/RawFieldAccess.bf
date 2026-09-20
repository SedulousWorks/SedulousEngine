using System;
using System.Reflection;

namespace Sedulous.Editor.Scene;

/// Reaching a reflected field of a RAW instance, an address plus the type that describes it,
/// which is how a component lives: a struct inside its manager's pool, with no object to
/// hand over. Nothing is cached; the pool moves under it, so every access starts from a
/// freshly asked address.
static class RawFieldAccess
{
	/// The field named `property` on `type`, or an error when the type does not reflect it.
	public static Result<FieldInfo> FindField(Type type, StringView property)
	{
		if (type == null)
			return .Err;
		let name = scope String(property);
		return type.GetField(name);
	}

	/// The field's address within an instance.
	public static void* AddressOf(FieldInfo field, void* instance)
		=> (uint8*)instance + field.MemberOffset;

	/// The integer stored at `address`, sized by the field: what an enum, a bool or any
	/// integer field yields for a raw edit.
	public static int64 ReadRawInt(void* address, int size)
	{
		switch (size)
		{
		case 1: return *(int8*)address;
		case 2: return *(int16*)address;
		case 8: return *(int64*)address;
		default: return *(int32*)address;
		}
	}

	public static void WriteRawInt(void* address, int size, int64 value)
	{
		switch (size)
		{
		case 1: *(int8*)address = (int8)value;
		case 2: *(int16*)address = (int16)value;
		case 8: *(int64*)address = value;
		default: *(int32*)address = (int32)value;
		}
	}

	/// Reads a field as an owned Variant; the caller disposes it.
	public static Result<Variant> Read(FieldInfo field, void* instance, Type instanceType)
	{
		let target = Variant.CreateReference(instanceType, instance);
		return field.GetValue(target);
	}

	/// Writes a Variant of the field's exact type.
	public static Result<void> Write(FieldInfo field, void* instance, Type instanceType,
		Variant value)
	{
		let target = Variant.CreateReference(instanceType, instance);
		if (field.SetValue(target, value) case .Err)
			return .Err;
		return .Ok;
	}
}
