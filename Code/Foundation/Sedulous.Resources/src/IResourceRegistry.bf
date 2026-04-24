namespace Sedulous.Resources;

using System;

/// Read-only interface for resolving resource GUIDs to file paths and vice versa.
/// Multiple registries can be stacked in the ResourceSystem.
/// Each registry has a name (used as protocol prefix) and a root path for
/// resolving relative asset paths to absolute filesystem paths.
interface IResourceRegistry
{
	/// Registry name, used as protocol prefix (e.g. "builtin", "project").
	StringView Name { get; }

	/// Root path for resolving relative asset paths.
	StringView RootPath { get; }

	/// Attempts to resolve a resource GUID to its file path.
	/// Returns true if the GUID was found; outPath is filled with the
	/// protocol-prefixed path (e.g. "builtin://primitives/cube.mesh").
	bool TryResolvePath(Guid id, String outPath);

	/// Attempts to resolve a file path to its resource GUID.
	/// Returns true if the path was found; outId receives the GUID.
	bool TryResolveId(StringView path, out Guid outId);

	/// Resolves a relative path to an absolute filesystem path.
	/// Returns true if the file exists at the resolved location.
	bool ResolvePath(StringView relativePath, String outAbsolutePath);
}
