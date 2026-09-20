using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Script;

/// A new script class from the language cook's starter for a tier: the source file under
/// the sources root, and the asset pointing at it, in the browser group or the root.
static class ScriptAssetCreators
{
	public static Instance CreateScriptInstance(EditorContext context, Group group, StringView languageId, StringView fileSuffix, ScriptTier tier, StringView baseName)
	{
		let project = context.Project;
		if (project == null)
			return null;
		let target = (group != null) ? group : project.SourceDb.RootGroup;
		let name = target.UniqueInstanceName(baseName, .. scope .());
		let fileName = scope String(name);
		fileName.Append('.');
		fileName.Append(fileSuffix);
		let cook = ScriptLanguageCooks.Find(languageId);
		if (cook == null)
			return null;
		let starter = scope String();
		cook.NewAssetTemplate(tier, starter);
		let path = PathJoin(project.SourcesRoot(.. scope .()), fileName, .. scope .());
		if (!(WriteFile(path, .((uint8*)starter.Ptr, starter.Length)) case .Ok))
			return null;
		let instance = target.CreateInstance(name, typeof(ScriptClassAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope ScriptClassAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(languageId);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		context.RequestCook(false); // so the new class is pickable and attachable now
		return instance;
	}
}
