using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Turns the type id stored in a stream back into an object.
///
/// This is what makes polymorphic loading possible: a payload records which type wrote it,
/// and the reader has to construct that type without knowing it at the call site.
///
/// An INSTANCE, with a global one for the ordinary case. Everything that loads polymorphic
/// data takes a registry and defaults to the global, so two databases in one process can
/// carry different registrations: a tool inspecting content built by another build, a test
/// that needs a table with exactly two types in it and no interference from whatever else
/// the process registered.
///
/// Core owns the table; it does not own the entries. A registry generated HERE could
/// enumerate the types in the projects that depend on Core, but it could not name them:
/// they are invisible to the code being compiled. So population belongs where the types
/// are. Apply [SerializableRegistry] to a class in the project that declares them and call
/// its RegisterAll.
class SerializableRegistry
{
	private Dictionary<uint64, function ISerializable()> mFactories = new .() ~ delete _;
	private delegate void(uint64) mObserver ~ delete _;

	/// Registers a constructor for a type id. Registering the same id twice replaces the
	/// first, so a later module can deliberately take over a type.
	public void Register(uint64 typeId, function ISerializable() factory)
	{
		let isNew = !mFactories.ContainsKey(typeId);
		mFactories[typeId] = factory;
		// Only a REAL insert is reported, so a module re-registering what it already owns
		// does not look to a recorder like a second acquisition it must later reverse.
		if (isNew && (mObserver != null))
			mObserver(typeId);
	}

	public bool IsRegistered(uint64 typeId) => mFactories.ContainsKey(typeId);

	public int Count => mFactories.Count;

	/// Constructs the type with this id, or null when no such type is registered. The
	/// caller owns what comes back.
	///
	/// Null is the ordinary answer for a payload written by a build that had a type this
	/// one does not, which is what framed regions exist to carry past.
	public ISerializable Create(uint64 typeId)
	{
		if (mFactories.TryGetValue(typeId, let factory))
			return factory();
		return null;
	}

	/// Forgets one type.
	///
	/// A factory is a FUNCTION POINTER, so one registered by a shared library outlives the
	/// library unless something removes it. The next Create for that id would then jump
	/// into unmapped memory, which is why a plugin host has to be able to take a
	/// registration back rather than only add one.
	public bool Unregister(uint64 typeId) => mFactories.Remove(typeId);

	/// The ids currently registered, appended to the list.
	///
	/// For a host that needs to know what a module added: snapshot before, snapshot after,
	/// and the difference is what that module owns.
	public void CopyIds(List<uint64> outIds)
	{
		for (let entry in mFactories)
			outIds.Add(entry.key);
	}

	/// Forgets everything. For tests, and for a host that tears a module back down.
	public void Clear() => mFactories.Clear();

	/// Watches registrations as they happen. ONE at a time, replacing any previous.
	///
	/// The plugin host's recording hook: it needs what a library added in order to reverse
	/// it before the library closes, and comparing snapshots cannot tell an id the plugin
	/// added from one that was already there. Owned here; pass null to stop watching.
	public void SetRegistrationObserver(delegate void(uint64) observer)
	{
		delete mObserver;
		mObserver = observer;
	}
}
