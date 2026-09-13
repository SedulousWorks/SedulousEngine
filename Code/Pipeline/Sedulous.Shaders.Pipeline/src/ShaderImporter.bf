using System;

namespace Sedulous.Shaders.Pipeline;

/// Filling a shader asset from a name and its two source paths.
///
/// NOT an IFileImporter: a shader takes two files, and dropping one of them says nothing about
/// where the other is. This is the authoring call an editor page makes once it has both.
static class ShaderImporter
{
	public static void Import(StringView name, StringView vertexFile, StringView fragmentFile,
		ShaderAsset outAsset)
	{
		outAsset.Name.Set(name);
		outAsset.FileName.Set(vertexFile);
		outAsset.FragmentFile.Set(fragmentFile);
	}
}
