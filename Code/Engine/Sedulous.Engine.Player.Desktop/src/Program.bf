using System;
using Sedulous.Engine.Player.DesktopMain;

namespace Sedulous.Engine.Player.Desktop;

/// The DESKTOP entry for the player.
///
/// A SEPARATE PROJECT from the browser entry rather than one project with a platform switch,
/// because what differs is not code. The dependencies differ (Shell.SDL3 and Runtime.SDL3
/// against Shell.Web and Runtime.Web) and a compile time branch cannot drop a dependency, so
/// one project would link SDL3 into the wasm build. The link flags and the target name differ
/// too, and both live in BeefProj.toml where no #if reaches.
///
/// The boot is DesktopPlayerMain's, in a library, so a project's own build boots the same way
/// with its packages linked in.
class Program
{
	public static int Main(String[] args) => DesktopPlayerMain.Run(args);
}
