using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Mcp;

namespace Sedulous.Editor.Mcp;

/// The curated, distribution facing documents as read only resources. Internal design, spec
/// and process documents never feed an agent through here: the MCP is a product surface.
static class ShippingDocResources
{
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
