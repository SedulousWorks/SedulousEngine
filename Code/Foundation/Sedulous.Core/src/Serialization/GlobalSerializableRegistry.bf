namespace Sedulous.Core.Serialization;

/// The process wide registry, which is what everything defaults to.
///
/// A global because the ordinary case is one table for the whole program, populated at
/// startup by each module registering what it declares. The injectable parameter beside
/// it is for the cases that are NOT ordinary: two databases with different registrations,
/// or a test that wants a table with nothing else in it.
static
{
	private static SerializableRegistry sGlobal = new .() ~ delete _;

	public static SerializableRegistry GlobalSerializableRegistry => sGlobal;
}
