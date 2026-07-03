using Win32.Foundation;
namespace DX11Triangle;

using Win32.UI.WindowsAndMessaging;
using Win32.UI.Input.KeyboardAndMouse;
using System;
using Win32;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Dxgi;
using Win32.Graphics.Direct3D.Fxc;
using Win32.System.LibraryLoader;

class Program
{
	static bool global_windowDidResize = false;

	static LRESULT WndProc(HWND hwnd, uint32 msg, WPARAM wparam, LPARAM lparam)
	{
		LRESULT result = 0;
		switch (msg)
		{
		case WM_KEYDOWN:
			{
				if (wparam == (.)VIRTUAL_KEY.VK_ESCAPE)
					DestroyWindow(hwnd);
				break;
			}
		case WM_DESTROY:
			{
				PostQuitMessage(0);
				break;
			}
		case WM_SIZE:
			{
				global_windowDidResize = true;
				break;
			}
		default:
			result = DefWindowProcW(hwnd, msg, wparam, lparam);
		}
		return result;
	}

	public static void Main()
	{
		HWND hwnd;
		{
		    WNDCLASSEXW winClass = .();
		    winClass.cbSize = sizeof(WNDCLASSEXW);
		    winClass.style = .CS_HREDRAW | .CS_VREDRAW;
		    winClass.lpfnWndProc = => WndProc;
		    winClass.hInstance = GetModuleHandle(null);
		    winClass.hIcon = LoadIconW(0, IDI_APPLICATION);
		    winClass.hCursor = LoadCursorW(0, IDC_ARROW);
		    winClass.lpszClassName = scope String("MyWindowClass").ToScopedNativeWChar!();
		    winClass.hIconSm = LoadIconW(0, IDI_APPLICATION);

		    if(RegisterClassExW(&winClass) == 0) {
		        MessageBoxA(0, (uint8*)"RegisterClassEx failed", (uint8*)"Fatal Error", .MB_OK);
		        return;// GetLastError();
		    }

		    RECT initialRect = .(0, 0, 1024, 768);
		    AdjustWindowRectEx(&initialRect, .WS_OVERLAPPEDWINDOW, FALSE, .WS_EX_OVERLAPPEDWINDOW);
		    int64 initialWidth = initialRect.right - initialRect.left;
		    int64 initialHeight = initialRect.bottom - initialRect.top;

		    hwnd = CreateWindowExW(.WS_EX_OVERLAPPEDWINDOW,
		                            winClass.lpszClassName,
		                            scope String("02. Drawing a Triangle").ToScopedNativeWChar!(),
		                            .WS_OVERLAPPEDWINDOW | .WS_VISIBLE,
		                            CW_USEDEFAULT, CW_USEDEFAULT,
		                            (int32)initialWidth, 
		                            (int32)initialHeight,
		                            0, 0, GetModuleHandle(null), null);

		    if(hwnd == 0) {
		        MessageBoxA(0, (uint8*)"CreateWindowEx failed", (uint8*)"Fatal Error", .MB_OK);
		        return;// GetLastError();
		    }
		}

		// Create D3D11 Device and Context
		ID3D11Device1* d3d11Device = null;
		ID3D11DeviceContext1* d3d11DeviceContext = null;
		{
		    ID3D11Device* baseDevice = null;
		    ID3D11DeviceContext* baseDeviceContext = null;
		    D3D_FEATURE_LEVEL[?] featureLevels = .(.D3D_FEATURE_LEVEL_11_0);
		    D3D11_CREATE_DEVICE_FLAG creationFlags = .D3D11_CREATE_DEVICE_BGRA_SUPPORT;
		    #if DEBUG
		    creationFlags |= .D3D11_CREATE_DEVICE_DEBUG;
		    #endif

		    HRESULT hResult = D3D11CreateDevice(null, .D3D_DRIVER_TYPE_HARDWARE, 
		                                        0, creationFlags, 
		                                        &featureLevels, featureLevels.Count, 
		                                        D3D11_SDK_VERSION, &baseDevice, 
		                                        null, &baseDeviceContext);
		    if(FAILED(hResult)){
		        MessageBoxA(0, (uint8*)"D3D11CreateDevice() failed", (uint8*)"Fatal Error", .MB_OK);
		        return;// GetLastError();
		    }
		    
		    // Get 1.1 interface of D3D11 Device and Context
		    hResult = baseDevice.QueryInterface(__uuidof<ID3D11Device1>(), (void**)&d3d11Device);
		    Runtime.Assert(SUCCEEDED(hResult));
		    baseDevice.Release();

		    hResult = baseDeviceContext.QueryInterface(__uuidof<ID3D11DeviceContext1>(), (void**)&d3d11DeviceContext);
		    Runtime.Assert(SUCCEEDED(hResult));
		    baseDeviceContext.Release();
		}

#if DEBUG
		// Set up debug layer to break on D3D11 errors
		ID3D11Debug *d3dDebug = null;
		d3d11Device.QueryInterface(__uuidof<ID3D11Debug>(), (void**)&d3dDebug);
		if (d3dDebug != null)
		{
		    ID3D11InfoQueue *d3dInfoQueue = null;
		    if (SUCCEEDED(d3dDebug.QueryInterface(__uuidof<ID3D11InfoQueue>(), (void**)&d3dInfoQueue)))
		    {
		        d3dInfoQueue.SetBreakOnSeverity(.D3D11_MESSAGE_SEVERITY_CORRUPTION, TRUE);
		        d3dInfoQueue.SetBreakOnSeverity(.D3D11_MESSAGE_SEVERITY_ERROR, TRUE);
		        d3dInfoQueue.Release();
		    }
		    d3dDebug.Release();
		}
#endif

		// Create Swap Chain
		IDXGISwapChain1* d3d11SwapChain = null;
		{
		    // Get DXGI Factory (needed to create Swap Chain)
		    IDXGIFactory2* dxgiFactory = null;
		    {
		        IDXGIDevice1* dxgiDevice = null;
		        HRESULT hResult = d3d11Device.QueryInterface(__uuidof<IDXGIDevice1>(), (void**)&dxgiDevice);
		        Runtime.Assert(SUCCEEDED(hResult));

		        IDXGIAdapter* dxgiAdapter = null;
		        hResult = dxgiDevice.GetAdapter(&dxgiAdapter);
		        Runtime.Assert(SUCCEEDED(hResult));
		        dxgiDevice.Release();

		        DXGI_ADAPTER_DESC adapterDesc = .();
		        dxgiAdapter.GetDesc(&adapterDesc);

		        Console.WriteLine("Graphics Device: {0}", scope String(adapterDesc.Description));

		        hResult = dxgiAdapter.GetParent(__uuidof<IDXGIFactory2>(), (void**)&dxgiFactory);
		        Runtime.Assert(SUCCEEDED(hResult));
		        dxgiAdapter.Release();
		    }
		    
		    DXGI_SWAP_CHAIN_DESC1 d3d11SwapChainDesc = .();
		    d3d11SwapChainDesc.Width = 0; // use window width
		    d3d11SwapChainDesc.Height = 0; // use window height
		    d3d11SwapChainDesc.Format = .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
		    d3d11SwapChainDesc.SampleDesc.Count = 1;
		    d3d11SwapChainDesc.SampleDesc.Quality = 0;
		    d3d11SwapChainDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		    d3d11SwapChainDesc.BufferCount = 2;
		    d3d11SwapChainDesc.Scaling = .DXGI_SCALING_STRETCH;
		    d3d11SwapChainDesc.SwapEffect = .DXGI_SWAP_EFFECT_DISCARD;
		    d3d11SwapChainDesc.AlphaMode = .DXGI_ALPHA_MODE_UNSPECIFIED;
		    d3d11SwapChainDesc.Flags = 0;

		    HRESULT hResult = dxgiFactory.CreateSwapChainForHwnd(d3d11Device, hwnd, &d3d11SwapChainDesc, null, null, &d3d11SwapChain);
		    Runtime.Assert(SUCCEEDED(hResult));

		    dxgiFactory.Release();
		}

		// Create Framebuffer Render Target
		ID3D11RenderTargetView* d3d11FrameBufferView = null;
		{
		    ID3D11Texture2D* d3d11FrameBuffer = null;
		    HRESULT hResult = d3d11SwapChain.GetBuffer(0, __uuidof<ID3D11Texture2D>(), (void**)&d3d11FrameBuffer);
		    Runtime.Assert(SUCCEEDED(hResult));

		    hResult = d3d11Device.CreateRenderTargetView(d3d11FrameBuffer, null, &d3d11FrameBufferView);
		    Runtime.Assert(SUCCEEDED(hResult));
		    d3d11FrameBuffer.Release();
		}

		// Create Vertex Shader
		ID3DBlob* vsBlob = null;
		ID3D11VertexShader* vertexShader = null;
		{
		    ID3DBlob* shaderCompileErrorsBlob = null;
		    HRESULT hResult = D3DCompileFromFile(scope String("shaders.hlsl").ToScopedNativeWChar!(), null, null, (uint8*)"vs_main", (uint8*)"vs_5_0", 0, 0, &vsBlob, &shaderCompileErrorsBlob);
		    if(FAILED(hResult))
		    {
		        char8* errorString = null;
		        if(hResult == HRESULT_FROM_WIN32(WIN32_ERROR.ERROR_FILE_NOT_FOUND))
		            errorString = "Could not compile shader; file not found";
		        else if(shaderCompileErrorsBlob != null){
		            errorString = (char8*)shaderCompileErrorsBlob.GetBufferPointer();
		            shaderCompileErrorsBlob.Release();
		        }
		        MessageBoxA(0, (uint8*)errorString, (uint8*)"Shader Compiler Error", .MB_ICONERROR | .MB_OK);
		        return;// 1;
		    }

		    hResult = d3d11Device.CreateVertexShader(vsBlob.GetBufferPointer(), vsBlob.GetBufferSize(), null, &vertexShader);
		    Runtime.Assert(SUCCEEDED(hResult));
		}

		// Create Pixel Shader
		ID3D11PixelShader* pixelShader = null;
		{
		    ID3DBlob* psBlob = null;
		    ID3DBlob* shaderCompileErrorsBlob = null;
		    HRESULT hResult = D3DCompileFromFile(scope String("shaders.hlsl").ToScopedNativeWChar!(), null, null, (uint8*)"ps_main", (uint8*)"ps_5_0", 0, 0, &psBlob, &shaderCompileErrorsBlob);
		    if(FAILED(hResult))
		    {
		        char8* errorString = null;
		        if(hResult == HRESULT_FROM_WIN32(WIN32_ERROR.ERROR_FILE_NOT_FOUND))
		            errorString = "Could not compile shader; file not found";
		        else if(shaderCompileErrorsBlob != null){
		            errorString = (char8*)shaderCompileErrorsBlob.GetBufferPointer();
		            shaderCompileErrorsBlob.Release();
		        }
		        MessageBoxA(0, (uint8*)errorString, (uint8*)"Shader Compiler Error", .MB_ICONERROR | .MB_OK);
		        return ;//1;
		    }

		    hResult = d3d11Device.CreatePixelShader(psBlob.GetBufferPointer(), psBlob.GetBufferSize(), null, &pixelShader);
		    Runtime.Assert(SUCCEEDED(hResult));
		    psBlob.Release();
		}

		// Create Input Layout
		ID3D11InputLayout* inputLayout = null;
		{
		    D3D11_INPUT_ELEMENT_DESC[?] inputElementDesc =
		    .(
		        .( (uint8*)"POS", 0, .DXGI_FORMAT_R32G32_FLOAT, 0, 0, .D3D11_INPUT_PER_VERTEX_DATA, 0 ),
		        .( (uint8*)"COL", 0, .DXGI_FORMAT_R32G32B32A32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, .D3D11_INPUT_PER_VERTEX_DATA, 0 )
		    );

		    HRESULT hResult = d3d11Device.CreateInputLayout(&inputElementDesc, inputElementDesc.Count, vsBlob.GetBufferPointer(), vsBlob.GetBufferSize(), &inputLayout);
		    Runtime.Assert(SUCCEEDED(hResult));
		    vsBlob.Release();
		}

		// Create Vertex Buffer
		ID3D11Buffer* vertexBuffer = null;
		uint32 numVerts;
		uint32 stride;
		uint32 offset;
		{
		    float[?] vertexData = .( // x, y, r, g, b, a
		        0.0f,  0.5f, 0.f, 1.f, 0.f, 1.f,
		        0.5f, -0.5f, 1.f, 0.f, 0.f, 1.f,
		        -0.5f, -0.5f, 0.f, 0.f, 1.f, 1.f
		    );
		    stride = 6 * sizeof(float);
		    numVerts = sizeof(float) * vertexData.Count / stride;
		    offset = 0;

		    D3D11_BUFFER_DESC vertexBufferDesc = .();
		    vertexBufferDesc.ByteWidth = sizeof(float) * vertexData.Count;
		    vertexBufferDesc.Usage     = .D3D11_USAGE_IMMUTABLE;
		    vertexBufferDesc.BindFlags = .D3D11_BIND_VERTEX_BUFFER;

		    D3D11_SUBRESOURCE_DATA vertexSubresourceData = .(){ pSysMem = &vertexData };

		    HRESULT hResult = d3d11Device.CreateBuffer(&vertexBufferDesc, &vertexSubresourceData, &vertexBuffer);
		    Runtime.Assert(SUCCEEDED(hResult));
		}

		// Main Loop
		bool isRunning = true;
		while(isRunning)
		{
		    MSG msg = .();
		    while(PeekMessageW(&msg, 0, 0, 0, .PM_REMOVE) != 0)
		    {
		        if(msg.message == WM_QUIT)
		            isRunning = false;
		        TranslateMessage(&msg);
		        DispatchMessageW(&msg);
		    }

		    if(global_windowDidResize)
		    {
		        d3d11DeviceContext.OMSetRenderTargets(0, null, null);
		        d3d11FrameBufferView.Release();

		        HRESULT res = d3d11SwapChain.ResizeBuffers(0, 0, 0, .DXGI_FORMAT_UNKNOWN, 0);
		        Runtime.Assert(SUCCEEDED(res));
		        
		        ID3D11Texture2D* d3d11FrameBuffer = null;
		        res = d3d11SwapChain.GetBuffer(0, __uuidof<ID3D11Texture2D>(), (void**)&d3d11FrameBuffer);
		        Runtime.Assert(SUCCEEDED(res));

		        res = d3d11Device.CreateRenderTargetView(d3d11FrameBuffer, null,
		                                                 &d3d11FrameBufferView);
		        Runtime.Assert(SUCCEEDED(res));
		        d3d11FrameBuffer.Release();

		        global_windowDidResize = false;
		    }

		    float[4] backgroundColor = .(0.1f, 0.2f, 0.6f, 1.0f );
		    d3d11DeviceContext.ClearRenderTargetView(d3d11FrameBufferView, &backgroundColor);

		    RECT winRect = .();
		    GetClientRect(hwnd, &winRect);
		    D3D11_VIEWPORT viewport = .( 0.0f, 0.0f, (float)(winRect.right - winRect.left), (float)(winRect.bottom - winRect.top), 0.0f, 1.0f );
		    d3d11DeviceContext.RSSetViewports(1, &viewport);

		    d3d11DeviceContext.OMSetRenderTargets(1, &d3d11FrameBufferView, null);

		    d3d11DeviceContext.IASetPrimitiveTopology(.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		    d3d11DeviceContext.IASetInputLayout(inputLayout);

		    d3d11DeviceContext.VSSetShader(vertexShader, null, 0);
		    d3d11DeviceContext.PSSetShader(pixelShader, null, 0);

		    d3d11DeviceContext.IASetVertexBuffers(0, 1, &vertexBuffer, &stride, &offset);

		    d3d11DeviceContext.Draw(numVerts, 0);
		    
		    d3d11SwapChain.Present(1, 0);
		}
	}
}