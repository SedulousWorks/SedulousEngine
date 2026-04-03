namespace Sedulous.Resources;

/// A handle to a resource that manages reference counting.
struct ResourceHandle<T> where T : IResource
{
	private T mResource;
	private bool mIsValid;

	/// Gets the underlying resource.
	public T Resource
	{
		get
		{
			if (!mIsValid || mResource?.RefCount <= 0)
				return default;
			return mResource;
		}
	}

	/// Returns true if this handle is valid.
	public bool IsValid => mIsValid && mResource?.RefCount > 0;

	/// Creates a handle to the specified resource.
	public this(T resource)
	{
		mResource = resource;
		mIsValid = resource != null;
		if (mIsValid)
			mResource.AddRef();
	}

	/// Releases the resource reference.
	public void Release() mut
	{
		if (mIsValid && mResource != null)
		{
			mResource.ReleaseRef();
			mResource = default;
			mIsValid = false;
		}
	}

	/// Adds a reference to the resource.
	public void AddRef() mut
	{
		if (mIsValid && mResource != null)
			mResource.AddRef();
	}
}
