using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Fonts.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Fonts.Tests;

/// The font page from the image pages' markup (Data/Editor/ImagePage.xml) over a font in a project:
/// its atlas baked and shown with its facts; the ramp's sizes a row of its own, one undo step, text
/// that is no list refused; the row gone while a distance field bakes one size.
class FontPageTests
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

	/// A project holding Roboto ("roboto.ttf") as a raster ramp of 12 and 16 over printable ASCII.
	class Bed
	{
		public String Dir = new .("scratch_font_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Roboto;

		public this()
		{
			FontsPipeline.RegisterAll(); // read back by its type, as the editor registers it
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let data = scope String();
			Test.Assert(DataRoot(data));
			let bytes = scope List<uint8>();
			Test.Assert(System.IO.File.ReadAll(PathJoin(data, "Engine/Fonts/roboto/Roboto-Bold.ttf", .. scope .()), bytes) case .Ok);
			Test.Assert(System.IO.File.WriteAll(PathJoin(Project.SourcesRoot(.. scope .()), "roboto.ttf", .. scope .()), bytes) case .Ok);
			Roboto = Project.SourceDb.RootGroup.CreateInstance("Roboto", typeof(FontAsset).GetFullName(.. scope .()));
			Test.Assert(Roboto != null);
			let asset = scope FontAsset();
			asset.FileName.Set("roboto.ttf");
			asset.Mode = .RasterRamp;
			asset.Sizes.Clear();
			asset.Sizes.Add(12.0f);
			asset.Sizes.Add(16.0f);
			asset.FirstCodepoint = 32;
			asset.LastCodepoint = 126;
			Test.Assert(Roboto.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the font; the caller deletes it.
		/// What the page last asked the picker to show (ours).
		public PickerRequest Picked = null ~ delete _;

		public FontEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Pick = new [=this] (request) =>
				{
					delete Picked;
					Picked = request;
				};
			return new FontEditorPage(Context, services, Roboto);
		}
	}

	static String Sizes(FontEditorPage page, String outText)
	{
		var value = page.Ramp.GetValue("sizes", 0);
		outText.Append(value.AsString);
		value.Dispose();
		return outText;
	}

	[Test]
	public static void ItsAtlasBakedAndShownTheRampsSizesARowOfItsOwnOneUndoStepTextThatIsNoListRefused()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Preview.View.HasImage);
		Test.Assert(page.PreviewGlyphs > 50);
		Test.Assert(page.SourceFile(.. scope .()) == "roboto.ttf");
		Test.Assert(!page.Fact("Atlas", .. scope .()).IsEmpty);
		Test.Assert(Sizes(page, .. scope .()) == "12, 16");

		let asset = page.AssetObject as FontAsset;
		Test.Assert(asset != null);
		Test.Assert(!page.SetSizes("12, big"));
		Test.Assert(!page.Notice("sizes", .. scope .()).IsEmpty);
		Test.Assert(Sizes(page, .. scope .()) == "12, 16");
		Test.Assert(!page.Commands.CanUndo);

		Test.Assert(page.SetSizes("10 20.5"));
		Test.Assert(page.Notice("sizes", .. scope .()).IsEmpty);
		Test.Assert(asset.Sizes.Count == 2);
		Test.Assert(Math.Abs(asset.Sizes[1] - 20.5f) < 1e-4f);
		Test.Assert(Sizes(page, .. scope .()) == "10, 20.5");
		page.Commands.Undo();
		Test.Assert(asset.Sizes.Count == 2);
		Test.Assert(asset.Sizes[1] == 16.0f);
		Test.Assert(Sizes(page, .. scope .()) == "12, 16");

		// A distance field bakes one size: the ramp's row goes while it does.
		page.Edit("Mode", PropertyWrite(Sedulous.GUI.Variant((int64)FontBakeMode.DistanceField)));
		Test.Assert(!page.Ramp.FindInfo("sizes").Visible);
		page.Commands.Undo();
		Test.Assert(page.Ramp.FindInfo("sizes").Visible);
		page.OnClose();
	}

	[Test]
	public static void BrowseOnTheSourceRowPicksAnotherFontFileOfTheProjectsTheRelinkIsOneUndoStep()
	{
		let bed = scope Bed();
		let sources = bed.Project.SourcesRoot(.. scope .());
		let faces = PathJoin(sources, "faces", .. scope .());
		Test.Assert(CreateDirectory(faces));
		let notAFont = scope List<uint8>() { (uint8)'x' };
		Test.Assert(WriteFile(PathJoin(faces, "bold.otf", .. scope .()), notAFont) case .Ok);
		Test.Assert(WriteFile(PathJoin(sources, "readme.txt", .. scope .()), notAFont) case .Ok);
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		page.BrowseSource();
		Test.Assert((bed.Picked != null) && (bed.Picked.OnPicked != null));
		Test.Assert(bed.Picked.Current == "roboto.ttf");
		Test.Assert(bed.Picked.Items.Count == 2); // the font files, not the text
		Test.Assert(bed.Picked.Items[0].Key == "faces/bold.otf");
		Test.Assert(bed.Picked.Items[1].Key == "roboto.ttf");
		bed.Picked.OnPicked("faces/bold.otf");
		Test.Assert(page.SourceFile(.. scope .()) == "faces/bold.otf");
		Test.Assert(page.Commands.CanUndo);
		page.Commands.Undo();
		Test.Assert(page.SourceFile(.. scope .()) == "roboto.ttf");
	}
}
