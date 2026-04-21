namespace Sedulous.Editor.Core;

using Sedulous.Scenes;

/// Context passed to component inspectors. Provides access to the
/// command stack, scene, entity, and editor services.
struct InspectorContext
{
	/// Per-page undo stack - wire PropertyEditor changes here.
	public EditorCommandStack CommandStack;

	/// The scene containing the inspected entity.
	public Scene Scene;

	/// The entity being inspected.
	public EntityHandle Entity;

	/// The editor context for broader access.
	public EditorContext EditorContext;
}
