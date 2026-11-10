using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Project;

/// A project template as its Template.xml describes it: the folder it is, and what New Project
/// shows of it.
class ProjectTemplate
{
	/// Its folder's name, what project_create's `template` names it by.
	public String Id = new .() ~ delete _;
	/// Its folder, absolute.
	public String Directory = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	/// One line saying what a project made from it starts with.
	public String Description = new .() ~ delete _;
	/// Its picture's path, absolute; empty when it has none.
	public String Picture = new .() ~ delete _;
	/// Where it is listed: lower first.
	public int32 Order;

	public void Clear()
	{
		Id.Clear();
		Directory.Clear();
		Name.Clear();
		Description.Clear();
		Picture.Clear();
		Order = 0;
	}
}

/// The project templates an SDK carries, Data/Templates/<Id>/, each a project's tree with a
/// Template.xml beside it, and a new project made from one by copying it.
///
/// A template is made by the engine's own tools, so its records are at the SDK's data versions
/// and its manifest carries the SDK's stamp. What names the project in it is a placeholder:
/// __PROJECT_NAME__ for the project's name (in its manifest and its package's), __GAME__ for the
/// name its code goes by (ProjectBuild.GameName), in paths and texts, and __GAME_ID__ for its
/// package's id (ProjectLayout.PluginIdFromName of that name), in texts. Nothing is parsed on the
/// way: a manager can make a project from a newer SDK's template than the settings it reads.
/// Every project made from one template shares the template's asset ids.
static class ProjectTemplates
{
	/// The templates' folder under a data root.
	public const String cTemplatesDir = "Templates";
	/// What makes a folder there a template.
	public const String cInfoFile = "Template.xml";
	/// The template project_create and New Project pick when none is named.
	public const String cDefault = "Starter";
	/// The placeholders.
	public const String cProjectName = "__PROJECT_NAME__";
	public const String cGame = "__GAME__";
	public const String cGameId = "__GAME_ID__";

	/// What builds, cooks, exports and the editor write at a project's root, never copied from a
	/// template, and the root .gitignore a new project gets: CookedDir also covers a platform's
	/// Cooked-<platform>.
	private const String[4] cRootWrittenDirs = .(ProjectLayout.CookedDir, ProjectLayout.CacheDir, "Dist", ProjectLayout.EditorDir);

	/// The templates' folder of the data root `dataRoot` (an SDK's Data), into `outDir`.
	public static void Folder(StringView dataRoot, String outDir) => PathJoin(dataRoot, cTemplatesDir, outDir);

