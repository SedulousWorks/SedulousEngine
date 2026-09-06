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

	/// Whether this factory can build in two stages. Default false, so the manager builds
	/// synchronously through Create and a factory that has not opted in keeps working
	/// unchanged.
	bool SupportsAsync => false;

	/// Stage one, on a WORKER thread. A pure function of the instance's stored bytes.
	///
	/// It must not touch the manager, the GPU, or anything global and mutable: several of
	/// these run at once, on threads that own none of it. Null means the decode failed.
	Object DecodeStage(Instance instance)
	{
		return null;
	}

	/// Stage two, on the MAIN thread: turns what was decoded into the product. Uploads,
	/// child binds and registry writes belong here, because this is the thread that owns
	/// them. Null means the build failed.
	///
	/// It TAKES OWNERSHIP of the decoded intermediate.
	Object FinalizeStage(ResourceManager manager, Object decoded)
	{
		return null;
	}
}
