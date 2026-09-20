using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Mcp;

namespace Sedulous.Tools.Mcp;

/// The curated, distribution facing documents the host serves: Documentation/Shipping in
/// the engine checkout, resolved by walking up from the executable and then from the
/// working directory, and KnownIssues.md from the same set. Internal design, spec and
/// process documents never feed an agent through here: the MCP is a product surface.
static class ShippingDocs
{
	public const String cDirectory = "Documentation/Shipping";
	public const String cKnownIssues = "KnownIssues.md";

	/// The shipping docs directory, or empty. A distribution stages the docs beside the
	/// tool; the checkout keeps them under Documentation/Shipping.
	public static void FindDirectory(String outPath)
	{
		outPath.Clear();
		for (let start in scope String[](GetExecutableDirectory(.. scope .()), GetCurrentDirectory(.. scope .())))
		{
			let dir = scope String(start);
			while (!dir.IsEmpty)
			{
				let candidate = PathJoin(dir, cDirectory, .. scope .());
				if (DirectoryExists(candidate))
				{
					outPath.Set(candidate);
					return;
				}
				let parent = PathParent(dir, .. scope .());
				if ((parent == dir) || parent.IsEmpty)
					break;
				dir.Set(parent);
			}
		}
	}

	/// KnownIssues.md: staged next to the executable first, the checkout layout second.
	public static void FindKnownIssues(String outPath)
	{
		outPath.Clear();
		let beside = PathJoin(GetExecutableDirectory(.. scope .()), cKnownIssues, .. scope .());
		if (FileExists(beside))
		{
			outPath.Set(beside);
			return;
		}
		let docs = FindDirectory(.. scope .());
		if (!docs.IsEmpty)
			PathJoin(docs, cKnownIssues, outPath);
	}

	/// Every *.md in the docs directory as a read only docs://<FileName> resource. Readers
	/// re-read the file per request, so an edit is live without restarting the host.
	public static void Register(McpServer server, StringView docsDir)
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems(names); }
		ListDirectory(docsDir, scope [&](name, isDirectory) =>
			{
				if (!isDirectory && name.EndsWith(".md"))
					names.Add(new String(name));
			});
		names.Sort(scope (a, b) => a <=> b);
		for (let name in names)
		{
			let path = new String();
			PathJoin(docsDir, name, path);
			server.RegisterResource(scope $"docs://{name}", name, "text/markdown",
				scope $"engine documentation: {name} (curated, distribution-facing)",
				new (outText, outError) =>
				{
					let bytes = scope List<uint8>();
					if (ReadFile(path, bytes) case .Err)
					{
						outError.AppendF("could not read '{}'", path);
						return false;
					}
					outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
					return true;
				}, path);
		}
	}
}
