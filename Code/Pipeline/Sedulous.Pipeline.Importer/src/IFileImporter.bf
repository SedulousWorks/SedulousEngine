using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;

namespace Sedulous.Pipeline.Importer;

/// Turns one OS file into a source under the project's sources tree plus the typed asset
/// instances that point at it.
///
/// Implementations live with their asset modules and the executable registers them; routing is
/// by lowercase extension. Several importers may claim one extension, and the registry exposes
/// every match so a caller can offer a chooser.
interface IFileImporter
{
	/// Shown in menus and choosers.
	StringView Label { get; }

	/// Does this importer claim the extension? Lowercase, and without the dot.
	bool Accepts(StringView @extension);

	/// Fresh options for one import, with their defaults set, or NULL when this importer has
	/// none and the import should run immediately on the drop with no dialog. THE CALLER OWNS
	/// what comes back.
	ImportOptions CreateOptions() => null;

	/// Whether the slow half of this import can run OFF the interface thread.
	///
	/// A slow importer splits in two: PrepareOnWorker does the pure parse and decode of the
	/// source file, touching no project and no database, and its payload is then handed to
	/// Import on the main thread for the fast database fan out.
	bool WantsWorkerPrepare => false;

	/// The worker half. THE CALLER OWNS what comes back, and hands it straight to Import.
	Object PrepareOnWorker(StringView sourcePath) => null;

	/// Everything Import would create, WITHOUT touching the project or the database, which is
	/// what the review dialog renders.
	///
	/// `prepared` is the worker payload when the two phase path ran, and an importer that
	/// supports both should reuse it rather than parse the file again. Leaving the plan empty
	/// means no per resource review.
	void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan)
	{
	}

	/// Re-import memory: the selection a PREVIOUS import of this source stored in the target
	/// group, left empty when there is none or the importer does not support it.
	///
	/// The caller merges it onto the fresh plan, so re-importing does not re-ask decisions that
	/// were already settled.
	void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
	{
	}

	/// Imports the file at an absolute path: copies the source under the sources tree and
	/// creates the typed asset instances in the group. Returns the PRIMARY instance created,
	/// which the database owns.
	///
	/// `options` is what CreateOptions returned after the user edited it, or null when this
	/// importer has none or the import is headless. `prepared` is the worker payload when the
	/// two phase path ran.
	///
	/// `deferredWrites`, when given, is where the importer MAY park its bulk writes instead of
	/// writing inline, for the caller to flush on a worker. Null means everything writes
	/// inline, which is what a headless run and a test want.
	Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
		ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites);
}
