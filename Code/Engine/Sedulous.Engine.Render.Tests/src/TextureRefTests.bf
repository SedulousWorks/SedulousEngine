using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// Sprite and decal texture references: the IDS have to survive a scene round trip. Resolving
/// one to a live product is the texture factory's own path.
class TextureRefTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void SpriteAndDecalTextureRefsRoundTripById()
	{
		let spriteTexture = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let decalTexture = Guid(11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);

		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let sprites = scene.AddSystem<SpriteComponentManager>();
			let decals = scene.AddSystem<DecalComponentManager>();
			let entity = scene.CreateEntity("Deco");

			let sprite = sprites.Add(entity);
			sprite.TextureAsset.SetId(spriteTexture);
			sprite.Size = .(2.0f, 3.0f);
			sprite.Additive = true;

			let decal = decals.Add(entity);
			decal.TextureAsset.SetId(decalTexture);
			decal.FadeEnd = 0.5f;

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		loaded.AddSystem<SpriteComponentManager>();
		loaded.AddSystem<DecalComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		SpriteComponent* sprite = null;
		loaded.GetSystem<SpriteComponentManager>().ForEach(scope [&] (component, entity) =>
			{
				sprite = component;
			});
		Test.Assert(sprite != null);
		Test.Assert(sprite.TextureAsset.Id == spriteTexture);
		Test.Assert(Near(sprite.Size.X, 2.0f));
		Test.Assert(sprite.Additive);
		// The raw view override is runtime only.
		Test.Assert(sprite.Texture == null);

		DecalComponent* decal = null;
		loaded.GetSystem<DecalComponentManager>().ForEach(scope [&] (component, entity) =>
			{
				decal = component;
			});
		Test.Assert(decal != null);
		Test.Assert(decal.TextureAsset.Id == decalTexture);
		Test.Assert(Near(decal.FadeEnd, 0.5f));
	}
}
