using System;
using System.Collections;

namespace Sedulous.Runtime;

/// The plugin parts compiled into this binary. Each part's type is [AlwaysInclude] and registers
/// an instance of itself here from its static constructor, so a binary's registry is exactly the
/// parts it links: a host takes its role's parts by project dependency, and nothing lists them
/// by hand.
///
/// Static constructors run in an order nothing here controls, so nothing may depend on it: the
/// list is made by the first registration (a field initializer would run in this class's own
/// static constructor, which may come after a part's and reset the list), and the plugin host
/// sorts what registered before it enables anything.
static class PluginRegistry
{
	private static List<PluginPart> sParts ~ DeleteContainerAndItems!(_);

	/// Called from a part's static constructor. TAKES OWNERSHIP of `part`.
	public static void Register(PluginPart part)
	{
		if (part == null)
			return;
		if (sParts == null)
			sParts = new .();
		sParts.Add(part);
	}

	/// The parts registered, in no meaningful order. BORROWED.
	public static Span<PluginPart> Parts => (sParts != null) ? (Span<PluginPart>)sParts : .();
}
