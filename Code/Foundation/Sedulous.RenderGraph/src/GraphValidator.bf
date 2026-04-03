using System;
using System.Collections;

namespace Sedulous.RenderGraph;

/// Severity of a validation message
public enum ValidationSeverity
{
	Warning,
	Error
}

/// A single validation message
public struct ValidationMessage
{
	public ValidationSeverity Severity;
	public String Message;

	public this(ValidationSeverity severity, StringView message)
	{
		Severity = severity;
		Message = new String(message);
	}
}

/// Validates a compiled render graph for common errors
public static class GraphValidator
{
	/// Run all validation checks on a render graph.
	/// Call after passes have been added but execution order doesn't matter.
	public static void Validate(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		CheckUninitializedReads(graph, outMessages);
		CheckEmptyPasses(graph, outMessages);
		CheckRedundantWrites(graph, outMessages);
	}

	/// Run validation and format results as a string
	public static void ValidateToString(RenderGraph graph, String outText)
	{
		let messages = scope List<ValidationMessage>();
		defer { for (let m in messages) delete m.Message; }

		Validate(graph, messages);

		if (messages.Count == 0)
		{
			outText.Append("Render graph validation: OK (no issues)\n");
			return;
		}

		outText.AppendF("Render graph validation: {} issue(s)\n", messages.Count);
		for (let msg in messages)
		{
			let prefix = (msg.Severity == .Error) ? "ERROR" : "WARNING";
			outText.AppendF("  [{}] {}\n", prefix, msg.Message);
		}
	}

	/// Check for reads of resources that have no prior writer (transient resources only)
	private static void CheckUninitializedReads(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;

		// Track which resources have been written
		let writtenResources = scope HashSet<uint32>();

		// Imported and persistent resources are considered "initialized"
		for (int i = 0; i < resources.Count; i++)
		{
			let res = resources[i];
			if (res != null && (res.Lifetime == .Imported || res.Lifetime == .Persistent))
				writtenResources.Add((uint32)i);
		}

		for (let pass in passes)
		{
			// Check reads
			for (let access in pass.Accesses)
			{
				if (access.IsRead && access.Handle.IsValid)
				{
					if (!writtenResources.Contains(access.Handle.Index))
					{
						let msg = scope String();
						let resName = (access.Handle.Index < (uint32)resources.Count && resources[access.Handle.Index] != null)
							? resources[access.Handle.Index].Name : "???";
						msg.AppendF("Pass '{}' reads resource '{}' (index {}) which has not been written to",
							pass.Name, resName, access.Handle.Index);
						outMessages.Add(.(ValidationSeverity.Error, msg));
					}
				}
			}

			// Mark writes
			for (let access in pass.Accesses)
			{
				if (access.IsWrite && access.Handle.IsValid)
					writtenResources.Add(access.Handle.Index);
			}
		}
	}

	/// Check for passes with no execute callback
	private static void CheckEmptyPasses(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		for (let pass in graph.Passes)
		{
			bool hasCallback = false;
			switch (pass.Type)
			{
			case .Render:  hasCallback = pass.ExecuteCallback != null;
			case .Compute: hasCallback = pass.ComputeCallback != null;
			case .Copy:    hasCallback = pass.CopyCallback != null;
			}

			if (!hasCallback)
			{
				let msg = scope String();
				msg.AppendF("Pass '{}' has no execute callback", pass.Name);
				outMessages.Add(.(ValidationSeverity.Warning, msg));
			}
		}
	}

	/// Check for resources written multiple times without any read in between
	private static void CheckRedundantWrites(RenderGraph graph, List<ValidationMessage> outMessages)
	{
		let passes = graph.Passes;
		let resources = graph.Resources;

		// Track last writer per resource (without intermediate read)
		let lastWriter = scope Dictionary<uint32, String>();
		defer { for (let v in lastWriter.Values) delete v; }

		for (let pass in passes)
		{
			// Check if this pass reads any resource that was previously written
			for (let access in pass.Accesses)
			{
				if (access.IsRead && access.Handle.IsValid)
				{
					if (lastWriter.GetAndRemove(access.Handle.Index) case .Ok(let kv))
						delete kv.value;
				}
			}

			// Check if this pass writes a resource that was already written without read
			for (let access in pass.Accesses)
			{
				if (access.IsWrite && access.Handle.IsValid)
				{
					if (lastWriter.TryGetValue(access.Handle.Index, let prevWriter))
					{
						let resName = (access.Handle.Index < (uint32)resources.Count && resources[access.Handle.Index] != null)
							? resources[access.Handle.Index].Name : "???";
						let msg = scope String();
						msg.AppendF("Resource '{}' written by pass '{}' was already written by '{}' without being read",
							resName, pass.Name, prevWriter);
						outMessages.Add(.(ValidationSeverity.Warning, msg));
					}

					if (lastWriter.GetAndRemove(access.Handle.Index) case .Ok(let kv))
						delete kv.value;
					lastWriter[access.Handle.Index] = new String(pass.Name);
				}
			}
		}
	}
}
