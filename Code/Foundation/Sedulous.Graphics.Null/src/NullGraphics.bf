using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.RHI.Null;

namespace Sedulous.Graphics.Null;

/// A headless GraphicsDevice over the null RHI.
///
/// A SEPARATE project from the GPU factory so a headless consumer, CI, a server, the
/// tests, links no backend at all. It is also the reference for what a real backend has
/// to provide.
static class NullGraphics
{
	public static Result<GraphicsDevice> CreateDevice(uint32 framesInFlight = 2)
	{
		let backend = NullRhi.CreateBackend();
		// Nothing wraps it, so the backend and the inner backend are the same object.
		return GraphicsDevice.FromBackend(backend, backend, framesInFlight);
	}

	/// For a test: the turn a null graphics device's display presents at, as a phone's surface
	/// reports one held away from its natural orientation. A window that asks to pre-rotate
	/// (RenderWindowDesc.PreRotate) and is made after this takes it.
	public static void SetDisplayTurn(GraphicsDevice device, ContentRotation turn)
	{
		(device.Raw as NullDevice).DisplayTurn = turn;
	}
}
