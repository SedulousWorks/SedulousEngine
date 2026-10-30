using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Image.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Image.Tests;

/// The image editor's registration, then the page from the image pages' markup
/// (Data/Editor/ImagePage.gml) over an image in a project: its picture decoded from the source file
/// and its pixels read, its facts read only, an edit of its colour space one undo step, a source
/// file that is not there said in the picture's place, and an asset that did not read.
class ImageEditorPageTests
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

	/// A project with a 4x2 picture ("dot.png": its top left pixel red, half transparent), an image
	/// over it ("Dot"), one over a file that is not there ("Gone") and one with nothing written
	/// ("Unread").
	class Bed
	{
		public String Dir = new .("scratch_image_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Dot;
		public Instance Gone;
		public Instance Unread;

		public this()
		{
			ImagePipeline.RegisterAll(); // read back by its type, as the editor registers it
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let picture = scope Sedulous.Image.Image(4, 2, .RGBA8);
			let pixels = picture.PixelData;
			for (int i < pixels.Length)
				pixels[i] = 255;
			pixels[1] = 0;
			pixels[2] = 0;
			pixels[3] = 128;
			Test.Assert(ImageIO.SaveImage(picture, PathJoin(Project.SourcesRoot(.. scope .()), "dot.png", .. scope .()), .PNG) case .Ok);
			let top = Project.SourceDb.RootGroup;
			let typeName = typeof(ImageAsset).GetFullName(.. scope .());
			Dot = top.CreateInstance("Dot", typeName);
			Gone = top.CreateInstance("Gone", typeName);
			Unread = top.CreateInstance("Unread", typeName);
			Test.Assert((Dot != null) && (Gone != null) && (Unread != null));
			let asset = scope ImageAsset();
			asset.FileName.Set("dot.png");
			Test.Assert(Dot.WriteObject(asset) case .Ok);
			asset.FileName.Set("gone.png");
			Test.Assert(Gone.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it.
		public ImageEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new ImageEditorPage(Context, services, instance);
		}
	}

	[Test]
	public static void TheFactoryReportsTheImageAssetPrimaryType()
	{
		let none = scope AssetPageServicesSource();
		let factory = scope ImageEditorPageFactory(none);
		Test.Assert(factory.PrimaryType == typeof(ImageAsset));
	}

	[Test]
	public static void RegisteringRoutesImageAssetToTheFactory()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		ImageEditor.Register(context, none);
		let found = context.Pages.FindFactory(typeof(ImageAsset));
		Test.Assert(found != null);
		Test.Assert(found.PrimaryType == typeof(ImageAsset));
		Test.Assert(ImageAssetEdit.PixelFormatLabel(.RGBA32F) == "RGBA32F (HDR)");
		Test.Assert(ImageAssetEdit.PixelFormatLabel(.R16F) == "?");
	}

	[Test]
	public static void TheSourceDecodedIntoThePictureItsPixelsReadItsFactsReadOnlyItsKindNamed()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Dot);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		// The kit's bar: save, undo, redo, discard, cook, rebuild.
		Test.Assert((page.Bar != null) && (page.Bar.Count == 6));
		Test.Assert(page.Preview != null);
		let view = page.Preview.View;
		Test.Assert(view.HasImage);
		Test.Assert((view.Pixels.Width == 4) && (view.Pixels.Height == 2));
		Test.Assert(view.ValueAt(0, 0, var pixel));
		Test.Assert((pixel.R == 255) && (pixel.G == 0) && (pixel.A == 128));
		Test.Assert(!page.Content.FindElement("image-empty").Displayed);
		Test.Assert((page.Content.FindElement("page-kind") as Sedulous.GUI.Label).Text == "Image");

		Test.Assert(page.SourceFile(.. scope .()) == "dot.png");
		Test.Assert(page.Fact("Dimensions", .. scope .()) == "4 x 2");
		Test.Assert(page.Fact("Pixel Format", .. scope .()) == "RGBA8");
		let facts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems(facts); }
		page.Facts.GetProperties("", facts);
		Test.Assert(!facts.IsEmpty);
		for (let info in facts)
			Test.Assert(info.ReadOnly);
		// The grid: the notices' section, the asset's, then the facts'.
		Test.Assert(page.Grid.Source == page.Sections);
		Test.Assert(page.Sections.SectionCount == 3);
		page.OnClose();
	}

	[Test]
	public static void AnEditOfTheColourSpaceIsOneUndoStepAndSaveWritesIt()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Dot);
		defer delete page;
		let asset = page.AssetObject as ImageAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.ColorSpace == .Srgb);
		page.Edit("ColorSpace", PropertyWrite(Sedulous.GUI.Variant((int64)ImageColorSpace.Linear)));
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(page.IsDirty);
		page.Commands.Undo();
		Test.Assert(asset.ColorSpace == .Srgb);
		var shown = page.Properties.GetValue("ColorSpace", 0);
		Test.Assert(shown.AsInt == (int64)ImageColorSpace.Srgb);
		shown.Dispose();
		page.Commands.Redo();
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
		let saved = bed.Dot.ReadObject();
		defer delete saved;
		let read = saved as ImageAsset;
		Test.Assert(read != null);
		Test.Assert(read.ColorSpace == .Linear);
		page.OnClose();
	}

	[Test]
	public static void ASourceFileThatIsNotThereIsSaidInThePicturesPlaceAnUnreadAssetInTheGrids()
	{
		let bed = scope Bed();
		let gone = bed.Open(bed.Gone);
		defer delete gone;
		Test.Assert(!gone.LoadFailed);
		Test.Assert(!gone.Preview.View.HasImage);
		Test.Assert(gone.Content.FindElement("image-empty").Displayed);
		Test.Assert(!gone.Content.FindElement("image-stage").Displayed);
		Test.Assert((gone.Content.FindElement("image-empty-text") as Sedulous.GUI.Label).Text == "gone.png is missing or did not decode.");
		gone.OnClose();

		let unread = bed.Open(bed.Unread);
		defer delete unread;
		Test.Assert(unread.LoadFailed);
		Test.Assert(unread.Content.FindElement("page-state").Displayed);
		Test.Assert(!unread.Grid.Displayed);
		Test.Assert(unread.Save() case .Err);
		unread.OnClose();
	}
}
