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
	/// 6: the record names the assembly its class is built into) plus every cook's, so a cook
	/// change recooks.
	public int32 Version => 6 + ScriptLanguageCooks.VersionSum;

	/// The surface the scripts are checked against: a change (an engine whose facades changed)
	/// recooks them, so a script that no longer compiles is found at cook time, not at load.
	public uint64 EnvironmentHash => ScriptLanguageCooks.SurfaceHashSum;

	/// Every file the script includes, and every file those include: each a cook input, so
	/// editing an included file recooks the scripts that include it.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let authored = (ScriptClassAsset)asset;
		let cook = ScriptLanguageCooks.Find(authored.Language);
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
		let preferred = ScriptClasses.Preferred(authored, .. scope .());
		if (!cook.Cook(source, authored.FileName.Value, preferred, record, problems, scope MountIncludeReader(context)))
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
}
