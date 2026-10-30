using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Content;
using Sedulous.Materials.Pipeline;
using Sedulous.Texture.Resource;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials.Tests;

/// The material page from the preview pages' markup (Data/Editor/PreviewPage.gml) over a PBR
/// material in a project, with no host (so no preview): its rows laid out from its shader's table
/// (the material's, its properties, its textures), an edit one undo step, Discard Changes taking
/// them all back, and the preview's shape or mesh kept per material (the bar showing it is no pick).
class MaterialPageTests
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

	/// A project holding a PBR material ("Wood") and its editor settings.
	class Bed
	{
		public String Dir = new .("scratch_material_page_project") ~ delete _;
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
		public Instance Wood;

		public this()
		{
			MaterialEditor.Register(Context, Services); // the asset's types and the preferences' section
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			Wood = Project.SourceDb.RootGroup.CreateInstance("Wood", typeof(MaterialAsset).GetFullName(.. scope .()));
			Test.Assert(Wood != null);
			let asset = scope MaterialAsset();
			MaterialShaderLayout.SetBuiltInShader(asset.Source, .Pbr);
			Test.Assert(Wood.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the material; the caller deletes it.
		public MaterialEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new MaterialEditorPage(Context, services, Wood);
		}
	}

	static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5;

	static double FloatOf(Sedulous.GUI.PropertyBag rows, StringView path)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		return value.AsFloat;
	}

	static int64 IntOf(Sedulous.GUI.PropertyBag rows, StringView path)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		return value.AsInt;
	}

	[Test]
	public static void ItsRowsAreItsShadersTableTheMaterialsEachPropertyByItsTypeEachTextureASlot()
	{
		let bed = scope Bed();
		Test.Assert(bed.Context.Pages.FindFactory(typeof(MaterialAsset)) != null);
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Source != null);
		Test.Assert(page.Sections.SectionCount == 5, "notices, the material, properties, textures, facts (no field rows)");

		let material = page.MaterialRows;
		Test.Assert(material.FindInfo("shader") != null);
		Test.Assert(material.FindInfo("shader").Kind == .Reference);
		Test.Assert(material.FindInfo("builtIn").Visible, "on no shader asset: a built-in");
		Test.Assert(IntOf(material, "builtIn") == 0, "PBR");
		Test.Assert(material.FindInfo("blend").Choices.Count == 6);

		let properties = page.PropertyRows;
		Test.Assert(properties.FindInfo("BaseColor") != null);
		Test.Assert(properties.FindInfo("BaseColor").Kind == .Color);
		Test.Assert(properties.FindInfo("EmissiveColor") != null);
		Test.Assert(properties.FindInfo("EmissiveColor").Hint == "ColorHdr");
		Test.Assert(properties.FindInfo("EmissiveColor.intensity") != null);
		Test.Assert(properties.FindInfo("Metallic") != null);
		Test.Assert(properties.FindInfo("Metallic").HasRange);
		Test.Assert(Near(properties.FindInfo("Metallic").Max, 1.0));
		Test.Assert(properties.FindInfo("Metallic").Hint == "slider", "a slider over its range");

		let textures = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(textures); }
		page.TextureRows.GetProperties(default, textures);
		Test.Assert(!textures.IsEmpty);
		for (let texture in textures)
		{
			Test.Assert(texture.Kind == .Reference);
			Test.Assert(texture.ReferenceType == typeof(Texture), "a texture or a render texture");
		}
	}

	[Test]
	public static void ABuiltInSwitchedLaysTheRowsOutAsItsOwnAndItsUndoAsTheyWere()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		Test.Assert(page.PropertyRows.FindInfo("Metallic") != null);
		page.EditRow(page.MaterialRows, "builtIn", Sedulous.GUI.Variant((int64)1)); // Unlit
		page.Refresh();
		Test.Assert(page.Source.ShaderName == "unlit", page.Source.ShaderName);
		Test.Assert(page.PropertyRows.FindInfo("Metallic") == null, "PBR's rows gone with it");
		Test.Assert(page.PropertyRows.FindInfo("BaseColor") != null);
		page.Commands.Undo();
		page.Refresh();
		Test.Assert(page.PropertyRows.FindInfo("Metallic") != null);
	}

	[Test]
	public static void TheBuiltInRowOffersEachBuiltInPhongLaysTheMaterialOutAsItsOwnOneStep()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		let builtIn = page.MaterialRows.FindInfo("builtIn");
		Test.Assert(builtIn != null);
		Test.Assert(builtIn.Choices.Count == 3);
		Test.Assert(builtIn.Choices[2].Name == "Phong");

		page.EditRow(page.MaterialRows, "builtIn", Sedulous.GUI.Variant((int64)2));
		page.Refresh();
		Test.Assert(page.Source.ShaderName == "phong");
		Test.Assert(IntOf(page.MaterialRows, "builtIn") == 2);
		Test.Assert(page.PropertyRows.FindInfo("Shininess") != null);
		Test.Assert(page.PropertyRows.FindInfo("Metallic") == null);
		page.Commands.Undo();
		page.Refresh();
		Test.Assert(page.Source.ShaderName == "forward");
		Test.Assert(page.PropertyRows.FindInfo("Metallic") != null);
	}

	[Test]
	public static void AnEditIsOneUndoStepTheRowFollowingDiscardTakesThemAllBackThePreviewsShapeOrMeshKeptPerMaterial()
	{
		let bed = scope Bed();
		let page = bed.Open();
		let before = FloatOf(page.PropertyRows, "Metallic");
		page.EditRow(page.PropertyRows, "Metallic", Sedulous.GUI.Variant(0.75));
		page.Refresh();
		Test.Assert(page.IsDirty);
		Test.Assert(Near(FloatOf(page.PropertyRows, "Metallic"), 0.75));
		page.Commands.Undo();
		page.Refresh();
		Test.Assert(Near(FloatOf(page.PropertyRows, "Metallic"), before));

		// The pipeline state, one step.
		page.EditRow(page.MaterialRows, "cull", Sedulous.GUI.Variant((int64)0));
		page.Refresh();
		Test.Assert(IntOf(page.MaterialRows, "cull") == 0);
		page.Commands.Undo();
		page.Refresh();
		Test.Assert(IntOf(page.MaterialRows, "cull") != 0);

		// A colour's intensity, the part written into its w.
		page.EditRow(page.PropertyRows, "EmissiveColor.intensity", Sedulous.GUI.Variant(4.0));
		page.Refresh();
		Test.Assert(Near(MaterialSourceEdit.ReadFloat4(page.Source, "EmissiveColor").W, 4.0));
		page.Commands.Undo();

		// Discard Changes (the bar's, as the old toolbar had it) takes every unsaved edit back.
		page.EditRow(page.PropertyRows, "Metallic", Sedulous.GUI.Variant(0.25));
		page.EditRow(page.MaterialRows, "cull", Sedulous.GUI.Variant((int64)0));
		page.DiscardChanges();
		page.Refresh();
		Test.Assert(!page.IsDirty);
		Test.Assert(!page.Commands.CanUndo);
		Test.Assert(Near(FloatOf(page.PropertyRows, "Metallic"), before));
		Test.Assert(IntOf(page.MaterialRows, "cull") != 0);

		page.SetPreviewShape(2); // the plane
		delete page;
		let again = bed.Open();
		Test.Assert(again.PreviewShape == 2);

		// A mesh picked is kept too: the page showing the kept choice on its bar (the shape box set
		// from code) is no shape picked, which would put the mesh away.
		let mesh = Guid(0x1234, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x56);
		again.SetPreviewMesh(mesh);
		delete again;
		let third = bed.Open();
		Test.Assert(third.PreviewMesh == mesh);
		third.Refresh(); // the bar shown again
		delete third;
		let fourth = bed.Open();
		defer delete fourth;
		Test.Assert(fourth.PreviewMesh == mesh);

		// The user's pick of a shape is one, and puts the mesh away.
		Test.Assert(fourth.ShapeChoice != null);
		fourth.ShapeChoice.SelectByUser(3); // the cylinder
		Test.Assert(fourth.PreviewShape == 3);
		Test.Assert(fourth.PreviewMesh.IsNil);
	}

	/// A gesture's previews reach the source as they go (the preview built from it), one undo step
	/// at its commit, from the source before it; a cancel takes them back.
	[Test]
	public static void AGesturesPreviewsReachTheSourceAsTheyGoOneUndoStepAtItsCommitACancelTakesThemBack()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		let properties = page.PropertyRows;
		let before = MaterialSourceEdit.ReadFloat(page.Source, "Roughness");
		// As a slider's drag: begun, previewed twice, committed.
		properties.BeginEdit("Roughness");
		properties.PreviewEdit("Roughness", PropertyWrite(Sedulous.GUI.Variant(0.3)));
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), 0.3), "live: the preview built from it");
		properties.PreviewEdit("Roughness", PropertyWrite(Sedulous.GUI.Variant(0.4)));
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), 0.4));
		Test.Assert(!page.Commands.CanUndo, "no step while it goes");
		properties.CommitEdit("Roughness", PropertyWrite(Sedulous.GUI.Variant(0.4)));
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), 0.4));
		page.Commands.Undo(); // the gesture's one step, back to before it
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), before));
		Test.Assert(!page.Commands.CanUndo);

		// Given up with Escape: the source as it was.
		properties.BeginEdit("Roughness");
		properties.PreviewEdit("Roughness", PropertyWrite(Sedulous.GUI.Variant(0.9)));
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), 0.9));
		properties.CancelEdit("Roughness");
		Test.Assert(Near(MaterialSourceEdit.ReadFloat(page.Source, "Roughness"), before));
		Test.Assert(!page.Commands.CanUndo);
	}

	[Test]
	public static void AShaderThatHasNotCookedIsRefusedSayingSoTheMaterialKeepsItsOwn()
	{
		let bed = scope Bed();
		// A shader asset with no cooked product yet (never saved, or broken).
		let shader = bed.Project.SourceDb.RootGroup.CreateInstance("Glow", typeof(MaterialAsset).GetFullName(.. scope .()));
		Test.Assert(shader != null);
		let notices = scope List<String>();
		defer { ClearAndDeleteItems!(notices); }
		bed.Context.OnNotice = new [=notices] (kind, message) => { notices.Add(new String(message)); };
		let page = bed.Open();
		defer delete page;
		page.EditRow(page.MaterialRows, "shader", Sedulous.GUI.Variant(shader.Id.ToString(.. scope .())));
		Test.Assert(page.Source.ShaderId.IsNil, "refused: still the built-in PBR");
		Test.Assert(!page.Commands.CanUndo);
		Test.Assert(notices.Count == 1);
		Test.Assert(notices[0].Contains("has not cooked", true));
	}
}
