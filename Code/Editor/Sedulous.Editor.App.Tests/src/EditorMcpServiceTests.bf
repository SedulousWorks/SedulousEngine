using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Http;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorMcpService, headless, over REAL loopback against a scratch project: the command
/// line's port before the preference's, the host's surface (the engine tools, host_info, the
/// pages, the windows, the profiler and the application's own) and its hooks reached by real
/// calls, the status lines and the log while it runs, the token minted once and saved, a
/// start refused when disabled or without a log capture, a second start and a second stop
/// harmless, and a port in use reported. Ports come from the OS (a listener on port 0, closed
/// before the host takes it), so a running editor's 7405 is never touched; the user data
/// directory is a scratch folder, so the user's own token is never touched either.
class EditorMcpServiceTests
{
	const String cToken = "sekrit";

	/// The services a service runs on; the status lines land in Said, the hooks in Events, and
	/// the global log in Log for the run of the bench.
	class Bench
	{
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public EditorJobService Jobs = new .() ~ delete _;
		public Settings UserSettings = new .() ~ delete _;
		public EditorLogBuffer Log = new .() ~ delete _;
		public EditorProject Project ~ delete _;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Events = new .() ~ DeleteContainerAndItems!(_);
		public String ProjectDir = new .() ~ delete _;
		public String UserData = new .() ~ delete _;
		private ILogger mPreviousLogger;
		private bool mPreviousOwned;

		public this(StringView leaf)
		{
			EditorSerializables.RegisterAll();
			let cwd = System.IO.Directory.GetCurrentDirectory(.. scope .());
			PathJoin(cwd, scope $"scratch_{leaf}_project", ProjectDir);
			PathJoin(cwd, scope $"scratch_{leaf}_userdata", UserData);
			RemoveDirectoryRecursive(ProjectDir);
			RemoveDirectoryRecursive(UserData);
			Test.Assert(EditorProject.Create(ProjectDir, "Hosted") case .Ok);
			Project = EditorProject.Open(ProjectDir);
			Test.Assert(Project != null);
			let said = Said;
			Context.OnStatus = new [=said](text) => { said.Add(new String(text)); };
			mPreviousLogger = DetachGlobalLogger(out mPreviousOwned);
			InitGlobalLogger(Log); // the bench's
		}

		public ~this()
		{
			bool logOwned = false;
			DetachGlobalLogger(out logOwned);
			InitGlobalLogger(mPreviousLogger, mPreviousOwned);
			Cook.Shutdown();
			DeleteAndNullify!(Project); // closed before its folder goes
			RemoveDirectoryRecursive(ProjectDir);
			RemoveDirectoryRecursive(UserData);
		}

		public EditorMcpSettings Preference => UserSettings.Section<EditorMcpSettings>();

		/// The services over this bench, every hook recording; the service owns them.
		public EditorMcpServiceServices Services()
		{
			let services = new EditorMcpServiceServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Jobs = Jobs;
			services.Builders = Builders;
			services.UserSettings = UserSettings;
			services.Log = Log;
			services.UserDataDirectory.Set(UserData);
			let bench = this;
			services.OpenPage = new [=bench](id) =>
				{
					bench.Events.Add(new $"open {id}");
					return bench.Context.AdoptPage(new TestPage(id));
				};
			services.ClosePage = new [=bench](page) =>
				{
					bench.Events.Add(new $"close {page.InstanceId}");
					bench.Context.ClosePage(page);
				};
			services.Windows = new [=bench](outWindows) => { bench.Events.Add(new .("windows")); };
			services.AddTools = new [=bench](server) =>
				{
					bench.Events.Add(new .("addTools"));
					server.RegisterTool("app_tool", "the application's own", scope SchemaBuilder().Build(), .ReadOnly,
						new (arguments, outResult, outError) => true);
				};
			return services;
		}

		public bool HasSaid(StringView text)
		{
			for (let line in Said)
				if (line == text)
					return true;
			return false;
		}

		public bool HasEvent(StringView name)
		{
			for (let recorded in Events)
				if (recorded == name)
					return true;
			return false;
		}

