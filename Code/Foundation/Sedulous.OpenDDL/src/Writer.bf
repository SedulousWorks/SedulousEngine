using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Provides utilities for serializing OpenDDL structures to text format.
/// </summary>
class OpenDDLWriter
{
	private String mOutput = new .() ~ delete _;
	private String mIndentString = new .("\t") ~ delete _;
	private int mIndentLevel = 0;
	private bool mCompactMode = false;
	private int mMaxValuesPerLine = 16;

	/// <summary>
	/// Gets or sets the string used for indentation.
	/// </summary>
	public StringView IndentString
	{
		get => mIndentString;
		set { mIndentString.Set(value); }
	}

	/// <summary>
	/// Gets or sets whether to use compact mode (minimal whitespace).
	/// </summary>
	public bool CompactMode
	{
		get => mCompactMode;
		set => mCompactMode = value;
	}

	/// <summary>
	/// Gets or sets the maximum number of values per line in primitive data.
	/// </summary>
	public int MaxValuesPerLine
	{
		get => mMaxValuesPerLine;
		set => mMaxValuesPerLine = value;
	}

	/// <summary>
	/// Clears the output buffer.
	/// </summary>
	public void Clear()
	{
		mOutput.Clear();
		mIndentLevel = 0;
	}

	/// <summary>
	/// Gets the serialized output.
	/// </summary>
	public StringView Output => mOutput;

	/// <summary>
	/// Copies the output to a string.
	/// </summary>
	public void CopyTo(String output)
	{
		output.Append(mOutput);
	}

	/// <summary>
	/// Writes a complete structure tree starting from the root.
	/// </summary>
	public void WriteStructureTree(Structure root)
	{
		for (let child in root.Children)
		{
			WriteStructure(child);
		}
	}

	/// <summary>
	/// Writes a structure and its contents.
	/// </summary>
	public void WriteStructure(Structure structure)
	{
		if (structure.BaseStructureType == StructureTypes.Primitive)
		{
			WritePrimitiveStructure((PrimitiveStructure)structure);
		}
		else
		{
			WriteDerivedStructure(structure);
		}
	}

	/// <summary>
	/// Writes a primitive structure.
	/// </summary>
	private void WritePrimitiveStructure(PrimitiveStructure structure)
	{
		WriteIndent();

		// Write data type
		mOutput.Append(structure.DataType.LongIdentifier);

		// Write array size if applicable
		if (structure.ArraySize > 0)
		{
			mOutput.AppendF("[{}]", structure.ArraySize);
			if (structure.HasStateData)
				mOutput.Append('*');
		}

		// Write name if present
		if (structure.HasName)
		{
			mOutput.Append(' ');
			mOutput.Append(structure.IsGlobalName ? '$' : '%');
			mOutput.Append(structure.StructureName);
		}

		// Write data
		mOutput.Append(mCompactMode ? "{" : " {");

		if (structure.DataElementCount > 0)
		{
			if (structure.ArraySize > 0)
			{
				WritePrimitiveSubarrays(structure);
			}
			else
			{
				WritePrimitiveData(structure);
			}
		}

		mOutput.Append('}');
		WriteNewLine();
	}

	/// <summary>
	/// Writes primitive data elements.
	/// </summary>
	private void WritePrimitiveData(PrimitiveStructure structure)
	{
		let count = structure.DataElementCount;
		let dataType = structure.DataType;

		bool multiLine = !mCompactMode && count > mMaxValuesPerLine;

		if (multiLine)
		{
			WriteNewLine();
			mIndentLevel++;
		}

		for (int i = 0; i < count; i++)
		{
			if (i > 0)
			{
				mOutput.Append(',');
				if (!mCompactMode)
					mOutput.Append(' ');
			}

			if (multiLine && (i % mMaxValuesPerLine == 0))
			{
				if (i > 0)
					WriteNewLine();
				WriteIndent();
			}

			WriteDataValue(structure, dataType, i);
		}

		if (multiLine)
		{
			WriteNewLine();
			mIndentLevel--;
			WriteIndent();
		}
	}

