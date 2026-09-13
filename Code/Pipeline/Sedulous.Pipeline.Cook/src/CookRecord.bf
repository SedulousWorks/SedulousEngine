using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Cook;

/// One source asset's last cook.
[Serializable]
class CookRecord
{
	public Guid Source = .Empty;
	public uint64 RecipeHash = 0;

	/// A FAILED record never satisfies a clean check, so a broken asset is retried on every
	/// cook rather than being remembered as done.
	public bool Failed = false;

	public List<CookFileMemo> Files = new .() ~ DeleteContainerAndItems!(_);
	public List<Guid> Reads = new .() ~ delete _;
	public List<Guid> References = new .() ~ delete _;
}
