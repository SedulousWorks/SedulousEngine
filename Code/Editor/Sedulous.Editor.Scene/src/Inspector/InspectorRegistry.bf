using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// The types the inspector can show, each with the rows generated for it. A component or
/// settings type not registered here shows a notice instead of rows, so registering is how
/// a module opts its types into the inspector.
static class InspectorRegistry
{
	private static Dictionary<Type, InspectorEntry> sEntries = new .() ~ DeleteDictionaryAndValues!(_);

	public static int Count => sEntries.Count;

	/// Registers T with its generated rows; registering twice is harmless.
	public static void Register<T>()
	{
		let type = typeof(T);
		if (sEntries.ContainsKey(type))
			return;
		let entry = new InspectorEntry();
		entry.Build = new (section) => { InspectorRows<T>.Build(section); };
		InspectorRows<T>.Meta(entry.DisplayName, entry.Category);
		sEntries[type] = entry;
	}

	public static InspectorEntry Find(Type type)
	{
		if ((type != null) && sEntries.TryGetValue(type, let entry))
			return entry;
		return null;
	}

	public static bool IsRegistered(Type type) => Find(type) != null;

	/// For a test that registers its own fixtures and wants a clean slate.
	public static void Clear() => DeleteDictionaryAndValues!(sEntries);
}
