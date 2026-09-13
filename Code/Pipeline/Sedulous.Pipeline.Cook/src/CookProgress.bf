using System;

namespace Sedulous.Pipeline.Cook;

/// Where a cook reports each finished item.
class CookProgress
{
	/// Called with how many are done, how many there are, the source's path, and whether it
	/// succeeded. BORROWED: the caller owns the delegate.
	public delegate void(int done, int total, StringView sourcePath, bool ok) OnItem = null;
}
