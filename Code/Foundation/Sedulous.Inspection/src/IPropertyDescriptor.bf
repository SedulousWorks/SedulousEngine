namespace Sedulous.Inspection;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;

/// Typed property descriptor interface. Called by comptime-generated
/// DescribeProperties methods. Editor implements this to build UI.
///
/// Each method takes two name parameters:
///   name        - property identity. Stable, machine-readable. Matches
///                 the name used in serialization (e.g., "CastsShadows").
///   displayName - shown in the inspector UI (e.g., "Casts Shadows").
///                 Falls back to name if not specified.
interface IPropertyDescriptor
{
	/// Float field with optional min/max range.
	void Float(StringView name, StringView displayName, float* ptr, float min, float max);

	/// Int32 field with optional min/max range.
	void Int32(StringView name, StringView displayName, int32* ptr, int32 min, int32 max);

	/// UInt32 field with optional min/max range.
	void UInt32(StringView name, StringView displayName, uint32* ptr, uint32 min, uint32 max);

	/// Boolean field.
	void Bool(StringView name, StringView displayName, bool* ptr);

	/// String field.
	void Str(StringView name, StringView displayName, String* ptr);

	/// Enum field. enumType is the runtime Type for building a dropdown.
	void EnumField(StringView name, StringView displayName, void* ptr, Type enumType);

	/// Float field displayed as a slider with min/max range.
	void Slider(StringView name, StringView displayName, float* ptr, float min, float max);

	/// Vector3 field (3 numeric fields: X, Y, Z).
	void Vec3(StringView name, StringView displayName, Vector3* ptr);

	/// Vector4 field (4 numeric fields: X, Y, Z, W).
	void Vec4(StringView name, StringView displayName, Vector4* ptr);

	/// Vector4 field displayed as a color swatch with HDR picker.
	/// Emitted when the field is tagged `[Property(.Color)]`.
	void Color4(StringView name, StringView displayName, Vector4* ptr);

	/// Quaternion field displayed as euler angles (3 numeric fields).
	void Quat(StringView name, StringView displayName, Quaternion* ptr);

	/// Single ResourceRef field.
	void ResRef(StringView name, StringView displayName, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		StringView extensionFilter = default);

	/// List of ResourceRef fields.
	void ResRefList(StringView name, StringView displayName, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter);

	/// Begin a named category group (Expander).
	void BeginCategory(StringView name);

	/// End the current category group.
	void EndCategory();
}
