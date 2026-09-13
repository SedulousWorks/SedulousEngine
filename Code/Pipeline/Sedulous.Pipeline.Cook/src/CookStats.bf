using System;
using System.Collections;

namespace Sedulous.Pipeline.Cook;

/// What a cook did.
class CookStats
{
	public int Cooked = 0;
	public int Failed = 0;
	/// Invariant products carried over from the host database during a variant cook.
	public int CopiedForward = 0;
	public int OrphansSwept = 0;

	/// Everything rebuilt OR carried forward, which is what a hot reload consumes.
	public List<Guid> CookedProducts = new .() ~ delete _;
}
