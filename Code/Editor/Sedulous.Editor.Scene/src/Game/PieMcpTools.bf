using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The play-in-editor tools the editor's MCP host serves through the scene editor's tool
/// contribution: pie_start, pie_stop, pie_state, pie_list and pie_screenshot. PIE is not one
/// game: every Game tab runs its own instance, so every call addresses ONE by its `pie` id
/// (`game-page` for the primary, `game-page-1`, ... for Play New Instance's), defaulting to
/// the primary, and every answer names the instance it is about.
static class PieMcpTools
{
	/// How many tools Register registers; a tripwire like the scene tools'.
	public const int cPieToolCount = 6;

	/// The primary Game tab's id.
	public const String cPrimaryId = "game-page";

	private const String cPieArgument = "the PIE instance's id, as pie_list reports it (default: the primary, `game-page`)";

	/// Frames: five minutes at 60 Hz, the cook Play waits on included, then pie_start gives up.
	private const int cStartPumpLimit = 18000;
	/// Frames: ten seconds at 60 Hz, then pie_screenshot gives up.
	private const int cCapturePumpLimit = 600;

	/// One pie_start or pie_screenshot in flight: the tool is re-entered every pump with the
	/// same arguments until the instance answers, or it gives up.
	private class Pending
	{
		/// BORROWED; null while nothing is in flight.
		public EditorPage Page = null;
		public int Pumps = 0;
		/// Per host, so two captures of one instance never share a default name.
		public int Serial = 0;
	}

	/// The pie_screenshot calls in flight, one per instance: the HTTP host re-enters every
	/// unfinished call each pump, so captures of two instances interleave.
	private class CaptureWaits
	{
		/// BORROWED pages, each with the pumps its capture has waited.
		public Dictionary<EditorPage, int> Pumps = new .() ~ delete _;
		public int Serial = 0;
	}

	public static void Register(McpServer server, EditorContext context)
	{
		let startSchema = scope SchemaBuilder();
		startSchema.Boolean("newInstance", "open another Game tab with an instance of its own (Play New Instance) instead of the primary");
		let starting = new Pending();
		server.RegisterTool("pie_start",
			"Start playing the project in the editor (PIE): the primary Game tab, or with `newInstance` another tab running an instance of its own - a host and a client, say. Cooks first, as Play does, loads the default scene and the startup script, and answers once the instance's first frame has rendered, with its state as pie_state gives it; `pie` is the id every other PIE tool takes. A primary already running is answered as it is, with `alreadyRunning`. A run that fails to start (a default scene that does not load) is an error; log_read says why.",
			startSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Start(context, starting, arguments, outResult, outError),
			starting);

		let stopSchema = scope SchemaBuilder();
		stopSchema.Str("pie", cPieArgument);
		stopSchema.Boolean("all", "stop every instance");
		server.RegisterTool("pie_stop",
			"Stop one PIE instance's run (or with `all`, every one's); its tab stays open, and the others keep running. Returns the ids stopped.",
			stopSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) => Stop(context, arguments, outResult, outError));

