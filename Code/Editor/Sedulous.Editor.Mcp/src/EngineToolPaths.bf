using System;
using Sedulous.Core;
using Sedulous.Core.IO;

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

	/// Fills KnownIssues and ShippingDocsDir, walking UP from each start directory in turn (a
	/// host passes its executable's directory, then its working directory) and checking the
	/// distribution layout first (KnownIssues.md staged beside the executable) and the engine
	/// checkout second (Documentation/Shipping). The first hit wins per field; a field left
	/// empty means not found: known_issues then fails with guidance and no docs:// resources
	/// register. The same walk for both hosts, so they agree.
	public void LocateShippingDocs(Span<StringView> starts)
	{
		for (let start in starts)
		{
			let dir = scope String(start);
			while (!dir.IsEmpty)
			{
				if (KnownIssues.IsEmpty)
				{
					let staged = PathJoin(dir, "KnownIssues.md", .. scope .());
					if (FileExists(staged))
						KnownIssues.Set(staged);
				}
				let shipping = PathJoin(dir, "Documentation/Shipping", .. scope .());
				if (DirectoryExists(shipping))
				{
					if (ShippingDocsDir.IsEmpty)
						ShippingDocsDir.Set(shipping);
					if (KnownIssues.IsEmpty)
					{
						let checkout = PathJoin(shipping, "KnownIssues.md", .. scope .());
						if (FileExists(checkout))
							KnownIssues.Set(checkout);
					}
				}
				if (!KnownIssues.IsEmpty && !ShippingDocsDir.IsEmpty)
					return;
				dir.Set(PathParent(dir, .. scope .()));
			}
		}
	}
}
