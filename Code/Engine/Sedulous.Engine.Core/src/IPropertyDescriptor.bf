namespace Sedulous.Engine.Core;

using System;
using Sedulous.Core.Mathematics;

/// Typed property descriptor interface. Called by comptime-generated
/// DescribeProperties methods. Editor implements this to build UI.
interface IPropertyDescriptor
{
	/// Float field with optional min/max range.
	void Float(StringView name, float* ptr, float min, float max);

	/// Int32 field with optional min/max range.
	void Int32(StringView name, int32* ptr, int32 min, int32 max);

	/// UInt32 field with optional min/max range.
	void UInt32(StringView name, uint32* ptr, uint32 min, uint32 max);

	/// Boolean field.
	void Bool(StringView name, bool* ptr);

	/// String field.
	void Str(StringView name, String* ptr);

	/// Enum field. enumType is the runtime Type for building a dropdown.
	void EnumField(StringView name, void* ptr, Type enumType);

	/// Float field displayed as a slider with min/max range.
	void Slider(StringView name, float* ptr, float min, float max);

	/// Vector3 field (3 numeric fields: X, Y, Z).
	void Vec3(StringView name, Vector3* ptr);

	/// Quaternion field displayed as euler angles (3 numeric fields).
	void Quat(StringView name, Quaternion* ptr);

	/// Begin a named category group (Expander).
	void BeginCategory(StringView name);

	/// End the current category group.
	void EndCategory();
}
