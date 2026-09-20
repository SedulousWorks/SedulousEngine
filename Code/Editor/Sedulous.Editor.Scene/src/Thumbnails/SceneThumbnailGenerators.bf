using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

static class SceneThumbnailGenerators
{
	/// Registers the generators for every asset the scene editor can stage. The service
	/// owns them; `context` is borrowed by the ones that read source assets.
	public static void Register(ThumbnailService service, EditorContext context)
	{
		service.RegisterSceneGenerator(new MeshThumbnailGenerator());
		service.RegisterSceneGenerator(new MaterialThumbnailGenerator());
		service.RegisterSceneGenerator(new PrefabThumbnailGenerator(context));
		service.RegisterSceneGenerator(new SceneThumbnailGenerator(context));
		service.RegisterSceneGenerator(new ParticleThumbnailGenerator());
		service.RegisterSceneGenerator(new SkeletonThumbnailGenerator());
		service.RegisterSceneGenerator(new ModelManifestThumbnailGenerator(context));
	}
}
