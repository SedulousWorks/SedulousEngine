using System;

namespace Sedulous.Editor.Project;

/// What one export produced.
class ExportResult
{
	public ExportStats Content = new .() ~ delete _;
	/// The player, the template's sidecars and the preset's additional files copied.
	public int FilesStaged = 0;
	public String OutputDir = new .() ~ delete _;
	/// Set when the resolved template was built against another engine version.
	public String EngineVersionWarning = new .() ~ delete _;
	public PruningReport Pruning = new .() ~ delete _;
	/// Which player the dist runs (the template's or the project's own) and why.
	public String PlayerReason = new .() ~ delete _;
	/// Why the export stopped short (the project's plugins, a failing export hook); empty when it
	/// did not.
	public String Refusal = new .() ~ delete _;

	public void CopyTo(ExportResult other)
	{
		other.PlayerReason.Set(PlayerReason);
		other.Refusal.Set(Refusal);
		Content.CopyTo(other.Content);
		other.FilesStaged = FilesStaged;
		other.OutputDir.Set(OutputDir);
		other.EngineVersionWarning.Set(EngineVersionWarning);
		Pruning.CopyTo(other.Pruning);
	}
}
