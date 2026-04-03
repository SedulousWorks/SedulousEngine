using System;

namespace Sedulous.Resources;

/// Listener for resource hot-reload events.
interface IResourceChangeListener
{
	/// Called after a resource has been reloaded in-place from disk.
	void OnResourceReloaded(StringView path, Type resourceType, IResource resource);
}
