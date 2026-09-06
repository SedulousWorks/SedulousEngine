using Win32.System.Com;
using System;
using Win32.Foundation;
using System.Diagnostics;
using Win32.Graphics.Direct3D12;
namespace Win32;

public static
{
	public static Guid __uuidof<T>() where T : IUnknown
	{
		return T.IID;
	}

	public static Guid __uuidof<T>(T* object) where T : IUnknown
	{
		return T.IID;
	}

	public static Guid __uuidof<T>(ComPtr<T> object) where T : IUnknown
	{
		return T.IID;
	}
}

// Copied from https://github.com/tannergooding/terrafx.interop.windows/blob/main/sources/Interop/Windows/ComPtr%601.cs
struct ComPtr<T> : IDisposable where T : IUnknown
{
	private T* mPtr;
	private uint32 mRefCount = 0;

	// Increments the reference count for the current COM object, if any
	private uint32 InternalAddRef() mut
	{
		T* ptr = mPtr;
		if (ptr != null)
		{
			mRefCount = ((IUnknown*)ptr).AddRef();
		}

		return 0;
	}

	// Decrements the reference count for the current COM object, if any
	private uint32 InternalRelease() mut
	{
		T* ptr = mPtr;
		if (ptr != null)
		{
			mPtr = null;

			mRefCount = ((IUnknown*)ptr).Release();
		}

		return mRefCount;
	}

	/// <summary>Creates a new <see cref="ComPtr{T}"/> instance from a raw pointer and increments the ref count.</summary>
	/// <param name="ptr">The raw pointer to wrap.</param>
	public this(T* ptr)
	{
		mPtr = ptr;
		 InternalAddRef();
	}

	/// <summary>Creates a new <see cref="ComPtr{T}"/> instance from a second one and increments the ref count.</summary>
	/// <param name="other">The other <see cref="ComPtr{T}"/> instance to copy.</param>
	public this(Self other)
	{
		mPtr = other.mPtr;
		 InternalAddRef();
	}

	/// <summary>Converts a raw pointer to a new <see cref="ComPtr{T}"/> instance and increments the ref count.</summary>
	/// <param name="ptr">The raw pointer to wrap.</param>
	[Inline]
	public static implicit operator ComPtr<T>(T* ptr)
		=> ComPtr<T>(ptr);

	/// <summary>Unwraps a <see cref="ComPtr{T}"/> instance and returns the internal raw pointer.</summary>
	/// <param name="other">The <see cref="ComPtr{T}"/> instance to unwrap.</param>
	[Inline]
	public static implicit operator T*(ComPtr<T> other)
		=> other.Get();

	/// <summary>Gets the currently wrapped raw pointer to a COM object.</summary>
	/// <returns>The raw pointer wrapped by the current <see cref="ComPtr{T}"/> instance.</returns>
	[Inline]
	public T* Get() => mPtr;

	[Inline]
	public T* GetInterface() => mPtr;

	/// <summary>Gets the address of the current <see cref="ComPtr{T}"/> instance as a raw <typeparamref name="T"/> double pointer. This method is only valid when the current <see cref="ComPtr{T}"/> instance is on the stack or pinned.
	/// </summary>
	/// <returns>The raw pointer to the current <see cref="ComPtr{T}"/> instance.</returns>
	[Inline]
	public T** GetAddressOf() mut
	{
		return (T**)&mPtr;
	}

	/// <summary>Releases the current COM object in use and gets the address of the <see cref="ComPtr{T}"/> instance as a raw <typeparamref name="T"/> double pointer. This method is only valid when the current <see cref="ComPtr{T}"/> instance is on the stack or pinned.</summary>
	/// <returns>The raw pointer to the current <see cref="ComPtr{T}"/> instance.</returns>
	[Inline]
	public T** ReleaseAndGetAddressOf() mut
	{
		InternalRelease();
		return GetAddressOf();
	}

	/// <summary>Swaps the current COM object reference with that of a given <see cref="ComPtr{T}"/> instance.</summary>
	/// <param name="other">The target <see cref="ComPtr{T}"/> instance to swap with the current one.</param>
	[Inline]
	public void Swap(ComPtr<T>* other) mut
	{
		T* tmp = mPtr;
		mPtr = other.mPtr;
		other.mPtr = tmp;
	}

	/// <summary>Swaps the current COM object reference with that of a given <see cref="ComPtr{T}"/> instance.</summary>
	/// <param name="other">The target <see cref="ComPtr{T}"/> instance to swap with the current one.</param>
	[Inline]
	public void Swap(ref ComPtr<T> other) mut
	{
		T* tmp = mPtr;
		mPtr = other.mPtr;
		other.mPtr = tmp;
	}

