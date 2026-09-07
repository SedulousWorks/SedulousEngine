using System;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Resource;

/// The runtime handle for a shader: its name, and the system its variants live in.
///
/// It holds NO variants of its own. Those belong to the shared shader system, which is what
/// lets two materials referring to the same shader share compiled modules rather than each
/// compiling their own.
class ShaderResource
{
	private ShaderSystem mSystem = null;
	private String mName = new String() ~ delete _;

	/// The system is BORROWED and must outlive this.
	public void Initialize(ShaderSystem system, StringView name)
	{
		mSystem = system;
		mName.Set(name);
	}

	public StringView Name => mName;

	/// The reload signal, bumped whenever the shader is rebuilt.
	///
	/// A pipeline cache stamps its pipelines with this and rebuilds when it moves, which is
	/// how an edit to a shader reaches a pipeline that was built from it.
	public uint64 Version => (mSystem != null) ? mSystem.Version(mName) : 0;

	public Sedulous.RHI.IShaderModule GetVariant(ShaderStage stage, ShaderFlags flags)
	{
		if (mSystem == null)
			return null;
		return mSystem.GetVariant(mName, stage, flags);
	}
}
