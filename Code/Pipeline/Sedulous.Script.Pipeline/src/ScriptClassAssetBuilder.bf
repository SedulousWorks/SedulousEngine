using System;
using Sedulous.Script; // ScriptProblems
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// Cooks a script asset into its class record: reads the source, hands it to the cook for
/// its language, writes the record. A thin shell that never names a language.
class ScriptClassAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ScriptClassAsset);
	public Type ProductType => typeof(ScriptClassSource);

	/// The shell's own version (2: each property a replicated flag; 3: the record carries
	/// data version 1, so the reader refuses one from before the flag; 4: the class is the
	/// asset's choice, never a guess among several; 5: the record carries the included files;
	/// 6: the record names the assembly its class is built into; 7: the behavior kind) plus
	/// every cook's, so a cook change recooks.
	public int32 Version => 7 + ScriptLanguageCooks.VersionSum;

	/// The surface the scripts are checked against: a change (an engine whose facades changed)
	/// recooks them, so a script that no longer compiles is found at cook time, not at load.
	public uint64 EnvironmentHash => ScriptLanguageCooks.SurfaceHashSum;

	/// Every file the script includes, and every file those include: each a cook input, so
	/// editing an included file recooks the scripts that include it. A class built into its
	/// project's assembly reads the assembly instead: it cooks after the project, a rebuilt one
	/// recooks it, and it refers to the assembly at run time.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let authored = (ScriptClassAsset)asset;
		let cook = ScriptLanguageCooks.Find(authored.Language);
		if ((cook != null) && cook.BuildsInAssembly)
		{
			// A scan's context carries the source database as Database (a build's as SourceDatabase).
			let sourceDb = (context.SourceDatabase != null) ? context.SourceDatabase : context.Database;
			let project = ScriptAssemblies.FindFor(sourceDb, authored.Language, authored.FileName.Value);
			if (project != null)
			{
				outDeps.Reads.Add(project.Id);
				outDeps.References.Add(project.Id);
			}
			return;
		}
		let source = scope String();
		if ((cook == null) || (AssetSource.ReadText(context, authored.FileName.Value, source) case .Err))
			return; // Build says so
		let found = scope List<ScriptIncludedSource>();
		defer { ClearAndDeleteItems!(found); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		// One that cannot be read the cook reports; those found before it are still inputs.
		ScriptIncludes.Gather(cook, authored.FileName.Value, source, scope MountIncludeReader(context), found, problems);
		for (let included in found)
			outDeps.AddFile(included.Path);
	}

	/// Included files, read from the cook's sources mount.
	private class MountIncludeReader : IScriptIncludeReader
	{
		private AssetBuildContext mContext;

		public this(AssetBuildContext context)
		{
			mContext = context;
		}

		public bool Read(StringView path, String outText) => AssetSource.ReadText(mContext, path, outText) case .Ok;
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let authored = (ScriptClassAsset)asset;

		let cook = ScriptLanguageCooks.Find(authored.Language);
		if (cook == null)
		{
			GlobalLog(.Error, "Cook: no script cook for language '{}' ({})", authored.Language, authored.FileName.Value);
			return .Err(.NotSupported);
		}

		let source = scope String();
		if (AssetSource.ReadText(context, authored.FileName.Value, source) case .Err(let readError))
		{
			GlobalLog(.Error, "Cook: script source '{}' could not be read", authored.FileName.Value);
			return .Err(readError);
		}

		let record = scope ScriptClassSource();
		record.Language.Set(authored.Language);
		record.SourceName.Set(authored.FileName.Value);
		record.Source.Set(source);
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		if (cook.BuildsInAssembly)
		{
			if (CookFromProject(cook, authored, source, context, record, problems) case .Err(let projectError))
				return .Err(projectError);
		}
		else if (!cook.Cook(source, authored.FileName.Value, record, problems, scope MountIncludeReader(context)))
		{
			// A warning is not why it failed.
			for (let p in problems)
				GlobalLog(ScriptProblems.IsWarning(p) ? .Warning : .Error, "Cook: {}", p);
			return .Err(.InvalidArgument);
		}
		for (let p in problems)
			GlobalLog(.Warning, "Cook: {}", p);

		return context.Output.WriteObject(record);
	}

	/// A class of a language that builds per project: its description from the project's cooked
	/// assembly, which cooks first, and the record naming that assembly. Not found when no project
	/// holds the file or its project has not built.
	private static Result<void, ErrorCode> CookFromProject(IScriptLanguageCook cook, ScriptClassAsset authored, StringView source,
		AssetBuildContext context, ScriptClassSource record, List<String> problems)
	{
		let file = authored.FileName.Value;
		let project = ScriptAssemblies.FindFor(context.SourceDatabase, authored.Language, file);
		if (project == null)
		{
			GlobalLog(.Error, "Cook: '{}': no {} project holds it (a project file in its folder or one above)", file, authored.Language);
			return .Err(.NotFound);
		}
		let built = (context.Database != null) ? context.Database.GetInstance(project.Id) : null;
		let stored = (built != null) ? built.ReadObject() : null;
		defer { if (stored != null) delete stored; }
		let assembly = stored as ScriptAssemblySource;
		if (assembly == null)
		{
			GlobalLog(.Error, "Cook: '{}': its project '{}' has not built", file, project.GetPath(.. scope .()));
			return .Err(.NotFound);
		}
		if (!cook.CookFromAssembly(source, file, assembly, record, problems))
		{
			for (let p in problems)
				GlobalLog(ScriptProblems.IsWarning(p) ? .Warning : .Error, "Cook: {}", p);
			return .Err(.InvalidArgument);
		}
		record.Assembly = project.Id;
		return .Ok;
	}
}
