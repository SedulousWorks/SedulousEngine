using System;

namespace Sedulous.Resources;

/// Interface for all resource types.
interface IResource
{
	/// Gets the unique identifier for this resource.
	Guid Id { get; }

	/// Gets the resource name.
	String Name { get; }

	/// Gets the current reference count.
	int RefCount { get; }

	/// Increments the reference count.
	void AddRef();

	/// Decrements the reference count. Deletes if count reaches zero.
	void ReleaseRef();
	
	void ReleaseLastRef();

	/// Decrements the reference count without deleting.
	int ReleaseRefNoDelete();
}
