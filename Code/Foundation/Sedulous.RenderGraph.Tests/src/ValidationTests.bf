namespace Sedulous.RenderGraph.Tests;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class ValidationTests
{
	[Test]
	public static void UninitializedRead_Detected()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		// Read without any prior write
		graph.AddRenderPass("BadPass", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }
		GraphValidator.Validate(graph, messages);

		bool hasError = false;
		for (let msg in messages)
		{
			if (msg.Severity == .Error)
				hasError = true;
		}
		Test.Assert(hasError);
	}

	[Test]
	public static void ImportedRead_NotFlagged()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let imported = graph.ImportTarget("External", null, null);

		// Reading an imported resource is fine (it's externally initialized)
		graph.AddRenderPass("ReadImported", scope (builder) => {
			builder.ReadTexture(imported);
			builder.NeverCull();
		});

		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }
		GraphValidator.Validate(graph, messages);

		bool hasError = false;
		for (let msg in messages)
		{
			if (msg.Severity == .Error)
				hasError = true;
		}
		Test.Assert(!hasError);
	}

	[Test]
	public static void EmptyPass_Warned()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		// Pass with no callback
		graph.AddRenderPass("Empty", scope (builder) => {
			builder.NeverCull();
		});

		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }
		GraphValidator.Validate(graph, messages);

		bool hasWarning = false;
		for (let msg in messages)
		{
			if (msg.Severity == .Warning)
				hasWarning = true;
		}
		Test.Assert(hasWarning);
	}

	[Test]
	public static void RedundantWrite_Warned()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		// Two writes without read in between
		graph.AddRenderPass("Write1", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddRenderPass("Write2", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
		});

		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }
		GraphValidator.Validate(graph, messages);

		bool hasWarning = false;
		for (let msg in messages)
		{
			if (msg.Severity == .Warning)
				hasWarning = true;
		}
		Test.Assert(hasWarning);
	}

	[Test]
	public static void CleanGraph_NoMessages()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Write", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
			builder.SetExecute(new (encoder) => {});
		});

		graph.AddRenderPass("Read", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
			builder.SetExecute(new (encoder) => {});
		});

		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }
		GraphValidator.Validate(graph, messages);

		Test.Assert(messages.Count == 0);
	}

	[Test]
	public static void ValidateToString_FormatsOutput()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("BadRead", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		let result = scope String();
		GraphValidator.ValidateToString(graph, result);

		Test.Assert(result.Contains("issue"));
	}
}
