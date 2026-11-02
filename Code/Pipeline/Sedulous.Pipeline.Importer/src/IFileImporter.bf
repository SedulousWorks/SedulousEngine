using System;
using System.Collections;
using System.Reflection;
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

	/// What one of the options' settings will do to this file ("Cuts 0.19 s from the end"), into
	/// `outEffect`, or why it cannot apply to it ("It is mono already"), into `outReason`, which shows
	/// the setting disabled. `prepared` is PrepareOnWorker's payload when the two phase path ran
	/// (null: nothing read, nothing to say). Default: nothing to say.
	void DescribeSetting(StringView sourcePath, ImportOptions options, Object prepared, FieldInfo setting,
		String outEffect, String outReason)
	{
	}

	/// Sets `options` (CreateOptions') as this importer would choose them for the file at
	/// `sourcePath`, before anyone sees them: a texture's usage guessed from its name, say. Reads
	/// at most a file's header. Default: the options' own defaults stand.
	void InitializeOptions(StringView sourcePath, ImportOptions options)
	{
	}

	/// The asset type a SINGLE-ASSET importer makes of `sourcePath`, for the name clash check before
	/// an import; empty for an importer that makes several (a model's), which keeps its own names
	/// apart.
	StringView AssetTypeName(StringView sourcePath) => default;

	/// The asset type that stands for `sourcePath` where the file is listed (its icon in the import
	/// window): the one asset a single-asset importer makes, else the one the others hang from (a
	/// model's manifest).
	StringView ListedTypeName(StringView sourcePath) => AssetTypeName(sourcePath);

	/// The clash an import of `sourcePath` would meet in `group` under the names `plan` gives (null:
	/// the file's own): what the editor's window shows on the file's row, and what an agent's import
	/// is refused with. Default: a single asset (AssetTypeName) under its Asset entry's target, else
	/// the file's stem; none when AssetTypeName is empty. An importer that makes several says what
	/// it claims (a model, its folder).
	void FindClash(Group group, StringView sourcePath, ImportPlan plan, StringView ledgerPath, ImportClash outClash)
	{
		outClash.Clear();
		let typeName = AssetTypeName(sourcePath);
		if (!typeName.IsEmpty)
			ImportPaths.SingleAssetClash(group, sourcePath, typeName, plan, ledgerPath, outClash);
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
