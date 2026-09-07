using System;
using System.Collections;

namespace Sedulous.Shaders;

/// What a corpus cook did, and everything that went wrong.
///
/// Errors accumulate rather than stopping the cook, so one broken shader does not hide the
/// rest. Success means the list is empty; a partially filled pack is left behind either way
/// and the caller decides whether to ship it, which a shipped build should not.
class ShaderCookReport
{
	public bool Success = false;
	/// Stage files processed.
	public int FilesCooked = 0;
	/// Variant and format pairs emitted.
	public int VariantsCooked = 0;
	/// Lint and compile diagnostics, one line each.
	public List<String> Errors = new List<String>() ~ DeleteContainerAndItems!(_);

	public void AddError(StringView file, StringView message)
	{
		let error = new String();
		error.AppendF("{}: {}", file, message);
		Errors.Add(error);
	}
}