		/// A line at `level` in the captured log, its category "MCP" (the buffer splits the
		/// "MCP: " prefix off), its message containing `text`.
		public bool Logged(LogLevel level, StringView text)
		{
			let entries = scope List<EditorLogEntry>();
			defer ClearAndDeleteItems(entries);
			Log.CollectSince(0, entries);
			for (let entry in entries)
				if ((entry.Level == level) && (entry.Category == "MCP") && entry.Message.Contains(text))
					return true;
			return false;
		}
	}

	class TestPage : EditorPage
	{
		public this(Guid asset)
		{
			InstanceId = asset;
		}

		public override StringView Title => "test";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	/// A port nothing listens on now: the OS's choice, its listener closed again.
	private static uint16 FreePort()
	{
		let probe = scope Sedulous.Net.TcpListener(0, true);
		Test.Assert(probe.IsOpen);
		return probe.BoundPort;
	}

	/// Whether `port` can be listened on now, i.e. nothing holds it.
	private static bool PortIsFree(uint16 port)
	{
		let probe = scope Sedulous.Net.TcpListener(port, true);
		return probe.IsOpen;
	}

	private static HttpRequest Post(StringView token, StringView body)
	{
		let request = new HttpRequest("POST", "/mcp");
		request.AddHeader("Authorization", scope $"Bearer {token}");
		request.AddHeader("Content-Type", "application/json");
		request.SetBodyText(body);
		return request;
	}

	/// One tools/call from the client thread: the parsed response, OWNED by the caller, or null
	/// on a transport failure.
	private static JsonValue Call(uint16 port, StringView body)
	{
		let request = Post(cToken, body);
		defer delete request;
		if (HttpClient.Fetch("127.0.0.1", port, request) case .Ok(let response))
		{
			defer delete response;
			if (response.Status == 200)
				return JsonValue.Parse(response.BodyText);
		}
		return null;
	}

	private static void ToolCall(int id, StringView tool, StringView arguments, String outBody)
	{
		outBody.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":{},\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", id, tool, arguments);
	}

	/// A finished tool's JSON payload out of the tools/call envelope, OWNED by the caller.
	private static JsonValue Payload(JsonValue response)
	{
		return JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
	}

	private static bool IsError(JsonValue response)
	{
		let flag = response.Get("result").Get("isError");
		return (flag != null) && flag.AsBool();
	}

	[Test]
	public static void StartsOnTheCommandLinesPortServesItsSurfaceAndStops()
	{
		let bench = scope Bench("mcp_service_serve");
		let preferencePort = FreePort();
		var commandLinePort = FreePort();
		while (commandLinePort == preferencePort)
			commandLinePort = FreePort();
		bench.Preference.Enabled = false; // --mcp alone turns it on
		bench.Preference.Port = preferencePort;
		bench.Preference.Token.Set(cToken);
		let services = bench.Services();
		services.ForceEnabled = true;
		services.Port = commandLinePort;
		let service = scope EditorMcpService(services);
		Test.Assert(!service.IsRunning);
		Test.Assert(service.Host == null);

		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.IsRunning);
		Test.Assert(service.Host != null);
		Test.Assert(service.Host.IsRunning);
		// The command line's port wins over the preference's.
		Test.Assert(service.Host.BoundPort == commandLinePort);
		Test.Assert(bench.HasEvent("addTools"));
		// The token was there: kept, written to the token file, the settings not saved.
		Test.Assert(bench.Preference.Token == cToken);
		Test.Assert(System.IO.File.ReadAllText(PathJoin(bench.UserData, EditorMcpHost.cTokenFileName, .. scope .()), .. scope .()) == cToken);
		Test.Assert(!System.IO.File.Exists(PathJoin(bench.UserData, EditorSettingsStore.cFileName, .. scope .())));
		// What the user sees while it runs: the status line and the log name the port.
		Test.Assert(bench.HasSaid(scope $"MCP host on 127.0.0.1:{commandLinePort}"));
		Test.Assert(bench.Logged(.Information, scope $"listening on 127.0.0.1:{commandLinePort}"));

