using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Materials;

/// Registers the material page's [Serializable] types (its preview preferences), so a settings
/// store can rebuild them from a file.
[SerializableRegistry]
static class MaterialsEditorSerializables
{
	/// The generated registration, and the renames: these moved from Editor.Scene with the
	/// page, so the preview choices saved before the move still load.
	public static void Register(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		for (let name in StringView[?]("MaterialPreviewSettings", "MaterialPreviewPref"))
			SerializableRenames.Register(scope $"Sedulous.Editor.Scene.{name}", scope $"Sedulous.Editor.Materials.{name}");
	}
}
