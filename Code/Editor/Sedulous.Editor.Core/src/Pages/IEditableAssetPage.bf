namespace Sedulous.Editor.Core;

using Sedulous.Resources;

/// Opt-in capability: a page whose backing data lives in the cached
/// `Resource` object the ResourceSystem hands out for a given URI.
///
/// When such a page closes with `IsDirty == true` the `EditorPageManager`
/// reverts the in-memory edits by calling
/// `ResourceSystem.ReloadResource(AssetRef)` before disposing the page -
/// otherwise the cached resource keeps the user's uncommitted mutations
/// and the next page opened against the same URI sees stale state.
///
/// Pages that don't edit a cached resource (read-only previews, error
/// pages, transient scenes) simply don't implement this interface.
///
/// Save-then-close: `IsDirty` is false after Save, so no reload fires
/// and the saved disk state matches the cache.
interface IEditableAssetPage
{
	/// Ref identifying this page's backing asset. Either component
	/// (Guid or Path) may be empty; an entirely-empty ref skips the
	/// reload on close. Returned by reference so the page's cached
	/// `ResourceRef` field isn't copied on every access (the Path
	/// component owns a heap String - copy-on-read would double-free).
	readonly ref ResourceRef AssetRef { get; }
}
