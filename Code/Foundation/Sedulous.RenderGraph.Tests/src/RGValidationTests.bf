using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// What validation finds in a graph, and what it leaves alone.
class RGValidationTests
{
	private static bool HasError(List<ValidationMessage> messages)
	{
		for (let message in messages)
		{
			if (message.Severity == .Error)
				return true;
		}
		return false;
	}

	private static bool Mentions(List<ValidationMessage> messages, StringView fragment)
	{
		for (let message in messages)
		{
			if (message.Message.Contains(fragment))
				return true;
		}
		return false;
	}

	/// Reading a transient NOTHING has written is an error: the pass will sample whatever was
	/// in the pooled texture.
	[Test]
	public static void AnUninitialisedReadIsAnError()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let never = graph.CreateTransient("NeverWritten", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Reader", scope (builder) =>
			{
				builder.ReadTexture(never);
				builder.NeverCull();
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(HasError(messages));
		Test.Assert(Mentions(messages, "NeverWritten"));
	}

	/// An IMPORTED or PERSISTENT resource was filled in by whoever owns it, which is what
	/// those lifetimes mean, so reading one is not a finding.
	[Test]
	public static void ReadingAnImportedResourceIsFine()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let imported = graph.ImportTarget("Imported", null, null);
		let persistent = graph.RegisterPersistent("History", null, null);

		graph.AddRenderPass("Reader", scope (builder) =>
			{
				builder.ReadTexture(imported);
				builder.ReadTexture(persistent);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(!HasError(messages));
	}

	/// A pass written EARLIER in the frame counts, which is what makes this an ordering check
	/// rather than a set membership one.
	[Test]
	public static void AWriteEarlierInTheFrameCounts()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Writer", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});
		graph.AddRenderPass("Reader", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(!HasError(messages));
	}

	/// A pass with no body records nothing, which is a warning rather than an error: it draws
	/// the right thing, namely nothing.
	[Test]
	public static void AnEmptyPassIsAWarning()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.AddRenderPass("Empty", scope (builder) => { builder.NeverCull(); });

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(!HasError(messages));
		Test.Assert(Mentions(messages, "no execute callback"));
	}

	/// A BUNDLE pass has a body too, so it is not empty.
	[Test]
	public static void ABundlePassIsNotEmpty()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.AddRenderPass("Bundles", scope (builder) =>
			{
				builder.NeverCull();
				builder.SetBundleExecute(new (encoder, bundles) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(!Mentions(messages, "no execute callback"));
	}

	/// A resource written twice with NO READ in between: the first write was thrown away.
	[Test]
	public static void ARedundantWriteIsAWarning()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("First", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});
		graph.AddRenderPass("Second", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(Mentions(messages, "already written"));
		Test.Assert(!HasError(messages), "wasteful rather than wrong");
	}

	/// A read between the two writes CONSUMES the first, so it was not wasted.
	[Test]
	public static void AReadBetweenTwoWritesIsNoFinding()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));
		let other = graph.CreateTransient("Other", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Write", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});
		graph.AddRenderPass("Read", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.SetColorTarget(0, other, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});
		graph.AddRenderPass("WriteAgain", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(!Mentions(messages, "already written"));
	}

	[Test]
	public static void ACleanGraphHasNothingToSay()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));
		let output = graph.ImportTarget("Output", null, null, ResourceState.Present);

		graph.AddRenderPass("Scene", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});
		graph.AddRenderPass("Present", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.SetColorTarget(0, output, .Clear, .Store);
				builder.SetExecute(new (encoder) => {});
			});

		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		GraphValidator.Validate(graph, messages);

		Test.Assert(messages.IsEmpty);
	}

	[Test]
	public static void TheReportSaysWhenThereIsNothingToReport()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let report = scope String();
		GraphValidator.ValidateToString(graph, report);
		Test.Assert(report.Contains("OK (no issues)"));
	}

	[Test]
	public static void TheReportListsWhatItFound()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let never = graph.CreateTransient("NeverWritten", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Reader", scope (builder) =>
			{
				builder.ReadTexture(never);
				builder.NeverCull();
			});

		let report = scope String();
		GraphValidator.ValidateToString(graph, report);

		Test.Assert(report.Contains("issue(s)"));
		Test.Assert(report.Contains("[ERROR]"));
		Test.Assert(report.Contains("[WARNING]"), "the pass has no body either");
		Test.Assert(report.Contains("NeverWritten"));
	}
}
