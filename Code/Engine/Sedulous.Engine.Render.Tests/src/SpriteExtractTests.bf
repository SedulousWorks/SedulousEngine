using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// Billboard extraction, and where a post tonemap sprite lands.
class SpriteExtractTests
{
	/// A world space panel wants its AUTHORED colours and still wants to be occluded, which is
	/// what the post tonemap category is for.
	[Test]
	public static void PostTonemapSpritesLandInTheWorldUiCategory()
	{
		let scene = scope Scene("world");
		let sprites = scene.AddSystem<SpriteComponentManager>();

		// Extraction only stores the view, so a bare null backed one is enough.
		let view = scope NullTextureView();

		let entity = scene.CreateEntity("panel");
		let sprite = sprites.Add(entity);
		sprite.Texture = view;
		sprite.PostTonemap = true;
		sprite.Orientation = .EntityOriented;
		scene.UpdateTransforms();

		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractSpritesInto(scene, snapshot, 1);
			Test.Assert(snapshot.Size == 1);
			let data = (SpriteRenderData)snapshot.Items[0];
			Test.Assert(data.Category == RenderCategories.WorldUI);
			Test.Assert(data.PostTonemap);

			let categories = CategoryRegistry.Instance;
			Test.Assert(categories.Affinity(data.Category) == .PostTonemap);
			Test.Assert(categories.Sort(data.Category) == .BackToFront);
		}

		// The default path stays transparent.
		sprite.PostTonemap = false;
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractSpritesInto(scene, snapshot, 1);
			Test.Assert(snapshot.Size == 1);
			Test.Assert(snapshot.Items[0].Category == RenderCategories.Transparent);
		}
	}
}
