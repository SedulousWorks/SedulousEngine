using System;

namespace Sedulous.Pipeline.Importer;

/// Everything an import needs to know about WHERE it lands.
///
/// Deliberately not the editor's project object: the pipeline is drivable headless, from a
/// command line, from the tool protocol and from a test, so the caller supplies the facts imports
/// consume and keeps its project model to itself.
class ImportContext
{
	/// The absolute path of the project's sources tree.
	public String SourcesRoot = new .() ~ delete _;

	/// What the import does when the name it would take is held by an asset of its own type that
	/// ANOTHER file made. Refused unless the caller says: the editor asks the user and passes the
	/// answer.
	public ImportConflictChoice OnConflict = .Refuse;

	/// The import ledger (ImportPaths.ImportLedgerPath, under the project's ignored cache): which OS
	/// file each file under the sources tree came from, so a re-import of the same file is told from
	/// another file of the same name. Empty: none is kept, and a file name alone decides.
	public String LedgerPath = new .() ~ delete _;

	public this(StringView sourcesRoot)
	{
		SourcesRoot.Set(sourcesRoot);
	}
}
