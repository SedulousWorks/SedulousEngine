using System;

namespace Sedulous.Resource.Tests;

/// A product whose destructor reaches back into the manager, the way a dying composite
/// does when it drops its child proxies.
class ReentrantProduct
{
	/// Set for the window in which re-entry is wanted, so building the fixture does not
	/// trigger it.
	public static ResourceManager Manager;
	public static int Destroyed;

	public int32 Area;

	public ~this()
	{
		Destroyed++;
		// Reads the manager while it is in the middle of a collection, which is what makes
		// mutating the list under the walk a use after free.
		if (Manager != null)
		{
			let rows = scope System.Collections.List<LiveProductRow>();
			Manager.ReportLiveProducts(rows);
		}
	}
}
