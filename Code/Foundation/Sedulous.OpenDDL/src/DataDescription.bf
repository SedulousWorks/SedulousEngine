using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Represents a derivative file format based on the OpenDDL language.
/// This class serves as a container for the tree hierarchy of data structures
/// in an OpenDDL file and provides parsing functionality.
/// </summary>
class DataDescription
{
	private Dictionary<StringView, Structure> mGlobalNameMap = new .() ~ delete _;
	private RootStructure mRootStructure = new .() ~ delete _;
	private Structure mErrorStructure;
	private int32 mErrorLine;
	private StringView mOriginalText;

	public this()
	{
	}

	/// <summary>
	/// Gets the root structure containing all top-level structures.
	/// </summary>
	public Structure RootStructure => mRootStructure;

	/// <summary>
	/// Gets the line number where an error occurred during parsing.
	/// Returns 0 if no error occurred.
	/// </summary>
	public int32 ErrorLine => mErrorLine;

	/// <summary>
	/// Finds a structure by global reference.
	/// </summary>
	/// <param name="reference">The reference to the structure to find.</param>
	/// <returns>The found structure, or null if not found.</returns>
	public Structure FindStructure(StructureRef reference)
	{
		if (reference == null || reference.IsNull)
			return null;

		if (!reference.IsGlobal)
			return null;

		let nameArray = reference.NameArray;
		if (nameArray.Count == 0)
			return null;

		// Find the structure with the first (global) name
		if (!mGlobalNameMap.TryGetValue(nameArray[0], let structure))
			return null;

		// If there are more names, follow local references
		if (nameArray.Count > 1)
			return structure.FindStructure(reference, 1);

		return structure;
	}

	/// <summary>
	/// Parses an OpenDDL file and builds the structure tree.
	/// </summary>
	/// <param name="text">The full contents of an OpenDDL file.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public DataResult ParseText(StringView text)
	{
		// Clear any previous data
		mRootStructure.ClearChildren();
		mGlobalNameMap.Clear();
		mErrorStructure = null;
		mErrorLine = 0;
		mOriginalText = text;

		var remaining = text;

		// Skip initial whitespace
		let wsLen = Lexer.GetWhitespaceLength(remaining);
		remaining = remaining.Substring(wsLen);

		if (remaining.IsEmpty)
			return .Ok;

		let result = ParseStructures(ref remaining, mRootStructure);

		if (result != .Ok)
		{
			mRootStructure.ClearChildren();
			mGlobalNameMap.Clear();
			mErrorLine = CalculateLineNumber(text, remaining);
			return result;
		}

		// Check for trailing content
		if (!remaining.IsEmpty)
		{
			mRootStructure.ClearChildren();
			mGlobalNameMap.Clear();
			mErrorLine = CalculateLineNumber(text, remaining);
			return .SyntaxError;
		}

		return .Ok;
	}

	/// <summary>
	/// Parses an OpenDDL file and processes the top-level structures.
	/// </summary>
	/// <param name="text">The full contents of an OpenDDL file.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public DataResult ProcessText(StringView text)
	{
		let result = ParseText(text);
		if (result != .Ok)
			return result;

		let processResult = ProcessData();
		if (processResult != .Ok)
		{
			if (mErrorStructure != null)
			{
				let location = mErrorStructure.TextLocation;
				if (!location.IsEmpty)
				{
					mErrorLine = CalculateLineNumber(mOriginalText, location);
				}
			}
		}

		return processResult;
	}

	/// <summary>
	/// Processes all parsed structures.
	/// </summary>
	/// <returns>Ok on success, or an error code.</returns>
	public virtual DataResult ProcessData()
	{
		return mRootStructure.ProcessData(this);
	}

	/// <summary>
	/// Creates a custom data structure for the given identifier.
	/// Override in derived classes to support custom structure types.
	/// </summary>
	/// <param name="identifier">The structure type identifier.</param>
	/// <returns>A new structure instance, or null if the identifier is not recognized.</returns>
	public virtual Structure CreateStructure(StringView identifier)
	{
		return null;
	}

	/// <summary>
	/// Validates a top-level structure.
	/// Override in derived classes to restrict which structures can appear at the top level.
	/// </summary>
	/// <param name="structure">The structure to validate.</param>
	/// <returns>True if the structure is valid at the top level.</returns>
	public virtual bool ValidateTopLevelStructure(Structure structure)
	{
		return true;
	}

