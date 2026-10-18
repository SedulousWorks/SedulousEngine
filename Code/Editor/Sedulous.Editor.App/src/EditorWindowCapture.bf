using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Engine.DefaultApp;
using Sedulous.RHI.Capture;

namespace Sedulous.Editor.App;

enum WindowCaptureState
{
	/// Requested; the window has not drawn and written it yet.
	case Pending;
	/// The PNG is at Path, Width by Height.
	case Written;
	/// The copy or the write failed, or the window closed first (the log says why).
	case Failed;
}

/// One window to capture: the shell window's id, whether it is the main window, the PNG.
/// The path is borrowed for the request.
struct WindowShotRequest
{
	public uint32 Window = 0;
	public bool Main = false;
	public StringView Path = default;

	public this() {}

	public this(uint32 window, bool main, StringView path)
	{
		Window = window;
		Main = main;
		Path = path;
	}
}

/// Where one requested capture stands.
class WindowShot
{
	public uint32 Window = 0;
	public bool Main = false;
	public String Path = new .() ~ delete _;
	public WindowCaptureState State = .Pending;
	public uint32 Width = 0;
	public uint32 Height = 0;
}

/// Screenshots of the editor's windows, each as the user sees it, UI included: the
/// --screenshot flag, the editor_screenshot tool and View > Screenshot Editor.
///
/// One capture per window id, kept across requests so its readback buffer is made once. The
/// application arms a request, records the copy in each armed window's frame after its UI has
/// drawn, and writes the PNGs on the next update once the GPU has run the copies.
class EditorWindowCapture
{
	private class Slot
	{
		public uint32 Window = 0;
		public WindowShot Shot = new .() ~ delete _;
		public ScreenshotCapture Capture = new .() ~ delete _;
	}

	private List<Slot> mSlots = new .() ~ DeleteContainerAndItems!(_);
	/// The latest request's slots, in the order it asked for them. Borrowed from mSlots.
	private List<Slot> mRequested = new .() ~ delete _;

	/// Arms one capture per request, replacing any earlier request.
	public void Request(Span<WindowShotRequest> requests)
	{
		mRequested.Clear();
		for (let request in requests)
		{
			let slot = SlotFor(request.Window);
			slot.Shot.Window = request.Window;
			slot.Shot.Main = request.Main;
			slot.Shot.Path.Set(request.Path);
			slot.Shot.State = .Pending;
			slot.Shot.Width = 0;
			slot.Shot.Height = 0;
			slot.Capture.Request(request.Path);
			mRequested.Add(slot);
		}
	}

	/// The latest request's captures, in the order they were requested. Borrowed until the
	/// next request.
	public void Shots(List<WindowShot> outShots)
	{
		outShots.Clear();
		for (let slot in mRequested)
			outShots.Add(slot.Shot);
	}

	/// Some requested capture still waits for its window.
	public bool Busy
	{
		get
		{
			for (let slot in mRequested)
			{
				if (slot.Shot.State == .Pending)
					return true;
			}
			return false;
		}
	}

	/// From window `windowId`'s frame, after its UI has drawn: records the copy of its
	/// backbuffer when a capture of it is armed.
	public void Record(IDevice device, ICommandEncoder encoder, uint32 windowId, ITexture backbuffer,
		TextureFormat format, uint32 width, uint32 height)
	{
		for (let slot in mRequested)
		{
			if ((slot.Window != windowId) || !slot.Capture.Armed)
				continue;
			if (!slot.Capture.Record(device, encoder, backbuffer, format, width, height))
				slot.Shot.State = .Failed; // logged by the capture
		}
	}

	/// The next update: writes the copies recorded last frame. A one-off, so it waits for the
	/// whole GPU once, then maps and writes each.
	public void Complete(IDevice device)
	{
		var waited = false;
		for (let slot in mRequested)
		{
			if (!slot.Capture.Recorded)
				continue;
			if (!waited)
			{
				device.WaitIdle();
				waited = true;
			}
			let written = scope Sedulous.Image.Image();
			let saved = slot.Capture.Complete(device, written) case .Ok;
			slot.Shot.State = saved ? .Written : .Failed;
			slot.Shot.Width = written.Width;
			slot.Shot.Height = written.Height;
		}
	}

	/// A requested window that is no longer open never draws: its capture fails.
	public void FailMissing(Span<uint32> openWindows)
	{
		for (let slot in mRequested)
		{
			if (slot.Shot.State != .Pending)
				continue;
			var open = false;
			for (let id in openWindows)
				open |= id == slot.Window;
			if (!open)
				slot.Shot.State = .Failed;
		}
	}

	/// Drops the readback buffers, while the device lives (the application's shutdown).
	public void Release(IDevice device)
	{
		for (let slot in mSlots)
			slot.Capture.Release(device);
	}

	private Slot SlotFor(uint32 windowId)
	{
		for (let slot in mSlots)
		{
			if (slot.Window == windowId)
				return slot;
		}
		let slot = new Slot();
		slot.Window = windowId;
		mSlots.Add(slot);
		return slot;
	}
}
