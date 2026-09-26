using System;

namespace Sedulous.Editor.Mcp;

/// The paths the shared surface needs that only a host can discover, each host its own way:
/// the stdio host walks up from its executable, and the editor knows its data root.
class EngineToolPaths
{
	/// The curated KnownIssues.md. Empty leaves known_issues failing with guidance.
	public String KnownIssues = new .() ~ delete _;
	/// The curated shipping docs directory, served as docs://<name>. Empty registers none.
	public String ShippingDocsDir = new .() ~ delete _;
	/// Where the player and its runtime sidecars live, for project_export.
	public String PlayerDir = new .() ~ delete _;
	/// The engine data root, whose Shaders the export cooks.
	public String DataRoot = new .() ~ delete _;
}
