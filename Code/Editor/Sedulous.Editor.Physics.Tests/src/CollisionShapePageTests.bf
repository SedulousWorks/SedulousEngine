using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Geometry;
using Sedulous.Physics.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Physics.Tests;

/// The collision shape page from the preview pages' markup (Data/Editor/PreviewPage.gml), no host
/// (so no preview): its source mesh a slot for what a mesh cooks to, each edit one undo step, no
/// mesh a notice, no collider said in the preview's place.
class CollisionShapePageTests
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

	[Test]
	public static void ItsSourceMeshASlotForWhatAMeshCooksToEachEditOneUndoStepNoMeshANoticeNoColliderSaid()
	{
		PhysicsPipeline.RegisterAll();
		let dir = "scratch_collision_page_project";
		RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		let context = scope EditorContext();
		context.SetProject(project);
		defer
		{
			context.SetProject(null);
			delete project;
			RemoveDirectoryRecursive(dir);
		}
		let shape = project.SourceDb.RootGroup.CreateInstance("Hull", typeof(CollisionShapeAsset).GetFullName(.. scope .()));
		Test.Assert(shape != null);
		Test.Assert(shape.WriteObject(scope CollisionShapeAsset()) case .Ok);

		let services = new AssetPageServices();
		services.LoadMarkup = new (path) => LoadMarkup(path);
		let page = scope CollisionShapeEditorPage(context, services, shape);
		Test.Assert(!page.LoadFailed);
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems(rows); }
		page.Properties.GetProperties("", rows);
		PropertyInfo mesh = null;
		for (let row in rows)
		{
			if (row.Name == "SourceMesh")
				mesh = row;
		}
		Test.Assert(mesh != null);
		Test.Assert(mesh.Kind == .Reference);
		Test.Assert(mesh.ReferenceType == typeof(StaticMeshSource));
		Test.Assert(!page.Notice("mesh", .. scope .()).IsEmpty);
		Test.Assert(page.Fact("Collider", .. scope .()) == "None: no source mesh");
		Test.Assert(!page.Pane.Showing);

		let crate = Guid(0x77, 0x1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		page.Edit("SourceMesh", PropertyWrite(Sedulous.GUI.Variant(crate.ToString(.. scope .()))));
		let edited = page.AssetObject as CollisionShapeAsset;
		Test.Assert(edited != null);
		Test.Assert(edited.SourceMesh == crate);
		Test.Assert(page.Notice("mesh", .. scope .()).IsEmpty);
		Test.Assert(page.IsDirty);
		page.Commands.Undo();
		Test.Assert(edited.SourceMesh.IsNil);
		Test.Assert(!page.Notice("mesh", .. scope .()).IsEmpty);
		page.OnClose();
	}

	/// A collider cooked before its mesh was cleared is not shown.
	[Test]
	public static void AColliderCookedBeforeItsMeshWasClearedIsNotShown()
	{
		let cooked = scope Sedulous.Physics.Resource.CollisionShape();
		cooked.Outline.Add(.(0, 0, 0));
		cooked.Outline.Add(.(1, 0, 0));
		cooked.Outline.Add(.(0, 1, 0));
		let mesh = Guid.Create();
		Test.Assert(CollisionShapeEditorPage.ShowsCollider(mesh, cooked));
		Test.Assert(!CollisionShapeEditorPage.ShowsCollider(.Empty, cooked), "cleared: the last cook's is not its");
		Test.Assert(!CollisionShapeEditorPage.ShowsCollider(mesh, null), "named, not cooked yet");
	}
}
