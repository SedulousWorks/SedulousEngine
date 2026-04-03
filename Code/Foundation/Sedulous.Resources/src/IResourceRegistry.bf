namespace Sedulous.Resources;

using System;

/// Read-only interface for resolving resource GUIDs to file paths and vice versa.
/// Multiple registries can be stacked in the ResourceSystem.
interface IResourceRegistry
{
	/// Attempts to resolve a resource GUID to its file path.
	/// Returns true if the GUID was found; outPath is filled with the path.
	bool TryResolvePath(Guid id, String outPath);

	/// Attempts to resolve a file path to its resource GUID.
	/// Returns true if the path was found; outId receives the GUID.
	bool TryResolveId(StringView path, out Guid outId);
}
