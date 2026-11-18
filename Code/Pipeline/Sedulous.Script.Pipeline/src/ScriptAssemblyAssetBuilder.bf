using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Script; // ScriptProblems
using Sedulous.Script.Resource;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline;

/// Builds a project's script assembly: the project file and every source of its language under
/// its folder, through the language's project build (ScriptAssemblyCooks). Never names a language.
class ScriptAssemblyAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ScriptAssemblyAsset);
	public Type ProductType => typeof(ScriptAssemblySource);

	/// The shell's own version plus every project build's, so a toolchain change rebuilds.
	public int32 Version => 1 + ScriptAssemblyCooks.VersionSum;

	/// The surface the assembly is built against: a change rebuilds it.
	public uint64 EnvironmentHash => ScriptLanguageCooks.SurfaceHashSum;

	/// Every source under the project's folder is an input: an edit, a new file or a removed one
	/// rebuilds it.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let project = (ScriptAssemblyAsset)asset;
		let cook = ScriptAssemblyCooks.Find(project.Language);
		if ((cook == null) || (context.Sources == null))
			return; // Build says so
		let files = scope List<String>();
		defer { ClearAndDeleteItems!(files); }
		ScriptAssemblies.ListSourcesUnder(context.Sources, PathParent(project.FileName.Value, .. scope .()), cook.SourceExtension, files);
		for (let file in files)
			outDeps.AddFile(file);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if ((context.Output == null) || (context.Sources == null))
			return .Err(.InvalidArgument);
		let project = (ScriptAssemblyAsset)asset;

		let cook = ScriptAssemblyCooks.Find(project.Language);
		if (cook == null)
		{
			GlobalLog(.Error, "Cook: no project build for language '{}' ({})", project.Language, project.FileName.Value);
			return .Err(.NotSupported);
		}

		let text = scope String();
		if (AssetSource.ReadText(context, project.FileName.Value, text) case .Err(let readError))
		{
			GlobalLog(.Error, "Cook: script project '{}' could not be read", project.FileName.Value);
			return .Err(readError);
		}

		let folder = PathParent(project.FileName.Value, .. scope .());
		let files = scope List<String>();
		defer { ClearAndDeleteItems!(files); }
		ScriptAssemblies.ListSourcesUnder(context.Sources, folder, cook.SourceExtension, files);
		let sources = scope List<ScriptAssemblyFile>();
		defer { ClearAndDeleteItems!(sources); }
		for (let file in files)
		{
			let source = sources.Add(.. new ScriptAssemblyFile());
			source.Path.Set(file);
			if (AssetSource.ReadText(context, file, source.Text) case .Err)
			{
				GlobalLog(.Error, "Cook: '{}' could not be read, so script project '{}' was not built", file, project.FileName.Value);
				return .Err(.NotFound);
			}
		}

		WriteLocalFiles(cook, context, folder);

		let built = scope ScriptAssemblySource();
		built.Language.Set(project.Language);
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		let ok = cook.Build(project.FileName.Value, text, sources, built, problems);
		for (let p in problems)
			GlobalLog((!ok && !ScriptProblems.IsWarning(p)) ? .Error : .Warning, "Cook: {}", p);
		if (!ok)
			return .Err(.InvalidArgument); // nothing written: the last good assembly stays
		return context.Output.WriteObject(built);
	}

	/// The project build's local files beside the project, written only when they differ, so a
	/// cook that changes nothing touches nothing a file watcher sees.
	private static void WriteLocalFiles(IScriptAssemblyCook cook, AssetBuildContext context, StringView folder)
	{
		let writable = context.Sources as IWritableFileSystem;
		if (writable == null)
			return;
		let local = scope List<ScriptAssemblyFile>();
		defer { ClearAndDeleteItems!(local); }
		cook.LocalFiles(local);
		for (let file in local)
		{
			let path = scope String();
			if (folder.IsEmpty)
				path.Set(file.Path);
			else
				PathJoin(folder, file.Path, path);
			let current = scope String();
			if ((AssetSource.ReadText(context, path, current) case .Ok) && (current == file.Text))
				continue;
			if (writable.Save(path, .((uint8*)file.Text.Ptr, file.Text.Length)) case .Err)
				GlobalLog(.Warning, "Cook: '{}' could not be written beside script project '{}'", path, folder);
		}
	}
}
