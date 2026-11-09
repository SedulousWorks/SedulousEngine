using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Project;

/// A player builder that runs no compiler: it writes a stand-in player into a folder, with what a
/// build leaves beside one, and reports it as BeefBuild's would be reported. An export run over it
/// stages a dist in milliseconds where a real build takes minutes, so the export's tests use it.
/// It refuses what ProjectPlayerBuilder refuses for a preset (ProjectPlayerBuilder.Target).
class StagedPlayerBuilder : IPlayerBuilder
{
	/// The stand-in shared library beside a desktop player, which ships.
	public const String cLibrary = "libstandin.so";
	/// The shader compiler's runtime beside it, which a build collects and leaves out.
	public const String cDxcLibrary = "libdxcompiler.so";

	private String mFolder = new .() ~ delete _;
	private int mBuilds;

	/// Writes its players under `folder`, one folder per entry and config.
	public this(StringView folder)
	{
		mFolder.Set(folder);
	}

	/// How many players it has made.
	public int Builds => mBuilds;

	public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
		String outRefusal)
	{
		outBuild.Clear();
		let config = scope String();
		BuildEntry entry;
		if (ProjectPlayerBuilder.Target(preset, out entry, config, outRefusal) case .Err(let refused))
			return .Err(refused);
		let game = ProjectBuild.GameName(project.Name, .. scope .());
		let name = ProjectBuild.EntryName(game, entry, .. scope .());
		if (onProgress != null)
			onProgress(scope $"Building {name} ({config})", PlayerBuild.cProgressStart);

		let directory = PathJoin(mFolder, scope $"{config}_{name}", .. scope .());
		if (!CreateDirectory(directory))
		{
			outRefusal.Set(scope $"'{directory}' could not be made");
			return .Err(.Internal);
		}
		if (entry == .PlayerWeb)
		{
			let page = scope $"{name}.html";
			if (!Write(directory, page, "<!doctype html>\n") || !Write(directory, scope $"{name}.js", "// player\n")
				|| !Write(directory, scope $"{name}.wasm", "wasm\n") || !Write(directory, "serve.py", "# serve\n")
				|| !Write(directory, BuildLayout.cThirdPartyNotices, "notices\n"))
			{
				outRefusal.Set(scope $"the stand-in player could not be written in '{directory}'");
				return .Err(.Internal);
			}
			ProjectPlayerBuilder.CollectWeb(directory, page, outBuild);
		}
		else
		{
			let binary = BuildLayout.ExecutableName(name, .. scope .());
			if (!Write(directory, binary, "#!player\n") || !Write(directory, cLibrary, "so\n") || !Write(directory, cDxcLibrary, "so\n")
				|| !Write(directory, BuildLayout.cThirdPartyNotices, "notices\n"))
			{
				outRefusal.Set(scope $"the stand-in player could not be written in '{directory}'");
				return .Err(.Internal);
			}
			FileCopy.MakeExecutable(PathJoin(directory, binary, .. scope .()));
			ProjectPlayerBuilder.CollectDesktop(directory, binary, outBuild);
		}
		outBuild.Description.Set(scope $"{name}, {config}, {ProjectBuild.EntryPlatform(entry)} (staged)");
		mBuilds++;
		if (onProgress != null)
			onProgress(scope $"Built {name} ({config})", PlayerBuild.cProgressEnd);
		return .Ok;
	}

	private static bool Write(StringView directory, StringView name, StringView text)
	{
		return WriteFile(PathJoin(directory, name, .. scope .()), .((uint8*)text.Ptr, text.Length)) case .Ok;
	}
}
