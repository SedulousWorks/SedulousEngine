using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The greeter's Tooling part: one tool of its own, and one whose name the engine holds.
class GreeterPart : PluginPart
{
	public static bool TakenRefused = false;
	private String mManifest = new .() ~ delete _;

	public this(StringView manifest) { mManifest.Set(manifest); }

	public override StringView PluginId => "greeter";
	public override PluginPartKind Kind => .Tooling;
	public override StringView ManifestXml => mManifest;

	public override void Load(PluginContext context)
	{
		let services = context.Find<McpPluginServices>();
		Test.Assert(services != null);
		Test.Assert(services.AddTools(new (tools) =>
			{
				let session = tools.Session;
				Test.Assert(tools.RegisterTool("greeter_hello", "Greets the open project", scope SchemaBuilder().Build(), .ReadOnly,
					new (arguments, outResult, outError) =>
					{
						outResult.Set("hello", JsonValue.MakeString((session.Project != null) ? StringView(session.Project.Name) : ""));
						return true;
					}));
				TakenRefused = !tools.RegisterTool("project_info", "an impostor", scope SchemaBuilder().Build(), .ReadOnly,
					new (arguments, outResult, outError) => true);
			}));
	}
}

/// A plugin's Tooling part adds MCP tools, which every server the host serves offers: the stdio
/// host's, there before the project opened, and a server started after the plugin loaded (the
/// editor starts its own once the project is open). They leave every server with their plugin, and
/// none may take a name a server already holds.
static class PluginMcpToolsTests
{
	private static String GreeterManifest()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("greeter");
		manifest.Version.Set("1.0");
		manifest.EngineVersion.Set(EngineVersion.String);
		let part = new PluginManifestPart();
		part.Kind.Set("Tooling");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		return manifest.Write(.. new .());
	}

	[Test]
	public static void APluginsToolIsServedByAServerThereBeforeItLoadsAndOneStartedAfterAndLeavesWithIt()
	{
		let dir = Scratch("mcp_plugin_tooling", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let plain = Scratch("mcp_plugin_tooling_plain", .. scope .());
		defer RemoveDirectoryRecursive(plain);
		let pluginTools = scope McpPluginServices();
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		let manifestXml = GreeterManifest();
		defer delete manifestXml;
		let parts = scope List<PluginPart>();
		defer { ClearAndDeleteItems!(parts); }
		parts.Add(new GreeterPart(manifestXml));
		owner.PluginParts = parts;
		owner.PluginTools = pluginTools;
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		PluginTools.Register(server, session);
		pluginTools.AttachServer(server, session);
		let engineTools = server.ToolCount;

		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Greeted"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", plain), "name", "Plain"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		delete CallOk(server, "plugin_enable", With(Obj(), "id", "greeter"));
		GreeterPart.TakenRefused = false;
		delete CallOk(server, "project_open", With(Obj(), "directory", dir)); // opened again: its plugins load with it

		// The stdio host's server, there before the plugin loaded, serves its tool.
		Test.Assert(server.ToolCount == engineTools + 1);
		Test.Assert(GreeterPart.TakenRefused, "the engine's project_info keeps its name");
		{
			let hello = CallOk(server, "greeter_hello", Obj());
			defer delete hello;
			Test.Assert(hello.Get("hello").AsString() == "Greeted");
			let info = CallOk(server, "project_info", Obj());
			defer delete info;
			Test.Assert(info.Get("settings") != null, "still the engine's");
		}

		// A server started after the plugin loaded serves it too, and leaves it as it stops.
		{
			let later = scope McpServer();
			later.RegisterTool("project_info", "the server's own", scope SchemaBuilder().Build(), .ReadOnly,
				new (arguments, outResult, outError) => true);
			pluginTools.AttachServer(later, session);
			Test.Assert(later.HasTool("greeter_hello"));
			let served = scope List<String>();
			defer { ClearAndDeleteItems!(served); }
			pluginTools.ToolsServedBy(later, served);
			Test.Assert(served.Count == 1);
			pluginTools.DetachServer(later);
			Test.Assert(!later.HasTool("greeter_hello"));
		}

		// A project that does not enable it: the tool leaves the server with its plugin.
		delete CallOk(server, "project_open", With(Obj(), "directory", plain));
		Test.Assert(!server.HasTool("greeter_hello"));
		Test.Assert(server.ToolCount == engineTools);

		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
		pluginTools.DetachServer(server);
	}
}
