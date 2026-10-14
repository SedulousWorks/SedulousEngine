using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Capture;

/// A capture of the next few seconds, written as a file: started by a key or a flag in any
/// player (or by a tool), it arms the profiler, lets the time run, waits a few frames more for
/// the last frames' GPU passes (they arrive when their frame slot comes round), then writes the
/// frames as a profile stream (.aeprofile, which the editor's panel opens) and as Chrome trace
/// JSON beside it (for Perfetto), and lets the profiler go. The host advances it after each
/// frame's end.
class CaptureRecorder
{
	/// Frames waited after the time is up, for the last frames' GPU passes (frames in flight).
	public const uint32 GpuGraceFrames = 4;

	private enum State
	{
		Idle,
		/// The time running.
		Recording,
		/// For the last frames' GPU passes.
		Waiting
	}

	private static CaptureRecorder sProcess = new .() ~ delete _;

	private String mApplication = new .("Engine") ~ delete _;
	private String mPlatform = new .() ~ delete _;
	private String mBuild = new .() ~ delete _;
	private String mFolder = new .() ~ delete _;
	private String mBase = new .() ~ delete _;
	private String mLastCapture = new .() ~ delete _;
	private State mState = .Idle;
	private int64 mDurationTicks;
	private int64 mStartTick;
	private uint64 mFirstFrame;
	private uint64 mLastFrame;
	private uint32 mGrace;

	/// The process's recorder: the key, the flag and the tools share it.
	public static CaptureRecorder Process => sProcess;

	/// Who records: the application (a player sets its project's name), written into each
	/// capture's header and its file name.
	public void SetApplication(StringView name) => mApplication.Set(name);
	public StringView Application => mApplication;
	public StringView Platform => mPlatform;
	public StringView Build => mBuild;

	/// The platform and build (the host sets them), written into each capture's header.
	public void SetBuild(StringView platform, StringView build)
	{
		mPlatform.Set(platform);
		mBuild.Set(build);
	}

	/// Captures the next `seconds` (at least one frame) into `folder` (made when missing),
	/// named after the application. False when a capture is already running.
	public bool Start(Profiler profiler, double seconds, StringView folder)
	{
		if (mState != .Idle)
			return false;
		mFolder.Set(folder);
		mBase.Clear();
		mBase.AppendF("{}/{}-{}", folder, mApplication, DateTime.Now.Ticks);
		mDurationTicks = (int64)(Math.Max(seconds, 0.0) * (double)ProfileClock.TicksPerSecond);
		mStartTick = ProfileClock.Now();
		mFirstFrame = profiler.CurrentFrameNumber;
		mGrace = 0;
		profiler.Arm();
		mState = .Recording;
		return true;
	}

	public bool Capturing => mState != .Idle;

	/// The last capture's stream file (its Chrome JSON beside it, ".json"); empty before one.
	public StringView LastCapture => mLastCapture;

	/// After each frame's end (the frame thread). True on the frame a capture was written.
	public bool OnFrameEnd(Profiler profiler)
	{
		if (mState == .Recording)
		{
			if ((ProfileClock.Now() - mStartTick < mDurationTicks) || (profiler.CurrentFrameNumber == mFirstFrame))
				return false;
			mLastFrame = profiler.CurrentFrameNumber - 1; // the last frame that ended
			mState = .Waiting;
		}
		if (mState != .Waiting)
			return false;
		mGrace++;
		if (mGrace < GpuGraceFrames)
			return false;
		Write(profiler);
		profiler.Disarm();
		mState = .Idle;
		return true;
	}

	private void Write(Profiler profiler)
	{
		CreateDirectory(mFolder); // its parents too
		let source = scope LiveProfileSource(profiler);
		let header = scope StreamHeader();
		header.TickFrequency = source.TickFrequency;
		header.Application.Set(mApplication);
		header.Platform.Set(mPlatform);
		header.Build.Set(mBuild);
		let written = WriteCaptureFiles(source, Math.Max(mFirstFrame, source.OldestFrame), mLastFrame, mBase, header, .. scope .());
		if (!written.IsEmpty)
			mLastCapture.Set(written);
	}

	/// Writes `source`'s frames `first` to `last` as a capture: `<basePath>.aeprofile`, the
	/// profile stream, and `<basePath>.json` beside it, Chrome trace JSON for Perfetto. The folder
	/// must exist. Appends the stream file's path to `outPath`, nothing when it could not be
	/// written.
	public static void WriteCaptureFiles(IProfileSource source, uint64 first, uint64 last, StringView basePath,
		StreamHeader header, String outPath)
	{
		let streamPath = scope $"{basePath}.aeprofile";
		{
			let file = scope FileStream(streamPath, .Write);
			if (!file.IsValid)
			{
				GlobalLog(.Warning, "Profiler: capture: cannot write {}", streamPath);
				return;
			}
			let writer = scope ProfileStreamWriter(file);
			writer.WriteHeader(header);
			for (var n = first; n <= last; n++)
			{
				if (let frame = source.Frame(n))
					writer.WriteFrame(source, frame);
			}
		}
		let json = scope String();
		ChromeTrace.Write(source, first, last, header.Application, json);
		let jsonFile = scope FileStream(scope $"{basePath}.json", .Write);
		if (jsonFile.IsValid)
			jsonFile.Write(.((uint8*)json.Ptr, json.Length));
		outPath.Append(streamPath);
	}
}
