namespace Sedulous.RHI;

using System;
using System.Collections;

/// A graphics backend (Vulkan, DX12, etc.). Entry point for the RHI.
///
/// Usage:
/// ```
/// let backend = VulkanBackend.Create(true); // true = enable validation
/// defer backend.Destroy();
/// ```
interface IBackend
{
	/// Whether the backend was successfully initialized.
	bool IsInitialized { get; }

	/// Enumerates available GPU adapters. Appends to the provided list.
	/// Caller owns the returned IAdapter references (do not delete them;
	/// they are destroyed when the backend is destroyed).
	void EnumerateAdapters(List<IAdapter> adapters);

	/// Creates a surface from native window handles.
	/// - windowHandle: HWND (Windows), or X11 Window (Linux)
	/// - displayHandle: null (Windows), or X11 Display* (Linux)
	Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle = null);

	/// Destroys this backend and all objects created from it.
	void Destroy();
}