	/// <summary>Converts the current object reference to type <typeparamref name="U"/> and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <typeparam name="U">The interface type to use to try casting the current COM object.</typeparam>
	/// <param name="ptr">A raw pointer to the target <see cref="ComPtr{T}"/> value to write to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target type <typeparamref name="U"/>.</returns>
	/// <remarks>This method will automatically release the target COM object pointed to by <paramref name="p"/>, if any.</remarks>
	public HRESULT As<U>(ComPtr<U>* ptr) where U : IUnknown
	{
		return ((IUnknown*)mPtr).QueryInterface(__uuidof<U>(), (void**)ptr.ReleaseAndGetAddressOf());
	}

	/// <summary>Converts the current object reference to type <typeparamref name="U"/> and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <typeparam name="U">The interface type to use to try casting the current COM object.</typeparam>
	/// <param name="other">A reference to the target <see cref="ComPtr{T}"/> value to write to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target type <typeparamref name="U"/>.</returns>
	/// <remarks>This method will automatically release the target COM object pointed to by <paramref name="other"/>, if any.</remarks>
	public HRESULT As<U>(ref ComPtr<U> other) where U : IUnknown
	{
		U* ptr = null;
		HRESULT result = ((IUnknown*)mPtr).QueryInterface(__uuidof<U>(), (void**)&ptr);

		other.Attach(ptr);

		return result;
	}

	/// <summary>Converts the current object reference to a type indicated by the given IID and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <param name="riid">The IID indicating the interface type to convert the COM object reference to.</param>
	/// <param name="other">A raw pointer to the target <see cref="ComPtr{T}"/> value to write to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target IID.</returns>
	/// <remarks>This method will automatically release the target COM object pointed to by <paramref name="other"/>, if any.</remarks>
	public HRESULT AsIID(in Guid riid, ComPtr<IUnknown>* other)
	{
		return ((IUnknown*)mPtr).QueryInterface(riid, (void**)other.ReleaseAndGetAddressOf());
	}

	/// <summary>Converts the current object reference to a type indicated by the given IID and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <param name="riid">The IID indicating the interface type to convert the COM object reference to.</param>
	/// <param name="other">A reference to the target <see cref="ComPtr{T}"/> value to write to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target IID.</returns>
	/// <remarks>This method will automatically release the target COM object pointed to by <paramref name="other"/>, if any.</remarks>
	public HRESULT AsIID(in Guid riid, ref ComPtr<IUnknown> other)
	{
		IUnknown* ptr = null;
		HRESULT result = ((IUnknown*)mPtr).QueryInterface(riid, (void**)&ptr);

		other.Attach(ptr);
		return result;
	}

	/// <summary>Releases the current COM object, if any, and replaces the internal pointer with an input raw pointer.</summary>
	/// <param name="ptr">The input raw pointer to wrap.</param>
	/// <remarks>This method will release the current raw pointer, if any, but it will not increment the references for <paramref name="other"/>.</remarks>
	public void Attach(T* ptr) mut
	{
		if (mPtr != null)
		{
			var @ref = ((IUnknown*)mPtr).Release();
			Debug.Assert((@ref != 0) || (mPtr != ptr));
		}
		mPtr = ptr;
	}

	/// <summary>Returns the raw pointer wrapped by the current instance, and resets the current <see cref="ComPtr{T}"/> value.</summary>
	/// <returns>The raw pointer wrapped by the current <see cref="ComPtr{T}"/> value.</returns>
	/// <remarks>This method will not change the reference count for the COM object in use.</remarks>
	public T* Detach() mut
	{
		T* ptr = mPtr;
		mPtr = null;
		return ptr;
	}

	/// <summary>Increments the reference count for the current COM object, if any, and copies its address to a target raw pointer.</summary>
	/// <param name="ptr">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>This method always returns <see cref="S_OK"/>.</returns>
	public HRESULT CopyTo(T** ptr) mut
	{
		InternalAddRef();
		*ptr = mPtr;
		return S_OK;
	}

	/// <summary>Increments the reference count for the current COM object, if any, and copies its address to a target <see cref="ComPtr{T}"/>.</summary>
	/// <param name="other">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>This method always returns <see cref="S_OK"/>.</returns>
	public HRESULT CopyTo(ComPtr<T>* other) mut
	{
		InternalAddRef();
		*other.ReleaseAndGetAddressOf() = mPtr;
		return S_OK;
	}

