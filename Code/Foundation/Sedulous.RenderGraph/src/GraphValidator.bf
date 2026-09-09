using System;
using System.Collections;

namespace Sedulous.RenderGraph;

/// Checks a compiled graph for the mistakes the declarations make possible.
///
/// None of it is fatal: a graph that reads something nothing wrote will draw the wrong thing,
/// and saying so beats guessing at the intent.
static class GraphValidator
{
	/// THE CALLER OWNS the messages appended.
	public static void Validate(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		CheckUninitializedReads(graph, outMessages);
		CheckEmptyPasses(graph, outMessages);
		CheckRedundantWrites(graph, outMessages);
	}

	public static void ValidateToString(RenderGraph graph, String outReport)
	{
		let messages = scope List<ValidationMessage>();
		defer { ClearAndDeleteItems!(messages); }
		Validate(graph, messages);

		if (messages.IsEmpty)
		{
			outReport.Append("Render graph validation: OK (no issues)\n");
			return;
		}

		outReport.AppendF("Render graph validation: {} issue(s)\n", messages.Count);
		for (let message in messages)
		{
			let prefix = (message.Severity == .Error) ? "ERROR" : "WARNING";
			outReport.AppendF("  [{}] {}\n", prefix, message.Message);
		}
	}

	/// Reads of a resource NOTHING has written yet.
	///
	/// Transient only: an imported or persistent resource was filled in by whoever owns it,
	/// which is exactly what those lifetimes mean.
	private static void CheckUninitializedReads(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		let resources = graph.Resources;
		let written = scope HashSet<uint32>();

		for (uint32 i = 0; i < (uint32)resources.Length; i++)
		{
			let resource = resources[i];
			if ((resource != null)
				&& ((resource.Lifetime == .Imported) || (resource.Lifetime == .Persistent)))
				written.Add(i);
		}

		for (let pass in graph.Passes)
		{
			for (let access in pass.Accesses)
			{
				if (!access.IsRead || !access.Handle.IsValid)
					continue;
				if (written.Contains(access.Handle.Index))
					continue;

				outMessages.Add(new ValidationMessage(.Error,
					scope $"Pass '{pass.Name}' reads resource '{NameOf(resources, access.Handle.Index)}' (index {access.Handle.Index}) which has not been written to"));
			}

			// The pass's own writes count only for the passes AFTER it, which is what makes
			// this an ordering check rather than a set membership one.
			for (let access in pass.Accesses)
			{
				if (access.IsWrite && access.Handle.IsValid)
					written.Add(access.Handle.Index);
			}
		}
	}

	/// A pass with no body records nothing, which is almost always a setup that forgot one.
	private static void CheckEmptyPasses(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		for (let pass in graph.Passes)
		{
			var hasCallback = false;
			switch (pass.Type)
			{
			case .Render: hasCallback = (pass.ExecuteCallback != null) || (pass.BundleCallback != null);
			case .Compute: hasCallback = pass.ComputeCallback != null;
			case .Copy: hasCallback = pass.CopyCallback != null;
			}

			if (!hasCallback)
			{
				outMessages.Add(new ValidationMessage(.Warning,
					scope $"Pass '{pass.Name}' has no execute callback"));
			}
		}
	}

	/// A resource written twice with no read in between: the first write was thrown away.
	private static void CheckRedundantWrites(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		let resources = graph.Resources;
		let lastWriter = scope Dictionary<uint32, String>();
		defer
		{
			for (let name in lastWriter.Values)
				delete name;
		}

		for (let pass in graph.Passes)
		{
			// A read consumes what was written, so the write before it was not wasted.
			for (let access in pass.Accesses)
			{
				if (access.IsRead && access.Handle.IsValid)
				{
					if (lastWriter.GetAndRemove(access.Handle.Index) case .Ok(let removed))
						delete removed.value;
				}
			}

			for (let access in pass.Accesses)
			{
				if (!access.IsWrite || !access.Handle.IsValid)
					continue;

				if (lastWriter.TryGetValue(access.Handle.Index, let previous))
				{
					outMessages.Add(new ValidationMessage(.Warning,
						scope $"Resource '{NameOf(resources, access.Handle.Index)}' written by pass '{pass.Name}' was already written by '{previous}' without being read"));
					delete previous;
				}

				lastWriter[access.Handle.Index] = new String(pass.Name);
			}
		}
	}

	private static StringView NameOf(Span<RenderGraphResource> resources, uint32 index)
	{
		if ((index < (uint32)resources.Length) && (resources[index] != null))
			return resources[index].Name;
		return "???";
	}
}
