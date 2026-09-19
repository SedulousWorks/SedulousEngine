using System;
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

	/// The shell's own version plus every cook's, so a cook change recooks.
	public int32 Version => 1 + ScriptLanguageCooks.VersionSum;

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
		if (!cook.Cook(source, authored.FileName.Value, authored.ClassName, record, problems))
		{
			for (let p in problems)
				GlobalLog(.Error, "Cook: {}", p);
			return .Err(.InvalidArgument);
		}
		for (let p in problems)
			GlobalLog(.Warning, "Cook: {}", p);

		return context.Output.WriteObject(record);
	}
}
