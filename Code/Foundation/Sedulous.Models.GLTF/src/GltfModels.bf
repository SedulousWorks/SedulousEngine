using Sedulous.Models;

namespace Sedulous.Models.GLTF;

/// Static helper for initializing GLTF model loading support.
public static class GltfModels
{
	private static GltfLoader sLoader = null;

	/// Register the GLTF model loader with ModelLoaderFactory.
	public static void Initialize()
	{
		if (sLoader == null)
		{
			sLoader = new GltfLoader();
			ModelLoaderFactory.RegisterLoader(sLoader);
		}
	}

	/// Unregister and cleanup.
	public static void Shutdown()
	{
		if (sLoader != null)
		{
			ModelLoaderFactory.UnregisterLoader(sLoader);
			delete sLoader;
			sLoader = null;
		}
	}

	/// Check if GLTF model loading is initialized.
	public static bool IsInitialized => sLoader != null;
}
