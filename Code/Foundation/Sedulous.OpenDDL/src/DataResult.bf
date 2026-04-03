using System;

namespace Sedulous.OpenDDL;

/// <summary>
/// Represents the result of parsing operations in OpenDDL.
/// Success is indicated by Ok, all other values represent specific errors.
/// </summary>
enum DataResult : uint32
{
	/// <summary>
	/// The operation completed successfully.
	/// </summary>
	Ok = 0,

	// ---- General Syntax Errors ----

	/// <summary>
	/// The syntax is invalid.
	/// </summary>
	SyntaxError = 0x53594E54, // 'SYNT'

	// ---- Identifier Errors ----

	/// <summary>
	/// No identifier was found where one was expected.
	/// </summary>
	IdentifierEmpty = 0x4944454D, // 'IDEM'

	/// <summary>
	/// An identifier contains an illegal character.
	/// </summary>
	IdentifierIllegalChar = 0x49444943, // 'IDIC'

	// ---- String Literal Errors ----

	/// <summary>
	/// A string literal is invalid.
	/// </summary>
	StringInvalid = 0x53544956, // 'STIV'

	/// <summary>
	/// A string literal contains an illegal character.
	/// </summary>
	StringIllegalChar = 0x53544943, // 'STIC'

	/// <summary>
	/// A string literal contains an illegal escape sequence.
	/// </summary>
	StringIllegalEscape = 0x53544945, // 'STIE'

	/// <summary>
	/// The end of file was reached inside a string literal.
	/// </summary>
	StringEndOfFile = 0x53544546, // 'STEF'

	// ---- Character Literal Errors ----

	/// <summary>
	/// A character literal contains an illegal character.
	/// </summary>
	CharIllegalChar = 0x43484943, // 'CHIC'

	/// <summary>
	/// A character literal contains an illegal escape sequence.
	/// </summary>
	CharIllegalEscape = 0x43484945, // 'CHIE'

	/// <summary>
	/// The end of file was reached inside a character literal.
	/// </summary>
	CharEndOfFile = 0x43484546, // 'CHEF'

	// ---- Literal Value Errors ----

	/// <summary>
	/// A boolean value is not "true", "false", "0", or "1".
	/// </summary>
	BoolInvalid = 0x424C4956, // 'BLIV'

	/// <summary>
	/// A data type value does not name a primitive type.
	/// </summary>
	TypeInvalid = 0x54594956, // 'TYIV'

	/// <summary>
	/// Base64 data is invalid.
	/// </summary>
	Base64Invalid = 0x42534956, // 'BSIV'

	/// <summary>
	/// An integer value lies outside the range of representable values
	/// for the number of bits in its underlying type.
	/// </summary>
	IntegerOverflow = 0x494E4F56, // 'INOV'

	/// <summary>
	/// A hexadecimal or binary literal used to represent a floating-point value
	/// contains more bits than the underlying type.
	/// </summary>
	FloatOverflow = 0x464C4F56, // 'FLOV'

	/// <summary>
	/// A floating-point literal has an invalid format.
	/// </summary>
	FloatInvalid = 0x464C4956, // 'FLIV'

	/// <summary>
	/// A reference uses an invalid syntax.
	/// </summary>
	ReferenceInvalid = 0x52464956, // 'RFIV'

	// ---- Structure Errors ----

	/// <summary>
	/// A structure name is equal to a previously used structure name.
	/// </summary>
	StructNameExists = 0x53544E45, // 'STNE'

	/// <summary>
	/// A property list contains a syntax error.
	/// </summary>
	PropertySyntaxError = 0x50505345, // 'PPSE'

	/// <summary>
	/// A property has specified an invalid type.
	/// This error is generated if ValidateProperty does not specify a recognized data type.
	/// </summary>
	PropertyInvalidType = 0x50504954, // 'PPIT'

	// ---- Primitive Data Errors ----

	/// <summary>
	/// A primitive data structure contains a syntax error.
	/// </summary>
	PrimitiveSyntaxError = 0x504D5345, // 'PMSE'

	/// <summary>
	/// A primitive data array size is too large.
	/// </summary>
	PrimitiveIllegalArraySize = 0x504D4153, // 'PMAS'

	/// <summary>
	/// A primitive data structure contains data in an invalid format.
	/// </summary>
	PrimitiveInvalidFormat = 0x504D4946, // 'PMIF'

