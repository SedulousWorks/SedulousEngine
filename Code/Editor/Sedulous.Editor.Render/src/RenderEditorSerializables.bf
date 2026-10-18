using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Render;

/// Registers the profile page's [Serializable] types (the preview scene each profile
/// remembers), so a settings store can rebuild them from a file.
[SerializableRegistry]
static class RenderEditorSerializables
{
	/// The generated registration, and the renames: these moved from Editor.Scene with the
	/// page, so the preview scenes saved before the move still load.
	public static void Register(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		for (let name in StringView[?]("ProfilePreviewSettings", "ProfilePreviewPref"))
			SerializableRenames.Register(scope $"Sedulous.Editor.Scene.{name}", scope $"Sedulous.Editor.Render.{name}");
	}
}