	/// The template in `directory` into `outTemplate`: its Template.xml read by key, as the
	/// manifest's header is. NotFound when the folder has none; InvalidArgument when it does not read.
	public static Result<void, ErrorCode> Read(StringView directory, ProjectTemplate outTemplate)
	{
		outTemplate.Clear();
		let absolute = ProjectBuild.Absolute(directory, .. scope .());
		if (!DirectoryExists(absolute))
			return .Err(.NotFound);
		let fs = scope NativeFileSystem(absolute);
		let stream = fs.Open(cInfoFile, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(stream, .Read);
		if (context == null)
			return .Err(.InvalidArgument);
		defer delete context;
		let archive = context.Serializer;
		if (archive == null)
			return .Err(.InvalidArgument);
		archive.BeginObject();
		if (!archive.IsOk)
			return .Err(.InvalidArgument);
		ReadKey(archive, "name", outTemplate.Name);
		ReadKey(archive, "description", outTemplate.Description);
		let picture = ReadKey(archive, "picture", .. scope .());
		if (archive.HasKey("order"))
		{
			archive.Key("order");
			int32 order = 0;
			archive.Scalar(&order, .Int32);
			outTemplate.Order = order;
		}
		archive.EndObject();
		if (!archive.IsOk)
			return .Err(.InvalidArgument);
		outTemplate.Directory.Set(absolute);
		PathFilename(absolute, outTemplate.Id);
		if (outTemplate.Name.IsEmpty)
			outTemplate.Name.Set(outTemplate.Id);
		if (!picture.IsEmpty)
			PathJoin(absolute, picture, outTemplate.Picture);
		return .Ok;
	}

	/// The string under `key` in the current object into `outValue`, left empty when there is none.
	private static void ReadKey(Sedulous.Core.Serialization.Serializer archive, StringView key, String outValue)
	{
		if (!archive.HasKey(key))
			return;
		archive.Key(key);
		archive.Text(outValue);
	}

	/// The templates under the data root `dataRoot` into `outTemplates` (new, the caller's), by
	/// their order, then their names: each folder of Data/Templates with a Template.xml that reads.
	/// Another folder there (a sky the starter content copies, the templates' own tools) is passed by.
	public static void ListTemplates(StringView dataRoot, List<ProjectTemplate> outTemplates)
	{
		let folder = Folder(dataRoot, .. scope .());
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ListDirectory(folder, scope [&](name, isDirectory) =>
			{
				if (isDirectory)
					names.Add(new .(name));
			});
		for (let name in names)
		{
			let template = new ProjectTemplate();
			if (Read(PathJoin(folder, name, .. scope .()), template) case .Ok)
				outTemplates.Add(template);
			else
				delete template;
		}
		outTemplates.Sort(scope (a, b) =>
			{
				if (a.Order != b.Order)
					return a.Order <=> b.Order;
				return String.Compare(a.Name, b.Name, false);
			});
	}

	/// The template `id` under the data root `dataRoot` into `outTemplate`. NotFound when there is
	/// none of that id; InvalidArgument when its Template.xml does not read.
	public static Result<void, ErrorCode> Find(StringView dataRoot, StringView id, ProjectTemplate outTemplate)
	{
		outTemplate.Clear();
		if (id.IsEmpty || id.Contains('/') || id.Contains('\\') || (id == ".") || (id == ".."))
			return .Err(.NotFound);
		return Read(PathJoin(Folder(dataRoot, .. scope .()), id, .. scope .()), outTemplate);
	}

	/// Makes a project named `projectName` at `target` from the template in `templateDir`: its tree
	/// copied less Template.xml, its picture and what builds and the editor write, each placeholder
	/// replaced in paths and texts (a file with a zero byte is copied as it is), the root .gitignore
	/// written when the template has none, and the fixed folders a project has made. `target` is
	/// made when absent, its parent existing. Refused, with nothing written: AlreadyExists when
	/// `target` holds anything; NotFound when `templateDir` is no template; InvalidArgument when
	/// it holds no manifest. When a copy fails part way, a `target` this made is taken away again.
	public static Result<void, ErrorCode> Instantiate(StringView templateDir, StringView target, StringView projectName)
	{
		let template = scope ProjectTemplate();
		if (Read(templateDir, template) case .Err(let error))
			return .Err(error);
		if (!FileExists(PathJoin(template.Directory, ProjectLayout.ManifestFile, .. scope .())))
			return .Err(.InvalidArgument);
		let destination = ProjectBuild.Absolute(target, .. scope .());
		bool made = false;
		if (DirectoryExists(destination))
		{
			bool empty = true;
			ListDirectory(destination, scope [&](name, isDirectory) => { empty = false; });
			if (!empty)
				return .Err(.AlreadyExists);
		}
		else
		{
			if (!DirectoryExists(PathParent(destination, .. scope .())) || !CreateDirectory(destination))
				return .Err(.NotFound);
			made = true;
		}

		let game = ProjectBuild.GameName(projectName, .. scope .());
		let names = scope Names(projectName, game);
		var result = CopyTree(template, template.Directory, destination, "", names);
		if (result case .Ok)
		{
			let ignore = PathJoin(destination, ProjectBuild.cIgnoreFile, .. scope .());
			if (!FileExists(ignore) && (WriteText(ignore, RootIgnoreText(.. scope .())) case .Err))
				result = .Err(.Internal);
			else if (!ProjectScaffold.EnsureDirectories(destination))
				result = .Err(.Internal);
		}
		if ((result case .Err) && made)
			RemoveDirectoryRecursive(destination);
		return result;
	}

	/// The .gitignore at a new project's root: what cooks, exports and the editor write there.
	public static void RootIgnoreText(String outText)
	{
		outText.Append("# Regenerated by a cook: the cooked assets and the cook database.\n");
		outText.AppendF("/{0}/\n/{0}-*/\n", ProjectLayout.CookedDir);
		outText.Append("# The project's own build (Build Project) and the editor's caches.\n");
		outText.AppendF("/{}/\n\n", ProjectLayout.CacheDir);
		outText.Append("# Export output (asset_export / project_export / the Export menu).\n");
		outText.Append("/Dist/\n\n");
		outText.Append("# The editor's per project workspace state: open pages, dock layout, favorites.\n");
		outText.AppendF("/{}/\n\n", ProjectLayout.EditorDir);
		outText.Append("# Python bytecode the tools leave behind.\n");
		outText.Append("__pycache__/\n");
	}

	/// `text` with each placeholder replaced: the project's name escaped for XML in a file whose
	/// name ends in .xml (its manifest and its package's), as it is elsewhere.
	public static void Substitute(StringView text, StringView projectName, StringView game, bool xml, String outText)
	{
		outText.Append(text);
		let name = scope String();
		if (xml)
			EscapeXmlText(projectName, name);
		else
			name.Append(projectName);
		outText.Replace(cProjectName, name);
		let id = ProjectLayout.PluginIdFromName(game, .. scope .());
		outText.Replace(cGameId, id);
		outText.Replace(cGame, game);
	}

	/// The names the placeholders become.
	private class Names
	{
		public String ProjectName = new .() ~ delete _;
		public String Game = new .() ~ delete _;

		public this(StringView projectName, StringView game)
		{
			ProjectName.Set(projectName);
			Game.Set(game);
		}
	}

	/// The template's folder `from` (at `relative` in it) copied into `to`.
	private static Result<void, ErrorCode> CopyTree(ProjectTemplate template, StringView from, StringView to, StringView relative, Names names)
	{
		let entries = scope List<(String name, bool isDirectory)>();
		defer
		{
			for (let entry in entries)
				delete entry.name;
		}
		if (!ListDirectory(from, scope [&](name, isDirectory) => { entries.Add((new String(name), isDirectory)); }))
			return .Err(.Internal);
		for (let entry in entries)
		{
			let path = scope String();
			if (!relative.IsEmpty)
				path.AppendF("{}/", relative);
			path.Append(entry.name);
			if (Skipped(template, path, entry.isDirectory))
				continue;
			let source = PathJoin(from, entry.name, .. scope .());
			let name = scope String(entry.name);
			name.Replace(cGame, names.Game);
			let destination = PathJoin(to, name, .. scope .());
			if (entry.isDirectory)
			{
				if (!DirectoryExists(destination) && !CreateDirectory(destination))
					return .Err(.Internal);
				if (CopyTree(template, source, destination, path, names) case .Err(let error))
					return .Err(error);
			}
			else if (CopyTemplateFile(source, destination, names) case .Err(let copyError))
				return .Err(copyError);
		}
		return .Ok;
	}

	/// Whether the template's entry at `path` (relative, '/' between folders) stays behind: its
	/// Template.xml and picture, and what builds, cooks, exports and the editor write (at the root,
	/// and in Code/).
	private static bool Skipped(ProjectTemplate template, StringView path, bool isDirectory)
	{
		if (!isDirectory && (path == cInfoFile))
			return true;
		if (!isDirectory && !template.Picture.IsEmpty)
		{
			let picture = PathJoin(template.Directory, path, .. scope .());
			if (picture == template.Picture)
				return true;
		}
		if (isDirectory)
		{
			for (int i < cRootWrittenDirs.Count)
			{
				let dir = cRootWrittenDirs[i];
				if ((path == dir) || ((dir == ProjectLayout.CookedDir) && path.StartsWith(scope $"{dir}-") && !path.Contains('/')))
					return true;
			}
		}
		let code = scope $"{ProjectLayout.CodeDir}/";
		if (!path.StartsWith(code))
			return false;
		let inCode = path.Substring(code.Length);
		if (isDirectory)
		{
			for (int i < ProjectBuild.cWrittenDirs.Count)
			{
				if (inCode == ProjectBuild.cWrittenDirs[i])
					return true;
			}
			return false;
		}
		for (int i < ProjectBuild.cWrittenFiles.Count)
		{
			if (inCode == ProjectBuild.cWrittenFiles[i])
				return true;
		}
		return false;
	}

	/// One file copied: its placeholders replaced when it is text (no zero byte in it).
	private static Result<void, ErrorCode> CopyTemplateFile(StringView source, StringView destination, Names names)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(source, bytes) case .Err)
			return .Err(.Internal);
		if (HasZeroByte(bytes))
		{
			if (WriteFile(destination, .(bytes.Ptr, bytes.Count)) case .Err)
				return .Err(.Internal);
			return .Ok;
		}
		let text = StringView((char8*)bytes.Ptr, bytes.Count);
		let written = scope String();
		Substitute(text, names.ProjectName, names.Game, destination.EndsWith(".xml"), written);
		if (WriteText(destination, written) case .Err)
			return .Err(.Internal);
		return .Ok;
	}

	/// Whether `bytes` hold a zero byte: what no text file of a template has, and binary ones do.
	private static bool HasZeroByte(List<uint8> bytes)
	{
		for (let b in bytes)
		{
			if (b == 0)
				return true;
		}
		return false;
	}

	private static Result<void> WriteText(StringView path, StringView text)
	{
		if (WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Err)
			return .Err;
		return .Ok;
	}

	/// Element text escaped: the three characters that would start markup.
	private static void EscapeXmlText(StringView text, String outText)
	{
		for (let c in text.RawChars)
		{
			switch (c)
			{
			case '&': outText.Append("&amp;");
			case '<': outText.Append("&lt;");
			case '>': outText.Append("&gt;");
			default: outText.Append(c);
			}
		}
	}
}
