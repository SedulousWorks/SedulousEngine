using System;
using System.Collections;

namespace Sedulous.Pipeline.Cook;

/// What a cook is about to do.
class CookPlan
{
	/// In dependency order, so a read cooks before whatever consumes it.
	public List<CookItem> Dirty = new .() ~ DeleteContainerAndItems!(_);

	/// Records whose source is gone, and whose products are swept.
	public List<Guid> Orphans = new .() ~ delete _;
	public int OrphansSweptCount = 0;

	public int UpToDate = 0;

	/// Instances with no registered builder, which is information rather than a problem: a
	/// project holds plenty of things nothing cooks.
	public int Unbuildable = 0;

	/// A SCOPED plan only: the roots and their whole dependency closure, every visited
	/// identity whether clean or dirty and whether buildable or not.
	///
	/// That set is what an export prunes against, so it has to include what was already clean.
	/// A whole project plan leaves it empty.
	public List<Guid> Reachable = new .() ~ delete _;
}
