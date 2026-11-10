using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.Projects.Tests;

/// A new project made from a template: the template's tree copied with its placeholders replaced
/// (the project's name, the name its code goes by under GameName's rules, its package's id), less
/// what builds and the editor write and the template's own Template.xml and picture; the root
/// .gitignore written; a target that is not empty refused, and nothing written outside the target.
/// The templates are listed by their order, a folder with no Template.xml passed by.
static class ProjectTemplateTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		Test.Assert(CreateDirectory(outPath));
	}

	private static void TemplateInfo(StringView name, StringView line, StringView picture, int order, String outText)
	{
		outText.AppendF("""
			<root>
				<object>
					<string name="name">{}</string>
					<string name="description">{}</string>
					<string name="picture">{}</string>
					<i32 name="order">{}</i32>
				</object>
			</root>

			""", name, line, picture, order);
	}

	/// The bytes of a file the template carries that are not text: a zero among them, and a
	/// placeholder's bytes, which stay as they are.
	private static uint8[12] cBinary = .(0x42, 0x00, 0x5F, 0x5F, 0x47, 0x41, 0x4D, 0x45, 0x5F, 0x5F, 0xFF, 0x00);

	/// A template in `dir`: its manifest named by the placeholder, its package's manifest and
	/// Engine part under the game's placeholder, a scene naming a behaviour by the package's id, a
	/// binary file, a picture, and what builds and the editor write (each of which stays behind).
	private static void WriteTemplate(StringView dir, StringView name, int order)
	{
		ProjectBuildBed.MakeDirectories(dir);
		Test.Assert(ProjectScaffold.Create(dir, ProjectTemplates.cProjectName) case .Ok);
		ProjectBuildBed.Write(dir, ProjectTemplates.cInfoFile, TemplateInfo(name, "A test template.", "picture.png", order, .. scope .()));
		ProjectBuildBed.Write(dir, "picture.png", "not really a picture");

		let manifest = scope PluginManifest();
		manifest.Id.Set(ProjectTemplates.cGameId);
		manifest.Name.Set(ProjectTemplates.cProjectName);
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let xml = scope String();
		Test.Assert(manifest.Write(xml) case .Ok);
		ProjectBuildBed.Write(dir, "Code/Plugin.xml", xml);
		ProjectBuildBed.Write(dir, "Code/__GAME__/BeefProj.toml", "[Project]\nName = \"__GAME__\"\n");
		ProjectBuildBed.Write(dir, "Code/__GAME__/src/__GAME__Engine.bf",
			"namespace __GAME__;\n\nclass __GAME__EnginePart\n{\n\tpublic StringView PluginId => \"__GAME_ID__\";\n}\n");
		ProjectBuildBed.Write(dir, "Content/Scenes/Main.scene.data", "<string name=\"type\">__GAME_ID__.Rotator</string>\n");
		let binary = PathJoin(dir, "Sources/blob.bin", .. scope .());
		ProjectBuildBed.MakeDirectories(PathParent(binary, .. scope .()));
		Test.Assert(WriteFile(binary, .(&cBinary[0], cBinary.Count)) case .Ok);

		ProjectBuildBed.Write(dir, "Cooked/stale.rasset", "cooked");
		ProjectBuildBed.Write(dir, "Cooked-Web/stale.rasset", "cooked");
		ProjectBuildBed.Write(dir, "Editor/layout.xml", "<layout/>");
		ProjectBuildBed.Write(dir, ".cache/imports.txt", "/home/someone/file.png");
		ProjectBuildBed.Write(dir, "Code/build/Debug_Linux64/x", "built");
		ProjectBuildBed.Write(dir, "Code/.generated/sdk.txt", "/somewhere");
		ProjectBuildBed.Write(dir, "Code/BeefConfig.toml", "UnversionedLibDirs = [\"/somewhere\"]\n");
	}

	private static void ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// Every file under `dir`, relative to it, into `outFiles` (new, the caller's).
	private static void Files(StringView dir, StringView relative, List<String> outFiles)
	{
		let entries = scope List<(String name, bool isDirectory)>();
		defer
		{
			for (let entry in entries)
				delete entry.name;
		}
		ListDirectory(PathJoin(dir, relative, .. scope .()), scope [&](name, isDirectory) => { entries.Add((new String(name), isDirectory)); });
		for (let entry in entries)
		{
			let path = scope String();
			if (!relative.IsEmpty)
				path.AppendF("{}/", relative);
			path.Append(entry.name);
			if (entry.isDirectory)
				Files(dir, path, outFiles);
			else
				outFiles.Add(new .(path));
		}
	}

	private static bool Has(List<String> files, StringView file)
	{
		for (let listed in files)
		{
			if (listed == file)
				return true;
		}
		return false;
	}

	[Test]
	public static void AProjectIsMadeFromATemplateWithItsNamesInPlace()
	{
		let root = Scratch("scratch_template_made", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let template = PathJoin(root, "Templates/Starter", .. scope .());
		WriteTemplate(template, "Starter", 1);
		let target = PathJoin(root, "Tom and Jerry", .. scope .());
		Test.Assert(ProjectTemplates.Instantiate(template, target, "Tom & Jerry") case .Ok);

		// The manifest: the name escaped as XML wants, read back as it was given.
		let header = scope ProjectHeader();
		Test.Assert(ProjectHeader.Read(target, header) case .Ok);
		Test.Assert(header.Name == "Tom & Jerry", header.Name);
		Test.Assert(header.EngineVersion == EngineVersion.String, "the template's stamp, carried over");
		let settings = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(target, settings) case .Ok);

		// The code: under the name it goes by, its package's id inside.
		let source = ReadText(PathJoin(target, "Code/TomJerry/src/TomJerryEngine.bf", .. scope .()), .. scope .());
		Test.Assert(source.Contains("namespace TomJerry;") && source.Contains("class TomJerryEnginePart") && source.Contains("\"tomjerry\""), source);
		Test.Assert(!source.Contains("__"), source);
		let project = ReadText(PathJoin(target, "Code/TomJerry/BeefProj.toml", .. scope .()), .. scope .());
		Test.Assert(project.Contains("Name = \"TomJerry\""), project);
		let plugin = ReadText(PathJoin(target, "Code/Plugin.xml", .. scope .()), .. scope .());
		Test.Assert(plugin.Contains("Tom &amp; Jerry") && plugin.Contains(">tomjerry<"), plugin);
		let scene = ReadText(PathJoin(target, "Content/Scenes/Main.scene.data", .. scope .()), .. scope .());
		Test.Assert(scene.Contains("tomjerry.Rotator"), scene);

		// A file with a zero byte is copied as it is, the placeholder's bytes in it kept.
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(target, "Sources/blob.bin", .. scope .()), bytes) case .Ok);
		Test.Assert(bytes.Count == cBinary.Count);
		for (int i < cBinary.Count)
			Test.Assert(bytes[i] == cBinary[i]);

		// What stays behind; the root .gitignore; the fixed folders, made empty.
		for (let gone in StringView[?](ProjectTemplates.cInfoFile, "picture.png", "Cooked/stale.rasset", "Cooked-Web", "Editor/layout.xml",
			".cache/imports.txt", "Code/build", "Code/.generated", "Code/BeefConfig.toml", "Code/__GAME__"))
		{
			let path = PathJoin(target, gone, .. scope .());
			Test.Assert(!FileExists(path) && !DirectoryExists(path), scope String(gone));
		}
		let ignore = ReadText(PathJoin(target, ".gitignore", .. scope .()), .. scope .());
		Test.Assert(ignore == ProjectTemplates.RootIgnoreText(.. scope .()), ignore);
		for (let dir in StringView[?]("/Cooked/", "/Cooked-*/", "/.cache/", "/Dist/", "/Editor/"))
			Test.Assert(ignore.Contains(scope $"{dir}\n"), scope String(dir));
		for (let fixedDir in StringView[?](ProjectLayout.ContentDir, ProjectLayout.SourcesDir, ProjectLayout.CookedDir, ProjectLayout.EditorDir,
			ProjectLayout.CacheDir))
			Test.Assert(DirectoryExists(PathJoin(target, fixedDir, .. scope .())), scope String(fixedDir));
	}

	[Test]
	public static void ANameThatIsNoIdentifierGivesTheCodeGameNamesName()
	{
		let root = Scratch("scratch_template_names", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let template = PathJoin(root, "Templates/Empty", .. scope .());
		WriteTemplate(template, "Empty", 0);
		let target = PathJoin(root, "Pigs", .. scope .());
		Test.Assert(ProjectTemplates.Instantiate(template, target, "3 Little Pigs!") case .Ok);
		Test.Assert(ProjectBuild.GameName("3 Little Pigs!", .. scope .()) == "Game3LittlePigs");
		Test.Assert(DirectoryExists(PathJoin(target, "Code/Game3LittlePigs", .. scope .())));
		Test.Assert(FileExists(PathJoin(target, "Code/Game3LittlePigs/src/Game3LittlePigsEngine.bf", .. scope .())));

		// The package the project's build and Add Native Code find is the one the template made.
		let settings = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(target, settings) case .Ok);
		Test.Assert(settings.Name == "3 Little Pigs!", settings.Name);
		let info = scope GamePackageInfo();
		Test.Assert(GamePackage.Find(target, settings, info), "its Plugin.xml reads");
		Test.Assert(info.Name == "Game3LittlePigs", info.Name);
		Test.Assert(info.Id == "game3littlepigs", info.Id);
		Test.Assert((info.Parts.Count == 1) && (info.Parts[0] == .Engine));
		let manifest = scope PluginManifest();
		Test.Assert(PluginManifest.Load(PathJoin(target, "Code", .. scope .()), manifest) case .Ok);
		Test.Assert((manifest.Id == info.Id) && (manifest.Name == "3 Little Pigs!"));

		// The substitution alone, for a name with nothing of an identifier in it.
		let text = ProjectTemplates.Substitute("__PROJECT_NAME__/__GAME__/__GAME_ID__", "!!!", ProjectBuild.GameName("!!!", .. scope .()), false,
			.. scope .());
		Test.Assert(text == "!!!/Game/game", text);
	}

	[Test]
	public static void ATargetThatIsNotEmptyIsRefusedAndNothingIsWrittenOutsideTheTarget()
	{
		let root = Scratch("scratch_template_refused", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let template = PathJoin(root, "Templates/Starter", .. scope .());
		WriteTemplate(template, "Starter", 1);
		let before = scope List<String>();
		defer { ClearAndDeleteItems!(before); }
		Files(root, "", before);

		// A folder with something in it: refused, untouched.
		let taken = PathJoin(root, "out/Taken", .. scope .());
		ProjectBuildBed.Write(taken, "notes.txt", "mine");
		Test.Assert(ProjectTemplates.Instantiate(template, taken, "Taken") case .Err(.AlreadyExists));
		let left = scope List<String>();
		defer { ClearAndDeleteItems!(left); }
		Files(taken, "", left);
		Test.Assert((left.Count == 1) && (left[0] == "notes.txt"));

		// A folder whose parent is not there; a folder that is no template; a template without a
		// manifest: each refused, and no target made.
		let orphan = PathJoin(root, "no such/Orphan", .. scope .());
		Test.Assert(ProjectTemplates.Instantiate(template, orphan, "Orphan") case .Err(.NotFound));
		Test.Assert(!DirectoryExists(PathParent(orphan, .. scope .())));
		let fresh = PathJoin(root, "out/Fresh", .. scope .());
		Test.Assert(ProjectTemplates.Instantiate(PathJoin(root, "Templates/Missing", .. scope .()), fresh, "Fresh") case .Err(.NotFound));
		let bare = PathJoin(root, "Templates/Bare", .. scope .());
		ProjectBuildBed.Write(bare, ProjectTemplates.cInfoFile, TemplateInfo("Bare", "No manifest.", "", 2, .. scope .()));
		Test.Assert(ProjectTemplates.Instantiate(bare, fresh, "Fresh") case .Err(.InvalidArgument));
		Test.Assert(!DirectoryExists(fresh));
		Test.Assert(DeleteFile(PathJoin(bare, ProjectTemplates.cInfoFile, .. scope .())) && RemoveDirectory(bare));

		// An empty folder is taken; what is made lands in it alone, and the template is as it was.
		Test.Assert(CreateDirectory(fresh));
		Test.Assert(ProjectTemplates.Instantiate(template, fresh, "Fresh") case .Ok);
		let after = scope List<String>();
		defer { ClearAndDeleteItems!(after); }
		Files(root, "", after);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		Files(fresh, "", made);
		Test.Assert(made.Count > 0);
		Test.Assert(after.Count == before.Count + 1 + made.Count, "the template's files, notes.txt and what went into the target");
		for (let file in after)
			Test.Assert(Has(before, file) || file.StartsWith("out/Fresh/") || (file == "out/Taken/notes.txt"), file);
		for (let file in before)
			Test.Assert(Has(after, file), file);
	}

	[Test]
	public static void TemplatesAreListedByTheirOrderAndFoundByTheirFolder()
	{
		let root = Scratch("scratch_template_list", .. scope .());
		defer RemoveDirectoryRecursive(root);
		let data = PathJoin(root, "Data", .. scope .());
		let folder = ProjectTemplates.Folder(data, .. scope .());
		WriteTemplate(PathJoin(folder, "Starter", .. scope .()), "Starter", 1);
		WriteTemplate(PathJoin(folder, "Empty", .. scope .()), "Empty", 0);
		ProjectBuildBed.Write(folder, "sky/sky.hdr", "not a template"); // the starter content's sky
		ProjectBuildBed.Write(folder, "Tools/make-templates.py", "# the templates' own tools");

		let templates = scope List<ProjectTemplate>();
		defer { ClearAndDeleteItems!(templates); }
		ProjectTemplates.ListTemplates(data, templates);
		Test.Assert(templates.Count == 2);
		Test.Assert((templates[0].Id == "Empty") && (templates[1].Id == "Starter"), "by their order, not their names");
		let starter = templates[1];
		Test.Assert(starter.Name == "Starter");
		Test.Assert(starter.Description == "A test template.");
		Test.Assert(starter.Order == 1);
		Test.Assert(starter.Directory == PathJoin(folder, "Starter", .. scope .()), starter.Directory);
		Test.Assert(starter.Picture == PathJoin(folder, "Starter/picture.png", .. scope .()), starter.Picture);

		let found = scope ProjectTemplate();
		Test.Assert(ProjectTemplates.Find(data, ProjectTemplates.cDefault, found) case .Ok);
		Test.Assert(found.Directory == starter.Directory);
		Test.Assert(ProjectTemplates.Find(data, "sky", found) case .Err(.NotFound), "a folder with no Template.xml");
		Test.Assert(ProjectTemplates.Find(data, "../Data/Templates/Starter", found) case .Err(.NotFound), "a template is named by its folder alone");
		Test.Assert(ProjectTemplates.Find(data, "", found) case .Err(.NotFound));

		// With no templates folder at all, none.
		ClearAndDeleteItems!(templates);
		ProjectTemplates.ListTemplates(PathJoin(root, "Nowhere", .. scope .()), templates);
		Test.Assert(templates.IsEmpty);
	}
}