	/// <summary>
	/// Creates a primitive structure for the given data type identifier.
	/// </summary>
	private PrimitiveStructure CreatePrimitive(StringView identifier)
	{
		int length;
		DataType dataType;
		if (Lexer.ReadDataType(identifier, out length, out dataType) == .Ok)
		{
			if (length == identifier.Length)
			{
				switch (dataType)
				{
				case .Bool:     return new BoolStructure(dataType);
				case .Int8:     return new Int8Structure(dataType);
				case .Int16:    return new Int16Structure(dataType);
				case .Int32:    return new Int32Structure(dataType);
				case .Int64:    return new Int64Structure(dataType);
				case .UInt8:    return new UInt8Structure(dataType);
				case .UInt16:   return new UInt16Structure(dataType);
				case .UInt32:   return new UInt32Structure(dataType);
				case .UInt64:   return new UInt64Structure(dataType);
				case .Half:     return new HalfStructure(dataType);
				case .Float:    return new FloatStructure(dataType);
				case .Double:   return new DoubleStructure(dataType);
				case .String:   return new StringStructure();
				case .Ref:      return new RefStructure();
				case .Type:     return new TypeStructure();
				case .Base64:   return new Base64Structure();
				}
			}
		}

		return null;
	}

	/// <summary>
	/// Parses structures within a container.
	/// </summary>
	private DataResult ParseStructures(ref StringView text, Structure root)
	{
		while (true)
		{
			// Read structure identifier
			if (Lexer.ReadIdentifier(text, var identLen) != .Ok)
				return .IdentifierEmpty;

			let identifier = text.Substring(0, identLen);

			// Try to create the structure
			bool primitiveFlag = false;
			bool unknownFlag = false;
			Structure structure = null;

			let primitive = CreatePrimitive(identifier);
			if (primitive != null)
			{
				structure = primitive;
				primitiveFlag = true;
			}
			else
			{
				structure = CreateStructure(identifier);
				if (structure == null)
				{
					structure = new Structure(StructureTypes.Unknown);
					unknownFlag = true;
				}
			}

			// Store text location for error reporting
			structure.[Friend]SetTextLocation(text);

			// Advance past identifier
			text = text.Substring(identLen);
			let ws1 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws1);

			// Parse array size for primitive structures
			if (primitiveFlag && !text.IsEmpty && text[0] == '[')
			{
				text = text.Substring(1);
				let ws2 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws2);

				// Check for negative sign (not allowed)
				if (!text.IsEmpty && (text[0] == '+' || text[0] == '-'))
				{
					delete structure;
					return .PrimitiveIllegalArraySize;
				}

				// Read array size
				int intLen;
				uint64 arraySize;
				let arraySizeResult = Lexer.ReadIntegerLiteral(text, out intLen, out arraySize);
				if (arraySizeResult != .Ok)
				{
					delete structure;
					return arraySizeResult;
				}

				if (arraySize == 0)
				{
					delete structure;
					return .PrimitiveIllegalArraySize;
				}

				if (arraySize > StructureTypes.MaxPrimitiveArraySize)
				{
					delete structure;
					return .PrimitiveIllegalArraySize;
				}

				((PrimitiveStructure)structure).ArraySize = (uint32)arraySize;

				text = text.Substring(intLen);
				let ws3 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws3);

				if (text.IsEmpty || text[0] != ']')
				{
					delete structure;
					return .PrimitiveSyntaxError;
				}

