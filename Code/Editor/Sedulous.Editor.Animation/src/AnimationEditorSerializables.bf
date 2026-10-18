using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Animation;

/// Registers the animation pages' [Serializable] types (their preview preferences), so a
/// settings store can rebuild them from a file.
[SerializableRegistry]
static class AnimationEditorSerializables
{
	/// The generated registration, and the renames: these moved from Editor.Scene with their
	/// pages, so the preview rigs saved before the move still load.
	public static void Register(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		for (let name in StringView[?]("ClipPreviewSettings", "ClipPreviewPref", "GraphPreviewSettings", "GraphPreviewPref"))
			SerializableRenames.Register(scope $"Sedulous.Editor.Scene.{name}", scope $"Sedulous.Editor.Animation.{name}");
	}
}
