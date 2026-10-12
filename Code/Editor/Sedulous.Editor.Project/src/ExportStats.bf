using System;
using System.Collections;

namespace Sedulous.Editor.Project;

/// The cook, stage and pack totals of one export.
class ExportStats
{
	public int Cooked = 0;
	public int CookFailed = 0;
	public int ScenesStaged = 0;
	public int FilesPacked = 0;
	/// The project's custom shaders the dist ships (their cooked ShaderSource products): the
	/// shader pack step cooks each into the dist's pack, as bytecode.
	public List<Guid> Shaders = new .() ~ delete _;

	public void CopyTo(ExportStats other)
	{
		other.Cooked = Cooked;
		other.CookFailed = CookFailed;
		other.ScenesStaged = ScenesStaged;
		other.FilesPacked = FilesPacked;
		other.Shaders.Clear();
		other.Shaders.AddRange(Shaders);
	}
}
