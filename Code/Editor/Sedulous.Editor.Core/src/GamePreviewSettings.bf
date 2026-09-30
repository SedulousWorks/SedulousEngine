using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// One resolution the Game tab offers to preview at.
[Serializable(1)]
class GamePreviewResolution
{
	/// "Steam Deck"
	public String Name = new .() ~ delete _;
	public uint32 Width = 1920;
	public uint32 Height = 1080;

	public this() {}

	public this(StringView name, uint32 width, uint32 height)
	{
		Name.Set(name);
		Width = width;
		Height = height;
	}
}

/// The user's preview resolutions, a settings section of the per user store: sizes to test a
/// game at on this machine, offered by the Game tab after the project's own resolution and its
/// export presets'. They say nothing about the game, which is why they are not the project's.
[Serializable(1)]
class GamePreviewSettings
{
	public List<GamePreviewResolution> Presets = new .() ~ DeleteContainerAndItems!(_);
	/// The defaults went in once; a user who then removes them keeps them removed.
	public bool Seeded = false;

	/// Seeds the common sizes the first time. True when it did, so the caller saves.
	public bool SeedDefaults()
	{
		if (Seeded)
			return false;
		Seeded = true;
		Presets.Add(new .("HD", 1280, 720));
		Presets.Add(new .("Full HD", 1920, 1080));
		Presets.Add(new .("QHD", 2560, 1440));
		Presets.Add(new .("Steam Deck", 1280, 800));
		Presets.Add(new .("Phone portrait", 1080, 2400));
		Presets.Add(new .("Phone landscape", 2400, 1080));
		return true;
	}

	/// The store's section, seeded on first use (and marked changed then, so it saves). Null
	/// with no store: headless and in tests.
	public static GamePreviewSettings From(Sedulous.Settings.Settings store)
	{
		if (store == null)
			return null;
		let section = store.Section<GamePreviewSettings>();
		if (section.SeedDefaults())
			store.MarkChanged<GamePreviewSettings>();
		return section;
	}
}
