using System;

namespace Sedulous.Editor.Core;

/// One seed entry point of the reachable closure.
class ExportRoot
{
	public Guid Id;
	/// The instance's source path, for the report; empty when unresolved.
	public String Name = new .() ~ delete _;
	public ExportRootReason Reason = .DefaultScene;

	public ExportRoot Clone()
	{
		let copy = new ExportRoot();
		copy.Id = Id;
		copy.Name.Set(Name);
		copy.Reason = Reason;
		return copy;
	}
}
