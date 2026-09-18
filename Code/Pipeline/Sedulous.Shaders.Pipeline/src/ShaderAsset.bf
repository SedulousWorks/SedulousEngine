using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Shaders.Pipeline;

/// A shader: its logical name and its two source files.
///
/// The VERTEX source is the file name a plain asset carries; the fragment one sits beside it.
/// Both are mount relative at cook time.
[Category("Rendering")]
[Serializable]
class ShaderAsset : Asset
{
	/// How a material refers to this shader.
	public String Name = new .() ~ delete _;

	/// The fragment stage's source file.
	public String FragmentFile = new .() ~ delete _;
}
