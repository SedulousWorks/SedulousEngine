using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.DefaultApp;

/// The player's quality choice, a section of the game's user settings: the chosen level's id.
[Serializable(1)]
class RenderQualityUserSettings
{
	public Guid Level;
}

/// Registration for the quality user settings section, which loading the file instantiates by
/// its name.
[SerializableRegistry]
static class QualityUserSettings
{
}

/// The quality levels a game's run offers its scripts (RenderQuality), read from the project, and
/// the player's saved choice among them. The player and the editor's Game tab both fill their
/// run's facade here; the player also keeps a choice in the user's settings, so the next run
/// starts at it.
static class QualityLevels
{
	/// Fills `facade` with the project's levels, in its order, each read through `resources`; a
	/// level that does not resolve is left out, with a warning. Returns the level the game starts
	/// at: `saved` (the player's choice) when the project lists it, else the preset's or the
	/// project's (ProjectSettings.StartupQuality); nil when that one was left out or the project
	/// lists none, for the engine's own level.
	public static Guid Offer(RenderQualityFacade facade, ProjectSettings settings, ResourceManager resources, Guid saved)
	{
		facade.Clear();
		var startOffered = false;
		let start = settings.StartupQuality(saved);
		for (let id in settings.QualityLevelIds)
		{
			let level = (resources != null) ? resources.Bind<RenderQualityLevel>(id).Get : null;
			if (level == null)
			{
				GlobalLog(.Warning, "Quality: the quality level {} did not resolve; it is not offered", id);
				continue;
			}
			facade.Add(id, level.Values.Label);
			startOffered |= (id == start);
		}
		facade.CurrentId = startOffered ? start : Guid();
		return facade.CurrentId;
	}

	/// The choice kept in `user` (nil: none).
	public static Guid Saved(Sedulous.Settings.Settings user)
	{
		let saved = user.Find<RenderQualityUserSettings>();
		return (saved != null) ? saved.Level : Guid();
	}

	/// Keeps `level` as the choice in `user`.
	public static void Keep(Sedulous.Settings.Settings user, Guid level)
	{
		user.Section<RenderQualityUserSettings>().Level = level;
		user.MarkChanged<RenderQualityUserSettings>();
	}
}