		var rng = Sedulous.Core.Random(11);
		let pageId = Guid.Generate(ref rng);
		let pageArgument = scope String()..AppendF("{{\"guid\":\"{}\"}}", pageId);
		let port = commandLinePort;
		JsonValue info = null, projectInfo = null, tools = null, opened = null, closed = null, screenshot = null;
		defer { delete info; delete projectInfo; delete tools; delete opened; delete closed; delete screenshot; }
		bool done = false;
		let client = scope Thread(new [&]() =>
			{
				info = Call(port, ToolCall(1, "host_info", "{}", .. scope .()));
				projectInfo = Call(port, ToolCall(2, "project_info", "{}", .. scope .()));
				tools = Call(port, "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/list\"}");
				opened = Call(port, ToolCall(4, "page_open", pageArgument, .. scope .()));
				closed = Call(port, ToolCall(5, "page_close", pageArgument, .. scope .()));
				screenshot = Call(port, ToolCall(6, "editor_screenshot", "{}", .. scope .()));
				done = true;
			});
		client.Start(false);
		for (int i = 0; (i < 5000) && !done; i++)
		{
			service.Pump(); // the calls are answered here, on this thread
			Thread.Sleep(1);
		}
		client.Join();

		// host_info: the editor's host over the project it was started on, with its build stamp.
		Test.Assert(info != null);
		let infoPayload = Payload(info);
		defer delete infoPayload;
		Test.Assert(infoPayload.Get("serverName").AsString() == "engine-editor-mcp");
		Test.Assert(infoPayload.Get("buildStamp").AsString() == EditorMcpService.BuildStamp(.. scope .()));
		Test.Assert(infoPayload.Get("host").Get("projectName").AsString() == "Hosted");
		// project_info answers for the same project.
		Test.Assert(projectInfo != null);
		let projectPayload = Payload(projectInfo);
		defer delete projectPayload;
		Test.Assert(projectPayload.Get("name").AsString() == "Hosted");
		// The surface: the engine tools, host_info, the pages, the windows, the profiler and the
		// application's own, each once.
		Test.Assert(tools != null);
		let listed = tools.Get("result").Get("tools");
		Test.Assert(listed.Count == EngineTools.cEngineToolCount + 1 + EditorPageTools.cPageToolCount
			+ EditorWindowTools.cWindowToolCount + EditorProfilerTools.cProfilerToolCount + 1);
		let names = scope List<String>();
		defer ClearAndDeleteItems(names);
		for (int i < listed.Count)
			names.Add(new String(listed.At(i).Get("name").AsString()));
		for (let expected in StringView[?]("host_info", "page_list", "page_close", "editor_screenshot", "profiler_capture", "app_tool"))
		{
			bool found = false;
			for (let name in names)
				found |= (name == expected);
			Test.Assert(found);
		}
		// The page tools reach the application's open and close.
		Test.Assert((opened != null) && !IsError(opened));
		Test.Assert(bench.HasEvent(scope $"open {pageId}"));
		Test.Assert((closed != null) && !IsError(closed));
		Test.Assert(bench.HasEvent(scope $"close {pageId}"));
		Test.Assert(bench.Context.OpenPages.Count == 0);
		// The screenshot asked the application for its windows; with none it fails.
		Test.Assert((screenshot != null) && IsError(screenshot));
		Test.Assert(bench.HasEvent("windows"));
		// Every finished call is said on the status line.
		Test.Assert(bench.HasSaid("MCP: host_info done"));
		Test.Assert(bench.HasSaid("MCP: page_open done"));
		Test.Assert(bench.HasSaid("MCP: editor_screenshot failed"));

		service.Stop();
		Test.Assert(!service.IsRunning);
		Test.Assert(service.Host == null);
		Test.Assert(PortIsFree(commandLinePort)); // released

