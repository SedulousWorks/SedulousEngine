namespace Sedulous.Engine.Core;

using System;
using Sedulous.Resources;

/// Tracks the resolution state of a ResourceRef -> loaded Resource -> GPU upload.
/// Handles first load, deferred retry (resource not yet available), and hot reload
/// detection (resource ID changed after reload from disk).
///
/// Usage: call Resolve() each frame. When it returns true, the resource changed -
/// the caller should upload the new data to the GPU.
struct ResolvedResource<T> where T : Resource, class, delete
{
	/// The loaded resource handle (ref-counted).
	public ResourceHandle<T> Handle;

	/// The resource that is currently uploaded to the GPU.
	/// Compared against Handle.Resource to detect changes.
	public T BoundResource;

	/// Last resolved ref path hash - used to detect path-only ref changes.
	private int mLastRefHash;

	/// Attempts to resolve the given ResourceRef to a loaded resource.
	/// Returns true if the resource changed (first load, hot reload, or ref changed).
	/// The caller should upload to GPU when this returns true.
	public bool Resolve(ResourceSystem resources, ResourceRef @ref) mut
	{
		if (!@ref.IsValid)
		{
			// Ref cleared - release if we had something
			if (Handle.IsValid)
			{
				Handle.Release();
				BoundResource = null;
				return true;
			}
			return false;
		}

		// Compute a hash of the ref to detect any change (GUID or path)
		int refHash = @ref.Id.GetHashCode();
		if (@ref.HasPath)
			refHash = refHash * 31 + @ref.Path.GetHashCode();

		bool needsLoad = !Handle.IsValid;
		if (!needsLoad && refHash != mLastRefHash)
		{
			// Ref changed - force reload
			Handle.Release();
			needsLoad = true;
		}
		mLastRefHash = refHash;

		// Attempt to load if needed
		if (needsLoad)
		{
			if (resources.LoadByRef<T>(@ref) case .Ok(let handle))
				Handle = handle;
			else
				return false; // Not available yet - retry next frame
		}

		// Check if loaded resource differs from what's on the GPU
		let currentResource = Handle.Resource;
		if (currentResource != BoundResource)
		{
			BoundResource = currentResource;
			return true; // Changed - caller should upload
		}

		return false;
	}

	/// Releases the handle and clears bound state.
	public void Release() mut
	{
		if (Handle.IsValid)
			Handle.Release();
		BoundResource = null;
	}
}
