using System;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Script;

/// A script's log, as globals: `Print("...")`, through the global logger under the Script
/// tag. Globals rather than a `Log` namespace, since AngelScript cannot give a namespace
/// the name of Math's `Log(float)`.
static
{
	[Scriptable]
	public static void Print(StringView message) => GlobalLog(.Information, scope $"Script: {message}");
	[Scriptable]
	public static void PrintWarning(StringView message) => GlobalLog(.Warning, scope $"Script: {message}");
	[Scriptable]
	public static void PrintError(StringView message) => GlobalLog(.Error, scope $"Script: {message}");
}
