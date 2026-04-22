namespace Sedulous.Engine.App;

using System;
using Sedulous.RHI;

/// GPU backend selection.
public enum BackendType
{
	Vulkan,
	DX12
}

/// Settings for an EngineApplication.
struct EngineAppSettings
{
	/// Window title.
	public StringView Title = "Sedulous Engine";

	/// Window width.
	public int32 Width = 1280;

	/// Window height.
	public int32 Height = 720;

	/// Whether the window is resizable.
	public bool Resizable = true;

	/// RHI backend to use.
	public BackendType Backend = .Vulkan;

	/// Whether to enable RHI validation layer.
	public bool EnableValidation = true;

	/// Swap chain format.
	public TextureFormat SwapChainFormat = .BGRA8UnormSrgb;

	/// Presentation mode.
	public PresentMode PresentMode = .Fifo;

	public bool EnableShaderCache = false;
}
