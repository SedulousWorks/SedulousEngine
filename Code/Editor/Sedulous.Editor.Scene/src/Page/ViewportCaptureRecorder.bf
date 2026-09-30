using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Editor.Scene;

/// A page's viewport capture, the three steps every capturing page takes: Request arms it,
/// Record copies the composed colour target once the page's frame is fully drawn (from
/// OnAfterSceneRender), and Complete writes the PNG on the next update, once the GPU has run
/// the copy. The scene page and the Game page both capture through one of these; State says
/// where the latest request stands.
class ViewportCaptureRecorder
{
	private ScreenshotCapture mScreenshot = new .() ~ delete _;
	private ViewportCapture mState = new .() ~ delete _;

	/// The latest request. BORROWED by callers.
	public ViewportCapture State => mState;
	/// A request waits for the next rendered frame.
	public bool Armed => mScreenshot.Armed;

	/// Arms the next Record to write `path`, replacing a pending request.
	public void Request(StringView path)
	{
		mState.State = .Pending;
		mState.Path.Set(path);
		mState.Width = 0;
		mState.Height = 0;
		mScreenshot.Request(path);
	}

	/// Records the copy of `target` (in `targetState`, where it is left) when a request is
	/// armed; a failure to record is the request's failure, logged by the capture.
	public void Record(IDevice device, ICommandEncoder encoder, ITexture target, TextureFormat format,
		uint32 width, uint32 height, ResourceState targetState)
	{
		if (!mScreenshot.Armed || (device == null) || (encoder == null))
			return;
		if (!mScreenshot.Record(device, encoder, target, format, width, height, targetState))
			mState.State = .Failed;
	}

	/// Writes the PNG of a copy recorded last frame. A one off, so it waits for the whole GPU,
	/// then maps and writes.
	public void Complete(IDevice device)
	{
		if (!mScreenshot.Recorded || (device == null))
			return;
		device.WaitIdle();
		let written = scope Image();
		let saved = mScreenshot.Complete(device, written);
		mState.State = (saved case .Ok) ? .Written : .Failed;
		mState.Width = written.Width;
		mState.Height = written.Height;
	}

	/// Drops the readback buffer; the page calls it on close, while the device lives.
	public void Release(IDevice device)
	{
		if (device != null)
			mScreenshot.Release(device);
	}
}
