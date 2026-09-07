using System;

namespace Sedulous.Shaders;

/// What a WGSL translation produced.
class WgslCookResult
{
	public bool Success = false;
	public WgslCookStage FailedStage = .Ok;
	/// The translated WGSL, on success.
	public String Wgsl = new String() ~ delete _;
	/// The tool's own diagnostic, on failure, so a shader that a browser would reject
	/// arrives with the reason rather than as a bare refusal.
	public String Error = new String() ~ delete _;
}