	/// <summary>
	/// Writes primitive subarrays.
	/// </summary>
	private void WritePrimitiveSubarrays(PrimitiveStructure structure)
	{
		let arraySize = (int)structure.ArraySize;
		let subarrayCount = structure.SubarrayCount;
		let dataType = structure.DataType;
		let hasState = structure.HasStateData;

		bool multiLine = !mCompactMode;

		if (multiLine)
		{
			WriteNewLine();
			mIndentLevel++;
		}

		for (int sub = 0; sub < subarrayCount; sub++)
		{
			if (sub > 0)
			{
				mOutput.Append(',');
				if (multiLine)
					WriteNewLine();
				else if (!mCompactMode)
					mOutput.Append(' ');
			}

			if (multiLine)
				WriteIndent();

			// Write state identifier if applicable
			if (hasState)
			{
				let state = GetStateValue(structure, sub);
				mOutput.AppendF("{} ", state);
			}

			mOutput.Append('{');

			for (int i = 0; i < arraySize; i++)
			{
				if (i > 0)
				{
					mOutput.Append(',');
					if (!mCompactMode)
						mOutput.Append(' ');
				}

				WriteDataValue(structure, dataType, sub * arraySize + i);
			}

			mOutput.Append('}');
		}

		if (multiLine)
		{
			WriteNewLine();
			mIndentLevel--;
			WriteIndent();
		}
	}

