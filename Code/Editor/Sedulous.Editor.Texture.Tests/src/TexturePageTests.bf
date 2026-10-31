using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Texture;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Texture.Tests;

/// The texture page from the image pages' markup (Data/Editor/ImagePage.xml) over a texture in a
/// project: a preset from the bar's menu one undo step however many settings it moves; Usage
/// setting the colour space in the same step, and a colour space that disagrees with it a notice;
/// what it says of its source read only.
class TexturePageTests
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

	/// A project with a 4x4 opaque picture ("bricks.png") and a texture over it ("Bricks").
	class Bed
	{
		public String Dir = new .("scratch_texture_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Bricks;

		public this()
		{
			TexturePipeline.RegisterAll(); // read back by its type, as the editor registers it
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let picture = scope Sedulous.Image.Image(4, 4, .RGBA8);
			let pixels = picture.PixelData;
			for (int i < pixels.Length)
				pixels[i] = (uint8)(((i % 4) == 3) ? 255 : (i * 7));
			Test.Assert(ImageIO.SaveImage(picture, PathJoin(Project.SourcesRoot(.. scope .()), "bricks.png", .. scope .()), .PNG) case .Ok);
			Bricks = Project.SourceDb.RootGroup.CreateInstance("Bricks", typeof(TextureAsset).GetFullName(.. scope .()));
			Test.Assert(Bricks != null);
			let asset = scope TextureAsset();
			asset.FileName.Set("bricks.png");
			asset.SetupFor3D();
			Test.Assert(Bricks.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the texture; the caller deletes it.
		public TextureEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new TextureEditorPage(Context, services, Bricks);
		}
	}

	[Test]
	public static void APresetFromTheBarsMenuIsOneUndoStepHoweverManySettingsItMoves()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.PresetButton != null);
		Test.Assert(page.PresetButton.Menu.ItemCount == TextureEditorPage.sPresets.Count);
		let asset = page.AssetObject as TextureAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.GenerateMipmaps);
		Test.Assert(asset.WrapU == .Repeat);

		Test.Assert(page.ApplyPreset("UI"));
		Test.Assert(!asset.GenerateMipmaps);
		Test.Assert(asset.WrapU == .ClampToEdge);
		Test.Assert(page.IsDirty);
		Test.Assert(page.Fact("Mip Levels", .. scope .()) == "1");
		page.Commands.Undo();
		Test.Assert(asset.GenerateMipmaps);
		Test.Assert(asset.WrapU == .Repeat);
		Test.Assert(page.Fact("Mip Levels", .. scope .()) == "3", "4x4, 2x2, 1x1");
		Test.Assert(!page.Commands.CanUndo);
		Test.Assert(!page.ApplyPreset("No Such Preset"));
		page.OnClose();
	}

	[Test]
	public static void UsageSetsTheColourSpaceInTheSameStepATextureWhoseTwoDisagreeSaysSo()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		let asset = page.AssetObject as TextureAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.ColorSpace == .Srgb);
		Test.Assert(page.Notice("colorSpace", .. scope .()).IsEmpty);

		page.Edit("Usage", PropertyWrite(Sedulous.GUI.Variant((int64)SourceUsage.Normal)));
		Test.Assert(asset.Usage == .Normal);
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(page.Notice("colorSpace", .. scope .()).IsEmpty);

		// The colour space overridden to sRGB on a normal map: the notice says why not.
		page.Edit("ColorSpace", PropertyWrite(Sedulous.GUI.Variant((int64)ImageColorSpace.Srgb)));
		Test.Assert(!page.Notice("colorSpace", .. scope .()).IsEmpty);

		// Each was one step: two undos put both back.
		page.Commands.Undo();
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(page.Notice("colorSpace", .. scope .()).IsEmpty);
		page.Commands.Undo();
		Test.Assert(asset.Usage == .Color);
		Test.Assert(asset.ColorSpace == .Srgb);
		Test.Assert(!page.Commands.CanUndo);

		Test.Assert(page.SourceFile(.. scope .()) == "bricks.png");
		Test.Assert(page.Fact("Size", .. scope .()) == "4 x 4  (LDR)");
		Test.Assert(!page.Fact("Cooks To", .. scope .()).IsEmpty);
		page.OnClose();
	}
}
