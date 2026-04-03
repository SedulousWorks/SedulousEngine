using System;
namespace Sedulous.OpenDDL;

/// <summary>
/// Represents the 16 primitive data types defined by OpenDDL.
/// Each type can be specified using either a long identifier or short identifier.
/// </summary>
enum DataType : uint32
{
	/// <summary>
	/// Boolean type that can have the value true or false.
	/// Long identifier: bool, Short identifier: b
	/// </summary>
	Bool = 0x424F4F4C, // 'BOOL'

	/// <summary>
	/// 8-bit signed integer that can have values in the range [-128, 127].
	/// Long identifier: int8, Short identifier: i8
	/// </summary>
	Int8 = 0x494E5438, // 'INT8'

	/// <summary>
	/// 16-bit signed integer that can have values in the range [-32768, 32767].
	/// Long identifier: int16, Short identifier: i16
	/// </summary>
	Int16 = 0x494E3136, // 'IN16'

	/// <summary>
	/// 32-bit signed integer that can have values in the range [-2^31, 2^31-1].
	/// Long identifier: int32, Short identifier: i32
	/// </summary>
	Int32 = 0x494E3332, // 'IN32'

	/// <summary>
	/// 64-bit signed integer that can have values in the range [-2^63, 2^63-1].
	/// Long identifier: int64, Short identifier: i64
	/// </summary>
	Int64 = 0x494E3634, // 'IN64'

	/// <summary>
	/// 8-bit unsigned integer that can have values in the range [0, 255].
	/// Long identifier: uint8, Short identifier: u8
	/// </summary>
	UInt8 = 0x55494E38, // 'UIN8'

	/// <summary>
	/// 16-bit unsigned integer that can have values in the range [0, 65535].
	/// Long identifier: uint16, Short identifier: u16
	/// </summary>
	UInt16 = 0x55493136, // 'UI16'

	/// <summary>
	/// 32-bit unsigned integer that can have values in the range [0, 2^32-1].
	/// Long identifier: uint32, Short identifier: u32
	/// </summary>
	UInt32 = 0x55493332, // 'UI32'

	/// <summary>
	/// 64-bit unsigned integer that can have values in the range [0, 2^64-1].
	/// Long identifier: uint64, Short identifier: u64
	/// </summary>
	UInt64 = 0x55493634, // 'UI64'

	/// <summary>
	/// 16-bit floating-point type in the standard S1-E5-M10 format.
	/// Long identifiers: half, float16, Short identifiers: h, f16
	/// </summary>
	Half = 0x48414C46, // 'HALF'

	/// <summary>
	/// 32-bit floating-point type in the standard S1-E8-M23 format.
	/// Long identifiers: float, float32, Short identifiers: f, f32
	/// </summary>
	Float = 0x464C4F54, // 'FLOT'

	/// <summary>
	/// 64-bit floating-point type in the standard S1-E11-M52 format.
	/// Long identifiers: double, float64, Short identifiers: d, f64
	/// </summary>
	Double = 0x444F5542, // 'DOUB'

	/// <summary>
	/// Double-quoted character string with contents encoded in UTF-8.
	/// Long identifier: string, Short identifier: s
	/// </summary>
	String = 0x53545247, // 'STRG'

	/// <summary>
	/// Sequence of structure names, or the keyword null.
	/// Long identifier: ref, Short identifier: r
	/// </summary>
	Ref = 0x52464E43, // 'RFNC'

	/// <summary>
	/// Type whose values are identifiers naming the types in this enum.
	/// Long identifier: type, Short identifier: t
	/// </summary>
	Type = 0x54595045, // 'TYPE'

	/// <summary>
	/// Generic binary data encoded as base64.
	/// Long identifier: base64, Short identifier: z
	/// </summary>
	Base64 = 0x42533634, // 'BS64'
}

