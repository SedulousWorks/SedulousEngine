using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Turns the type id stored in a stream back into an object.
///
/// This is what makes polymorphic loading possible: a payload records which type wrote it,
/// and the reader has to construct that type without knowing it at the call site.
///
/// Core owns the table; it does not own the entries. A registry generated HERE could
/// enumerate the types in the projects that depend on Core, but it could not name them:
/// they are invisible to the code being compiled. So population belongs where the types
/// are, which is also where ownership should sit. Apply [SerializableRegistry] to a class
/// in the project that declares them and call its RegisterAll.
static class SerializableRegistry
{
	private static Dictionary<uint64, function ISerializable()> sFactories = new .() ~ delete _;

	/// Registers a constructor for a type id. Registering the same id twice replaces the
	/// first, so a later module can deliberately take over a type.
	public static void Register(uint64 typeId, function ISerializable() factory)
	{
		sFactories[typeId] = factory;
	}

	public static bool IsRegistered(uint64 typeId) => sFactories.ContainsKey(typeId);

	public static int Count => sFactories.Count;

	/// Constructs the type with this id, or null when no such type is registered. The
	/// caller owns what comes back.
	///
	/// Null is the ordinary answer for a payload written by a build that had a type this
	/// one does not, which is what framed regions exist to carry past.
	public static ISerializable Create(uint64 typeId)
	{
		if (sFactories.TryGetValue(typeId, let factory))
			return factory();
		return null;
	}

	/// Forgets one type.
	///
	/// A factory is a FUNCTION POINTER, so one registered by a shared library outlives the
	/// library unless something removes it. The next Create for that id would then jump
	/// into unmapped memory, which is why a plugin host has to be able to take a
	/// registration back rather than only add one.
	public static bool Unregister(uint64 typeId) => sFactories.Remove(typeId);

	/// The ids currently registered, appended to the list.
	///
	/// For a host that needs to know what a module added: snapshot before, snapshot after,
	/// and the difference is what that module owns.
	public static void CopyIds(List<uint64> outIds)
	{
		for (let entry in sFactories)
			outIds.Add(entry.key);
	}

	/// Forgets everything. For tests, and for a host that tears a module back down.
	public static void Clear() => sFactories.Clear();
}
