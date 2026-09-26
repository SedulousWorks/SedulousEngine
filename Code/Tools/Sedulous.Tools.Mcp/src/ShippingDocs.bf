using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Mcp;

namespace Sedulous.Tools.Mcp;

/// Where the curated, distribution facing documents are: Documentation/Shipping in the
/// engine checkout, found by walking up from the executable and then from the working
/// directory, and KnownIssues.md from the same set. Registering them is Editor.Mcp's.
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
}
