using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Mcp;
using Sedulous.Json;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// The live editor's windows, as the screenshot tool sees them, and the call in flight.
class WindowToolSeams
{
	/// The ids of the editor's windows that can draw a frame now (open, not minimised), the
	/// main window first; empty is nothing to capture. Owned.
	public delegate void(List<uint32> outWindows) Windows ~ delete _;
	/// Arms a capture of each. Owned.
	public delegate void(Span<WindowShotRequest> requests) Request ~ delete _;
	/// Where the latest request's captures stand, borrowed until the next request. Owned.
	public delegate void(List<WindowShot> outShots) Shots ~ delete _;

	/// A capture requested; the tool is re-entered until it lands.
	public bool Pending = false;
	public uint32 Pumps = 0;
}

/// editor_screenshot: the whole editor window as the user sees it (the panels, the pages, the
/// menus, the dialogs, the toasts), where viewport_screenshot and pie_screenshot show one
/// viewport. Re-entered each pump until every capture is written.
static class EditorWindowTools
{
	/// How many tools Register registers; a tripwire like cPageToolCount.
	public const int cWindowToolCount = 1;
	/// Frames: ten seconds at 60 Hz, then the tool gives up.
	private const uint32 cCapturePumpLimit = 600;
	private static StringView[2] cWindowChoices = .("main", "all");
	/// Main thread only: the tool's pump and the View > Screenshot action both run there.
	private static uint32 sSerial = 0;

	/// A new PNG path under <user-data>/screenshots for `stem`, the directory made if needed:
	/// <stem>-<pid>-<n>.png, n counting up across every caller in the process, so the tool and
	/// the View > Screenshot action never pick one name. False when the directory cannot be made.
	public static bool NewScreenshotPath(StringView stem, String outPath)
	{
		let directory = PathJoin(GetUserDataDirectory(.. scope .()), "screenshots", .. scope .());
		if (!CreateDirectory(directory))
			return false;
		sSerial++;
		PathJoin(directory, scope $"{stem}-{System.Diagnostics.Process.CurrentId}-{sSerial}.png", outPath);
		return true;
	}

	/// The PNG for a window after the first: the first's path with -window<id> before its
	/// extension.
	private static void SecondaryPath(StringView first, uint32 window, String outPath)
	{
		let stem = first.EndsWith(".png") ? first.Substring(0, first.Length - 4) : first;
		outPath.AppendF("{}-window{}.png", stem, window);
	}

	private static JsonValue ShotJson(WindowShot shot)
	{
		let json = JsonValue.MakeObject();
		json.Set("window", JsonValue.MakeNumber(shot.Window));
		json.Set("main", JsonValue.MakeBool(shot.Main));
		json.Set("path", JsonValue.MakeString(shot.Path));
		json.Set("width", JsonValue.MakeNumber(shot.Width));
		json.Set("height", JsonValue.MakeNumber(shot.Height));
		return json;
	}

	/// OWNERSHIP of the seams transfers to the tool.
	public static void Register(McpServer server, WindowToolSeams seams)
	{
		let schema = scope SchemaBuilder();
		schema.Enum("window", cWindowChoices, "\"main\" (default) or \"all\" its windows");
		schema.Str("path", "the PNG to write (default: a new file under <user-data>/screenshots)");
		server.RegisterTool("editor_screenshot",
			"The whole editor window as the user sees it, as a PNG: the panels, the pages, the menus, the dialogs and the toasts, where viewport_screenshot and pie_screenshot show one viewport. `window` \"main\" (the default) is the main window; \"all\" also writes each floating window, beside the first file with -window<id> before its extension. Waits for the next frame and the GPU, then returns {path, shots: [{window, main, path, width, height}]}; read the file. `path` is where to write the main window (its directory must exist; default: <user-data>/screenshots/editor-<pid>-<n>.png). Gives up after ten seconds without a frame (a minimised editor draws none).",
			schema.Build(), .Creates,
			new (arguments, outResult, outError) =>
			{
				if (seams.Pending)
				{
					// Re-entered: the same call, one pump later.
					seams.Pumps++;
					let shots = scope List<WindowShot>();
					seams.Shots(shots);
					var done = !shots.IsEmpty;
					for (let shot in shots)
					{
						if (shot.State == .Failed)
						{
							seams.Pending = false;
							outError.AppendF("the capture of window {} failed (log_read, category Screenshot, says why; a window closed before it drew fails too)", shot.Window);
							return .Failed;
						}
						done &= shot.State == .Written;
					}
					if (done)
					{
						seams.Pending = false;
						let list = JsonValue.MakeArray();
						for (let shot in shots)
							list.Add(ShotJson(shot));
						outResult.Set("path", JsonValue.MakeString(shots[0].Path));
						outResult.Set("shots", list);
						return .Answered;
					}
					if (seams.Pumps > cCapturePumpLimit)
					{
						seams.Pending = false;
						outError.Append("the editor drew no frame in ten seconds - is its window minimised or hidden?");
						return .Failed;
					}
					return .NotFinished;
				}

				let windows = scope List<uint32>();
				seams.Windows(windows);
				if (windows.IsEmpty)
				{
					outError.Append("the editor has no window that can draw a frame (minimised?)");
					return .Failed;
				}
				let all = McpTools.ArgString(arguments, "window", .. scope .()) == "all";
				let path = McpTools.ArgString(arguments, "path", .. scope .());
				if (path.IsEmpty && !NewScreenshotPath("editor", path))
				{
					outError.Append("could not create <user-data>/screenshots");
					return .Failed;
				}
				let count = all ? windows.Count : 1;
				let paths = scope List<String>();
				defer { for (let p in paths) delete p; }
				let requests = scope List<WindowShotRequest>();
				for (int i < count)
				{
					let shotPath = new String();
					paths.Add(shotPath);
					if (i == 0)
						shotPath.Set(path);
					else
						SecondaryPath(path, windows[i], shotPath);
					requests.Add(.(windows[i], i == 0, shotPath));
				}
				seams.Request(requests);
				seams.Pending = true;
				seams.Pumps = 0;
				return .NotFinished;
			}, seams);
	}
}
