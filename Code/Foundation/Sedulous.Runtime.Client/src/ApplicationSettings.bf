using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using System;

namespace Sedulous.Runtime.Client;

/// Backend type selection.
public enum BackendType
{
	Vulkan,
	DX12,
}

struct ApplicationSettings
{
	public StringView Title = "Sedulous Application";
	public int32 Width = 1280;
	public int32 Height = 720;
	public bool Resizable = true;
	public TextureFormat SwapChainFormat = .BGRA8UnormSrgb;
	public PresentMode PresentMode = .Mailbox;
	public Color ClearColor = .(0.1f, 0.1f, 0.1f, 1.0f);
	public bool EnableDepth = false;
	public TextureFormat DepthFormat = .Depth24PlusStencil8;
	public BackendType Backend = .Vulkan;
	public bool EnableValidation = true;
	public bool EnableShaderCache = false;
}
