using System;
using Sedulous.Content;

namespace Sedulous.Resource;

/// Builds a runtime product from a stored instance. One factory per product type.
interface IResourceFactory
{
	/// The type this builds, as the stable id the manager keys factories on.
	uint64 ProductTypeId { get; }

	/// Builds the product. THE HANDLE TAKES OWNERSHIP of what comes back; null is a
	/// failure.
	///
	/// A composite resource resolves its children through the manager, and doing so
	/// records a dependency edge automatically, so reloading a child reloads whatever was
	/// built from it.
	Object Create(ResourceManager manager, Instance instance);
}
