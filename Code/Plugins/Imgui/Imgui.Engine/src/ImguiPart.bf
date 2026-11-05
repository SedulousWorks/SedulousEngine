using System;
using Sedulous.Runtime;

namespace Imgui;

/// Imgui.Engine's part. Its load registers nothing: the ImguiSubsystem needs the app's graphics
/// device and data mount, which a plugin's context does not offer, so each app that uses Imgui
/// adds the subsystem itself.
[AlwaysInclude]
class ImguiEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new ImguiEnginePart());
	}

	public override StringView PluginId => "imgui";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context) {}
}
