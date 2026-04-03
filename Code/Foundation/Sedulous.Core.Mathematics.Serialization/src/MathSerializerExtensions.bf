using System;
using Sedulous.Serialization;

namespace Sedulous.Core.Mathematics;

using static Sedulous.Core.Mathematics.MathSerializerExtensions;

/// Extension methods for serializing math types.
static class MathSerializerExtensions
{
	/// Serializes a Vector2.
	public static SerializationResult Vector2(this Serializer s, StringView name, ref Vector2 value)
	{
		return s.FixedFloatArray(name, &value.X, 2);
	}

	/// Serializes a Vector3.
	public static SerializationResult Vector3(this Serializer s, StringView name, ref Vector3 value)
	{
		return s.FixedFloatArray(name, &value.X, 3);
	}

	/// Serializes a Vector4.
	public static SerializationResult Vector4(this Serializer s, StringView name, ref Vector4 value)
	{
		return s.FixedFloatArray(name, &value.X, 4);
	}

	/// Serializes a Quaternion.
	public static SerializationResult Quaternion(this Serializer s, StringView name, ref Quaternion value)
	{
		return s.FixedFloatArray(name, &value.X, 4);
	}

	/// Serializes a Matrix (4x4).
	/// The matrix is serialized in column-major order (16 floats).
	public static SerializationResult Matrix4x4(this Serializer s, StringView name, ref Matrix value)
	{
		return s.FixedFloatArray(name, &value.M11, 16);
	}
}
