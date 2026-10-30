using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Content;
using Sedulous.Geometry.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Geometry.Tests;

/// The mesh viewer from the preview pages' markup (Data/Editor/PreviewPage.gml) over a mesh in a
/// project, with no host (so no preview): not cooked, said in the preview's place; its choices on
/// the preview's bar after its own separator; its material kept with the project for the mesh; a
/// stat line split into its row.
class MeshPageTests
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

	/// A project holding a static mesh ("Crate"), never cooked.
	class Bed
	{
		public String Dir = new .("scratch_mesh_page_project") ~ delete _;
		public EditorProject Project;
		public Settings Store = new .() ~ delete _;
		/// What the registered factories make pages with: the markup. Declared before the context, so
		/// it outlives the factories the context's registry holds.
		public AssetPageServicesSource Services = new .(new () =>
			{
				let services = new AssetPageServices();
				services.LoadMarkup = new (path) => LoadMarkup(path);
				return services;
			}) ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public Instance Crate;

		public this()
		{
			GeometryPipeline.RegisterAll(); // read back by its type, as the editor registers it
			MeshEditor.Register(Context, Services); // and the preferences' section
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			Crate = Project.SourceDb.RootGroup.CreateInstance("Crate", typeof(StaticMeshAsset).GetFullName(.. scope .()));
			Test.Assert(Crate != null);
			Test.Assert(Crate.WriteObject(scope StaticMeshAsset()) case .Ok);
		}

		public ~this()
		{
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the mesh; the caller deletes it.
		public MeshEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new MeshEditorPage(Context, services, Crate, typeof(StaticMeshAsset));
		}
	}

	[Test]
	public static void NotCookedSaidInThePreviewsPlaceItsChoicesOnThePreviewsBarItsMaterialKeptWithTheProject()
	{
		let bed = scope Bed();
		Test.Assert(bed.Context.Pages.FindFactory(typeof(StaticMeshAsset)) != null);
		Test.Assert(bed.Context.Pages.FindFactory(typeof(SkinnedMeshAsset)) != null);

		let page = bed.Open();
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Pane != null);
		Test.Assert(page.Pane.Viewport == null, "no host here");
		Test.Assert(!page.Pane.Showing);
		Test.Assert(page.Content.FindElement("preview-empty").Displayed);
		Test.Assert((page.Content.FindElement("preview-empty-title") as Sedulous.GUI.Label).Text == "Not cooked yet");
		Test.Assert(page.Fact("Status", .. scope .()) == "Not cooked yet");

		// The material slot and the LOD choice follow the bar's own separator, the LOD hidden for a
		// mesh with no chain.
		Test.Assert(page.MaterialSlot != null);
		let own = page.Content.FindElement("preview-own");
		Test.Assert(own != null);
		let bar = own.Parent;
		Test.Assert(bar.GetChildIndex(page.MaterialSlot) == bar.GetChildIndex(own) + 1);
		Test.Assert(bar.GetChildIndex(page.LodChoice) == bar.GetChildIndex(own) + 2);
		Test.Assert(!page.LodChoice.Displayed);

		let wood = Guid(0x12, 0x34, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		page.SetPreviewMaterial(wood);
		Test.Assert(page.PreviewMaterial == wood);
		page.OnClose();
		delete page;
		let again = bed.Open();
		Test.Assert(again.PreviewMaterial == wood, "kept for this mesh");
		again.OnClose();
		delete again;
	}

	[Test]
	public static void AStatLineSplitIntoItsRow()
	{
		let name = scope String();
		let value = scope String();
		MeshStats.Split("Vertices: 1200", name, value);
		Test.Assert((name == "Vertices") && (value == "1200"));
		name.Clear();
		value.Clear();
		MeshStats.Split("  [2] material 1  |  90 indices", name, value);
		Test.Assert((name == "Submesh 2") && (value == "material 1  |  90 indices"));
		name.Clear();
		value.Clear();
		MeshStats.Split("  LOD 1: 400 triangles  |  below 0.250 coverage", name, value);
		Test.Assert((name == "LOD 1") && (value == "400 triangles  |  below 0.250 coverage"));
	}

	/// Both mesh factories, the static and the skinned, make their pages with the one source's
	/// services (the markup here): the skinned one no longer asks the static one's.
	[Test]
	public static void BothFactoriesMakeTheirPagesWithTheOneSourcesServices()
	{
		let bed = scope Bed();
		for (let type in Type[2](typeof(StaticMeshAsset), typeof(SkinnedMeshAsset)))
		{
			let factory = bed.Context.Pages.FindFactory(type);
			Test.Assert((factory != null) && (factory.PrimaryType == type));
			let page = factory.CreatePage(bed.Context, bed.Crate);
			defer delete page;
			Test.Assert((page as MeshEditorPage) != null);
			Test.Assert(((MeshEditorPage)page).Content != null, "made with the source's markup");
		}
	}
}
