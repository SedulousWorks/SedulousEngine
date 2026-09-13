using System;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Core;

/// The SOURCE side of an asset: a serializable that names an external source file, plus
/// whatever import settings a concrete asset adds.
///
/// Asset is authoring, Resource is runtime. The player links none of this: it loads cooked
/// products and never an authoring asset. A concrete asset derives this, adds its settings,
/// and calls the base Serialize for the file name.
class Asset : ISerializable
{
	/// The source file, relative to the sources mount, or empty when the data is embedded.
	///
	/// TYPED rather than a string, because normalisation guarantees the forward slash relative
	/// form in cooked data: a Windows authored backslash heals on load instead of breaking
	/// the mount for everybody else.
	public SourcePath FileName = new .() ~ delete _;

	public virtual void Serialize(ISerializer ar)
	{
		ar.Key("fileName");
		FileName.Serialize(ar);
	}
}