	/// <summary>
	/// A primitive array contains too few elements.
	/// </summary>
	PrimitiveArrayUnderSize = 0x504D5553, // 'PMUS'

	/// <summary>
	/// A primitive array contains too many elements.
	/// </summary>
	PrimitiveArrayOverSize = 0x504D4F53, // 'PMOS'

	/// <summary>
	/// A state identifier contained in primitive array data is not recognized.
	/// This error is generated when GetStateValue returns false.
	/// </summary>
	PrimitiveInvalidState = 0x504D5354, // 'PMST'

	/// <summary>
	/// A structure contains a substructure of an invalid type, or a structure
	/// of an invalid type appears at the top level of the file.
	/// This error is generated when either ValidateSubstructure or
	/// ValidateTopLevelStructure returns false.
	/// </summary>
	InvalidStructure = 0x49565354, // 'IVST'

	// ---- Processing Errors (used during ProcessData) ----

	/// <summary>
	/// A structure is missing a substructure of a required type.
	/// </summary>
	MissingSubstructure = 0x4D535342, // 'MSSB'

	/// <summary>
	/// A structure contains too many substructures of a legal type.
	/// </summary>
	ExtraneousSubstructure = 0x45585342, // 'EXSB'

	/// <summary>
	/// The primitive data contained in a structure uses an invalid format
	/// (type, element count, subarray size, or state data).
	/// </summary>
	InvalidDataFormat = 0x49564446, // 'IVDF'

	/// <summary>
	/// The value specified for a property is invalid.
	/// </summary>
	InvalidPropertyValue = 0x49565056, // 'IVPV'

	/// <summary>
	/// The target of a reference does not exist.
	/// </summary>
	BrokenReference = 0x42524546, // 'BREF'
}

extension DataResult
{
	/// <summary>
	/// Returns true if the result indicates success.
	/// </summary>
	public bool IsOk => this == .Ok;

	/// <summary>
	/// Returns true if the result indicates an error.
	/// </summary>
	public bool IsError => this != .Ok;

	/// <summary>
	/// Gets a human-readable description of the result.
	/// </summary>
	public StringView Description
	{
		get
		{
			switch (this)
			{
			case .Ok: return "Operation completed successfully";
			case .SyntaxError: return "Syntax error";
			case .IdentifierEmpty: return "No identifier found where one was expected";
			case .IdentifierIllegalChar: return "Identifier contains an illegal character";
			case .StringInvalid: return "String literal is invalid";
			case .StringIllegalChar: return "String literal contains an illegal character";
			case .StringIllegalEscape: return "String literal contains an illegal escape sequence";
			case .StringEndOfFile: return "End of file reached inside string literal";
			case .CharIllegalChar: return "Character literal contains an illegal character";
			case .CharIllegalEscape: return "Character literal contains an illegal escape sequence";
			case .CharEndOfFile: return "End of file reached inside character literal";
			case .BoolInvalid: return "Boolean value is not 'true', 'false', '0', or '1'";
			case .TypeInvalid: return "Data type value does not name a primitive type";
			case .Base64Invalid: return "Base64 data is invalid";
			case .IntegerOverflow: return "Integer value exceeds representable range";
			case .FloatOverflow: return "Floating-point literal contains too many bits";
			case .FloatInvalid: return "Floating-point literal has invalid format";
			case .ReferenceInvalid: return "Reference uses invalid syntax";
			case .StructNameExists: return "Structure name already exists";
			case .PropertySyntaxError: return "Property list contains a syntax error";
			case .PropertyInvalidType: return "Property has invalid type";
			case .PrimitiveSyntaxError: return "Primitive data structure contains a syntax error";
			case .PrimitiveIllegalArraySize: return "Primitive data array size is too large";
			case .PrimitiveInvalidFormat: return "Primitive data has invalid format";
			case .PrimitiveArrayUnderSize: return "Primitive array contains too few elements";
			case .PrimitiveArrayOverSize: return "Primitive array contains too many elements";
			case .PrimitiveInvalidState: return "State identifier not recognized";
			case .InvalidStructure: return "Structure type is invalid in this context";
			case .MissingSubstructure: return "Required substructure is missing";
			case .ExtraneousSubstructure: return "Too many substructures of this type";
			case .InvalidDataFormat: return "Data format is invalid";
			case .InvalidPropertyValue: return "Property value is invalid";
			case .BrokenReference: return "Referenced structure does not exist";
			}
		}
	}
}
