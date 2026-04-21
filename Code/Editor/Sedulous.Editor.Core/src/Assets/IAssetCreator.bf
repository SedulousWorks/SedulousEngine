namespace Sedulous.Editor.Core;

using System;

/// Registered by plugins to add "Create > Material", "Create > Animation Clip", etc.
/// Populates File > New submenu and asset browser right-click > Create menu.
interface IAssetCreator
{
	/// Display name in menus (e.g. "Material", "Animation Clip").
	StringView DisplayName { get; }

	/// Category for grouping (e.g. "Rendering", "Animation"). Becomes a submenu.
	StringView Category { get; }

	/// Default file extension (e.g. ".mat", ".anim").
	StringView Extension { get; }

	/// Create a new default asset at the given path.
	Result<void> Create(StringView path, EditorContext context);
}
