using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Pipeline.ScriptSurface;

/// The PIPELINE script surface: the runtime closure and every pipeline module on top of
/// it, so a script cook, the cooker, the export packager and the headless MCP server see
/// the same types a running game does plus what the pipeline exposes for tooling. It is
/// wider than the runtime root and narrower than the editor's, and it is its own project so
/// a host links exactly the surface it may expose.
///
/// The facade closure plus the Pipeline domain's own types, never the whole dependency
/// closure: a component marked for the editor is not a runtime contract, and a script cook or
/// an MCP check against it would accept code the running game cannot compile.
///
/// Both the Runtime and the Pipeline domains are allowed here: a type in the Pipeline domain
/// reaching the runtime root fails that build, and reaching this one is the point.
static class PipelineScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.", "System."),
			scope StringView[](ScriptDomains.Runtime, ScriptDomains.Pipeline), .RuntimeAndDomains);
	}
}
