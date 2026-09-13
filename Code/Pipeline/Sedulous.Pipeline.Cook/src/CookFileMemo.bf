using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Cook;

/// One source file's content hash, and the stat that says the hash is still good.
///
/// The memo is what keeps a plan cheap: hashing every source file of a large project on every
/// plan would cost more than the cook. A file whose size and time have not moved keeps its
/// hash unread.
[Serializable]
class CookFileMemo
{
	/// Relative to the sources mount.
	public String Path = new .() ~ delete _;
	public int64 Size = 0;
	public int64 ModifiedTicks = 0;
	public uint64 ContentHash = 0;
}
