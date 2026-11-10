using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Project;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// Where the project manager is, and starting it. An editor has one project: Close Project, and
/// an editor started with no project, hand the user to the manager, which opens the next one.
static class ManagerLauncher
{
	/// The manager's folder in an SDK, beside its Data, and its executable's name there.
	public const String cManagerFolder = "ProjectManager";
	public const String cManagerName = "Sedulous.Tools.ProjectManager";

	/// The project manager into `outPath`, made absolute, each only when its file is there:
	/// `given` (--manager: the manager that launched this editor); else the one the SDK registry at
	/// `sdksPath` (empty: the user's sdks.xml) recorded as the last to run; else <sdk>/ProjectManager/
	/// of the SDK whose Data is `dataRoot` (empty: none). False, `outPath` empty, for none.
	public static bool Find(StringView given, StringView sdksPath, StringView dataRoot, String outPath)
	{
		outPath.Clear();
		if (!given.IsEmpty && Take(given, outPath))
			return true;
		let registryPath = scope String(sdksPath);
		if (registryPath.IsEmpty)
			SdkRegistry.DefaultPath(registryPath);
		let registry = scope SdkRegistry(registryPath);
		let recorded = scope String();
		if (registry.ManagerPath(recorded) && Take(recorded, outPath))
			return true;
		if (dataRoot.IsEmpty)
			return false;
		let sdk = PathParent(ProjectBuild.Absolute(dataRoot, .. scope .()), .. scope .());
		let folder = PathJoin(sdk, cManagerFolder, .. scope .());
		let beside = PathJoin(folder, BuildLayout.ExecutableName(cManagerName, .. scope .()), .. scope .());
		return Take(beside, outPath);
	}

	/// Starts the manager at `manager` with `--data-root <dataRoot>` (none when empty), so it sits
	/// with the SDK this editor runs from, through `launch` (null: a process of its own,
	/// Process.Start). True when it started.
	public static bool Start(StringView manager, StringView dataRoot, delegate bool(StringView executable, Span<StringView> arguments) launch)
	{
		let arguments = scope StringView[dataRoot.IsEmpty ? 0 : 2];
		if (!dataRoot.IsEmpty)
		{
			arguments[0] = "--data-root";
			arguments[1] = dataRoot;
		}
		return (launch != null) ? launch(manager, arguments) : Sedulous.Core.Process.Start(manager, arguments);
	}

	/// `path`, made absolute, into `outPath` when a file is there.
	private static bool Take(StringView path, String outPath)
	{
		let absolute = ProjectBuild.Absolute(path, .. scope .());
		if (!FileExists(absolute))
			return false;
		outPath.Set(absolute);
		return true;
	}
}
