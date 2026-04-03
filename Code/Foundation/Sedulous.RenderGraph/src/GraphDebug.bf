using System;
using System.Collections;

namespace Sedulous.RenderGraph;

/// Debug visualization and text reports for render graphs
public static class GraphDebug
{
	/// Export the render graph as a DOT/Graphviz string
	public static void ExportDOT(RenderGraph graph, String outDot)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;

		outDot.Append("digraph RenderGraph {\n");
		outDot.Append("  rankdir=LR;\n");
		outDot.Append("  node [fontname=\"Helvetica\"];\n\n");

		// Pass nodes
		for (int i = 0; i < passes.Count; i++)
		{
			let pass = passes[i];
			let color = GetPassColor(pass);
			let style = pass.IsCulled ? "dashed" : "filled";
			let fontColor = pass.IsCulled ? "gray" : "white";

			outDot.AppendF("  pass{} [label=\"{}\" shape=box style={} fillcolor=\"{}\" fontcolor=\"{}\"", i, pass.Name, style, color, fontColor);
			if (pass.IsCulled)
				outDot.Append(" color=gray");
			outDot.Append("];\n");
		}

		outDot.Append("\n");

		// Resource nodes
		for (int i = 0; i < resources.Count; i++)
		{
			let res = resources[i];
			if (res == null) continue;

			let shape = (res.ResourceType == .Texture) ? "ellipse" : "diamond";
			let lifetimeLabel = GetLifetimeLabel(res.Lifetime);
			outDot.AppendF("  res{} [label=\"{}\\n({})\" shape={}];\n", i, res.Name, lifetimeLabel, shape);
		}

		outDot.Append("\n");

		// Edges (resource accesses)
		for (int passIdx = 0; passIdx < passes.Count; passIdx++)
		{
			let pass = passes[passIdx];
			for (let access in pass.Accesses)
			{
				if (!access.Handle.IsValid || access.Handle.Index >= (uint32)resources.Count)
					continue;
				if (resources[access.Handle.Index] == null)
					continue;

				let resNode = scope String();
				resNode.AppendF("res{}", access.Handle.Index);
				let passNode = scope String();
				passNode.AppendF("pass{}", passIdx);

				if (access.IsRead)
				{
					outDot.AppendF("  {} -> {} [label=\"{}\"", resNode, passNode, GetAccessLabel(access.Type));
					if (pass.IsCulled) outDot.Append(" style=dashed color=gray");
					outDot.Append("];\n");
				}
				if (access.IsWrite)
				{
					outDot.AppendF("  {} -> {} [label=\"{}\"", passNode, resNode, GetAccessLabel(access.Type));
					if (pass.IsCulled) outDot.Append(" style=dashed color=gray");
					outDot.Append("];\n");
				}
			}
		}

		outDot.Append("}\n");
	}

	/// Export a text summary of the render graph
	public static void ExportSummary(RenderGraph graph, String outText)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;
		let executionOrder = graph.ExecutionOrder;

		int activeCount = 0;
		int culledCount = 0;
		for (let p in passes)
		{
			if (p.IsCulled) culledCount++;
			else activeCount++;
		}

		int resCount = 0;
		int transientCount = 0;
		int persistentCount = 0;
		int importedCount = 0;
		for (let r in resources)
		{
			if (r == null) continue;
			resCount++;
			switch (r.Lifetime)
			{
			case .Transient:  transientCount++;
			case .Persistent: persistentCount++;
			case .Imported:   importedCount++;
			}
		}

		outText.AppendF("=== Render Graph Summary ===\n");
		outText.AppendF("Passes: {} active, {} culled, {} total\n", activeCount, culledCount, passes.Count);
		outText.AppendF("Resources: {} total ({} transient, {} persistent, {} imported)\n",
			resCount, transientCount, persistentCount, importedCount);
		outText.AppendF("Output: {}x{}\n\n", graph.OutputWidth, graph.OutputHeight);

		if (executionOrder.Count > 0)
		{
			outText.Append("Execution order:\n");
			for (int i = 0; i < executionOrder.Count; i++)
			{
				let passIdx = executionOrder[i];
				let pass = passes[passIdx];
				let typeStr = GetPassTypeLabel(pass.Type);
				outText.AppendF("  {}. [{}] {}\n", i + 1, typeStr, pass.Name);
			}
		}
	}

	// --- Helpers ---

	private static StringView GetPassColor(RenderGraphPass pass)
	{
		switch (pass.Type)
		{
		case .Render:  return "#4488cc";
		case .Compute: return "#cc8844";
		case .Copy:    return "#44aa44";
		}
	}

	private static StringView GetLifetimeLabel(RGResourceLifetime lifetime)
	{
		switch (lifetime)
		{
		case .Transient:  return "transient";
		case .Persistent: return "persistent";
		case .Imported:   return "imported";
		}
	}

	private static StringView GetAccessLabel(RGAccessType type)
	{
		switch (type)
		{
		case .ReadTexture:      return "read";
		case .ReadBuffer:       return "read";
		case .ReadDepthStencil: return "depth-read";
		case .ReadCopySrc:      return "copy-src";
		case .WriteColorTarget: return "color-out";
		case .WriteDepthTarget: return "depth-out";
		case .WriteStorage:     return "storage-write";
		case .WriteCopyDst:     return "copy-dst";
		case .ReadWriteStorage: return "rw-storage";
		}
	}

	private static StringView GetPassTypeLabel(RGPassType type)
	{
		switch (type)
		{
		case .Render:  return "Render";
		case .Compute: return "Compute";
		case .Copy:    return "Copy";
		}
	}
}
