using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Scene.Resource;
using Sedulous.Shaders;
using Sedulous.VFS;
using Sedulous.VFS.Pak;

namespace Sedulous.Editor.Core;

/// The export driver's helpers: the cooked tree packed with the reachable filter, a scene
/// staged as a binary product, the shader pack cooked into the dist's Data, and the small
/// name helpers.
static class ExportStaging
{
	public const String cSceneStream = "scene";

	/// Whether a packed file's owner is in the reachable set: the file's path with any
	/// extension stripped names its instance's path.
	public static bool FileOwnerReachable(StringView file, HashSet<String> reachablePaths)
	{
		var nameStart = 0;
		for (int i < file.Length)
			if (file[i] == '/')
				nameStart = i + 1;
		for (int i = nameStart; i < file.Length; i++)
			if ((file[i] == '.') && reachablePaths.Contains(scope String(file.Substring(0, i))))
				return true;
		return false;
	}

	/// Every file under `folder` of the mount into the pak; `reachablePaths` null packs all.
	public static bool PackTree(NativeFileSystem mount, StringView folder, PakBuilder pak, ref int fileCount, HashSet<String> reachablePaths)
	{
		let entries = scope List<DirEntry>();
		defer { for (var entry in entries) entry.Dispose(); }
		if (mount.Enumerate(folder, entries) case .Err)
			return folder.IsEmpty;
		for (let entry in entries)
		{
			let path = folder.IsEmpty ? scope:: String(entry.Name) : PathJoin(folder, entry.Name, .. scope:: .());
			if (entry.IsDirectory)
			{
				if (!PackTree(mount, path, pak, ref fileCount, reachablePaths))
					return false;
				continue;
			}
			if ((reachablePaths != null) && !FileOwnerReachable(path, reachablePaths))
				continue;
			let stream = mount.Open(path, .Read);
			if (stream == null)
				return false;
			defer delete stream;
			let bytes = scope List<uint8>();
			bytes.Resize((int)stream.Size());
			if ((bytes.Count > 0) && (stream.Read(bytes) != bytes.Count))
				return false;
			pak.Add(path, bytes);
			fileCount++;
		}
		return true;
	}

	/// The scene's document and stream into the staging database at the same group path,
	/// the stream pre-transcoded when `sceneStreams` has it, else verbatim.
	public static bool StageScene(Instance scene, ContentDatabase staging, Dictionary<Guid, List<uint8>> sceneStreams)
	{
		var group = staging.RootGroup;
		for (let part in scene.OwningGroup.GetPath(.. scope .()).Split('/'))
		{
			if (part.IsEmpty)
				continue;
			group = group.CreateGroup(part);
			if (group == null)
				return false;
		}
		let object = scene.ReadObject();
		if (object == null)
			return false;
		defer delete object;
		let staged = group.CreateInstanceWithId(scene.Id, scene.Name, scene.TypeName);
		if ((staged == null) || (staged.WriteObject(object) case .Err))
			return false;
		if ((sceneStreams != null) && sceneStreams.TryGetValue(scene.Id, let pre))
			return staged.WriteData(cSceneStream, pre) case .Ok;
		let stream = scene.ReadData(cSceneStream);
		if (stream == null)
			return true;
		defer delete stream;
		let bytes = scope List<uint8>();
		bytes.Resize((int)stream.Size());
		if ((bytes.Count > 0) && (stream.Read(bytes) != bytes.Count))
			return false;
		return staged.WriteData(cSceneStream, bytes) case .Ok;
	}

	public static bool IsSceneLike(Instance instance)
		=> (instance.TypeName == McpDocumentNames.cSceneDocument) || (instance.TypeName == McpDocumentNames.cPrefabDocument);

	public static void CollectScenes(Group group, List<Instance> outScenes)
	{
		for (let instance in group.Instances)
			if (IsSceneLike(instance))
				outScenes.Add(instance);
		for (let child in group.Groups)
			CollectScenes(child, outScenes);
	}

	public static void CollectAllInstances(Group group, List<Instance> outInstances)
	{
		for (let instance in group.Instances)
			outInstances.Add(instance);
		for (let child in group.Groups)
			CollectAllInstances(child, outInstances);
	}

