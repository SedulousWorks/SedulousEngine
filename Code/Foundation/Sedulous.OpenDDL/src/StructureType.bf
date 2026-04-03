using System;
namespace Sedulous.OpenDDL;

/// <summary>
/// Represents the type of a structure in OpenDDL.
/// Structure types are represented as 32-bit integers, typically four-character codes.
/// </summary>
typealias StructureType = uint32;

/// <summary>
/// Predefined structure type constants used by the OpenDDL parser.
/// </summary>
static class StructureTypes
{
	/// <summary>
	/// The root structure type, used for the implicit root of the structure tree.
	/// </summary>
	public const StructureType Root = 0;

	/// <summary>
	/// Base type for all primitive structures (bool, int, float, string, etc.).
	/// This is used as the base structure type for all built-in primitive types.
	/// </summary>
	public const StructureType Primitive = 0x5052494D; // 'PRIM'

	/// <summary>
	/// Structure type for unrecognized/unknown structure identifiers.
	/// Structures with this type are parsed but ignored during processing.
	/// </summary>
	public const StructureType Unknown = 0x21554E4B; // '!UNK'

	/// <summary>
	/// Maximum allowed subarray size for primitive data.
	/// </summary>
	public const int32 MaxPrimitiveArraySize = 256;

	/// <summary>
	/// Creates a four-character code from a string.
	/// </summary>
	/// <param name="code">A string of exactly 4 ASCII characters.</param>
	/// <returns>The 32-bit four-character code.</returns>
	public static StructureType MakeFourCC(StringView code)
	{
		Runtime.Assert(code.Length == 4, "FourCC must be exactly 4 characters");
		return ((uint32)code[0] << 24) |
			   ((uint32)code[1] << 16) |
			   ((uint32)code[2] << 8) |
			   ((uint32)code[3]);
	}

	/// <summary>
	/// Converts a four-character code to a readable string.
	/// </summary>
	/// <param name="code">The four-character code.</param>
	/// <param name="output">String to append the result to.</param>
	public static void FourCCToString(StructureType code, String output)
	{
		if (code == 0)
		{
			output.Append("ROOT");
			return;
		}

		char8[4] chars;
		chars[0] = (char8)((code >> 24) & 0xFF);
		chars[1] = (char8)((code >> 16) & 0xFF);
		chars[2] = (char8)((code >> 8) & 0xFF);
		chars[3] = (char8)(code & 0xFF);

		for (let c in chars)
		{
			if (c >= ' ' && c <= '~')
				output.Append(c);
			else
				output.AppendF("\\x{0:X2}", (uint8)c);
		}
	}
}
