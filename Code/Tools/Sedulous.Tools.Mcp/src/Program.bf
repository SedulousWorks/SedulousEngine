using System;
using Sedulous.Editor.McpMain;

namespace Sedulous.Tools.Mcp;

/// The stock headless MCP server. The startup is McpMain's, in a library, so a project's own
/// build (`<Game>Tools mcp`) serves the same tools with its packages linked in.
class Program
{
	public static int Main(String[] args) => McpMain.Run(args);
}
