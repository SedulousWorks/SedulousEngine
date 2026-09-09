namespace Sedulous.Json;

/// What a JSON value is.
enum JsonType : uint8
{
	case Null;
	case Bool;
	case Number;
	case String;
	case Array;
	case Object;
}
