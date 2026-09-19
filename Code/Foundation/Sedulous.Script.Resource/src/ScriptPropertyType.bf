namespace Sedulous.Script.Resource;

/// The kinds a script's authored property can have: what the inspector edits and a
/// component override stores. A small closed set on purpose; it is the wire format of
/// every override in every scene file.
enum ScriptPropertyType : uint8
{
	case None = 0;
	case Float;
	case Int;
	case Bool;
	case String;
	case Color;
	case Vec3;
	/// An entity reference, by its stable id: remapped by the prefab machinery like every
	/// other entity reference in a payload.
	case Entity;
	/// A typed resource reference, by id; the type name says which.
	case Asset;
}
