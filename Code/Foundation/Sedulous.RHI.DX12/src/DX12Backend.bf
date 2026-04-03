namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.System.Com;
using Sedulous.RHI;

/// DX12 implementation of IBackend.
class DX12Backend : IBackend
{
	private IDXGIFactory4* mFactory;
	private bool mValidation;
	private bool mInitialized;
	private List<DX12Adapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);

	public bool IsInitialized => mInitialized;

	public static Result<DX12Backend> Create(bool enableValidation = false)
	{
		let backend = new DX12Backend();
		if (backend.Init(enableValidation) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("DX12Backend: Init failed");
			delete backend;
			return .Err;
		}
		return .Ok(backend);
	}

	private Result<void> Init(bool enableValidation)
	{
		mValidation = enableValidation;

		// Enable debug layer before device creation
		if (mValidation)
		{
			ID3D12Debug* debugController = null;
			if (SUCCEEDED(D3D12GetDebugInterface(ID3D12Debug.IID, (void**)&debugController)))
			{
				debugController.EnableDebugLayer();
				debugController.Release();
			}
		}

		// Create DXGI factory
		uint32 factoryFlags = mValidation ? 1 : 0; // DXGI_CREATE_FACTORY_DEBUG = 1
		HRESULT hr = CreateDXGIFactory2(factoryFlags, IDXGIFactory4.IID, (void**)&mFactory);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Backend: CreateDXGIFactory2 failed (0x{hr:X})");
			return .Err;
		}

		// Enumerate adapters
		EnumerateAdaptersInternal();

		mInitialized = true;
		return .Ok;
	}

	private void EnumerateAdaptersInternal()
	{
		uint32 i = 0;
		IDXGIAdapter1* adapter = null;
		while (SUCCEEDED(mFactory.EnumAdapters1(i, &adapter)))
		{
			DXGI_ADAPTER_DESC1 desc = default;
			adapter.GetDesc1(&desc);

			// Skip software adapters
			if ((desc.Flags & (uint32)DXGI_ADAPTER_FLAG.DXGI_ADAPTER_FLAG_SOFTWARE) != 0)
			{
				adapter.Release();
				i++;
				continue;
			}

			// Check if the adapter supports D3D12 feature level 12.0
			if (SUCCEEDED(D3D12CreateDevice((IUnknown*)adapter, .D3D_FEATURE_LEVEL_12_0, ID3D12Device.IID, null)))
			{
				mAdapters.Add(new DX12Adapter(adapter, mFactory));
			}
			else
			{
				adapter.Release();
			}

			i++;
		}
	}

	public void EnumerateAdapters(List<IAdapter> adapters)
	{
		for (let adapter in mAdapters)
			adapters.Add(adapter);
	}

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle = null)
	{
		if (windowHandle == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12Backend: CreateSurface called with null window handle");
			return .Err;
		}
		return .Ok(new DX12Surface((HWND)windowHandle));
	}

	public void Destroy()
	{
		for (let adapter in mAdapters)
			delete adapter;
		mAdapters.Clear();

		if (mFactory != null)
		{
			mFactory.Release();
			mFactory = null;
		}

		mInitialized = false;
	}

	// --- Internal ---
	public IDXGIFactory4* Factory => mFactory;
}
