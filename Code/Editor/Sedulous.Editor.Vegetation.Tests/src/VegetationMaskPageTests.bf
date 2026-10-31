using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Vegetation.Resource;
using Sedulous.Vegetation.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation.Tests;

/// The vegetation mask page over its markup (Data/Editor/ImagePage.xml) and a scratch project,
/// without a host: a painted mask's planes one at a time, the density under the pointer, its size
/// read only; a plane added keeping those painted; a blank mask; an imported one's planes its image's
/// channels.
class VegetationMaskPageTests
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

	/// A project with a painted mask ("Grass": 4 x 2, two planes, the second a ramp), a blank one
	/// ("Fresh") and one imported from a 2 x 1 image ("Field", four planes).
	private class Bed
	{
		public String Dir = new .("scratch_vegetation_mask_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Grass;
		public Instance Fresh;
		public Instance Field;

		public this()
		{
			VegetationPipeline.RegisterAll(); // the instances' type, written and read back
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let typeName = typeof(VegetationMaskAsset).GetFullName(.. scope .());
			let top = Project.SourceDb.RootGroup;
			Grass = top.CreateInstance("Grass", typeName);
			Fresh = top.CreateInstance("Fresh", typeName);
			Field = top.CreateInstance("Field", typeName);
			Test.Assert((Grass != null) && (Fresh != null) && (Field != null));

			let mask = scope VegetationMaskAsset();
			mask.Width = 4;
			mask.Height = 2;
			mask.PlaneCount = 2;
			Test.Assert(Grass.WriteObject(mask) case .Ok);
			Test.Assert(Fresh.WriteObject(mask) case .Ok);
			uint8[16] densities = default;
			for (int i < 8)
				densities[8 + i] = (uint8)(i * 30); // plane 2: a ramp; plane 1: nothing
			densities[0] = 255;
			Test.Assert(Grass.WriteData(VegetationMaskSource.DensityStream, .(&densities[0], 16)) case .Ok);

			let picture = scope Sedulous.Image.Image(2, 1, .RGBA8);
			let rgba = picture.PixelData;
			uint8[8] texels = .(10, 20, 30, 40, 50, 60, 70, 80);
			for (int i < 8)
				rgba[i] = texels[i];
			let sources = Project.SourcesRoot(.. scope .());
			CreateDirectory(sources); // there already, or made
			Test.Assert(ImageIO.SaveImage(picture, PathJoin(sources, "field.png", .. scope .()), .PNG) case .Ok);
			let imported = scope VegetationMaskAsset();
			imported.FileName.Set("field.png");
			imported.PlaneCount = 4; // the cook keeps this many of its channels
			Test.Assert(Field.WriteObject(imported) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it (before the bed).
		public VegetationMaskPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new VegetationMaskPage(Context, services, instance);
		}
	}

	static bool ReadOnly(VegetationMaskPage page, StringView path)
	{
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		page.Properties.GetProperties("", rows);
		for (let info in rows)
		{
			if (info.Name == path)
				return info.ReadOnly;
		}
		Test.Assert(false, scope String()..AppendF("no row {}", path));
		return false;
	}

	[Test]
	public static void APaintedMasksPlanesOneAtATimeTheDensityUnderThePointerItsSizeReadOnly()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Grass);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Painted);
		Test.Assert(!page.Imported);
		Test.Assert(page.PlaneCount == 2);
		Test.Assert(page.PlaneChoice != null);
		Test.Assert(page.PlaneChoice.SelectedIndex == 0);
		Test.Assert(page.DensityAt(0, 0, let first));
		Test.Assert(first == 255);
		Test.Assert(page.Fact("Covered", .. scope .()) == "13%"); // one texel of eight

		page.ShowPlane(1);
		Test.Assert(page.ShownPlane == 1);
		Test.Assert(page.PlaneChoice.SelectedIndex == 1);
		Test.Assert(page.DensityAt(3, 1, let last));
		Test.Assert(last == 210); // the ramp's last
		Test.Assert(!page.DensityAt(4, 0, let off) && (off == 0)); // off the mask
		Test.Assert(page.Preview.View.HasImage);

		Test.Assert(ReadOnly(page, "Width"));
		Test.Assert(ReadOnly(page, "Height"));
		Test.Assert(!ReadOnly(page, "PlaneCount"));
		Test.Assert(!page.Notice("size", .. scope .()).IsEmpty);
		Test.Assert(page.Fact("Painted", .. scope .()) == "Yes");
	}

	[Test]
	public static void APlaneAddedKeepsThosePaintedOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Grass);
		defer delete page;
		page.ShowPlane(1);
		page.Edit("PlaneCount", PropertyWrite(Sedulous.GUI.Variant((int64)3)));
		Test.Assert(page.PlaneCount == 3);
		Test.Assert(page.ShownPlane == 1); // the plane shown stays
		Test.Assert(page.DensityAt(3, 1, let kept));
		Test.Assert(kept == 210);
		page.ShowPlane(2);
		Test.Assert(page.DensityAt(0, 0, let fresh));
		Test.Assert(fresh == 0); // a new plane starts empty

		page.Commands.Undo();
		Test.Assert(page.PlaneCount == 2);
		Test.Assert(page.ShownPlane == 1); // what is left of it
	}

	[Test]
	public static void ABlankMaskSaysNothingIsPaintedAndKeepsItsSizeEditable()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Fresh);
		defer delete page;
		Test.Assert(!page.Painted);
		Test.Assert(!page.Preview.View.HasImage);
		Test.Assert(!ReadOnly(page, "Width"));
		Test.Assert(page.Notice("size", .. scope .()).IsEmpty);
		Test.Assert(page.Fact("Painted", .. scope .()) == "Not yet");
	}

	/// Sedulous's cook keeps an imported mask's first PlaneCount channels (at most four), so its plane
	/// count stays editable where Raptor's is read only.
	[Test]
	public static void AnImportedMasksPlanesAreItsImagesChannelsItsSizeReadOnly()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Field);
		defer delete page;
		Test.Assert(page.Imported);
		Test.Assert(page.PlaneCount == 4);
		page.ShowPlane(2);
		Test.Assert(page.DensityAt(1, 0, let blue));
		Test.Assert(blue == 70); // the second texel's blue
		Test.Assert(ReadOnly(page, "Width"));
		Test.Assert(!ReadOnly(page, "PlaneCount"));
		Test.Assert(page.Fact("Source Size", .. scope .()) == "2 x 1");
	}
}
