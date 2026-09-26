using System;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// A step of an operation: finished with its outcome filled, not finished yet, or failed or
/// refused with the text the agent reads.
enum OperationStep
{
	Finished,
	NotYet,
	Failed
}

/// What asset_cook reports: the plan's split and the build's counts.
struct CookOutcome
{
	public int Planned = 0;
	public int Cooked = 0;
	public int Failed = 0;
	public int OrphansSwept = 0;
	public int UpToDate = 0;
	public int Unbuildable = 0;
}

/// asset_import's resolved request: the importer is routed by the tool (by extension and
/// hint), the group path is the agent's (slash joined; empty is the root). Borrowed views,
/// valid for the call.
struct ImportRequest
{
	public StringView Source = default;
	public StringView GroupPath = default;
	public IFileImporter Importer = null;
}

/// What asset_import reports: the created asset's identity.
class ImportOutcome
{
	public Guid Id;
	public String Name = new .() ~ delete _;
	public String Type = new .() ~ delete _;
}

/// project_export's resolved request: the preset the tool resolved by name, the output root,
/// and whether to re-cook everything first. Borrowed, valid for the call.
struct ExportRequest
{
	public ExportPreset Preset = null;
	public StringView OutRoot = default;
	public bool Rebuild = false;
}

/// How a HOST runs the work behind asset_cook, asset_import and project_export.
///
/// The tools themselves are shared: their arguments, refusals and result shapes are the same
/// on every host. WHERE the work runs is the host's: the stdio host runs it inline on the
/// calling thread (every step answers at once), the editor on its own background services
/// (the cook service, the job service) with the tool re-entered each pump until they finish,
/// so the editor never blocks on an agent's call.
///
/// Every operation is IDEMPOTENT ACROSS RE-ENTRIES: a tool that is not finished is called
/// again with the same arguments on the host's next pump, so the first call with a request
/// starts the work and later calls with the same request poll it. An implementation keeps
/// that state itself, and one operation of each kind is in flight at a time (the tool is one
/// call).
interface IProjectOperations
{
	/// The incremental cook over the open project (force rebuilds all).
	OperationStep Cook(bool force, ref CookOutcome outOutcome, String outError);
	/// One OS file into the open project's source database (does not cook).
	OperationStep Import(ImportRequest request, ImportOutcome outOutcome, String outError);
	/// A shippable dist of the open project through the one export entry point.
	OperationStep Export(ExportRequest request, ExportResult outResult, String outError);
}
