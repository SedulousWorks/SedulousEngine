using System;

namespace Sedulous.Shaders.Pipeline;

/// Filling a shader asset from a name and its .hlsl path: the authoring call an editor page
/// makes. The entry points keep their defaults (VSMain and PSMain) unless the caller sets them.
static class ShaderImporter
{
	public static void Import(StringView name, StringView file, ShaderAsset outAsset)
	{
		outAsset.Name.Set(name);
		outAsset.FileName.Set(file);
	}
}
