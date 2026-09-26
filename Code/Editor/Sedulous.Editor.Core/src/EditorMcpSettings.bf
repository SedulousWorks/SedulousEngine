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

	/// The Preferences fields as typed. portText must name a port in 1024..65535 (below needs
	/// elevation, 0 cannot be put in a client's URL): anything else leaves the port as it was
	/// and returns false. The token is taken verbatim; empty means mint a new one on the next
	/// enable.
	public bool ApplyFromPreferences(bool enable, StringView portText, StringView newToken)
	{
		Enabled = enable;
		Token.Set(newToken);
		if (int64.Parse(portText) case .Ok(let parsed))
		{
			if ((parsed < 1024) || (parsed > 65535))
				return false;
			Port = (uint32)parsed;
			return true;
		}
		return false;
	}

	/// A fresh bearer token: a random Guid's canonical text, 36 characters. From the system's
	/// entropy, so two editors never mint the same one.
	public static void GenerateToken(String outToken)
	{
		outToken.Clear();
		Guid.Create().ToString(outToken, 'D');
	}
}