	/// Letters, digits, '-', '_' and '.' pass; anything else is '-'; empty is "export".
	public static void SanitizeName(StringView name, String outName)
	{
		outName.Clear();
		for (let c in name)
			outName.Append((c.IsLetterOrDigit || (c == '-') || (c == '_') || (c == '.')) ? c : '-');
		if (outName.IsEmpty)
			outName.Set("export");
	}

	/// The preset's player name or the template's binary, with .exe on a Windows target.
	public static void PlayerOutputName(StringView platform, StringView playerName, StringView templateBinary, String outName)
	{
		outName.Set(playerName.IsEmpty ? templateBinary : playerName);
		if (platform.StartsWith("Win") && !outName.EndsWith(".exe"))
			outName.Append(".exe");
	}

	/// The DXC runtime is omitted from a dist: it renders from the cooked shader pack.
	public static bool IsDxcRuntimeLib(StringView name) => name.Contains("dxcompiler") || name.Contains("dxil");

	public static bool IsWebPlatform(StringView platform) => platform.StartsWith("Web") || platform.StartsWith("Wasm");

	/// WGSL for the web, SPIR-V and DXIL for Windows, SPIR-V elsewhere.
	public static void FormatsForPlatform(StringView platform, List<CookedShaderFormat> outFormats)
	{
		if (IsWebPlatform(platform))
			outFormats.Add(.Wgsl);
		else if (platform.StartsWith("Win"))
		{
			outFormats.Add(.SpirV);
			outFormats.Add(.Dxil);
		}
		else
			outFormats.Add(.SpirV);
	}

	/// Cooks the engine shader corpus under the data root into <dist>/Data/Shaders/
	/// shaders.dpak and writes the data root marker beside it, so the shipped player finds
	/// its data the way every executable does.
	public static Result<void, ErrorCode> StageShaderPack(StringView outputDir, StringView dataRoot, StringView platform, out int outVariants)
	{
		outVariants = 0;
		let shaderDir = DataPath(dataRoot, ShaderSystemHost.cShaderFolder, .. scope .());
		if (!DirectoryExists(shaderDir))
		{
			GlobalLog(.Error, "Export: cannot cook shaders: no '{}' under the data root '{}'", ShaderSystemHost.cShaderFolder, dataRoot);
			return .Err(.NotFound);
		}
		let compiler = scope ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			GlobalLog(.Error, "Export: cannot cook shaders: the DXC compiler is unavailable");
			return .Err(.Internal);
		}
		let formats = scope List<CookedShaderFormat>();
		FormatsForPlatform(platform, formats);
		var options = ShaderCookOptions();
		options.ShaderDirectory = shaderDir;
		options.ScratchDirectory = outputDir;
		options.Formats = formats;
		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler, options, pack, report);
		for (let error in report.Errors)
			GlobalLog(.Error, "Export: shader cook: {}", error);
		if (!report.Success)
			return .Err(.Internal);
		let distData = PathJoin(outputDir, "Data", .. scope .());
		let packPath = PathJoin(distData, ShaderSystemHost.cShaderPackPath, .. scope .());
		if (!CreateDirectory(PathParent(packPath, .. scope .())))
		{
			GlobalLog(.Error, "Export: could not create '{}'", PathParent(packPath, .. scope .()));
			return .Err(.Internal);
		}
		let output = scope FileStream(packPath, .Write);
		if (!output.IsValid || (pack.Write(output) case .Err))
		{
			GlobalLog(.Error, "Export: could not write '{}'", packPath);
			return .Err(.Internal);
		}
		let marker = "# Data root marker (Sedulous.VFS FindDataRoot). Staged by the export.\nversion: 1\n";
		if (WriteFile(PathJoin(distData, cDataRootMarker, .. scope .()), .((uint8*)marker.Ptr, marker.Length)) case .Err)
		{
			GlobalLog(.Error, "Export: could not write the data root marker");
			return .Err(.Internal);
		}
		outVariants = pack.Count;
		return .Ok;
	}
}
