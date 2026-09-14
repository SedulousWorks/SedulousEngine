using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.ModelImporter.Tests;

/// Writing a vertex stream a byte at a time.
///
/// A model mesh's layout is DECLARED by its vertex elements rather than by a struct, and what
/// these cases exercise is a converter reading that declaration, so the fixtures write the
/// bytes the elements describe instead of borrowing a struct that already agrees with them.
static class VertexBytes
{
	public static void Append(List<uint8> bytes, float value)
	{
		var value;
		let raw = (uint8*)&value;
		for (int i < 4)
			bytes.Add(raw[i]);
	}

	public static void Append(List<uint8> bytes, Float2 value)
	{
		Append(bytes, value.X);
		Append(bytes, value.Y);
	}

	public static void Append(List<uint8> bytes, Float3 value)
	{
		Append(bytes, value.X);
		Append(bytes, value.Y);
		Append(bytes, value.Z);
	}

	public static void Append(List<uint8> bytes, Float4 value)
	{
		Append(bytes, value.X);
		Append(bytes, value.Y);
		Append(bytes, value.Z);
		Append(bytes, value.W);
	}

	public static void AppendJoints(List<uint8> bytes, uint16 j0, uint16 j1 = 0, uint16 j2 = 0,
		uint16 j3 = 0)
	{
		for (let joint in scope uint16[](j0, j1, j2, j3))
		{
			bytes.Add((uint8)(joint & 0xFF));
			bytes.Add((uint8)(joint >> 8));
		}
	}
}
