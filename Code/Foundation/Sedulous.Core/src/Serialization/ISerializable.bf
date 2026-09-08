namespace Sedulous.Core.Serialization;

/// A type that describes its own data.
///
/// Value and container types do not need this; they go through the non-intrusive Serialize
/// free functions. This is for the objects that are stored and loaded by identity.
///
/// The body is usually generated: applying [Serializable] adds this interface and emits a
/// Serialize that walks the type's fields. Implementing it by hand is the opt-out, for a
/// type whose stored shape is not its field list.
interface ISerializable
{
	/// Describes this object's data once, running in whichever direction ar is set to.
	/// `mut`, so a VALUE type can implement it: a struct reading itself back has to write
	/// its own fields, and a non mut member would make every value component a class.
	/// A class implementer is unaffected, mut being a no op for one.
	void Serialize(ISerializer ar) mut;
}
