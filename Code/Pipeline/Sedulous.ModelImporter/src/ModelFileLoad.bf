using System;
using Sedulous.Model;
using Sedulous.Model.FBX;
using Sedulous.Model.GLTF;
using Sedulous.Model.IO;

namespace Sedulous.ModelImporter;

/// Loading a model file through every format this library knows.
///
/// Registration is scoped to the call rather than left standing, so loading a model from a
/// tool, a test or an import never depends on somebody else having registered first, and
/// never leaves a loader behind that outlives what registered it.
static class ModelFileLoad
{
	/// Loads the file, leaving the model's bounds calculated on success.
	public static ModelLoadResult Load(StringView path, Model outModel)
	{
		let gltf = scope GltfLoader();
		let fbx = scope FbxLoader();
		ModelLoaderRegistry.Register(gltf);
		ModelLoaderRegistry.Register(fbx);
		defer
		{
			ModelLoaderRegistry.Unregister(fbx);
			ModelLoaderRegistry.Unregister(gltf);
		}

		let loaded = ModelLoaderRegistry.Load(path, outModel);
		if (loaded == .Ok)
			outModel.CalculateBounds();
		return loaded;
	}
}
