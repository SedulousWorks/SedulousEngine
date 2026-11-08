using System;

namespace Snowline;

/// The assets the game's code names by id: its courses, screens, sounds and the gem's burst, as the
/// project's imports and Tools/ made them (a re-import or a rewrite keeps an asset's id).
static class Assets
{
	// The courses in order (Scenes/, written by Tools/course.py).
	public static readonly Guid Meadow = Id("3bf5f9c4-b106-8e4a-b815-0cfd3bfabdf0");
	public static readonly Guid Forest = Id("7d1a37c1-3b59-b640-a61f-3928be5a2179");
	public static readonly Guid Ridge = Id("44874676-6ba8-b84a-84d8-8fee02fef806");

	// The screens, on the engine GUI (Tools/ui, imported by Tools/setup.py), pushed by id.
	public const String TitleDoc = "{f0daf034-a4c9-4348-be76-83dd05bb4f08}";
	public const String HudDoc = "{13cbfb43-a8f4-1349-bd50-6a7446a6ec44}";
	public const String PauseDoc = "{f3f0d06a-768a-9648-a945-1220d7527e8c}";
	public const String FinishDoc = "{bd132384-40c8-764a-a57f-21252ad488ba}";
	public const String EndingDoc = "{be9658e8-7260-704f-ae92-cf9da4329f77}";

	// The game's sounds (Audio/, imported by Tools/sounds.py).
	/// The music on the title and in a run.
	public static readonly Guid MusicTitle = Id("63a38c8d-9801-2d4f-bc6c-6d0edcf1b6fe");
	public static readonly Guid MusicRun = Id("2fabcfe4-fe0e-9c45-834d-425e928a8892");
	/// A gate passed and missed.
	public static readonly Guid GatePass = Id("36c2b160-0b76-8045-9951-b6b7d8f1f299");
	public static readonly Guid GateMiss = Id("19153965-5a29-6044-8bce-29e0c5a196ee");
	/// The menus' click and back.
	public static readonly Guid Click = Id("df75216e-ec15-6342-b049-77fc8c92ae7b");
	public static readonly Guid Back = Id("c66c58dc-4f57-854f-a287-00e4b0c52e07");
	/// The stings for a medal won or not.
	public static readonly Guid MedalSting = Id("20c7ac1f-31ea-ee4d-9584-fec06d7bcdc7");
	public static readonly Guid NoMedalSting = Id("ac6923f0-a216-e64f-b42c-7159db62047f");
	/// A gem taken, and the results' tally ticking, pitched up row by row.
	public static readonly Guid GemChime = Id("64c88944-0a22-4e45-8af5-39858c0ada37");
	/// The board's: the pop of a jump or a kicker's lip, a clean landing, a crash into the snow
	/// and a hit on a tree or rock (Kenney's Impact Sounds).
	public static readonly Guid Pop = Id("31185485-42b7-f143-834d-de25ed0273a0");
	public static readonly Guid Land = Id("26ab84be-85fc-9740-8f10-b59010685665");
	public static readonly Guid Crash = Id("a63050c3-4f0b-4d4a-8802-895686b6d347");
	public static readonly Guid TreeHit = Id("550d9682-7b83-4746-bde4-0f4cef53de99");

	/// Prefabs/GemSparkle (Tools/gems.py): the burst where a gem was taken.
	public static readonly Guid GemSparkle = Id("d8481501-8ba1-064c-b56f-503f47e264c5");

	private static Guid Id(StringView text) => Guid.Parse(text).Get();
}
