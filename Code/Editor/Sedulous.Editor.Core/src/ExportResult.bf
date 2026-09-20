using System;

namespace Sedulous.Editor.Core;

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
}
