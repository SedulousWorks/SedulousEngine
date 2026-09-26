using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor's MCP host, a settings section: agent access to the OPEN project over localhost
/// HTTP. Off by default. Port is where it listens (one editor per port: a second editor takes
/// another); Token is the bearer secret the editor generates on first enable (see
/// GenerateToken) and also writes to <user-data>/mcp-token so a local agent configures
/// itself. Edited in Preferences; --mcp and --mcp-port override one run.
[Serializable(1)]
class EditorMcpSettings
{
	public const uint32 DefaultPort = 7405;

	public bool Enabled = false;
	public uint32 Port = DefaultPort;
	public String Token = new .() ~ delete _;

	/// A fresh bearer token: a random Guid's canonical text, 36 characters. From the system's
	/// entropy, so two editors never mint the same one.
	public static void GenerateToken(String outToken)
	{
		outToken.Clear();
		Guid.Create().ToString(outToken, 'D');
	}
}
