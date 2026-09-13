using System;

namespace Sedulous.Pipeline.Importer;

/// Everything an import needs to know about WHERE it lands.
///
/// Deliberately not the editor's project object: the pipeline is drivable headless, from a
/// command line, from the tool protocol and from a test, so the caller supplies the one fact
/// imports consume and keeps its project model to itself.
class ImportContext
{
	/// The absolute path of the project's sources tree.
	public String SourcesRoot = new .() ~ delete _;

	public this(StringView sourcesRoot)
	{
		SourcesRoot.Set(sourcesRoot);
	}
}
