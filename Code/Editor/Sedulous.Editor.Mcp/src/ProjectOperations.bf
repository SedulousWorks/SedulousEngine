using System;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Project;
using Sedulous.Mcp;

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
	/// The importer's options, its defaults with the call's toggles applied; null when the
	/// importer has none. BORROWED.
	public ImportOptions Options = null;
}

/// What asset_import reports: the created asset's identity and where the time went (the
/// main thread share is the number that must stay small in the editor).
class ImportOutcome
{
	public Guid Id;
	public String Name = new .() ~ delete _;
	/// The content type's full name, and the namespace part of it.
	public String Type = new .() ~ delete _;
	public String TypeNamespace = new .() ~ delete _;
	public int DeferredWrites = 0;
	public int64 PrepareMs = 0;
	public int64 MainMs = 0;
	public int64 FlushMs = 0;

	/// The identity from the instance an import placed.
	public void SetIdentity(Sedulous.Content.Instance instance)
	{
		Id = instance.Id;
		Name.Set(instance.Name);
		Type.Set(instance.TypeName);
		let dot = instance.TypeName.LastIndexOf('.');
		TypeNamespace.Set((dot > 0) ? StringView(instance.TypeName, 0, dot) : "");
	}

	public void CopyTo(ImportOutcome other)
	{
		other.Id = Id;
		other.Name.Set(Name);
		other.Type.Set(Type);
		other.TypeNamespace.Set(TypeNamespace);
		other.DeferredWrites = DeferredWrites;
		other.PrepareMs = PrepareMs;
		other.MainMs = MainMs;
		other.FlushMs = FlushMs;
	}
}

/// asset_create's resolved request: the creator the tool found, the group path (created when
/// missing; empty is the creator's own folder) and the exact name (empty is the creator's own,
/// made unique). Borrowed, valid for the call.
struct CreateRequest
{
	public AssetCreator Creator = null;
	public StringView GroupPath = default;
	public StringView Name = default;
}

/// What asset_create reports: the new asset's identity and where it landed.
class CreateOutcome
{
	public Guid Id;
	public String Name = new .() ~ delete _;
	public String Type = new .() ~ delete _;
	public String Path = new .() ~ delete _;

	public void SetFrom(Instance instance)
	{
		Id = instance.Id;
		Name.Set(instance.Name);
		Type.Set(instance.TypeName);
		instance.GetPath(Path..Clear());
	}
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
/// again with the same arguments on the host's next pump, so the first entry of a call starts
/// the work and later entries poll it. An implementation keeps that progress in the call's
/// State (it is the operation's, not the tool's), so two calls in flight at once, identical
/// or not, are two operations; the state's destructor cleans up after a call whose caller
/// left.
interface IProjectOperations
{
	/// The incremental cook over the open project (force rebuilds all).
	OperationStep Cook(ToolCall call, bool force, ref CookOutcome outOutcome, String outError);
	/// One OS file into the open project's source database (does not cook).
	OperationStep Import(ToolCall call, ImportRequest request, ImportOutcome outOutcome, String outError);
	/// One new asset from a creator (AssetCreation.Run), and whatever the host does after a
	/// creation: the editor's cook request and default scene; nothing on the stdio host, whose
	/// agent cooks next.
	OperationStep Create(ToolCall call, CreateRequest request, CreateOutcome outOutcome, String outError);
	/// A shippable dist of the open project through the one export entry point.
	OperationStep Export(ToolCall call, ExportRequest request, ExportResult outResult, String outError);
}