		let stateSchema = scope SchemaBuilder();
		stateSchema.Str("pie", cPieArgument);
		server.RegisterTool("pie_state",
			"One PIE instance's state: whether it is running (or starting, waiting on the cook), the scene it is in, `runTime`, the seconds of frames since it started (unscaled: a menu that stops gameplay time does not stop it), the frames rendered since, and its startup script's state (`none`, `running`, or `faulted` with the reason).",
			stateSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let page = ResolvePie(context, arguments, outError);
				if (page == null)
					return false;
				WriteState(page as IPieInstancePage, outResult);
				return true;
			});

		server.RegisterTool("pie_list",
			"Every open PIE instance, each with its state as pie_state gives it: what the user started as well as what an agent did.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let items = JsonValue.MakeArray();
				for (let page in context.OpenPages)
				{
					if (let pie = page as IPieInstancePage)
					{
						let item = JsonValue.MakeObject();
						WriteState(pie, item);
						items.Add(item);
					}
				}
				outResult.Set("count", JsonValue.MakeNumber(items.Count));
				outResult.Set("instances", items);
				return true;
			});

		let shotSchema = scope SchemaBuilder();
		shotSchema.Str("pie", cPieArgument);
		shotSchema.Str("path", "the PNG to write (default: a new file under <user-data>/screenshots)");
		let capturing = new CaptureWaits();
		server.RegisterTool("pie_screenshot",
			"What one running PIE instance's Game tab renders, as a PNG at the viewport's size: the game through its own camera, with its UI and overlays. Brings the tab to front (a hidden viewport never renders), waits for the next frame and the GPU, then returns {pie, path, width, height}; read the file. `path` is where to write (an existing directory; default: <user-data>/screenshots/<pie>-<pid>-<n>.png). Refused for a stopped instance; gives up after ten seconds without a rendered frame.",
			shotSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Screenshot(context, capturing, arguments, outResult, outError),
			capturing);

		PieRunTool.Register(server, context);
	}

	private static ToolOutcome Start(EditorContext context, Pending pending, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (pending.Page != null)
		{
			// Re-entered: the same call, one pump later.
			let page = pending.Page;
			pending.Pumps++;
			if (!context.OpenPages.Contains(page))
			{
				pending.Page = null;
				outError.Append("the Game tab closed while starting");
				return .Failed;
			}
			let pie = page as IPieInstancePage;
			if (pie.IsRunning && (pie.FrameCount > 0))
			{
				pending.Page = null;
				WriteState(pie, outResult);
				outResult.Set("alreadyRunning", JsonValue.MakeBool(false));
				return .Answered;
			}
			if (!pie.IsRunning && !pie.IsStarting)
			{
				pending.Page = null;
				outError.AppendF("PIE instance '{}' did not start (log_read says why)", pie.PieId);
				return .Failed;
			}
			if (pending.Pumps > cStartPumpLimit)
			{
				pending.Page = null;
				outError.AppendF("PIE instance '{}' rendered no frame in five minutes - a cook still running, or its tab hidden (an editor window minimised)?", pie.PieId);
				return .Failed;
			}
			return .NotFinished;
		}

		let newInstance = (arguments != null) && (arguments.Get("newInstance") != null) && arguments.Get("newInstance").AsBool();
		if (!newInstance)
		{
			if (let primary = FindPie(context, cPrimaryId))
			{
				let pie = primary as IPieInstancePage;
				if (pie.IsRunning)
				{
					WriteState(pie, outResult);
					outResult.Set("alreadyRunning", JsonValue.MakeBool(true));
					return .Answered;
				}
			}
		}

		// The editor's own Play path opens (or reveals) the tab; the new one is the Game page
		// that was not open before.
		let before = scope List<EditorPage>();
		for (let page in context.OpenPages)
		{
			if (page is IPieInstancePage)
				before.Add(page);
		}
		let actionId = newInstance ? "game.playNewInstance" : "game.play";
		switch (context.Actions.Execute(actionId))
		{
		case .Err(.NotSupported):
			outError.AppendF("the editor refused '{}': it plays only with a project open", actionId);
			return .Failed;
		case .Err(let code):
			outError.AppendF("the editor has no '{}' action ({})", actionId, code);
			return .Failed;
		case .Ok:
		}
		EditorPage target = null;
		for (let page in context.OpenPages)
		{
			let pie = page as IPieInstancePage;
			if (pie == null)
				continue;
			if (newInstance ? !before.Contains(page) : (pie.PieId == cPrimaryId))
			{
				target = page;
				break;
			}
		}
		if (target == null)
		{
			outError.Append("no Game tab opened: this editor build has no play-in-editor");
			return .Failed;
		}
		(target as IPieInstancePage).Play();
		pending.Page = target;
		pending.Pumps = 0;
		return .NotFinished;
	}

	private static ToolOutcome Stop(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let stopped = JsonValue.MakeArray();
		let all = (arguments != null) && (arguments.Get("all") != null) && arguments.Get("all").AsBool();
		if (all)
		{
			for (let page in context.OpenPages)
			{
				if (let pie = page as IPieInstancePage)
				{
					if (pie.IsRunning || pie.IsStarting)
						stopped.Add(JsonValue.MakeString(pie.PieId));
					pie.Stop();
				}
			}
		}
		else
		{
			let page = ResolvePie(context, arguments, outError);
			if (page == null)
			{
				delete stopped;
				return .Failed;
			}
			let pie = page as IPieInstancePage;
			if (pie.IsRunning || pie.IsStarting)
				stopped.Add(JsonValue.MakeString(pie.PieId));
			pie.Stop();
		}
		outResult.Set("stopped", stopped);
		return .Answered;
	}

	private static ToolOutcome Screenshot(EditorContext context, CaptureWaits waits, JsonValue arguments, JsonValue outResult, String outError)
	{
		// A wait whose tab closed is over; its page pointer is never used again.
		for (let wait in waits.Pumps)
		{
			if (!context.OpenPages.Contains(wait.key))
				@wait.Remove();
		}
		let page = ResolvePie(context, arguments, outError);
		if (page == null)
			return .Failed;
		let pie = page as IPieInstancePage;
		if (waits.Pumps.TryGetValue(page, let pumps))
		{
			// Re-entered: the same call, one pump later.
			let capture = pie.LastViewportCapture;
			waits.Pumps[page] = pumps + 1;
			if (capture.State == .Written)
			{
				waits.Pumps.Remove(page);
				outResult.Set("pie", JsonValue.MakeString(pie.PieId));
				outResult.Set("path", JsonValue.MakeString(capture.Path));
				outResult.Set("width", JsonValue.MakeNumber(capture.Width));
				outResult.Set("height", JsonValue.MakeNumber(capture.Height));
				return .Answered;
			}
			if (capture.State == .Failed)
			{
				waits.Pumps.Remove(page);
				outError.AppendF("the capture of PIE instance '{}' failed (log_read, category Screenshot, says why)", pie.PieId);
				return .Failed;
			}
			if (!pie.IsRunning)
			{
				waits.Pumps.Remove(page);
				outError.AppendF("PIE instance '{}' stopped before a frame was captured", pie.PieId);
				return .Failed;
			}
			if (pumps + 1 > cCapturePumpLimit)
			{
				waits.Pumps.Remove(page);
				outError.AppendF("PIE instance '{}' rendered no frame in ten seconds - is its tab visible (an editor window minimised or hidden)?", pie.PieId);
				return .Failed;
			}
			return .NotFinished;
		}
		if (!pie.IsRunning)
		{
			outError.AppendF("PIE instance '{}' is not running (pie_start runs it)", pie.PieId);
			return .Failed;
		}
		let path = scope String();
		let pathArg = (arguments != null) ? arguments.Get("path") : null;
		if ((pathArg != null) && pathArg.IsString)
			path.Set(pathArg.AsString());
		if (path.IsEmpty)
		{
			let directory = scope String();
			PathJoin(GetUserDataDirectory(.. scope .()), "screenshots", directory);
			if (!CreateDirectory(directory))
			{
				outError.AppendF("could not create '{}'", directory);
				return .Failed;
			}
			waits.Serial++;
			PathJoin(directory, scope $"{pie.PieId}-{System.Diagnostics.Process.CurrentId}-{waits.Serial}.png", path);
		}
		context.RevealPage(page); // to front: a background tab's viewport never renders
		pie.RequestViewportCapture(path);
		waits.Pumps[page] = 0;
		return .NotFinished;
	}

	/// The open Game page with this PIE id, or null.
	public static EditorPage FindPie(EditorContext context, StringView id)
	{
		for (let page in context.OpenPages)
		{
			if (let pie = page as IPieInstancePage)
			{
				if (pie.PieId == id)
					return page;
			}
		}
		return null;
	}

	/// The instance a call addresses: `pie`, or the primary.
	public static EditorPage ResolvePie(EditorContext context, JsonValue arguments, String outError)
	{
		let arg = (arguments != null) ? arguments.Get("pie") : null;
		let id = ((arg != null) && arg.IsString && !arg.AsString().IsEmpty) ? arg.AsString() : StringView(cPrimaryId);
		let page = FindPie(context, id);
		if (page != null)
			return page;
		if (id == cPrimaryId)
			outError.Append("no Game tab is open (pie_start opens and runs one)");
		else
			outError.AppendF("no PIE instance '{}' (pie_list names them)", id);
		return null;
	}

	public static void WriteState(IPieInstancePage pie, JsonValue outResult)
	{
		outResult.Set("pie", JsonValue.MakeString(pie.PieId));
		outResult.Set("running", JsonValue.MakeBool(pie.IsRunning));
		outResult.Set("starting", JsonValue.MakeBool(pie.IsStarting));
		outResult.Set("scene", JsonValue.MakeString(pie.SceneName));
		outResult.Set("runTime", JsonValue.MakeNumber(pie.RunTime));
		outResult.Set("frames", JsonValue.MakeNumber((double)pie.FrameCount));
		let script = JsonValue.MakeObject();
		switch (pie.ScriptState)
		{
		case .None: script.Set("state", JsonValue.MakeString("none"));
		case .Running: script.Set("state", JsonValue.MakeString("running"));
		case .Faulted:
			script.Set("state", JsonValue.MakeString("faulted"));
			script.Set("fault", JsonValue.MakeString(pie.ScriptFault));
		}
		outResult.Set("script", script);
	}
}
