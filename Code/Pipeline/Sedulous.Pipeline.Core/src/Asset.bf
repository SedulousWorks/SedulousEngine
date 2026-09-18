using Sedulous.Core;
using System;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Core;

/// The SOURCE side of an asset: it names an external source file, and a concrete asset adds
/// whatever import settings it has.
///
/// Asset is authoring, Resource is runtime. The player links none of this: it loads cooked
/// products and never an authoring asset.
///
/// NOT serializable on its own, and deliberately. A concrete asset carries [Serializable],
/// which walks the whole base chain, so the file name below is stored without this class
/// declaring anything about it. A hand written body here would be a second description of the
/// same field, and the two would drift.
class Asset
{
	/// The source file, relative to the sources mount, or empty when the data is embedded.
	///
	/// TYPED rather than a string, because normalisation guarantees the forward slash relative
	/// form in cooked data: a Windows authored backslash heals on load instead of breaking
	/// the mount for everybody else.
	[DisplayName("Source File")]
	public SourcePath FileName = new .() ~ delete _;
}
