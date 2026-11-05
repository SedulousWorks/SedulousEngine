using System;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;

namespace Imgui;

/// Imgui.Engine's part. Its load adds the ImguiSubsystem to the process's subsystems, from the
/// client services a windowed application offers (its graphics device and data mount); a process
/// with no window or no device offers none, and nothing is added. The application still drives it
/// each frame (NewFrame, then its widgets, then Render).
[AlwaysInclude]
class ImguiEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	/// The subsystem its load added, owned here (the manager borrows it): one host per process.
	private ImguiSubsystem mSubsystem = null ~ delete _;

	static this()
	{
		PluginRegistry.Register(new ImguiEnginePart());
	}

	public override StringView PluginId => "imgui";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		let client = context.Find<ClientServices>();
		if ((client == null) || (client.Host == null) || (client.Data == null))
			return;
		let graphics = client.Host.Graphics;
		if ((graphics == null) || (graphics.Raw == null))
			return;
		mSubsystem = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight, client.Data);
		context.Subsystems.RegisterSubsystem<ImguiSubsystem>(mSubsystem);
	}

	public override void Unload(PluginContext context)
	{
		if (mSubsystem == null)
			return;
		context.Subsystems.RemoveSubsystem<ImguiSubsystem>();
		DeleteAndNullify!(mSubsystem);
	}
}
