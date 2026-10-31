using System;
using System.Collections;

namespace Sedulous.Shaders;

/// The PULL seam for shader source.
///
/// Instead of every pass pushing strings in, the shader system asks a provider when it
/// misses. In development that is files under the shader root, so an edit hot reloads with
/// no rebuild; in a shipped build it is a cooked pack. An explicit RegisterSource still
/// wins, so a module with a bespoke inline shader keeps working unchanged.
interface IShaderSourceProvider
{
	/// The HLSL for a name and stage, and the entry point that stage's function is called in
	/// it; false when this provider has no such shader.
	bool FetchSource(StringView name, ShaderStage stage, String outSource, String outEntryPoint);

	/// Every shader name this can serve, for tooling.
	void CollectShaderNames(List<String> outNames);

	/// Every shared include (.hlsli) this serves, as an include names it ("wind.hlsli",
	/// "surface/forward.hlsli"), appended as owned strings. The shader system reads them through
	/// its include resolver for the effect blocks they declare.
	void CollectIncludeNames(List<String> outNames);

	/// Appends the names whose source changed since the last poll, returning whether any
	/// did.
	///
	/// Called once per frame, so an implementation THROTTLES rather than sweeping every
	/// time: the caller has no way to know how expensive the check is.
	bool PollChanges(List<String> outChangedNames);
}
