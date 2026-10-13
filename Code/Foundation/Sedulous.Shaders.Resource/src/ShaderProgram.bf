using System;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Resource;

/// One program of a shader: what the shader system registers under one name. The views are into
/// the ShaderSource it came from.
class ShaderProgram
{
	/// The shader's name plus the program's suffix ("lava", "lava.depth").
	public String Name = new .() ~ delete _;
	public StringView VertexSource;
	public StringView FragmentSource;
	public StringView VertexEntryPoint;
	public StringView FragmentEntryPoint;
	public ShaderFlags VertexVariantMask = .None;
	public ShaderFlags FragmentVariantMask = .None;
}
