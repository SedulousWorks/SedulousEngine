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
/// harmless, a port in use reported, and Preferences' Save starting and stopping it. With no
/// project (the project manager's), the editor's own tools serve and the project's refuse. Ports come
/// from the OS (a listener on port 0, closed before the host takes it), so a running editor's
/// 7405 is never touched; the user data directory is a scratch folder, so the user's own token
/// is never touched either.
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
		// The project's plugins' export hooks, which project_export through this host runs.
		let hooks = scope ExportPluginServices();
		bench.Context.ExportHooks = hooks;
		defer { bench.Context.ExportHooks = null; }

		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.Session.ExportHooks === hooks, "the session carries them");
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
		// The surface: the engine tools, host_info, the pages, the windows, the input tools, the
		// profiler and the application's own, each once.
		Test.Assert(tools != null);
		let listed = tools.Get("result").Get("tools");
		Test.Assert(listed.Count == EngineTools.cEngineToolCount + 1 + EditorPageTools.cPageToolCount
			+ EditorWindowTools.cWindowToolCount + EditorInputTools.cInputToolCount + EditorProfilerTools.cProfilerToolCount
			+ 1);
		let names = scope List<String>();
		defer ClearAndDeleteItems(names);
		for (int i < listed.Count)
			names.Add(new String(listed.At(i).Get("name").AsString()));
		for (let expected in StringView[?]("host_info", "page_list", "page_close", "editor_screenshot", "editor_click", "profiler_capture", "app_tool"))
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
		Test.Assert(service.Session.ExportHooks == null, "dropped as it stops");
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
		// Nor in the project manager.
		Test.Assert(!service.EnsureRunning());
		Test.Assert(!service.IsRunning);
		bench.Preference.Enabled = true;
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

	/// The preference's port, taken, is reported at once: no retry.
	[Test]
	public static void APortInUseIsReported()
	{
		let bench = scope Bench("mcp_service_taken");
		bench.Preference.Enabled = true;
		bench.Preference.Token.Set(cToken);
		var holder = new Sedulous.Net.TcpListener(0, true); // another editor, as far as this one knows
		Test.Assert(holder.IsOpen);
		let port = holder.BoundPort;
		bench.Preference.Port = port;
		let services = bench.Services();
		let service = scope EditorMcpService(services);
		Test.Assert(!service.Start(bench.Project));
		Test.Assert(!service.IsRunning);
		Test.Assert(!service.IsRetrying);
		Test.Assert(service.Host == null);
		// Said in the log, with the way out; the status line does not claim a host.
		Test.Assert(bench.Logged(.Warning, scope $"could not listen on 127.0.0.1:{port}"));
		Test.Assert(!bench.HasSaid(scope $"MCP host on 127.0.0.1:{port}"));
		// The port freed, the same service starts on it.
		DeleteAndNullify!(holder);
		Test.Assert(service.Start(bench.Project));
		Test.Assert(service.Host.BoundPort == port);
	}

	/// The retry policy, over times given: a try due every interval from the first refusal, the
	/// last refusal past the window ending it, a window of none never retrying, and End stopping it.
	[Test]
	public static void ARefusedBindIsTriedEveryIntervalUntilTheWindowPasses()
	{
		var retry = BindRetry();
		Test.Assert(!retry.IsActive);
		Test.Assert(retry.Begin(1000, 1000));
		Test.Assert(retry.IsActive);
		Test.Assert(!retry.IsDue(1000 + BindRetry.cIntervalMs - 1));
		Test.Assert(retry.IsDue(1000 + BindRetry.cIntervalMs));
		Test.Assert(retry.Refused(1000 + BindRetry.cIntervalMs), "inside the window: on");
		Test.Assert(!retry.IsDue(1000 + 2 * BindRetry.cIntervalMs - 1), "the next an interval after that try");
		Test.Assert(retry.IsDue(1000 + 2 * BindRetry.cIntervalMs));
		Test.Assert(retry.Refused(1999));
		Test.Assert(!retry.Refused(2000), "the window passed");
		Test.Assert(!retry.IsActive);
		Test.Assert(!retry.IsDue(5000));

		Test.Assert(!retry.Begin(0, 0), "a window of none tries once");
		Test.Assert(!retry.IsActive);
		Test.Assert(retry.Begin(0));
		retry.End();
		Test.Assert(!retry.IsActive && !retry.IsDue(BindRetry.cWindowMs));
	}

	/// The command line's port, busy as a relaunched editor finds it while the one before exits:
	/// the start says no, the host tries again from Pump without blocking it, and listens once the
	/// port is let go. Still taken past the window, it is logged and released.
	[Test]
	public static void TheCommandLinesPortIsTriedAgainUntilItIsLetGo()
	{
		let bench = scope Bench("mcp_service_retry");
		bench.Preference.Token.Set(cToken);
		var holder = new Sedulous.Net.TcpListener(0, true); // the editor before this one, exiting
		Test.Assert(holder.IsOpen);
		let port = holder.BoundPort;
		{
			let services = bench.Services();
			services.Port = port;
			services.ForceEnabled = true;
			let service = scope EditorMcpService(services);
			Test.Assert(!service.Start(bench.Project));
			Test.Assert(service.IsRetrying);
			Test.Assert(!service.IsRunning);
			Test.Assert(!bench.Logged(.Warning, scope $"could not listen on 127.0.0.1:{port}"), "not yet");
			service.Pump(); // nothing due yet: it returns at once
			Test.Assert(service.IsRetrying);
			DeleteAndNullify!(holder); // that editor has gone
			for (int i = 0; (i < 3000) && !service.IsRunning; i++)
			{
				service.Pump();
				System.Threading.Thread.Sleep(1);
			}
			Test.Assert(service.IsRunning);
			Test.Assert(!service.IsRetrying);
			Test.Assert(service.Port == port);
			Test.Assert(bench.HasSaid(scope $"MCP host on 127.0.0.1:{port}"));
			service.Stop();
		}
		// Taken for good: given up once the window passes.
		holder = new Sedulous.Net.TcpListener(port, true);
		defer delete holder;
		Test.Assert(holder.IsOpen);
		{
			let services = bench.Services();
			services.Port = port;
			services.ForceEnabled = true;
			services.BindRetryMs = 300;
			let service = scope EditorMcpService(services);
			Test.Assert(!service.Start(bench.Project));
			Test.Assert(service.IsRetrying);
			for (int i = 0; (i < 3000) && service.IsRetrying; i++)
			{
				service.Pump();
				System.Threading.Thread.Sleep(1);
			}
			Test.Assert(!service.IsRetrying);
			Test.Assert(!service.IsRunning);
			Test.Assert(service.Host == null);
			Test.Assert(bench.Logged(.Warning, scope $"could not listen on 127.0.0.1:{port}"));
		}
	}

	/// Preferences' Save over a real host, as the application wires it (the open project's host
	/// started again over the saved section): enabled, the host starts; turned off, it stops and
	/// lets the port go.
	[Test]
	public static void PreferencesSaveStartsOrStopsTheHostOverTheOpenProject()
	{
		let bench = scope Bench("mcp_service_preferences");
		bench.Preference.Token.Set(cToken);
		let port = FreePort();
		let services = bench.Services();
		services.Port = port; // the command line's: the preference's port stays the dialog's
		let service = scope EditorMcpService(services);

		let context = new Sedulous.GUI.GUIContext();
		let root = new Sedulous.GUI.SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		let preferences = new EditorPreferencesServices();
		preferences.User = bench.UserSettings;
		let project = bench.Project;
		preferences.McpChanged = new [=service, =project] () => { service.Start(project); };
		let dialog = new EditorPreferencesDialog(preferences, PreferencesDialogTests.LoadPreferences());
		defer delete dialog; // before the root and the service
		let enabled = dialog.Window.FindElement("pref-mcp-enabled") as Sedulous.GUI.CheckBox;
		Test.Assert(enabled != null);

		Test.Assert(dialog.Open(root));
		Test.Assert(!enabled.Checked);
		Test.Assert(enabled.HandleActivate());
		Test.Assert(dialog.Save());
		Test.Assert(service.IsRunning);
		Test.Assert(service.Host.BoundPort == port);
		Test.Assert(bench.Preference.Token == cToken, "the token shown is the token kept");

		Test.Assert(dialog.Open(root));
		Test.Assert(enabled.Checked);
		Test.Assert(enabled.HandleActivate());
		Test.Assert(dialog.Save());
		Test.Assert(!service.IsRunning);
		Test.Assert(PortIsFree(port));
	}

	/// The project manager's host: enabled, it serves with no project, once however often the
	/// manager shows; host_info says so, the project's tools refuse, the editor's answer, and the
	/// manager's GUI is reached as a user would.
	[Test]
	public static void WithNoProjectItServesTheManagerAndTheProjectsToolsRefuse()
	{
		let bench = scope Bench("mcp_service_manager");
		bench.Preference.Enabled = false;
		bench.Preference.Token.Set(cToken);
		let port = FreePort();
		// The manager over the window: a button to find.
		let gui = new Sedulous.GUI.GUIContext();
		let root = new Sedulous.GUI.SceneRoot(gui);
		gui.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(400.0f, 300.0f);
		let samples = new Sedulous.GUI.Button();
		samples.Id = "manager-tab-samples";
		samples.Text = "Samples";
		samples.Position = .(10.0f, 10.0f);
		samples.Size = .(80.0f, 30.0f);
		root.AddChild(samples);
		samples.ReleaseRef(); // the root holds it
		root.UpdateLayout();
		let services = bench.Services();
		services.Port = port;
		services.GuiRoot = new [=root] () => root;
		let service = scope EditorMcpService(services);

		// Not enabled, no host: the user never asked for one.
		Test.Assert(!service.EnsureRunning());
		Test.Assert(!service.IsRunning);
		// The user's Start (the MCP panel's) runs it whatever the preference says; their Stop
		// holds, over the manager and every project, until they start it again or the preferences
		// change.
		Test.Assert(service.StartByUser(null));
		Test.Assert(service.Port == port);
		Test.Assert(service.ConnectCommand(.. scope .()).Contains(scope $"http://127.0.0.1:{port}/mcp"));
		service.StopByUser();
		Test.Assert(!service.IsRunning);
		Test.Assert(service.IsStopHeld);
		Test.Assert(service.Port == 0);
		Test.Assert(service.ConnectCommand(.. scope .()).IsEmpty);
		Test.Assert(!service.EnsureRunning());
		service.Restart(null); // the preferences changed, and they say off
		Test.Assert(!service.IsStopHeld);
		Test.Assert(!service.IsRunning);
		// The activity kept the host's own events.
		Test.Assert(service.Activity.Count == 2);
		Test.Assert(service.Activity[0].Tool.StartsWith("Listening on 127.0.0.1:"));
		Test.Assert(service.Activity[1].Tool == "Stopped");
		service.Activity.Clear();
		services.ForceEnabled = true;
		Test.Assert(service.EnsureRunning());
		Test.Assert(service.Host.BoundPort == port);
		let host = service.Host;
		Test.Assert(service.EnsureRunning());
		Test.Assert(service.Host == host, "the manager shown again keeps the host");

		var rng = Sedulous.Core.Random(12);
		let guidArgument = scope String()..AppendF("{{\"guid\":\"{}\"}}", Guid.Generate(ref rng));
		JsonValue info = null, assets = null, opened = null, scene = null, pages = null, log = null, found = null;
		defer { delete info; delete assets; delete opened; delete scene; delete pages; delete log; delete found; }
		bool done = false;
		let client = scope Thread(new [&]() =>
			{
				delete Call(port, "{\"jsonrpc\":\"2.0\",\"id\":10,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-06-18\",\"clientInfo\":{\"name\":\"test-agent\",\"version\":\"1.0\"}}}");
				info = Call(port, ToolCall(1, "host_info", "{}", .. scope .()));
				assets = Call(port, ToolCall(2, "asset_list", "{}", .. scope .()));
				opened = Call(port, ToolCall(3, "page_open", guidArgument, .. scope .()));
				scene = Call(port, ToolCall(4, "scene_validate", guidArgument, .. scope .()));
				pages = Call(port, ToolCall(5, "page_list", "{}", .. scope .()));
				log = Call(port, ToolCall(6, "log_read", "{\"limit\":5}", .. scope .()));
				found = Call(port, ToolCall(7, "editor_find", "{\"target\":\"#manager-tab-samples\"}", .. scope .()));
				done = true;
			});
		client.Start(false);
		for (int i = 0; (i < 5000) && !done; i++)
		{
			service.Pump();
			Thread.Sleep(1);
		}
		client.Join();

		// host_info: the manager, no project.
		Test.Assert((info != null) && !IsError(info));
		let infoPayload = Payload(info);
		defer delete infoPayload;
		Test.Assert(infoPayload.Get("host").Get("projectOpen").AsBool() == false);
		Test.Assert(infoPayload.Get("host").Get("screen").AsString() == "projectManager");
		Test.Assert(infoPayload.Get("host").Get("projectName") == null);
		// The project's tools refuse, naming the fix; nothing was asked to open.
		for (let refused in JsonValue[?](assets, opened, scene))
		{
			Test.Assert((refused != null) && IsError(refused));
			Test.Assert(refused.Get("result").Get("content").At(0).Get("text").AsString().Contains(McpTools.cNoProject));
		}
		for (let recorded in bench.Events)
			Test.Assert(!recorded.StartsWith("open "));
		// The editor's own answer: no pages, the log, and the manager's GUI.
		Test.Assert((pages != null) && !IsError(pages));
		let pagesPayload = Payload(pages);
		defer delete pagesPayload;
		Test.Assert(pagesPayload.Get("pages").Count == 0);
		Test.Assert((log != null) && !IsError(log));
		Test.Assert((found != null) && !IsError(found));
		let foundPayload = Payload(found);
		defer delete foundPayload;
		Test.Assert(foundPayload.Get("count").AsInt() == 1);
		Test.Assert(foundPayload.Get("nodes").At(0).Get("text").AsString() == "Samples");

		// The activity: the host listening, the client, then each call in order with its outcome.
		let activity = service.Activity;
		Test.Assert(service.ClientName == "test-agent");
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		for (int i < activity.Count)
		{
			let entry = activity[i];
			if (entry.IsCall)
				seen.Add(new $"{entry.Tool}:{(entry.Outcome == .Failed) ? "failed" : "done"}");
			else
				seen.Add(new String(entry.Tool));
		}
		Test.Assert(seen.Count == 9);
		Test.Assert(seen[0].StartsWith("Listening on 127.0.0.1:"));
		Test.Assert(seen[1] == "test-agent 1.0 connected", seen[1]);
		Test.Assert(seen[2] == "host_info:done");
		Test.Assert(seen[3] == "asset_list:failed");
		Test.Assert(seen[8] == "editor_find:done");
		Test.Assert(activity[4].Arguments == guidArgument);

		// The user's Stop holds even over --mcp.
		service.StopByUser();
		Test.Assert(!service.EnsureRunning());
		Test.Assert(PortIsFree(port));
	}
}
