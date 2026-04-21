namespace Sedulous.Editor.Core;

using System;

/// Top-level editor plugin interface.
/// Each engine module provides one (e.g., PhysicsEditorPlugin, RenderEditorPlugin).
/// Discovered automatically via [EditorPlugin] attribute.
///
/// During Initialize, plugins register their extensions with EditorContext:
/// inspectors, gizmos, page factories, panel factories, asset creators, menu items.
interface IEditorPlugin : IDisposable
{
	/// Display name for this plugin.
	StringView Name { get; }

	/// Called after discovery, in priority order. Register extensions here.
	void Initialize(EditorContext context);

	/// Called before editor shutdown.
	void Shutdown();

	/// Called each frame. For plugins that need per-frame logic.
	void Update(float deltaTime);
}
