using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Shell.Null;

namespace Sedulous.Graphics.Tests;

/// The render host over the null RHI and the null shell, with no GPU anywhere.
///
/// Headless is the point: device bring up, a window's frame begin and end, the frame in
/// flight ring, several windows in one frame, resize, and the skip paths are all
/// questions about the HOST's bookkeeping, and answering them on real hardware would say
/// nothing more while making the suite unrunnable on a machine without a GPU.
class GraphicsHostTests
{
	[Test]
	public static void ADeviceComesUpOverTheNullBackend()
	{
		Test.Assert(NullGraphics.CreateDevice() case .Ok(let device));
		defer delete device;

		Test.Assert(device.Raw != null);
		Test.Assert(device.GraphicsQueue != null);
		Test.Assert(device.FramesInFlight == 2);
		Test.Assert(device.CurrentFrame == 0);
	}

	/// A frames-in-flight of zero would divide by zero on the first AdvanceFrame, so it
	/// is clamped to one rather than refused: asking for no pipelining is a coherent
	/// request, asking for a ring of length zero is not.
	[Test]
	public static void AZeroFrameRingIsClampedToOne()
	{
		Test.Assert(NullGraphics.CreateDevice(0) case .Ok(let device));
		defer delete device;

		Test.Assert(device.FramesInFlight == 1);
		device.AdvanceFrame();
		Test.Assert(device.CurrentFrame == 0, "a ring of one never leaves slot zero");
	}

	[Test]
	public static void AWindowRendersAndTheRingAdvances()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		Test.Assert(device.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let window));
		defer delete window;

		var frame0 = window.BeginFrame();
		Test.Assert(frame0.Valid);
		Test.Assert(frame0.FrameIndex == 0);
		Test.Assert(frame0.Window === window);
		Test.Assert(frame0.Encoder != null);
		Test.Assert(frame0.BackbufferView != null);
		window.EndFrame(ref frame0);
		device.AdvanceFrame();
		Test.Assert(device.CurrentFrame == 1);

		// The next frame takes the next ring slot.
		var frame1 = window.BeginFrame();
		Test.Assert(frame1.Valid);
		Test.Assert(frame1.FrameIndex == 1);
		window.EndFrame(ref frame1);
		device.AdvanceFrame();
		Test.Assert(device.CurrentFrame == 0, "wraps at two frames in flight");

		// And the third wraps back to slot zero, which is where the fence wait that guards
		// reuse has to hold up.
		var frame2 = window.BeginFrame();
		Test.Assert(frame2.Valid);
		Test.Assert(frame2.FrameIndex == 0);
		window.EndFrame(ref frame2);
	}

	/// Several windows are UNIFORM: they render in the same application frame at the same
	/// ring index, and the device advances once for all of them.
	[Test]
	public static void TwoWindowsRenderIndependentlyInOneFrame()
	{
		let shell = scope NullShell();
		Test.Assert(shell.WindowManager.CreateWindow(WindowSettings()) case .Ok(let second));

		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		Test.Assert(device.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let a));
		defer delete a;
		Test.Assert(device.CreateRenderWindow(second, .()) case .Ok(let b));
		defer delete b;

		var frameA = a.BeginFrame();
		var frameB = b.BeginFrame();
		Test.Assert(frameA.Valid);
		Test.Assert(frameB.Valid);
		Test.Assert(frameA.FrameIndex == frameB.FrameIndex, "one ring index for the frame");
		Test.Assert(frameA.Window !== frameB.Window);

		a.EndFrame(ref frameA);
		b.EndFrame(ref frameB);
		device.AdvanceFrame();
		Test.Assert(device.CurrentFrame == 1, "one advance for the whole frame");
	}

	[Test]
	public static void SyncSizeRebuildsTheChainWhenTheWindowChanges()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice() case .Ok(let device));
		defer delete device;

		Test.Assert(device.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let window));
		defer delete window;

		Test.Assert(!window.SyncSize(), "nothing has changed yet");

		(shell.MainWindow as NullWindow).Resize(1600, 900);
		Test.Assert(window.SyncSize(), "the change was picked up");
		Test.Assert(window.Swap.Width == 1600);
		Test.Assert(window.Swap.Height == 900);

		Test.Assert(!window.SyncSize(), "stable again");
	}

	/// A frame describes the BACK BUFFER, not the live window.
	///
	/// The two differ for exactly as long as a resize has not been synced, and every
	/// viewport and scissor downstream has to agree with the attachment actually being
	/// rendered into. Reporting the window's size instead puts them out of bounds, which
	/// on WebGPU drops the whole command buffer rather than the one call.
	[Test]
	public static void AFrameReportsTheBackbufferSizeNotTheWindowSize()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice() case .Ok(let device));
		defer delete device;

		Test.Assert(device.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let window));
		defer delete window;

		let oldWidth = window.Swap.Width;
		let oldHeight = window.Swap.Height;
		// Resized WITHOUT a SyncSize, so the chain is still at the old size.
		(shell.MainWindow as NullWindow).Resize(oldWidth + 320, oldHeight + 240);

		var frame = window.BeginFrame();
		Test.Assert(frame.Valid);
		Test.Assert(frame.Width == oldWidth);
		Test.Assert(frame.Height == oldHeight);
		window.EndFrame(ref frame);
		device.AdvanceFrame();
	}

	/// A minimised window has no extent to render into, so the frame comes back invalid
	/// and ending it is a harmless no op: the caller skips the window and branches nowhere.
	[Test]
	public static void AMinimizedWindowYieldsAnInvalidFrame()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice() case .Ok(let device));
		defer delete device;

		Test.Assert(device.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let window));
		defer delete window;

		(shell.MainWindow as NullWindow).SetMinimized(true);

		var frame = window.BeginFrame();
		Test.Assert(!frame.Valid);
		window.EndFrame(ref frame);
	}
}
