namespace Sedulous.Core.Serialization;

/// The kind of a scalar being moved.
///
/// It separates what kind of value this is from how many bytes it occupies, so a keyed or
/// text backend can emit the right token while a binary backend needs only the width.
enum ScalarKind : uint8
{
	case Bool;
	case Int8;
	case UInt8;
	case Int16;
	case UInt16;
	case Int32;
	case UInt32;
	case Int64;
	case UInt64;
	case Float32;
	case Float64;

	/// The width of one value of this kind, in bytes.
	public int Size
	{
		get
		{
			switch (this)
			{
			case .Bool, .Int8, .UInt8:
				return 1;
			case .Int16, .UInt16:
				return 2;
			case .Int32, .UInt32, .Float32:
				return 4;
			case .Int64, .UInt64, .Float64:
				return 8;
			}
		}
	}
}
