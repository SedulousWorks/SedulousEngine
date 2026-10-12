using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Shaders.Resource;

/// An authored shader: a name, its per stage HLSL, and the entry point each stage's function
/// is called in its source.
///
/// Inline source rather than a path, because the resource system already owns finding and
/// versioning the bytes. A cooked bytecode variant can replace the strings later without
/// the name or the stage split changing.
[Serializable(2)]
class ShaderSource
{
	public String Name = new String() ~ delete _;
	public String VertexSource = new String() ~ delete _;
	public String FragmentSource = new String() ~ delete _;
	public String VertexEntryPoint = new String() ~ delete _;
	public String FragmentEntryPoint = new String() ~ delete _;
}
