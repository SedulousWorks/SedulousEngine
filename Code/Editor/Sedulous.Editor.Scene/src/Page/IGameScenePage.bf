using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A page running the game in a scene (a Game tab), as the scene tools read it: entity_inspect
/// with `pie` reads the scene of the one with that id. Play in editor implements it, through
/// its IPieInstancePage; a module reaches it with `page as IGameScenePage`.
interface IGameScenePage
{
	/// The tab's id: `game-page` (GameScenePages.cPrimaryPieId) for the primary, `game-page-1`,
	/// `game-page-2`, ... for the instances Play New Instance opens. The dock persists the tab
	/// under it too.
	StringView PieId { get; }
	/// A run is going.
	bool IsRunning { get; }
	/// The scene the run is in now; null when it has none.
	Sedulous.Scene.Scene RunningScene { get; }
}

/// The open Game tabs, as the scene tools find them.
static class GameScenePages
{
	/// The primary Game tab's id.
	public const String cPrimaryPieId = "game-page";

	/// The open Game tab with this id, or null.
	public static IGameScenePage Find(EditorContext context, StringView id)
	{
		for (let page in context.OpenPages)
		{
			if (let game = page as IGameScenePage)
			{
				if (game.PieId == id)
					return game;
			}
		}
		return null;
	}

	/// The Game tab a call's `pie` names (absent or empty: the primary); null, with the reason
	/// for the agent to read, when none is open.
	public static IGameScenePage Resolve(EditorContext context, JsonValue arguments, String outError)
	{
		let arg = (arguments != null) ? arguments.Get("pie") : null;
		let id = ((arg != null) && arg.IsString && !arg.AsString().IsEmpty) ? arg.AsString() : StringView(cPrimaryPieId);
		if (let game = Find(context, id))
			return game;
		if (id == cPrimaryPieId)
			outError.Append("no Game tab is open (pie_start opens and runs one)");
		else
			outError.AppendF("no PIE instance '{}' (pie_list names them)", id);
		return null;
	}
}
