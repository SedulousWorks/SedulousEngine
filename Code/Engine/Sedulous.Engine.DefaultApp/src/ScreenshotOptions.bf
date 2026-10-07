using System;

namespace Sedulous.Engine.DefaultApp;

/// The --screenshot flags: capture to Path at rendered frame Frame (1 based) or, when
/// AfterSeconds is set, at the first frame past that many seconds of run time, which is frame
/// rate independent and the form a "screenshot after 15 seconds" wants; with a count, that many
/// consecutive frames from there; exit once the last is written when asked. An empty path is no
/// capture.
///
/// OWNED by whoever holds it: the application's setter takes the reference.
class ScreenshotOptions
{
	public String Path = new .() ~ delete _;
	/// A few frames for the scene to load and settle.
	public uint32 Frame = 30;
	/// Above nought wins over Frame.
	public float AfterSeconds = 0.0f;
	/// --screenshot-exit: quit once the file is written.
	public bool ExitAfter = false;
	/// --screenshot-count: this many consecutive frames from the due one. A single screenshot
	/// cannot show frame to frame change (TAA's jitter in a player), and separate runs differ
	/// in more than the frame.
	public uint32 Count = 1;

	public bool Requested => !Path.IsEmpty;

	/// The file for the `index`th frame of a run, into `outPath`: the path itself for one
	/// frame, else the path with "-<index>" before its extension ("shot.png" is "shot-0.png",
	/// "shot-1.png", ...). A dot in a directory name is not an extension.
	public void PathFor(uint32 index, String outPath)
	{
		if (Count <= 1)
		{
			outPath.Append(Path);
			return;
		}
		var dot = Path.Length;
		for (int i = Path.Length; i > 0; i--)
		{
			let c = Path[i - 1];
			if (c == '.')
			{
				dot = i - 1;
				break;
			}
			if ((c == '/') || (c == '\\'))
				break;
		}
		outPath.AppendF("{}-{}{}", StringView(Path, 0, dot), index, StringView(Path, dot));
	}

	/// Whether this frame, the `frames`th rendered at `seconds` of run time, is the one.
	public bool Due(uint64 frames, float seconds)
	{
		return (AfterSeconds > 0.0f) ? (seconds >= AfterSeconds) : (frames == Frame);
	}

	/// Reads `--screenshot <path>`, `--screenshot-frame <n>`, `--screenshot-after <seconds>`,
	/// `--screenshot-count <n>` and `--screenshot-exit` out of a command line and ignores
	/// everything else, which has its own readers. The caller owns the result.
	public static ScreenshotOptions FromArguments(Span<String> args)
	{
		let options = new ScreenshotOptions();
		for (int i = 0; i < args.Length; i++)
		{
			let arg = args[i];
			if ((arg == "--screenshot") && (i + 1 < args.Length))
			{
				options.Path.Set(args[++i]);
			}
			else if ((arg == "--screenshot-frame") && (i + 1 < args.Length))
			{
				let frame = uint32.Parse(args[++i]).GetValueOrDefault();
				// Never "frame 0": the count is 1 based.
				options.Frame = (frame > 0) ? frame : 1;
			}
			else if ((arg == "--screenshot-after") && (i + 1 < args.Length))
			{
				options.AfterSeconds = float.Parse(args[++i]).GetValueOrDefault();
			}
			else if ((arg == "--screenshot-count") && (i + 1 < args.Length))
			{
				let count = uint32.Parse(args[++i]).GetValueOrDefault();
				// Never "no frames".
				options.Count = (count > 0) ? count : 1;
			}
			else if (arg == "--screenshot-exit")
			{
				options.ExitAfter = true;
			}
		}
		return options;
	}
}
