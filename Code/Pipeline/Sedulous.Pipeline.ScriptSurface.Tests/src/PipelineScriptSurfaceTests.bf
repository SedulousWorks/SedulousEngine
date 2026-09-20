using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Pipeline.ScriptSurface.Tests;

/// The pipeline surface contains the runtime surface and may add to it.
static class PipelineScriptSurfaceTests
{
	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope ScriptSurface();
		PipelineScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == PipelineScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked: the runtime's 159, the two
		// Pipeline domain enums, and three foundation enums only the pipeline links.
		Test.Assert(PipelineScriptSurface.TypeCount == 164, scope $"the pipeline surface has {PipelineScriptSurface.TypeCount} types");
	}

	[Test]
	public static void ItContainsTheRuntimeSurface()
	{
		let pipeline = scope ScriptSurface();
		PipelineScriptSurface.Populate(pipeline);
		let runtime = scope ScriptSurface();
		EngineScriptSurface.Populate(runtime);
		for (let t in runtime.Types)
			Test.Assert(pipeline.Find(t.FullName) != null, scope $"{t.FullName} is on the runtime surface and not the pipeline's");
		Test.Assert(pipeline.Types.Count >= runtime.Types.Count);
	}

	/// A type in a pipeline module is the Pipeline domain, never Editor and never left to
	/// default to Runtime: the headless cooker and MCP host have it without the editor, and
	/// the player has it not at all.
	[Test]
	public static void PipelineModuleTypesCarryThePipelineDomain()
	{
		let s = scope ScriptSurface();
		PipelineScriptSurface.Populate(s);
		int pipelineDomained = 0;
		for (let t in s.Types)
		{
			if (!t.FullName.Contains(".Pipeline.") && !t.FullName.StartsWith("Sedulous.ModelImporter."))
				continue;
			Test.Assert(t.Domain == ScriptDomains.Pipeline, scope $"{t.FullName} is {t.Domain}");
			pipelineDomained++;
		}
		Test.Assert(pipelineDomained >= 2, scope $"{pipelineDomained} pipeline domain types");
	}

	[Test]
	public static void BothDomainsAreAllowedAndOnlyThoseAppear()
	{
		let s = scope ScriptSurface();
		PipelineScriptSurface.Populate(s);
		let domains = scope List<String>();
		defer { ClearAndDeleteItems(domains); }
		s.CollectDomains(domains);
		for (let d in domains)
			Test.Assert((d == ScriptDomains.Runtime) || (d == ScriptDomains.Pipeline), d);
	}
}
