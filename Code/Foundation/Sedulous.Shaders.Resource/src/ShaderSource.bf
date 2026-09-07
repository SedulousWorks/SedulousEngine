using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Shaders.Resource;

/// An authored shader: a name and its per stage HLSL.
///
/// Inline source rather than a path, because the resource system already owns finding and
/// versioning the bytes. A cooked bytecode variant can replace the strings later without
/// the name or the stage split changing.
[Serializable(1)]
class ShaderSource
{
	public String Name = new String() ~ delete _;
	public String VertexSource = new String() ~ delete _;
	public String FragmentSource = new String() ~ delete _;
}
