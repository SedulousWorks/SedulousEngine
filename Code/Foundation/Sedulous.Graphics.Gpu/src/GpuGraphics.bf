using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;

namespace Sedulous.Graphics.Gpu;

/// Turning a GraphicsDeviceDesc into a live device on a real backend.
///
/// The one place a backend is named. Everything above it, the application host, the UI,
/// the renderer, talks to GraphicsDevice and never to Vulkan, which is what lets a
/// headless consumer link Sedulous.Graphics.Null instead of this and change nothing else.
static class GpuGraphics
{
	public static Result<GraphicsDevice> CreateDevice(GraphicsDeviceDesc desc)
	{
		if (desc.Backend == .Null)
			return NullGraphics.CreateDevice(desc.FramesInFlight);

		IBackend inner = null;
		switch (desc.Backend)
		{
		case .Vulkan:
			if (!(VulkanRhi.CreateBackend(desc.EnableValidation) case .Ok(let backend)))
			{
				GlobalLog(.Error, "GpuGraphics.CreateDevice: the Vulkan backend could not be created");
				return .Err;
			}
			inner = backend;
		case .DX12:
			GlobalLog(.Error, "GpuGraphics.CreateDevice: the DX12 backend is not ported yet");
			return .Err;
		case .WebGPU:
			if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
			{
				GlobalLog(.Error, "GpuGraphics.CreateDevice: the WebGPU backend could not be created");
				return .Err;
			}
			inner = backend;
		case .Null:
			return .Err; // handled above
		}

		// The wrapper BORROWS the real backend, so both are handed over: one to use, one
		// to destroy.
		let outer = desc.EnableValidation ? ValidationRhi.Wrap(inner) : inner;
		return GraphicsDevice.FromBackend(outer, inner, desc.FramesInFlight, desc.RequiredFeatures);
	}
}
