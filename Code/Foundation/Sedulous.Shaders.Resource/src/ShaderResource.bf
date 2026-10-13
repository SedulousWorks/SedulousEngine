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
	private String mDepthName = new String() ~ delete _;
	private String mPickName = new String() ~ delete _;
	private bool mDepthProgramsAlways = false;

	/// The system is BORROWED and must outlive this.
	public void Initialize(ShaderSystem system, StringView name)
	{
		mSystem = system;
		mName.Set(name);
	}

	public StringView Name => mName;

	/// Records the shader's own depth like programs (a ShaderSource's .depth and .pick), and
	/// whether they replace the built-ins for every material or only for a masked one.
	public void SetDepthPrograms(bool depth, bool pick, bool always)
	{
		mDepthName.Clear();
		mPickName.Clear();
		if (depth)
			mDepthName..Set(mName).Append(ShaderSource.cDepthProgramSuffix);
		if (pick)
			mPickName..Set(mName).Append(ShaderSource.cPickProgramSuffix);
		mDepthProgramsAlways = always;
	}

	/// The program a material on this shader draws the depth prepass and shadows with: the
	/// shader's own when it has one and needs it (it moves its vertices, or the material is
	/// masked and cuts out with the shader's alpha); empty is the built-in.
	public StringView DepthProgram(bool masked) => (mDepthProgramsAlways || masked) ? StringView(mDepthName) : StringView();

	/// The program its pick draws with, chosen as DepthProgram is.
	public StringView PickProgram(bool masked) => (mDepthProgramsAlways || masked) ? StringView(mPickName) : StringView();

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