	/// <summary>Increments the reference count for the current COM object, if any, and copies its address to a target <see cref="ComPtr{T}"/>.</summary>
	/// <param name="other">The target reference to copy the address of the current COM object to.</param>
	/// <returns>This method always returns <see cref="S_OK"/>.</returns>
	public HRESULT CopyTo(ref ComPtr<T> other) mut
	{
		 InternalAddRef();
		other.Attach(mPtr);
		return S_OK;
	}

	/// <summary>Converts the current COM object reference to a given interface type and assigns that to a target raw pointer.</summary>
	/// <param name="ptr">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target type <typeparamref name="U"/>.</returns>
	public HRESULT CopyTo<U>(U** ptr)
		where U : IUnknown
	{
		return ((IUnknown*)mPtr).QueryInterface(__uuidof<U>(), (void**)ptr);
	}

	/// <summary>Converts the current COM object reference to a given interface type and assigns that to a target <see cref="ComPtr{T}"/>.</summary>
	/// <param name="other">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target type <typeparamref name="U"/>.</returns>
	public HRESULT CopyTo<U>(ComPtr<U>* other)
		where U : IUnknown
	{
		return ((IUnknown*)mPtr).QueryInterface(__uuidof<U>(), (void**)other.ReleaseAndGetAddressOf());
	}

	/// <summary>Converts the current COM object reference to a given interface type and assigns that to a target <see cref="ComPtr{T}"/>.</summary>
	/// <param name="other">The target reference to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target type <typeparamref name="U"/>.</returns>
	public HRESULT CopyTo<U>(ref ComPtr<U> other)
		where U : IUnknown
	{
		U* ptr = null;
		HRESULT result = ((IUnknown*)mPtr).QueryInterface(__uuidof<U>(), (void**)&ptr);

		other.Attach(ptr);
		return result;
	}

	/// <summary>Converts the current object reference to a type indicated by the given IID and assigns that to a target address.</summary>
	/// <param name="riid">The IID indicating the interface type to convert the COM object reference to.</param>
	/// <param name="ptr">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target IID.</returns>
	public HRESULT CopyTo(in Guid riid, void** ptr)
	{
		return ((IUnknown*)mPtr).QueryInterface(riid, ptr);
	}

	/// <summary>Converts the current object reference to a type indicated by the given IID and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <param name="riid">The IID indicating the interface type to convert the COM object reference to.</param>
	/// <param name="other">The target raw pointer to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target IID.</returns>
	public HRESULT CopyTo(in Guid riid, ComPtr<IUnknown>* other)
	{
		return ((IUnknown*)mPtr).QueryInterface(riid, (void**)other.ReleaseAndGetAddressOf());
	}

	/// <summary>Converts the current object reference to a type indicated by the given IID and assigns that to a target <see cref="ComPtr{T}"/> value.</summary>
	/// <param name="riid">The IID indicating the interface type to convert the COM object reference to.</param>
	/// <param name="other">The target reference to copy the address of the current COM object to.</param>
	/// <returns>The result of <see cref="IUnknown.QueryInterface"/> for the target IID.</returns>
	public HRESULT CopyTo(in Guid riid, ref ComPtr<IUnknown> other)
	{
		IUnknown* ptr = null;
		HRESULT result = ((IUnknown*)mPtr).QueryInterface(riid, (void**)&ptr);

		other.Attach(ptr);
		return result;
	}


	/// <summary>
	/// Moves the current <see cref="ComPtr{T}"/> instance and resets it without releasing the reference.
	/// </summary>
	/// <returns>The moved <see cref="ComPtr{T}"/> instance.</returns>
	[Inline]
	public ComPtr<T> Move() mut
	{
	    ComPtr<T> copy = default;

	    Swap(ref copy);

	    return copy;
	}

	/// <summary>Resets the current instance by decrementing the reference count for the target COM object and setting the internal raw pointer to <see langword="null"/>.</summary>
	/// <returns>The updated reference count for the COM object that was in use, if any.</returns>
	[Inline]
	public uint32 Reset() mut
	{
		return InternalRelease();
	}

	[Inline]
	public void Dispose() mut
	{
		T* ptr = mPtr;

		if (ptr != null)
		{
			mRefCount = ((IUnknown*)ptr).Release();
		}
	}

	public static bool operator ==(Self a, T* b)
	{
		return a.mPtr == b;
	}

	public static bool operator !=(Self a, T* b)
	{
		return !(a == b);
	}

	public static bool operator !(Self a)
	{
		return a.mPtr == null;
	}

	public static T* operator ->(Self self) => self.Get();

	public static implicit operator T(Self self) => *self.mPtr;
}