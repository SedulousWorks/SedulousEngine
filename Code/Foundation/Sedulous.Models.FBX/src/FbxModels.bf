using Sedulous.Models;

namespace Sedulous.Models.FBX;

/// Static helper for initializing FBX model loading support.
public static class FbxModels
{
	private static FbxLoader sLoader = null;

	/// Register the FBX model loader with ModelLoaderFactory.
	public static void Initialize()
	{
		if (sLoader == null)
		{
			sLoader = new FbxLoader();
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

	/// Check if FBX model loading is initialized.
	public static bool IsInitialized => sLoader != null;
}
