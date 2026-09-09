using System;
using System.Collections;

namespace Sedulous.UI;

/// Maps short names to view types.
///
/// The style sheet parser resolves element selectors through this, and the markup loader
/// resolves element names. A control registers itself with
/// `UITypeRegistry.Register("MyControl", typeof(MyControl))`.
///
/// DIVERGES from Raptor in having no RegisterBuiltins. Its body reaches every control class,
/// so it belongs with the controls rather than here; until those are ported, callers register
/// what they need.
static class UITypeRegistry
{
	private static Dictionary<String, Type> sTypes = new .() ~ DeleteDictionaryAndKeys!(_);

	/// Registers a type under a name, replacing any previous registration.
	public static void Register(StringView name, Type type)
	{
		if (sTypes.TryGetAlt(name, let existingKey, ?))
		{
			sTypes[existingKey] = type;
			return;
		}
		sTypes[new String(name)] = type;
	}

	/// The type registered under a name, or null.
	public static Type Resolve(StringView name)
	{
		if (sTypes.TryGetValueAlt(name, let type))
			return type;
		return null;
	}

	public static int Count => sTypes.Count;

	/// Forgets every registration. For tests, which must not leak state into one another.
	public static void Clear()
	{
		for (let key in sTypes.Keys)
			delete key;
		sTypes.Clear();
	}
}
