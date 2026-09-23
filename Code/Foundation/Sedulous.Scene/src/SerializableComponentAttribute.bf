using System;

namespace Sedulous.Scene;

/// Marks a component that PERSISTS, and states its identity on disk.
///
/// The id lives on the component rather than on the manager that stores it, because it
/// describes the TYPE: two managers of the same component would have to agree on it, and
/// a manager is the wrong place to keep a fact about something else.
///
/// The id is stated rather than derived from the type's name. A runtime type is not stable
/// across builds, and a rename must not silently orphan every component ever saved.
///
/// Implies everything ComponentAttribute does, so a serializable component needs only this
/// one.
[AttributeUsage(.Struct, .ReflectAttribute, ReflectUser = .Type | .NonStaticFields)]
struct SerializableComponentAttribute : Attribute
{
	public String TypeId;
	/// Bumped when the stored shape changes.
	///
	/// A payload stamped with any other version is REFUSED, so a bump means the data written
	/// under the old one has to be re-saved. A reader that guessed at an older layout would
	/// decode the wrong fields and hand back something that looks plausible, which is worse
	/// than saying no.
	public uint32 DataVersion;
	/// The oldest stored version a LEGACY READER still accepts, nought meaning the current
	/// one alone.
	///
	/// Set it alongside a bump when the component keeps a reader for the layout before, and
	/// its Serialize body branches on `ar.Version`. One version back, named in the commit
	/// that adds it, and deleted once the saved data has moved on.
	public uint32 MinReadDataVersion;

	public this(String typeId, uint32 dataVersion = 1, uint32 minReadDataVersion = 0)
	{
		TypeId = typeId;
		DataVersion = dataVersion;
		MinReadDataVersion = minReadDataVersion;
	}
}
