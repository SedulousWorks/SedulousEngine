using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.System.Com;

namespace Sedulous.RHI.DX12;

/// The D3D12 backend: the DXGI factory, the adapters on it, and the surfaces handed out.
///
/// OWNERSHIP is the whole of this class's job, and COM makes it two layers. The factory is a
/// reference this holds and gives up in Destroy. Every adapter is a Beef object owned here
/// AND a DXGI reference owned by that object, so deleting the list releases both. Surfaces
/// are owned here too, which is what the Vulkan backend does: ISurface has no Destroy of its
/// own, so a backend that handed them out would have nowhere to free them.
class DxBackend : IBackend
{
	private IDXGIFactory4* mFactory = null; // owned, released in Destroy
	private bool mValidationEnabled = false;
	private bool mInitialized = false;

	private List<DxAdapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);
	private List<IAdapter> mAdapterHandles = new .() ~ delete _; // views, not owned
	private List<DxSurface> mSurfaces = new .() ~ DeleteContainerAndItems!(_);

	public bool IsInitialized => mInitialized;
	public IDXGIFactory4* Factory => mFactory;
	public bool ValidationEnabled => mValidationEnabled;

	public Result<void> Initialize(bool enableValidation)
	{
		mValidationEnabled = enableValidation;

		// The debug layer has to be switched on BEFORE any device is made, including the
		// throwaway ones the adapters create to answer feature questions.
		if (mValidationEnabled)
		{
			ID3D12Debug* debugController = null;
			if (SUCCEEDED(D3D12GetDebugInterface(ID3D12Debug.IID, (void**)&debugController)))
			{
				debugController.EnableDebugLayer();
				debugController.Release();
			}
		}

		let factoryFlags = mValidationEnabled ? DXGI_CREATE_FACTORY_DEBUG : 0;
		let hr = CreateDXGIFactory2(factoryFlags, IDXGIFactory4.IID, (void**)&mFactory);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxBackend: CreateDXGIFactory2 failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		EnumerateAdaptersInternal();
		mInitialized = true;
		return .Ok;
	}

	private void EnumerateAdaptersInternal()
	{
		for (uint32 i = 0; true; i++)
		{
			IDXGIAdapter1* adapter = null;
			// Anything other than success ends the walk. DXGI reports the end as NOT_FOUND;
			// treating every failure the same way keeps a null adapter from being read.
			if (FAILED(mFactory.EnumAdapters1(i, &adapter)) || (adapter == null))
				break;

			DXGI_ADAPTER_DESC1 desc = .();
			adapter.GetDesc1(&desc);

			if ((desc.Flags & (uint32)DXGI_ADAPTER_FLAG.DXGI_ADAPTER_FLAG_SOFTWARE) != 0)
			{
				adapter.Release();
				continue;
			}

			// A null ppDevice makes this a SUPPORT TEST rather than a creation, so there is
			// nothing to release on the way back out.
			if (SUCCEEDED(D3D12CreateDevice((IUnknown*)adapter, .D3D_FEATURE_LEVEL_12_0,
				ID3D12Device.IID, null)))
			{
				// The adapter's DXGI reference goes WITH it; the factory's does not, because
				// this backend outlives every adapter it made.
				let a = new DxAdapter(adapter, mFactory);
				mAdapters.Add(a);
				mAdapterHandles.Add(a);
			}
			else
			{
				adapter.Release();
			}
		}

		// Best GPU first, so a caller that takes the head gets the one it wanted.
		AdapterSelection.SortByPreference(mAdapterHandles);
	}

	public Span<IAdapter> EnumerateAdapters() => mAdapterHandles;

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform)
	{
		if (windowHandle == null)
		{
			GlobalLog(.Error, "DxBackend: the window handle is null");
			return .Err;
		}

		// The display handle and the platform are ignored: DXGI takes an HWND and nothing
		// else, so there is no second identifier to carry.
		let surface = new DxSurface((HWND)(int)windowHandle);
		mSurfaces.Add(surface);
		return .Ok(surface);
	}

	public void Destroy()
	{
		ClearAndDeleteItems!(mSurfaces);
		ClearAndDeleteItems!(mAdapters);
		mAdapterHandles.Clear();

		if (mFactory != null)
		{
			mFactory.Release();
			mFactory = null;
		}

		mInitialized = false;
	}
}

static class DxRhi
{
	/// A D3D12 backend, or an error when there is no DXGI factory. The CALLER owns what comes
	/// back and gives it up through Destroy.
	public static Result<IBackend> CreateBackend(bool enableValidation = false)
	{
		let backend = new DxBackend();
		if (backend.Initialize(enableValidation) case .Err)
		{
			delete backend;
			return .Err;
		}
		return .Ok(backend);
	}
}
