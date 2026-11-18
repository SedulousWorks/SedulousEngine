using System;
using Sedulous.Core.IO;
using Sedulous.VFS;

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

	/// The absolute path of the project's Code/ folder, which a source name starting Code/ names
	/// (SourcePath.CodeFolder). Empty: such a name is a folder under the sources tree.
	public String CodeRoot = new .() ~ delete _;

	/// The folder under the sources this import's copies go in: its asset group's folder (a
	/// model's own group, Models/Crate), under Code/ for code. Empty: the sources' root.
	public String Folder = new .() ~ delete _;

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

	/// Takes every setting of `other`: a copy an import narrows (its own folder) without
	/// touching the caller's.
	public void CopyFrom(ImportContext other)
	{
		SourcesRoot.Set(other.SourcesRoot);
		CodeRoot.Set(other.CodeRoot);
		Folder.Set(other.Folder);
		OnConflict = other.OnConflict;
		LedgerPath.Set(other.LedgerPath);
	}

	/// The file on disk a name under the sources (an asset's file name) is, into `outPath`.
	public void FileOf(StringView sourcesName, String outPath) => SourcePath.FileOnDisk(SourcesRoot, CodeRoot, sourcesName, outPath);

	/// `file` (a name relative to the import, a .gltf's sidecar uri) as a name under the sources,
	/// in the import's folder, into `outName`.
	public void InFolder(StringView file, String outName)
	{
		if (Folder.IsEmpty)
			outName.Set(file);
		else
			PathJoin(Folder, file, outName);
	}
}
