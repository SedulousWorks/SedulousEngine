using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Shaders;
using Sedulous.Shaders.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Shaders.Tests;

/// The shader page over its markup without a host (no preview drawn): the source read and checked
/// against the engine's library (what the shader is, its properties), a broken edit's problem with
/// the preview kept on the last version that compiled and saying so, and one history for the code
/// and the asset's grid. Skipped where no shader compiler is available, as the pipeline's tests are.
class ShaderPageTests
{
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static bool ReadData(StringView relative, String outText)
	{
		let data = scope String();
		return DataRoot(data) && (System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), outText, true) case .Ok);
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let text = scope String();
		Test.Assert(ReadData(relative, text));
		RegisterGuiElements();
		RegisterToolkitElements();
		RegisterCodeElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	static bool HaveCompiler()
	{
		let compiler = scope ShaderCompiler();
		return compiler.Initialize() case .Ok;
	}

	/// A project with the gallery's first lesson ("Colour", Sources/Colour.hlsl: an unlit surface
	/// shader with one property).
	private class Bed
	{
		public String Dir = new .("scratch_shader_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public CodeLanguages Languages = new .(new (path, outText) => ReadData(path, outText)) ~ delete _;
		public Instance Colour;
		public String Source = new .() ~ delete _;

		public this()
		{
			ShadersPipeline.RegisterAll(); // the instance's type, written and read back
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Test.Assert(ReadData("SampleProjects/ShaderGallery/Sources/01_UnlitColour.hlsl", Source));
			// Line feeds alone, as the page's code document holds a file's text: a Windows checkout
			// gives the sample CRLF endings.
			Source.Replace("\r", "");
			Test.Assert(System.IO.File.WriteAllText(PathJoin(Project.SourcesRoot(.. scope .()), "Colour.hlsl", .. scope .()), Source) case .Ok);
			Colour = Project.SourceDb.RootGroup.CreateInstance("Colour", typeof(ShaderAsset).GetFullName(.. scope .()));
			Test.Assert(Colour != null);
			let asset = scope ShaderAsset();
			asset.Name.Set("Colour");
			asset.FileName.Set("Colour.hlsl");
			Test.Assert(Colour.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the shader; the caller deletes it (before the bed).
		public ShaderEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Languages = Languages;
			let data = scope String();
			Test.Assert(DataRoot(data));
			return new ShaderEditorPage(Context, services, Colour, PathJoin(data, "Engine/Shaders", .. scope .()));
		}
	}

	[Test]
	public static void RegisteredForTheShaderAsset()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		ShaderEditor.Register(context, none, "Engine/Shaders");
		let found = context.Pages.FindFactory(typeof(ShaderAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(ShaderAsset)));
	}

	[Test]
	public static void CheckedAgainstTheEnginesLibraryABrokenEditsProblemWithThePreviewKeptOneHistoryWithTheGrid()
	{
		if (!HaveCompiler())
			return; // no shader compiler: nothing to check against
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Code != null);
		Test.Assert(page.Text(.. scope .()) == bed.Source);
		Test.Assert(page.ErrorCount == 0, page.Found.IsEmpty ? "" : page.Found[0].Message);
		Test.Assert(page.Kind == "Unlit surface shader");
		Test.Assert(page.PropertyCount == 1);
		Test.Assert(!page.PreviewStale);

		// Broken: its problem, and the preview kept on the last version that compiled.
		let last = (uint32)(page.Code.Document.LineCount - 1);
		page.Code.SetCaret(.(last, 0));
		page.Code.Type("this is not hlsl\n");
		page.CheckNow();
		Test.Assert(page.ErrorCount > 0);
		Test.Assert(page.Kind.IsEmpty);
		Test.Assert(page.PreviewStale);

		// The grid's edit after the typing: one history, undone in order.
		page.Edit("Name", PropertyWrite(Sedulous.GUI.Variant("Paint")));
		let asset = page.AssetObject as ShaderAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.Name == "Paint");
		page.Commands.Undo(); // the name
		Test.Assert(((ShaderAsset)page.AssetObject).Name == "Colour");
		Test.Assert(page.Text(.. scope .()) != bed.Source);
		page.Commands.Undo(); // the typing
		Test.Assert(page.Text(.. scope .()) == bed.Source);
		page.CheckNow();
		Test.Assert(page.ErrorCount == 0);
		Test.Assert(!page.PreviewStale);
	}
}
