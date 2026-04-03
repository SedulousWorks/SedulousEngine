namespace Sedulous.Models;

using System;
using System.IO;
using System.Collections;

/// Factory for loading models using registered loaders.
public static class ModelLoaderFactory
{
	private static List<IModelLoader> sLoaders = new .() ~ DeleteContainerAndItems!(_);

	/// Register a model loader.
	public static void RegisterLoader(IModelLoader loader)
	{
		if (loader != null && !sLoaders.Contains(loader))
			sLoaders.Add(loader);
	}

	/// Unregister a model loader.
	public static void UnregisterLoader(IModelLoader loader)
	{
		sLoaders.Remove(loader);
	}

	/// Get a loader that supports the given file extension.
	public static IModelLoader GetLoaderForExtension(StringView fileExtension)
	{
		for (let loader in sLoaders)
		{
			if (loader.SupportsExtension(fileExtension))
				return loader;
		}
		return null;
	}

	/// Load a model from file, automatically selecting the appropriate loader.
	public static ModelLoadResult LoadModel(StringView path, Model model)
	{
		let ext = Path.GetExtension(path, .. scope .());
		let loader = GetLoaderForExtension(ext);

		if (loader == null)
			return .UnsupportedFormat;

		return loader.Load(path, model);
	}

	/// Get number of registered loaders.
	public static int LoaderCount => sLoaders.Count;

	/// Check if any loaders are registered.
	public static bool HasLoaders => sLoaders.Count > 0;

	/// Cleanup all registered loaders.
	public static void Shutdown()
	{
		DeleteContainerAndItems!(sLoaders);
		sLoaders = new .();
	}
}
