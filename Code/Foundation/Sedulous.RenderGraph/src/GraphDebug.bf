using System;
using System.Collections;

namespace Sedulous.RenderGraph;

/// Turning a compiled graph into something a person can read.
static class GraphDebug
{
	/// Graphviz DOT: the passes as boxes, the resources as ellipses and diamonds, and every
	/// access as an edge. What was culled is dashed and grey, so a pass that vanished and the
	/// reason it did are both on the page.
	public static void ExportDOT(RenderGraph graph, String outText)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;

		outText.Append("digraph RenderGraph {\n");
		outText.Append("  rankdir=LR;\n");
		outText.Append("  node [fontname=\"Helvetica\"];\n\n");

		for (int i < passes.Length)
		{
			let pass = passes[i];
			let style = pass.IsCulled ? "dashed" : "filled";
			let fontColor = pass.IsCulled ? "gray" : "white";

			outText.AppendF("  pass{} [label=\"{}\" shape=box style={} fillcolor=\"{}\" fontcolor=\"{}\"",
				i, pass.Name, style, PassColor(pass.Type), fontColor);
			if (pass.IsCulled)
				outText.Append(" color=gray");
			outText.Append("];\n");
		}
		outText.Append("\n");

		for (int i < resources.Length)
		{
			let resource = resources[i];
			if (resource == null)
				continue;

			let shape = (resource.ResourceType == .Texture) ? "ellipse" : "diamond";
			outText.AppendF("  res{} [label=\"{}\\n({})\" shape={}];\n", i, resource.Name,
				LifetimeLabel(resource.Lifetime), shape);
		}
		outText.Append("\n");

		for (int passIndex < passes.Length)
		{
			let pass = passes[passIndex];
			for (let access in pass.Accesses)
			{
				if (!access.Handle.IsValid || (access.Handle.Index >= (uint32)resources.Length))
					continue;
				if (resources[access.Handle.Index] == null)
					continue;

				let label = AccessLabel(access.Type);
				// A read write access draws BOTH edges, which is what says the pass depends
				// on what it is about to overwrite.
				if (access.IsRead)
				{
					outText.AppendF("  res{} -> pass{} [label=\"{}\"", access.Handle.Index,
						passIndex, label);
					if (pass.IsCulled)
						outText.Append(" style=dashed color=gray");
					outText.Append("];\n");
				}
				if (access.IsWrite)
				{
					outText.AppendF("  pass{} -> res{} [label=\"{}\"", passIndex,
						access.Handle.Index, label);
					if (pass.IsCulled)
						outText.Append(" style=dashed color=gray");
					outText.Append("];\n");
				}
			}
		}

		outText.Append("}\n");
	}

	/// The counts and the execution order, for a log line rather than a graph viewer.
	public static void ExportSummary(RenderGraph graph, String outText)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;
		let executionOrder = graph.ExecutionOrder;

		var active = 0;
		var culled = 0;
		for (let pass in passes)
		{
			if (pass.IsCulled)
				culled++;
			else
				active++;
		}

		var total = 0;
		var transient = 0;
		var persistent = 0;
		var imported = 0;
		for (let resource in resources)
		{
			if (resource == null)
				continue;

			total++;
			switch (resource.Lifetime)
			{
			case .Transient: transient++;
			case .Persistent: persistent++;
			case .Imported: imported++;
			}
		}

		outText.Append("=== Render Graph Summary ===\n");
		outText.AppendF("Passes: {} active, {} culled, {} total\n", active, culled, passes.Length);
		outText.AppendF("Resources: {} total ({} transient, {} persistent, {} imported)\n",
			total, transient, persistent, imported);
		outText.AppendF("Output: {}x{}\n\n", graph.OutputWidth, graph.OutputHeight);

		if (executionOrder.IsEmpty)
			return;

		outText.Append("Execution order:\n");
		for (int i < executionOrder.Length)
		{
			let pass = passes[executionOrder[i]];
			outText.AppendF("  {}. [{}] {}\n", i + 1, PassTypeLabel(pass.Type), pass.Name);
		}
	}

	private static StringView PassColor(RGPassType type)
	{
		switch (type)
		{
		case .Render: return "#4488cc";
		case .Compute: return "#cc8844";
		case .Copy: return "#44aa44";
		}
	}

	private static StringView LifetimeLabel(RGResourceLifetime lifetime)
	{
		switch (lifetime)
		{
		case .Transient: return "transient";
		case .Persistent: return "persistent";
		case .Imported: return "imported";
		}
	}

	private static StringView AccessLabel(RGAccessType type)
	{
		switch (type)
		{
		case .ReadTexture: return "read";
		case .ReadBuffer: return "read";
		case .ReadDepthStencil: return "depth-read";
		case .SampleDepthStencil: return "depth-sample";
		case .ReadCopySrc: return "copy-src";
		case .WriteColorTarget: return "color-out";
		case .WriteDepthTarget: return "depth-out";
		case .WriteStorage: return "storage-write";
		case .WriteCopyDst: return "copy-dst";
		case .ReadWriteStorage: return "rw-storage";
		case .ReadWriteDepthTarget: return "depth-rw";
		case .ReadWriteColorTarget: return "color-rw";
		}
	}

	private static StringView PassTypeLabel(RGPassType type)
	{
		switch (type)
		{
		case .Render: return "Render";
		case .Compute: return "Compute";
		case .Copy: return "Copy";
		}
	}
}
