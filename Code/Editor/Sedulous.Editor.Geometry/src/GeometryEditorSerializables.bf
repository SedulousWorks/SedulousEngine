using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Geometry;

/// Registers the mesh page's [Serializable] types (its preview preferences), so a settings
/// store can rebuild them from a file.
[SerializableRegistry]
static class GeometryEditorSerializables
{
	/// The generated registration, and the renames: these moved from Editor.Scene with the
	/// page, so the preview materials saved before the move still load.
	public static void Register(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		for (let name in StringView[?]("MeshPreviewSettings", "MeshPreviewPref"))
			SerializableRenames.Register(scope $"Sedulous.Editor.Scene.{name}", scope $"Sedulous.Editor.Geometry.{name}");
	}
}
