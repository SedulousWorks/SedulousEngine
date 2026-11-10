using System;
using Sedulous.VFS;
using Sedulous.VFS.Pak;

namespace Sedulous.Engine.Player;

/// Where a game and the engine's data are, when they are not folders the player finds by path
/// (an Android app's, read in place from its APK). Each one given replaces the lookup: Game holds
/// player.xml, Content is its Content.pak, and Data is the engine's data root.
///
/// OWNED until the player's boot takes them; whatever it leaves goes with this.
class PlayerMounts
{
	public IFileSystem Game = null ~ delete _;
	public PakFileSystem Content = null ~ delete _;
	public IFileSystem Data = null ~ delete _;
}