extension DataType
{
	/// <summary>
	/// Returns the long identifier string for this data type.
	/// </summary>
	public StringView LongIdentifier
	{
		get
		{
			switch (this)
			{
			case .Bool: return "bool";
			case .Int8: return "int8";
			case .Int16: return "int16";
			case .Int32: return "int32";
			case .Int64: return "int64";
			case .UInt8: return "uint8";
			case .UInt16: return "uint16";
			case .UInt32: return "uint32";
			case .UInt64: return "uint64";
			case .Half: return "half";
			case .Float: return "float";
			case .Double: return "double";
			case .String: return "string";
			case .Ref: return "ref";
			case .Type: return "type";
			case .Base64: return "base64";
			}
		}
	}

	/// <summary>
	/// Returns the short identifier string for this data type.
	/// </summary>
	public StringView ShortIdentifier
	{
		get
		{
			switch (this)
			{
			case .Bool: return "b";
			case .Int8: return "i8";
			case .Int16: return "i16";
			case .Int32: return "i32";
			case .Int64: return "i64";
			case .UInt8: return "u8";
			case .UInt16: return "u16";
			case .UInt32: return "u32";
			case .UInt64: return "u64";
			case .Half: return "h";
			case .Float: return "f";
			case .Double: return "d";
			case .String: return "s";
			case .Ref: return "r";
			case .Type: return "t";
			case .Base64: return "z";
			}
		}
	}

	/// <summary>
	/// Parses a data type from its identifier string.
	/// </summary>
	/// <param name="identifier">The identifier to parse (long or short form).</param>
	/// <returns>The parsed DataType, or null if the identifier is not recognized.</returns>
	public static DataType? FromIdentifier(StringView identifier)
	{
		switch (identifier)
		{
		case "bool", "b": return .Bool;
		case "int8", "i8": return .Int8;
		case "int16", "i16": return .Int16;
		case "int32", "i32": return .Int32;
		case "int64", "i64": return .Int64;
		case "uint8", "u8", "unsigned_int8": return .UInt8;
		case "uint16", "u16", "unsigned_int16": return .UInt16;
		case "uint32", "u32", "unsigned_int32": return .UInt32;
		case "uint64", "u64", "unsigned_int64": return .UInt64;
		case "half", "h", "float16", "f16": return .Half;
		case "float", "f", "float32", "f32": return .Float;
		case "double", "d", "float64", "f64": return .Double;
		case "string", "s": return .String;
		case "ref", "r": return .Ref;
		case "type", "t": return .Type;
		case "base64", "z": return .Base64;
		default: return null;
		}
	}

	/// <summary>
	/// Returns true if this data type is an integer type (signed or unsigned).
	/// </summary>
	public bool IsInteger
	{
		get
		{
			switch (this)
			{
			case .Int8, .Int16, .Int32, .Int64,
				 .UInt8, .UInt16, .UInt32, .UInt64:
				return true;
			default:
				return false;
			}
		}
	}

	/// <summary>
	/// Returns true if this data type is a signed integer type.
	/// </summary>
	public bool IsSignedInteger
	{
		get
		{
			switch (this)
			{
			case .Int8, .Int16, .Int32, .Int64:
				return true;
			default:
				return false;
			}
		}
	}

	/// <summary>
	/// Returns true if this data type is an unsigned integer type.
	/// </summary>
	public bool IsUnsignedInteger
	{
		get
		{
			switch (this)
			{
			case .UInt8, .UInt16, .UInt32, .UInt64:
				return true;
			default:
				return false;
			}
		}
	}

	/// <summary>
	/// Returns true if this data type is a floating-point type.
	/// </summary>
	public bool IsFloatingPoint
	{
		get
		{
			switch (this)
			{
			case .Half, .Float, .Double:
				return true;
			default:
				return false;
			}
		}
	}

	/// <summary>
	/// Returns true if this data type is numeric (integer or floating-point).
	/// </summary>
	public bool IsNumeric => IsInteger || IsFloatingPoint;
}