		// Without the command line's port, the preference's.
		services.Port = 0;
		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.Host.BoundPort == preferencePort);
		service.Stop();
		Test.Assert(PortIsFree(preferencePort));
	}

	[Test]
	public static void DisabledOrWithoutALogCaptureItDoesNotStart()
	{
		let bench = scope Bench("mcp_service_disabled");
		bench.Preference.Enabled = false;
		bench.Preference.Port = 0;
		let services = bench.Services();
		let service = scope EditorMcpService(services);
		// Neither the preference nor the command line: nothing starts, nothing is minted.
		Test.Assert(!service.Start(bench.Project));
		Test.Assert(!service.IsRunning);
		Test.Assert(bench.Preference.Token.IsEmpty);
		Test.Assert(!bench.HasEvent("addTools"));
		// No project: nothing to serve.
		bench.Preference.Enabled = true;
		Test.Assert(!service.Start(null));
		Test.Assert(!service.IsRunning);
		// No log capture: log_read would have nothing to serve, so the host does not start.
		services.Log = null;
		Test.Assert(!service.Start(bench.Project));
		Test.Assert(!service.IsRunning);
		Test.Assert(bench.Logged(.Warning, "no log capture was installed"));
		Test.Assert(bench.Preference.Token.IsEmpty);
		// With one, the preference alone starts it.
		services.Log = bench.Log;
		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.IsRunning);
	}

	[Test]
	public static void TheFirstEnableMintsTheTokenOnceAndSavesIt()
	{
		let bench = scope Bench("mcp_service_mint");
		bench.Preference.Enabled = true;
		bench.Preference.Port = 0; // the OS's choice
		let service = scope EditorMcpService(bench.Services());
		Test.Assert(bench.Preference.Token.IsEmpty);
		Test.Assert(service.Start(bench.Project));
		let token = scope String(bench.Preference.Token);
		Test.Assert(token.Length == 36);
		// The token file and the saved settings carry it, under the services' user data folder.
		Test.Assert(System.IO.File.ReadAllText(PathJoin(bench.UserData, EditorMcpHost.cTokenFileName, .. scope .()), .. scope .()) == token);
		let saved = scope Settings();
		Test.Assert(EditorSettingsStore.Load(scope NativeFileSystem(bench.UserData), saved) case .Ok);
		Test.Assert(saved.Section<EditorMcpSettings>().Token == token);
		// Kept from then on: a second start serves the same secret.
		service.Stop();
		Test.Assert(service.Start(bench.Project));
		Test.Assert(bench.Preference.Token == token);
	}

	[Test]
	public static void StartingWhileRunningAndStoppingWhenStoppedAreHarmless()
	{
		let bench = scope Bench("mcp_service_twice");
		bench.Preference.Enabled = true;
		bench.Preference.Token.Set(cToken);
		let port = FreePort();
		let services = bench.Services();
		services.Port = port;
		{
			let service = scope EditorMcpService(services);
			service.Stop(); // none runs: nothing
			Test.Assert(!service.IsRunning);
			Test.Assert(service.Start(bench.Project));
			// Again while running: the first host goes before the second binds the same port.
			Test.Assert(service.Start(bench.Project));
			Test.Assert(service.IsRunning);
			Test.Assert(service.Host.BoundPort == port);
			Test.Assert(service.Host.IsRunning);
			service.Stop();
			service.Stop();
			Test.Assert(!service.IsRunning);
			Test.Assert(PortIsFree(port));
			service.Pump(); // nothing to pump: nothing happens
			// Running when it goes: its destructor stops the host.
			Test.Assert(service.Start(bench.Project));
			Test.Assert(!PortIsFree(port));
		}
		Test.Assert(PortIsFree(port));
	}

	[Test]
	public static void APortInUseIsReported()
	{
		let bench = scope Bench("mcp_service_taken");
		bench.Preference.Enabled = true;
		bench.Preference.Token.Set(cToken);
		var holder = new Sedulous.Net.TcpListener(0, true); // another editor, as far as this one knows
		Test.Assert(holder.IsOpen);
		let port = holder.BoundPort;
		let services = bench.Services();
		services.Port = port;
		let service = scope EditorMcpService(services);
		Test.Assert(!service.Start(bench.Project));
		Test.Assert(!service.IsRunning);
		Test.Assert(service.Host == null);
		// Said in the log, with the way out; the status line does not claim a host.
		Test.Assert(bench.Logged(.Warning, scope $"could not listen on 127.0.0.1:{port}"));
		Test.Assert(!bench.HasSaid(scope $"MCP host on 127.0.0.1:{port}"));
		// The port freed, the same service starts on it.
		DeleteAndNullify!(holder);
		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.Host.BoundPort == port);
	}
}