				text = text.Substring(1);
				let ws4 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws4);

				// Check for state flag
				if (!text.IsEmpty && text[0] == '*')
				{
					((PrimitiveStructure)structure).HasStateData = true;
					text = text.Substring(1);
					let ws5 = Lexer.GetWhitespaceLength(text);
					text = text.Substring(ws5);
				}
			}

			// Add to parent now (but we may remove it later if unknown)
			root.AppendChild(structure);

			// Validate the structure
			if (!unknownFlag && !root.ValidateSubstructure(this, structure))
			{
				structure.RemoveFromParent();
				delete structure;
				return .InvalidStructure;
			}

			// Parse structure name
			if (!text.IsEmpty && (text[0] == '$' || text[0] == '%'))
			{
				let isGlobal = text[0] == '$';
				text = text.Substring(1);

				if (Lexer.ReadIdentifier(text, var nameLen) != .Ok)
				{
					if (!unknownFlag)
					{
						structure.RemoveFromParent();
						delete structure;
					}
					return .IdentifierEmpty;
				}

				let name = text.Substring(0, nameLen);
				structure.SetName(name, isGlobal);

				// Add to appropriate name map
				if (isGlobal)
				{
					if (mGlobalNameMap.ContainsKey(structure.StructureName))
					{
						structure.RemoveFromParent();
						delete structure;
						return .StructNameExists;
					}
					mGlobalNameMap[structure.StructureName] = structure;
				}
				else
				{
					// Local names need to be added after SetName since AppendChild was called earlier
					structure.UpdateParentLocalNameMap();
				}

				text = text.Substring(nameLen);
				let ws6 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws6);
			}

			// Parse properties for non-primitive structures
			if (!primitiveFlag && !text.IsEmpty && text[0] == '(')
			{
				text = text.Substring(1);
				let ws7 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws7);

				if (!text.IsEmpty && text[0] != ')')
				{
					let propResult = ParseProperties(ref text, structure);
					if (propResult != .Ok)
					{
						if (!unknownFlag)
						{
							structure.RemoveFromParent();
							delete structure;
						}
						return propResult;
					}

					if (text.IsEmpty || text[0] != ')')
					{
						if (!unknownFlag)
						{
							structure.RemoveFromParent();
							delete structure;
						}
						return .PropertySyntaxError;
					}
				}

				text = text.Substring(1);
				let ws8 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws8);
			}

			// Expect opening brace
			if (text.IsEmpty || text[0] != '{')
			{
				if (!unknownFlag)
				{
					structure.RemoveFromParent();
					delete structure;
				}
				return .SyntaxError;
			}

			text = text.Substring(1);
			let ws9 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws9);

			// Parse content
			if (!text.IsEmpty && text[0] != '}')
			{
				if (primitiveFlag)
				{
					let dataResult = ParsePrimitiveData(ref text, (PrimitiveStructure)structure, root);
					if (dataResult != .Ok)
					{
						if (!unknownFlag)
						{
							structure.RemoveFromParent();
							delete structure;
						}
						return dataResult;
					}
				}
				else
				{
					let subResult = ParseStructures(ref text, structure);
					if (subResult != .Ok)
					{
						if (!unknownFlag)
						{
							structure.RemoveFromParent();
							delete structure;
						}
						return subResult;
					}
				}

				if (text.IsEmpty || text[0] != '}')
				{
					if (!unknownFlag)
					{
						structure.RemoveFromParent();
						delete structure;
					}
					return .SyntaxError;
				}
			}

			text = text.Substring(1);
			let ws10 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws10);

			// Remove unknown structures
			if (unknownFlag)
			{
				structure.RemoveFromParent();
				delete structure;
			}

			// Check if we're done
			if (text.IsEmpty || text[0] == '}')
				break;
		}

		return .Ok;
	}

	/// <summary>
	/// Parses properties within parentheses.
	/// </summary>
	private DataResult ParseProperties(ref StringView text, Structure structure)
	{
		while (true)
		{
			// Read property identifier
			if (Lexer.ReadIdentifier(text, var identLen) != .Ok)
				return .IdentifierEmpty;

			let identifier = text.Substring(0, identLen);
			text = text.Substring(identLen);
			let ws1 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws1);

			// Check if property is valid
			DataType expectedType;
			let isValid = structure.ValidateProperty(this, identifier, out expectedType);

			if (isValid)
			{
				if (expectedType != .Bool)
				{
					// Non-bool properties require = value
					if (text.IsEmpty || text[0] != '=')
						return .PropertySyntaxError;

					text = text.Substring(1);
					let ws2 = Lexer.GetWhitespaceLength(text);
					text = text.Substring(ws2);

					// Parse the value based on expected type
					let parseResult = ParsePropertyValue(ref text, expectedType);
					if (parseResult != .Ok)
						return parseResult;
				}
				else
				{
					// Bool properties can be just the identifier (defaults to true)
					// or can have = value
					if (!text.IsEmpty && text[0] == '=')
					{
						text = text.Substring(1);
						let ws3 = Lexer.GetWhitespaceLength(text);
						text = text.Substring(ws3);

						// Parse bool value
						let parseResult = ParsePropertyValue(ref text, .Bool);
						if (parseResult != .Ok)
							return parseResult;
					}
				}
			}
			else
			{
				// Unknown property - try to parse and discard value
				if (!text.IsEmpty && text[0] == '=')
				{
					text = text.Substring(1);
					let ws4 = Lexer.GetWhitespaceLength(text);
					text = text.Substring(ws4);

					// Try to parse any valid property value type
					let discardResult = ParseUnknownPropertyValue(ref text);
					if (discardResult != .Ok)
						return .PropertySyntaxError;
				}
			}

			// Check for comma (more properties) or end
			if (!text.IsEmpty && text[0] == ',')
			{
				text = text.Substring(1);
				let ws5 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws5);
				continue;
			}

			break;
		}

		return .Ok;
	}

	/// <summary>
	/// Parses a property value of a known type.
	/// </summary>
	private DataResult ParsePropertyValue(ref StringView text, DataType dataType)
	{
		int len;

		switch (dataType)
		{
		case .Bool:
			bool boolValue;
			if (Lexer.ReadBoolLiteral(text, out len, out boolValue) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .BoolInvalid;

		case .Int8, .Int16, .Int32, .Int64, .UInt8, .UInt16, .UInt32, .UInt64:
			uint64 intValue;
			if (Lexer.ReadIntegerLiteral(text, out len, out intValue) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .IntegerOverflow;

		case .Half, .Float, .Double:
			double floatValue;
			if (Lexer.ReadFloatLiteral(text, out len, out floatValue) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .FloatInvalid;

		case .String:
			let stringValue = scope String();
			if (Lexer.ReadStringLiteral(text, out len, stringValue) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .StringInvalid;

		case .Ref:
			int refLen;
			let refResult = StructureRef.Parse(text, out refLen, scope StructureRef());
			if (refResult == .Ok)
			{
				text = text.Substring(refLen);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return refResult;

		case .Type:
			DataType typeValue;
			if (Lexer.ReadDataType(text, out len, out typeValue) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .TypeInvalid;

		case .Base64:
			let base64Value = scope List<uint8>();
			if (Lexer.ReadBase64Data(text, out len, base64Value) == .Ok)
			{
				text = text.Substring(len);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				return .Ok;
			}
			return .Base64Invalid;
		}
	}

	/// <summary>
	/// Tries to parse any valid property value type (for unknown properties).
	/// </summary>
	private DataResult ParseUnknownPropertyValue(ref StringView text)
	{
		int len;

		// Try bool first
		bool boolValue;
		if (Lexer.ReadBoolLiteral(text, out len, out boolValue) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try string
		let stringValue = scope String();
		if (Lexer.ReadStringLiteral(text, out len, stringValue) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try reference
		int refLen;
		let refResult = StructureRef.Parse(text, out refLen, scope StructureRef());
		if (refResult == .Ok)
		{
			text = text.Substring(refLen);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try data type
		DataType typeValue;
		if (Lexer.ReadDataType(text, out len, out typeValue) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try integer
		uint64 intValue;
		if (Lexer.ReadIntegerLiteral(text, out len, out intValue) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try float
		double floatValue;
		if (Lexer.ReadFloatLiteral(text, out len, out floatValue) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		// Try base64
		let base64Value = scope List<uint8>();
		if (Lexer.ReadBase64Data(text, out len, base64Value) == .Ok)
		{
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;
		}

		return .PropertySyntaxError;
	}

	/// <summary>
	/// Parses primitive data within braces.
	/// </summary>
	private DataResult ParsePrimitiveData(ref StringView text, PrimitiveStructure structure, Structure parentStructure)
	{
		let arraySize = structure.ArraySize;
		let hasState = structure.HasStateData;
		let dataType = structure.DataType;

		if (arraySize == 0)
		{
			// Flat list of values
			return ParseFlatData(ref text, structure, dataType);
		}
		else
		{
			// Subarrays with optional state
			return ParseSubarrayData(ref text, structure, parentStructure, dataType, arraySize, hasState);
		}
	}

	/// <summary>
	/// Parses a flat list of primitive values.
	/// </summary>
	private DataResult ParseFlatData(ref StringView text, PrimitiveStructure structure, DataType dataType)
	{
		while (true)
		{
			let result = ParseAndAddValue(ref text, structure, dataType);
			if (result != .Ok)
				return result;

			// Check for comma
			if (!text.IsEmpty && text[0] == ',')
			{
				text = text.Substring(1);
				let ws = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws);
				continue;
			}

			break;
		}

		return .Ok;
	}

	/// <summary>
	/// Parses subarrays with optional state identifiers.
	/// </summary>
	private DataResult ParseSubarrayData(ref StringView text, PrimitiveStructure structure, Structure parentStructure,
		DataType dataType, uint32 arraySize, bool hasState)
	{
		while (true)
		{
			uint32 stateValue = 0;

			// Check for optional state identifier
			if (hasState)
			{
				if (Lexer.ReadIdentifier(text, var stateLen) == .Ok)
				{
					let stateId = text.Substring(0, stateLen);
					if (!parentStructure.GetStateValue(stateId, out stateValue))
						return .PrimitiveInvalidState;

					text = text.Substring(stateLen);
					let ws = Lexer.GetWhitespaceLength(text);
					text = text.Substring(ws);
				}
			}

			// Expect opening brace
			if (text.IsEmpty || text[0] != '{')
				return .PrimitiveInvalidFormat;

			text = text.Substring(1);
			let ws1 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws1);

			// Store state if applicable
			if (hasState)
			{
				AddStateValue(structure, stateValue);
			}

			// Parse exactly arraySize values
			for (uint32 i = 0; i < arraySize; i++)
			{
				if (i > 0)
				{
					if (text.IsEmpty || text[0] != ',')
						return .PrimitiveArrayUnderSize;

					text = text.Substring(1);
					let ws2 = Lexer.GetWhitespaceLength(text);
					text = text.Substring(ws2);
				}

				let result = ParseAndAddValue(ref text, structure, dataType);
				if (result != .Ok)
					return result;
			}

			// Check for closing brace (not comma, which would indicate too many values)
			if (text.IsEmpty)
				return .PrimitiveInvalidFormat;

			if (text[0] == ',')
				return .PrimitiveArrayOverSize;

			if (text[0] != '}')
				return .PrimitiveInvalidFormat;

			text = text.Substring(1);
			let ws3 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws3);

			// Check for more subarrays
			if (!text.IsEmpty && text[0] == ',')
			{
				text = text.Substring(1);
				let ws4 = Lexer.GetWhitespaceLength(text);
				text = text.Substring(ws4);
				continue;
			}

			break;
		}

		return .Ok;
	}

	/// <summary>
	/// Parses a single value and adds it to the structure.
	/// </summary>
	private DataResult ParseAndAddValue(ref StringView text, PrimitiveStructure structure, DataType dataType)
	{
		int len;

		switch (dataType)
		{
		case .Bool:
			bool boolValue;
			let boolResult = Lexer.ReadBoolLiteral(text, out len, out boolValue);
			if (boolResult != .Ok)
				return boolResult;
			((BoolStructure)structure).AddData(boolValue);
			text = text.Substring(len);
			let ws = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws);
			return .Ok;

		case .Int8:
			uint64 intValue;
			bool isNegative;
			let intResult = Lexer.ReadSignedIntegerLiteral(text, out len, out intValue, out isNegative);
			if (intResult != .Ok)
				return intResult;
			if (isNegative)
			{
				let signed = -(int64)intValue;
				if (signed < int8.MinValue)
					return .IntegerOverflow;
				((Int8Structure)structure).AddData((int8)signed);
			}
			else
			{
				if (intValue > (uint64)int8.MaxValue)
					return .IntegerOverflow;
				((Int8Structure)structure).AddData((int8)intValue);
			}
			text = text.Substring(len);
			let ws2 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws2);
			return .Ok;

		case .Int16:
			uint64 int16Value;
			bool int16Neg;
			let int16Result = Lexer.ReadSignedIntegerLiteral(text, out len, out int16Value, out int16Neg);
			if (int16Result != .Ok)
				return int16Result;
			if (int16Neg)
			{
				let signed = -(int64)int16Value;
				if (signed < int16.MinValue)
					return .IntegerOverflow;
				((Int16Structure)structure).AddData((int16)signed);
			}
			else
			{
				if (int16Value > (uint64)int16.MaxValue)
					return .IntegerOverflow;
				((Int16Structure)structure).AddData((int16)int16Value);
			}
			text = text.Substring(len);
			let ws3 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws3);
			return .Ok;

		case .Int32:
			uint64 int32Value;
			bool int32Neg;
			let int32Result = Lexer.ReadSignedIntegerLiteral(text, out len, out int32Value, out int32Neg);
			if (int32Result != .Ok)
				return int32Result;
			if (int32Neg)
			{
				let signed = -(int64)int32Value;
				if (signed < int32.MinValue)
					return .IntegerOverflow;
				((Int32Structure)structure).AddData((int32)signed);
			}
			else
			{
				if (int32Value > (uint64)int32.MaxValue)
					return .IntegerOverflow;
				((Int32Structure)structure).AddData((int32)int32Value);
			}
			text = text.Substring(len);
			let ws4 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws4);
			return .Ok;

		case .Int64:
			uint64 int64Value;
			bool int64Neg;
			let int64Result = Lexer.ReadSignedIntegerLiteral(text, out len, out int64Value, out int64Neg);
			if (int64Result != .Ok)
				return int64Result;
			if (int64Neg)
			{
				let signed = -(int64)int64Value;
				((Int64Structure)structure).AddData(signed);
			}
			else
			{
				if (int64Value > (uint64)int64.MaxValue)
					return .IntegerOverflow;
				((Int64Structure)structure).AddData((int64)int64Value);
			}
			text = text.Substring(len);
			let ws5 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws5);
			return .Ok;

		case .UInt8:
			uint64 uint8Value;
			bool uint8Neg;
			let uint8Result = Lexer.ReadSignedIntegerLiteral(text, out len, out uint8Value, out uint8Neg);
			if (uint8Result != .Ok)
				return uint8Result;
			if (uint8Neg || uint8Value > uint8.MaxValue)
				return .IntegerOverflow;
			((UInt8Structure)structure).AddData((uint8)uint8Value);
			text = text.Substring(len);
			let ws6 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws6);
			return .Ok;

		case .UInt16:
			uint64 uint16Value;
			bool uint16Neg;
			let uint16Result = Lexer.ReadSignedIntegerLiteral(text, out len, out uint16Value, out uint16Neg);
			if (uint16Result != .Ok)
				return uint16Result;
			if (uint16Neg || uint16Value > uint16.MaxValue)
				return .IntegerOverflow;
			((UInt16Structure)structure).AddData((uint16)uint16Value);
			text = text.Substring(len);
			let ws7 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws7);
			return .Ok;

		case .UInt32:
			uint64 uint32Value;
			bool uint32Neg;
			let uint32Result = Lexer.ReadSignedIntegerLiteral(text, out len, out uint32Value, out uint32Neg);
			if (uint32Result != .Ok)
				return uint32Result;
			if (uint32Neg || uint32Value > uint32.MaxValue)
				return .IntegerOverflow;
			((UInt32Structure)structure).AddData((uint32)uint32Value);
			text = text.Substring(len);
			let ws8 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws8);
			return .Ok;

		case .UInt64:
			uint64 uint64Value;
			bool uint64Neg;
			let uint64Result = Lexer.ReadSignedIntegerLiteral(text, out len, out uint64Value, out uint64Neg);
			if (uint64Result != .Ok)
				return uint64Result;
			if (uint64Neg)
				return .IntegerOverflow;
			((UInt64Structure)structure).AddData(uint64Value);
			text = text.Substring(len);
			let ws9 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws9);
			return .Ok;

		case .Half:
			double halfValue;
			let halfResult = Lexer.ReadFloatLiteral(text, out len, out halfValue);
			if (halfResult != .Ok)
				return halfResult;
			// Store as uint16 (IEEE 754 half-precision)
			((HalfStructure)structure).AddData(FloatToHalf((float)halfValue));
			text = text.Substring(len);
			let ws10 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws10);
			return .Ok;

		case .Float:
			double floatValue;
			let floatResult = Lexer.ReadFloatLiteral(text, out len, out floatValue);
			if (floatResult != .Ok)
				return floatResult;
			((FloatStructure)structure).AddData((float)floatValue);
			text = text.Substring(len);
			let ws11 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws11);
			return .Ok;

		case .Double:
			double doubleValue;
			let doubleResult = Lexer.ReadFloatLiteral(text, out len, out doubleValue);
			if (doubleResult != .Ok)
				return doubleResult;
			((DoubleStructure)structure).AddData(doubleValue);
			text = text.Substring(len);
			let ws12 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws12);
			return .Ok;

		case .String:
			let stringValue = scope String();
			let stringResult = Lexer.ReadStringLiteral(text, out len, stringValue);
			if (stringResult != .Ok)
				return stringResult;
			((StringStructure)structure).AddData(stringValue);
			text = text.Substring(len);
			let ws13 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws13);
			return .Ok;

		case .Ref:
			let refValue = new StructureRef();
			int refLen;
			let refResult = StructureRef.Parse(text, out refLen, refValue);
			if (refResult != .Ok)
			{
				delete refValue;
				return refResult;
			}
			((RefStructure)structure).AddData(refValue);
			text = text.Substring(refLen);
			let ws14 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws14);
			return .Ok;

		case .Type:
			DataType typeValue;
			let typeResult = Lexer.ReadDataType(text, out len, out typeValue);
			if (typeResult != .Ok)
				return typeResult;
			((TypeStructure)structure).AddData(typeValue);
			text = text.Substring(len);
			let ws15 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws15);
			return .Ok;

		case .Base64:
			let base64Value = new List<uint8>();
			let base64Result = Lexer.ReadBase64Data(text, out len, base64Value);
			if (base64Result != .Ok)
			{
				delete base64Value;
				return base64Result;
			}
			((Base64Structure)structure).AddData(base64Value);
			text = text.Substring(len);
			let ws16 = Lexer.GetWhitespaceLength(text);
			text = text.Substring(ws16);
			return .Ok;
		}
	}

	/// <summary>
	/// Adds a state value to a primitive structure.
	/// </summary>
	private void AddStateValue(PrimitiveStructure structure, uint32 state)
	{
		switch (structure.DataType)
		{
		case .Bool:     ((BoolStructure)structure).AddState(state);
		case .Int8:     ((Int8Structure)structure).AddState(state);
		case .Int16:    ((Int16Structure)structure).AddState(state);
		case .Int32:    ((Int32Structure)structure).AddState(state);
		case .Int64:    ((Int64Structure)structure).AddState(state);
		case .UInt8:    ((UInt8Structure)structure).AddState(state);
		case .UInt16:   ((UInt16Structure)structure).AddState(state);
		case .UInt32:   ((UInt32Structure)structure).AddState(state);
		case .UInt64:   ((UInt64Structure)structure).AddState(state);
		case .Half:     ((HalfStructure)structure).AddState(state);
		case .Float:    ((FloatStructure)structure).AddState(state);
		case .Double:   ((DoubleStructure)structure).AddState(state);
		case .String:   ((StringStructure)structure).AddState(state);
		case .Ref:      ((RefStructure)structure).AddState(state);
		case .Type:     ((TypeStructure)structure).AddState(state);
		case .Base64:   ((Base64Structure)structure).AddState(state);
		}
	}

	/// <summary>
	/// Calculates the line number from the start of text to current position.
	/// </summary>
	private static int32 CalculateLineNumber(StringView original, StringView current)
	{
		int32 line = 1;
		let consumed = original.Length - current.Length;

		for (int i = 0; i < consumed && i < original.Length; i++)
		{
			if (original[i] == '\n')
				line++;
		}

		return line;
	}

	/// <summary>
	/// Converts a float to IEEE 754 half-precision format.
	/// </summary>
	private static uint16 FloatToHalf(float value)
	{
		var value;
		// Get the bit representation of the float
		uint32 bits = *(uint32*)&value;

		uint32 sign = (bits >> 16) & 0x8000;
		int32 exponent = (int32)((bits >> 23) & 0xFF) - 127 + 15;
		uint32 mantissa = bits & 0x007FFFFF;

		if (exponent <= 0)
		{
			// Subnormal or zero
			if (exponent < -10)
				return (uint16)sign;

			mantissa = (mantissa | 0x00800000) >> (1 - exponent);
			return (uint16)(sign | (mantissa >> 13));
		}
		else if (exponent == 0xFF - 127 + 15)
		{
			// Infinity or NaN
			if (mantissa == 0)
				return (uint16)(sign | 0x7C00); // Infinity
			return (uint16)(sign | 0x7C00 | (mantissa >> 13)); // NaN
		}
		else if (exponent > 30)
		{
			// Overflow to infinity
			return (uint16)(sign | 0x7C00);
		}

		return (uint16)(sign | ((uint32)exponent << 10) | (mantissa >> 13));
	}
}
