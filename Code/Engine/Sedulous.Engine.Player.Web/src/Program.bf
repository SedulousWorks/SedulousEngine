using System;
using Sedulous.Engine.Player.WebMain;

namespace Sedulous.Engine.Player.Web;

/// The stock BROWSER entry for the player. The boot is WebPlayerMain's, in a library, so a
/// project's own build (<Game>PlayerWeb) boots the same way with its packages linked in; the
/// wasm link is this project's, in its BeefProj.toml.
class Program
{
	public static int Main(String[] args) => WebPlayerMain.Run(args);
}