	/// <summary>
	/// Writes a single data value.
	/// </summary>
	private void WriteDataValue(PrimitiveStructure structure, DataType dataType, int index)
	{
		switch (dataType)
		{
		case .Bool:
			let value = ((BoolStructure)structure)[index];
			mOutput.Append(value ? "true" : "false");

		case .Int8:
			let value = ((Int8Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .Int16:
			let value = ((Int16Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .Int32:
			let value = ((Int32Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .Int64:
			let value = ((Int64Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .UInt8:
			let value = ((UInt8Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .UInt16:
			let value = ((UInt16Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .UInt32:
			let value = ((UInt32Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .UInt64:
			let value = ((UInt64Structure)structure)[index];
			mOutput.AppendF("{}", value);

		case .Half:
			let bits = ((HalfStructure)structure)[index];
			let value = HalfToFloat(bits);
			WriteFloat(value);

		case .Float:
			let value = ((FloatStructure)structure)[index];
			WriteFloat(value);

		case .Double:
			let value = ((DoubleStructure)structure)[index];
			WriteDouble(value);

		case .String:
			let value = ((StringStructure)structure)[index];
			WriteString(value);

		case .Ref:
			let value = ((RefStructure)structure)[index];
			value.ToString(mOutput);

		case .Type:
			let value = ((TypeStructure)structure)[index];
			mOutput.Append(value.LongIdentifier);

		case .Base64:
			let value = ((Base64Structure)structure)[index];
			WriteBase64(value);
		}
	}

	/// <summary>
	/// Gets a state value from a primitive structure.
	/// </summary>
	private uint32 GetStateValue(PrimitiveStructure structure, int index)
	{
		switch (structure.DataType)
		{
		case .Bool:     return ((BoolStructure)structure).StateArray[index];
		case .Int8:     return ((Int8Structure)structure).StateArray[index];
		case .Int16:    return ((Int16Structure)structure).StateArray[index];
		case .Int32:    return ((Int32Structure)structure).StateArray[index];
		case .Int64:    return ((Int64Structure)structure).StateArray[index];
		case .UInt8:    return ((UInt8Structure)structure).StateArray[index];
		case .UInt16:   return ((UInt16Structure)structure).StateArray[index];
		case .UInt32:   return ((UInt32Structure)structure).StateArray[index];
		case .UInt64:   return ((UInt64Structure)structure).StateArray[index];
		case .Half:     return ((HalfStructure)structure).StateArray[index];
		case .Float:    return ((FloatStructure)structure).StateArray[index];
		case .Double:   return ((DoubleStructure)structure).StateArray[index];
		case .String:   return ((StringStructure)structure).StateArray[index];
		case .Ref:      return ((RefStructure)structure).StateArray[index];
		case .Type:     return ((TypeStructure)structure).StateArray[index];
		case .Base64:   return ((Base64Structure)structure).StateArray[index];
		}
	}

	/// <summary>
	/// Writes a derived (non-primitive) structure.
	/// </summary>
	private void WriteDerivedStructure(Structure structure)
	{
		WriteIndent();

		// Write structure type identifier
		String typeStr = scope .();
		StructureTypes.FourCCToString(structure.StructureType, typeStr);
		mOutput.Append(typeStr);

		// Write name if present
		if (structure.HasName)
		{
			mOutput.Append(' ');
			mOutput.Append(structure.IsGlobalName ? '$' : '%');
			mOutput.Append(structure.StructureName);
		}

		// Write opening brace
		if (mCompactMode)
		{
			mOutput.Append('{');
		}
		else
		{
			mOutput.Append(" {");
			WriteNewLine();
		}

		// Write children
		mIndentLevel++;
		for (let child in structure.Children)
		{
			WriteStructure(child);
		}
		mIndentLevel--;

		// Write closing brace
		WriteIndent();
		mOutput.Append('}');
		WriteNewLine();
	}

	/// <summary>
	/// Writes a float value with appropriate precision.
	/// </summary>
	private void WriteFloat(float value)
	{
		if (value.IsNaN)
		{
			mOutput.Append("0x7FC00000"); // Quiet NaN
			return;
		}
		if (value.IsPositiveInfinity)
		{
			mOutput.Append("0x7F800000");
			return;
		}
		if (value.IsNegativeInfinity)
		{
			mOutput.Append("0xFF800000");
			return;
		}

		// Use enough precision to round-trip
		mOutput.AppendF("{:G9}", value);

		// Ensure it looks like a float (has decimal point or exponent)
		bool hasDecimalOrExponent = false;
		for (let c in mOutput.RawChars)
		{
			if (c == '.' || c == 'e' || c == 'E')
			{
				hasDecimalOrExponent = true;
				break;
			}
		}
		if (!hasDecimalOrExponent)
			mOutput.Append(".0");
	}

	/// <summary>
	/// Writes a double value with appropriate precision.
	/// </summary>
	private void WriteDouble(double value)
	{
		if (value.IsNaN)
		{
			mOutput.Append("0x7FF8000000000000"); // Quiet NaN
			return;
		}
		if (value.IsPositiveInfinity)
		{
			mOutput.Append("0x7FF0000000000000");
			return;
		}
		if (value.IsNegativeInfinity)
		{
			mOutput.Append("0xFFF0000000000000");
			return;
		}

		// Use enough precision to round-trip
		mOutput.AppendF("{:G17}", value);

		// Ensure it looks like a float
		bool hasDecimalOrExponent = false;
		for (let c in mOutput.RawChars)
		{
			if (c == '.' || c == 'e' || c == 'E')
			{
				hasDecimalOrExponent = true;
				break;
			}
		}
		if (!hasDecimalOrExponent)
			mOutput.Append(".0");
	}

	/// <summary>
	/// Writes a string with proper escaping.
	/// </summary>
	private void WriteString(StringView value)
	{
		mOutput.Append('"');

		for (let c in value.RawChars)
		{
			switch (c)
			{
			case '"':  mOutput.Append("\\\"");
			case '\\': mOutput.Append("\\\\");
			case '\a': mOutput.Append("\\a");
			case '\b': mOutput.Append("\\b");
			case '\f': mOutput.Append("\\f");
			case '\n': mOutput.Append("\\n");
			case '\r': mOutput.Append("\\r");
			case '\t': mOutput.Append("\\t");
			case '\v': mOutput.Append("\\v");
			default:
				if (c >= ' ' && c <= '~')
				{
					mOutput.Append(c);
				}
				else if ((uint8)c < 0x80)
				{
					// Control character - use hex escape
					mOutput.AppendF("\\x{0:X2}", (uint8)c);
				}
				else
				{
					// UTF-8 continuation byte or start byte - pass through
					mOutput.Append(c);
				}
			}
		}

		mOutput.Append('"');
	}

	/// <summary>
	/// Writes base64-encoded data.
	/// </summary>
	private void WriteBase64(List<uint8> data)
	{
		const char8[64] base64Chars = .('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
										'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
										'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
										'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
										'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
										'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
										'w', 'x', 'y', 'z', '0', '1', '2', '3',
										'4', '5', '6', '7', '8', '9', '+', '/');

		let len = data.Count;
		int i = 0;

		while (i + 3 <= len)
		{
			let b0 = data[i];
			let b1 = data[i + 1];
			let b2 = data[i + 2];

			mOutput.Append(base64Chars[(b0 >> 2) & 0x3F]);
			mOutput.Append(base64Chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
			mOutput.Append(base64Chars[((b1 << 2) | (b2 >> 6)) & 0x3F]);
			mOutput.Append(base64Chars[b2 & 0x3F]);

			i += 3;
		}

		// Handle remaining bytes
		let remaining = len - i;
		if (remaining == 1)
		{
			let b0 = data[i];
			mOutput.Append(base64Chars[(b0 >> 2) & 0x3F]);
			mOutput.Append(base64Chars[(b0 << 4) & 0x3F]);
			mOutput.Append("==");
		}
		else if (remaining == 2)
		{
			let b0 = data[i];
			let b1 = data[i + 1];
			mOutput.Append(base64Chars[(b0 >> 2) & 0x3F]);
			mOutput.Append(base64Chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
			mOutput.Append(base64Chars[(b1 << 2) & 0x3F]);
			mOutput.Append('=');
		}
	}

	/// <summary>
	/// Writes indentation.
	/// </summary>
	private void WriteIndent()
	{
		if (mCompactMode)
			return;

		for (int i = 0; i < mIndentLevel; i++)
		{
			mOutput.Append(mIndentString);
		}
	}

	/// <summary>
	/// Writes a newline.
	/// </summary>
	private void WriteNewLine()
	{
		if (!mCompactMode)
			mOutput.Append('\n');
	}

	/// <summary>
	/// Converts IEEE 754 half-precision to single-precision.
	/// </summary>
	private static float HalfToFloat(uint16 bits)
	{
		uint32 sign = ((uint32)bits & 0x8000) << 16;
		uint32 exponent = (bits >> 10) & 0x1F;
		uint32 mantissa = bits & 0x03FF;

		if (exponent == 0)
		{
			if (mantissa == 0)
			{
				// Zero
				uint32 result = sign;
				return *(float*)&result;
			}
			else
			{
				// Subnormal - normalize
				while ((mantissa & 0x0400) == 0)
				{
					mantissa <<= 1;
					exponent--;
				}
				exponent++;
				mantissa &= ~0x0400u;
			}
		}
		else if (exponent == 31)
		{
			// Infinity or NaN
			uint32 result = sign | 0x7F800000 | (mantissa << 13);
			return *(float*)&result;
		}

		// Normal number
		exponent = exponent + 127 - 15;
		uint32 floatBits = sign | (exponent << 23) | (mantissa << 13);
		return *(float*)&floatBits;
	}
}

/// <summary>
/// Extension methods for convenient structure serialization.
/// </summary>
static class OpenDDLWriterExtensions
{
	/// <summary>
	/// Serializes a structure tree to an OpenDDL string.
	/// </summary>
	public static void ToOpenDDL(this Structure root, String output, bool compact = false)
	{
		let writer = scope OpenDDLWriter();
		writer.CompactMode = compact;
		writer.WriteStructureTree(root);
		writer.CopyTo(output);
	}

	/// <summary>
	/// Serializes a single structure to an OpenDDL string.
	/// </summary>
	public static void StructureToOpenDDL(this Structure structure, String output, bool compact = false)
	{
		let writer = scope OpenDDLWriter();
		writer.CompactMode = compact;
		writer.WriteStructure(structure);
		writer.CopyTo(output);
	}
}
