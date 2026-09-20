using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Physics.Resource;
using Sedulous.Physics.Pipeline;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Physics.Tests;

/// The collision shape editor's registration, labels and outline mesh.
class CollisionShapeEditorTests
{
	[Test]
	public static void TheFactoryReportsTheCollisionShapeAssetPrimaryType()
	{
		let factory = scope CollisionShapeEditorPageFactory(null, null);
		Test.Assert(factory.PrimaryType == typeof(CollisionShapeAsset));
		Test.Assert(CollisionShapeEditorPage.CookLabel(.ConvexHull) == "Convex hull (dynamic)");
		Test.Assert(CollisionShapeEditorPage.CookLabel(.TriangleMesh) == "Triangle mesh (static)");
	}

	[Test]
	public static void RegisteringRoutesTheAssetAndAddsTheThumbnailGenerator()
	{
		let context = scope EditorContext();
		CollisionShapeEditor.Register(context, null, null);
		let found = context.Pages.FindFactory(typeof(CollisionShapeAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(CollisionShapeAsset)));

		let generator = scope CollisionThumbnailGenerator();
		let names = scope List<StringView>();
		generator.AssetTypeNames(names);
		Test.Assert((names.Count == 1) && (names[0] == "CollisionShapeAsset"));
		Test.Assert(!generator.NeedsPrivateScene);
	}

	[Test]
	public static void TheOutlineBecomesALitTriangleMesh()
	{
		let shape = scope CollisionShape();
		shape.Outline.Add(.(0, 0, 0));
		shape.Outline.Add(.(1, 0, 0));
		shape.Outline.Add(.(0, 0, 1));
		shape.Outline.Add(.(0, 1, 0));
		shape.Outline.Add(.(1, 1, 0));
		shape.Outline.Add(.(0, 1, 1));
		shape.Outline.Add(.(5, 5, 5)); // a stray vertex, dropped
		let mesh = scope StaticMesh();
		Test.Assert(CollisionOutlineMesh.Build(shape, mesh));
		Test.Assert((mesh.VertexCount == 6) && (mesh.IndexCount == 6));
		Test.Assert(mesh.SubMeshes.Count == 1);
		Test.Assert(mesh.Bounds.Max.Y == 1.0f);

		// Too few vertices for a triangle: nothing.
		let flat = scope CollisionShape();
		flat.Outline.Add(.(0, 0, 0));
		flat.Outline.Add(.(1, 0, 0));
		Test.Assert(!CollisionOutlineMesh.Build(flat, mesh));
		Test.Assert(mesh.VertexCount == 0);
	}

	[Test]
	public static void StagingWithoutTheRenderManagersFails()
	{
		let generator = scope CollisionThumbnailGenerator();
		let stage = scope Scene();
		var framing = ThumbnailFraming();
		Test.Assert(generator.Stage(.(), stage, null, ref framing) == .Failed);
		generator.Unstage(stage);
	}
}
