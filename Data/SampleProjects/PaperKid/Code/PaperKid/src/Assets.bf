using System;

namespace PaperKid;

/// The assets the game's code names by id: its scenes, screens, prefabs, clips and sounds, as the
/// project's imports and Tools/ made them (a re-import or a rewrite keeps an asset's id).
static class Assets
{
	// The scenes: the title's backdrop and the five blocks (Scenes/Start, Scenes/Block1 to Block5).
	public static readonly Guid Start = Id("abf41c6a-3a62-4a4f-830f-47fb88f610ff");
	public static readonly Guid Block1 = Id("252c2c2a-4795-6a4d-bafb-95001f747b70");
	public static readonly Guid Block2 = Id("5e9597f2-196d-1f42-b917-366eb2b6c2b1");
	public static readonly Guid Block3 = Id("12f0e95d-f5cd-7f4f-b5d4-5e2194dd3413");
	public static readonly Guid Block4 = Id("8eaa0f69-9e48-c248-a145-168e61e26a79");
	public static readonly Guid Block5 = Id("16eed323-f9a4-5e44-b9f7-50514bdd6aa0");

	// The screens, on the engine GUI (Tools/ui, imported by Tools/importui.py), pushed by id.
	public const String TitleDoc = "{79ff1415-3645-3e4c-80e6-6478638c4a4c}";
	public const String HudDoc = "{d0ff2e93-ff1a-8a40-b10f-93209f42af4f}";
	public const String ClearedDoc = "{339a9f1f-78bd-0849-953b-b45541400bb4}";
	public const String FailedDoc = "{9f898f82-4624-8045-b310-733575eb1026}";
	public const String GameOverDoc = "{d3fdf1b6-dba0-d649-b2d0-0214f3e53b1b}";
	public const String PauseDoc = "{94dd821d-1f47-9748-9cc1-239c264f6a9e}";
	public const String SettingsDoc = "{53fdc7e9-ec44-444f-a65b-bd50d5e6410f}";

	// The music (Audio/Music): the menus', a track per block in turn, and the ending's.
	public static readonly Guid TitleMusic = Id("92494f18-c682-6d47-8bbc-fa49f6917d4e");
	public static readonly Guid BlockMusicA = Id("859ea749-874f-414e-8bba-2ae82b7bfbfd");
	public static readonly Guid BlockMusicB = Id("9d7a0b20-f4b0-5c44-ac6d-ffe78caf041e");
	public static readonly Guid BlockMusicC = Id("4bf0e18f-ab1c-9e4e-a3b8-2361247c2309");
	public static readonly Guid EndingMusic = Id("eaa4c451-d3a3-ac4b-bccc-890a0ecec6e3");

	// The sounds (Audio; see CREDITS.md).
	public static readonly Guid ClearedFanfare = Id("e9d46ca7-2060-844b-b8c3-555510d06481");
	public static readonly Guid FailedJingle = Id("994964a2-ab5c-9042-95a1-bf0a2760a186");
	public static readonly Guid Congratulations = Id("f99a33d8-a955-614b-82c2-615c51c94615");
	public static readonly Guid GameOverVoice = Id("f2867be6-7007-9348-9a64-fca3a00e6fe5");
	public static readonly Guid ClickSound = Id("df6ebf4a-2bbf-5646-938d-4aa110b96a78");
	public static readonly Guid SliderSound = Id("d3cef52a-509c-e240-94e2-ecb446665285");
	public static readonly Guid ThrowSound = Id("0886b159-7ded-3045-b521-9a6572e961b4");
	public static readonly Guid CrashSound = Id("02cdef9a-69c1-5b4b-9e87-898a47b1b959");
	public static readonly Guid LandSound = Id("a178cf74-4e03-9e41-8ba7-625dab7a98ec"); // Audio/PaperLand
	public static readonly Guid DeliveredSound = Id("554f86eb-3e59-fe4b-adf7-670f7368d5e3");
	public static readonly Guid HurrySound = Id("5b1216d3-4e08-644c-9c30-477abe779ddf"); // Audio/HurryUp
	public static readonly Guid TickSound = Id("4163c0e1-2750-2f4c-9532-424598299c0b");
	public static readonly Guid TimeOverSound = Id("3c4b85de-ef61-ff4b-b1b5-2924a8ed3062");

	// The kid's clips (Models/KidBike, from Tools/blender/kid_bike.py). Ride turns the wheels twice
	// and the pedals once a second; each throw is the same second with that arm's throw in its first
	// half, so Ride picks up where it ends.
	public static readonly Guid RideClip = Id("4144355b-1e50-2849-8efb-e4718cefb37e");
	public static readonly Guid ThrowLeftClip = Id("3a3dc692-8809-954f-add5-febbef310a0a");
	public static readonly Guid ThrowRightClip = Id("92e5c9bc-d635-1d46-ac08-eadc0cc58792");

	// The prefabs the code spawns (Prefabs, by Tools/kit.py).
	/// A thrown paper (Prefabs/Newspaper): a body and its Paper behaviour.
	public static readonly Guid Newspaper = Id("a08aecb1-23c6-c14d-8705-8c18170504b5");
	/// One dot of the throw's arc.
	public static readonly Guid AimDot = Id("40b43d5c-0d3e-f04b-b71c-39bb82d20063");
	/// The reticle on the porch a throw is pulled toward.
	public static readonly Guid TargetRing = Id("a0d47e87-2ec8-d341-87b8-9e2d416c5684");

	// The bursts (Prefabs/Fx*), each removing itself when it has played (Fx).
	/// Confetti over the rider when a block is cleared.
	public static readonly Guid FxConfetti = Id("94a59a6c-f4d9-0841-b9c1-0d3102825c6a");
	/// Sparkles off a porch that took its paper.
	public static readonly Guid FxSparkle = Id("f9f2812e-7302-1e41-b95c-15d8e38e49a2");
	/// Road dust off the wheels in a crash.
	public static readonly Guid FxDust = Id("f60d1ddf-66a7-6848-8474-30f75869ab41");
	/// A puff where a paper lands hard.
	public static readonly Guid FxPuff = Id("8fdf193a-2ba9-c44d-ab1d-b75071f66278");

	private static Guid Id(StringView text) => Guid.Parse(text).Get();
}
