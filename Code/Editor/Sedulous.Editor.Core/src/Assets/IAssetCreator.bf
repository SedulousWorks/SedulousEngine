namespace Sedulous.Editor.Core;

using System;
using Sedulous.VFS;

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

	/// Create a new default asset and write it through `mount` at the
	/// mount-relative `locator`. Implementations serialize to a stream and
	/// call `mount.Save(locator, ...)` - they must not touch the filesystem
	/// directly, so creation works for any writable mount, not just disk.
	/// Returns the resource's GUID on success so the caller can register it.
	Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context);
}
