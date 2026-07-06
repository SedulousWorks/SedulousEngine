namespace Sedulous.RHI;

using System;
using System.Collections;
using Sedulous.Surface;

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

	/// Creates a presentation surface for a window. The SurfaceInfo carries the
	/// native handles together with the windowing system that produced them, so
	/// the backend never has to guess (X11 vs Wayland) which would risk feeding
	/// handles to the wrong platform surface entry point.
	Result<ISurface> CreateSurface(SurfaceInfo info);

	/// Destroys this backend and all objects created from it.
	void Destroy();
}
