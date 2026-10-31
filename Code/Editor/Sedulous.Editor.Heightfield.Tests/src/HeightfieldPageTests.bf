using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Heightfield.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Heightfield.Tests;

/// The heightfield page from the image pages' markup (Data/Editor/ImagePage.xml) over heightfields
/// in a project: its heights from the lowest to the highest, a sample in metres, its range's facts
/// following an edit; a blank heightfield said in the picture's place.
class HeightfieldPageTests
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

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A project with a 3x1 heightmap ("ridge.png": 64, 192, 128), a heightfield over it ("Ridge")
	/// and a blank one ("Flat"), both from -10 to 90 m.
	class Bed
	{
		public String Dir = new .("scratch_heightfield_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Ridge;
		public Instance Flat;

		public this()
		{
			HeightfieldPipeline.RegisterAll(); // read back by its type, as the editor registers it
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			uint8[3] heights = .(64, 192, 128);
			let map = scope Sedulous.Image.Image(3, 1, .R8, heights);
			Test.Assert(ImageIO.SaveImage(map, PathJoin(Project.SourcesRoot(.. scope .()), "ridge.png", .. scope .()), .PNG) case .Ok);
			let top = Project.SourceDb.RootGroup;
			let typeName = typeof(HeightfieldAsset).GetFullName(.. scope .());
			Ridge = top.CreateInstance("Ridge", typeName);
			Flat = top.CreateInstance("Flat", typeName);
			Test.Assert((Ridge != null) && (Flat != null));
			let asset = scope HeightfieldAsset();
			asset.MinY = -10.0f;
			asset.MaxY = 90.0f;
			Test.Assert(Flat.WriteObject(asset) case .Ok);
			asset.FileName.Set("ridge.png");
			Test.Assert(Ridge.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it.
		public HeightfieldEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new HeightfieldEditorPage(Context, services, instance);
		}
	}

	static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ItsHeightsFromTheLowestToTheHighestASampleInMetresItsRangesFactsFollowingAnEdit()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Ridge);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		let view = page.Preview.View;
		Test.Assert(view.HasImage);
		Test.Assert(view.ValueAt(0, 0, var pixel));
		Test.Assert(pixel.R == 0, "the lowest, black");
		Test.Assert(view.ValueAt(1, 0, out pixel));
		Test.Assert(pixel.R == 255, "the highest, white");
		Test.Assert(view.ValueAt(2, 0, out pixel));
		Test.Assert(pixel.R == 128);

		Test.Assert(page.SampleAt(1, 0, var sample));
		Test.Assert(sample == 192 * 257);
		Test.Assert(Near(page.HeightOf(65535), 90.0f));
		Test.Assert(Near(page.HeightOf(0), -10.0f));
		Test.Assert(!page.SampleAt(3, 0, ?));
		Test.Assert(page.Fact("Source Size", .. scope .()) == "3 x 1");
		Test.Assert(page.Fact("Highest", .. scope .()) == "65.29 m", "192/255 of the way from -10 to 90");

		page.Edit("MaxY", PropertyWrite(Sedulous.GUI.Variant(190.0)));
		Test.Assert(page.Fact("Highest", .. scope .()) == "140.59 m");
		page.Commands.Undo();
		Test.Assert(page.Fact("Highest", .. scope .()) == "65.29 m");
		Test.Assert(HeightfieldEditorPage.Metres(-0.5f, .. scope .()) == "-0.50 m");
		page.OnClose();
	}

	[Test]
	public static void ABlankHeightfieldSaidInThePicturesPlace()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Flat);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(!page.Preview.View.HasImage);
		Test.Assert(page.Content.FindElement("image-empty").Displayed);
		Test.Assert(page.SourceFile(.. scope .()) == "Not set");
		page.OnClose();
	}
}
