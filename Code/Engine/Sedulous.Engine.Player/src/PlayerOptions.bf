using System;
using Sedulous.Runtime;
using Sedulous.VFS;
using Sedulous.VFS.Pak;

namespace Sedulous.Engine.Player;

/// What a player run was asked for on the way in.
class PlayerOptions
{
	public String ProjectDir = new .() ~ delete _;
	/// A source database path. Empty takes the manifest's own default scene.
	public String SceneOverride = new .() ~ delete _;
	/// Above nought exits after that many seconds, which is what a smoke run wants.
	public float ExitAfterSeconds = 0.0f;
	/// The game's mounts made by the host (an Android app's, read from its APK); null, they come
	/// from ProjectDir. OWNED until the application takes them at startup.
	public IFileSystem GameRoot = null ~ delete _;
	public PakFileSystem ContentPak = null ~ delete _;
}
