using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Play;

/// Registers play in editor's [Serializable] types (the Game tab's resolution choice), so a
/// settings store can rebuild them from a file.
[SerializableRegistry]
static class PlayEditorSerializables
{
	/// The generated registration, and the rename: the Game tab's settings moved from
	/// Editor.Scene with it, so the resolution chosen before the move still loads.
	public static void Register(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		SerializableRenames.Register("Sedulous.Editor.Scene.GamePageSettings", "Sedulous.Editor.Play.GamePageSettings");
	}
}
