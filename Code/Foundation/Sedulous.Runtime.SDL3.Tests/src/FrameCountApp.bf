using Sedulous.Runtime.Client;

namespace Sedulous.Runtime.SDL3.Tests;

/// An application that counts frames and asks to stop on a chosen one.
///
/// The exit CODE is carried through deliberately: the runner's contract is that whatever the
/// application asked for is what the process returns, and a runner that loops correctly but
/// answers zero would pass a frame count check alone.
class FrameCountApp : IApplication
{
	private int32 mExitOn;
	private int32 mExitCode;

	public int32 Frames = 0;

	public this(int32 exitOnFrame, int32 exitCode)
	{
		mExitOn = exitOnFrame;
		mExitCode = exitCode;
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		if (++Frames == mExitOn)
			host.RequestExit(mExitCode);
	}
}
