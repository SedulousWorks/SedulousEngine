using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;

namespace NativeSample;

/// NativeSample.Engine: this game's native code, the Engine part of its plugin package, which every
/// host loads.
///
/// Load is the one registration point: subsystems, scene managers, script facades and types
/// all register through the context here, and what the context records is reversed when the
/// plugin unloads (the project closing). Unload removes what the recording cannot, such as a
/// subsystem Load added. The part registers itself when the program starts, so linking the
/// project is all it takes; the project's entry enables it.
[AlwaysInclude]
class NativeSampleEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new NativeSampleEnginePart());
	}

	public override StringView PluginId => "nativesample";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		GlobalLog(.Information, "NativeSample loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}

