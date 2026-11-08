using System;

namespace SkyHopper;

/// The assets the game's code names by id: its scenes, screens, effects, clips and sounds, as the
/// project's imports made them (a re-import keeps an asset's id).
static class Assets
{
	// The levels (Scenes/Level1 to Level5).
	public static readonly Guid Level1 = Id("d54b3804-21ff-724a-a076-4e971ef6b238");
	public static readonly Guid Level2 = Id("d56e307e-8751-4241-a1ff-565b483b2cf1");
	public static readonly Guid Level3 = Id("e8094435-4425-034d-b972-6bca7668b14d");
	public static readonly Guid Level4 = Id("e4fe9908-429b-3c4f-9257-95cddc58d7d6");
	public static readonly Guid Level5 = Id("ea16b013-ac16-8a4f-9281-f8ebcb5d94f1");

	// The screens, on the engine GUI (Tools/ui, imported by Tools/importui.py).
	public const String HudDoc = "{e09972b0-43f3-034d-9760-b3f74dcf11ad}";
	public const String TitleDoc = "{5fd73dbe-154b-db49-8901-6ce2c3b20a02}";
	public const String IntroDoc = "{a5c33950-5d25-514a-ac27-86c20e332525}";
	public const String PauseDoc = "{bdc6be12-9060-8042-bf90-2946b0423368}";
	public const String ClearDoc = "{bc75d2d9-8afe-7f4a-a5b0-bbdb84695c53}";
	public const String VictoryDoc = "{b64e0bde-4209-304d-a9ab-8d9fc79d3e67}";
	public const String FadeDoc = "{f41b5031-33c0-d142-8f7b-24950e820278}";
	public const String SettingsDoc = "{d9a81097-a913-b84d-8b2f-73d02e45cc44}";
	public const String GameOverDoc = "{824cdd2c-b9b9-d94d-bdd2-5b628b5131b8}";

	// Music: CodeManu's Platformer Game Music Pack (CC-BY 3.0) and Juhani Junkala's Chiptune
	// Adventures (CC0); see CREDITS.md.
	public static readonly Guid MenuMusic = Id("3d2725e8-4b25-6a40-944d-57f5060a741d"); // Audio/Music-IntroTheme
	public static readonly Guid Level1Music = Id("220216e9-ce96-e34d-9ff3-d6f2644ff9a4"); // Audio/Music-GrasslandsTheme
	public static readonly Guid Level2Music = Id("b90d9d25-b608-4643-9ce2-19bd3e5a9ded"); // Audio/Music-Stage1
	public static readonly Guid Level3Music = Id("852aeb40-1328-374e-9bb8-76663e55f695"); // Audio/Music-Stage2

	// The sounds (Kenney, CC0).
	public static readonly Guid ButtonSound = Id("d85b7392-aa68-0144-a40a-830d4e32079b"); // Audio/button-maximize_007
	public static readonly Guid ClearJingle = Id("26864262-5533-b442-8d38-b77aeaa1ce30"); // Audio/jingles_NES13
	public static readonly Guid VictoryJingle = Id("a8c66ad5-4705-ae4e-af1e-ca70bb89e446"); // Audio/jingles_NES00
	/// Audio/powerUp7: a coin, a pickup (pitched higher), the tally's tick and a star landing.
	public static readonly Guid Chime = Id("cd3e0197-ff26-a740-8ad2-a7774508f0f8");
	public static readonly Guid JumpSound = Id("f0771aa4-37aa-8a47-92f1-43e708c441e0"); // Audio/phaseJump1
	public static readonly Guid HurtSound = Id("4425182f-1d33-d244-a267-0d020575d807"); // Audio/phaserDown2
	public static readonly Guid FallSound = Id("ba04916a-434c-684d-8c3d-00cbab83ca76"); // Audio/zapThreeToneDown
	/// Audio/impactSoft_heavy_000: an enemy stomped flat.
	public static readonly Guid SquashSound = Id("411669a4-eadb-2c4b-b74d-a7d86338559c");

	// The Character model's clips (Models/Character/Character).
	public static readonly Guid IdleClip = Id("9d570e4d-2821-d043-abc6-bd79566a5dc3");
	public static readonly Guid RunClip = Id("4a8fbc98-4874-514f-983d-7a060c8713c0");
	public static readonly Guid JumpClip = Id("4dfca5b6-4d94-cc43-a328-3210e392d7a1");

	// The effects (FX/*), each removing itself when it is done (TimedLife).
	/// Dust at the feet on a jump and a hard landing.
	public static readonly Guid Dust = Id("0f9877ac-2cfa-fe41-b1bf-bbc2be01dba3");
	/// A poof where the player went, and where they reappear.
	public static readonly Guid Poof = Id("5d7697bb-a73a-0f43-8c69-86bc81a81f3a");
	/// The burst where a coin or a pickup was taken.
	public static readonly Guid CoinSparkle = Id("e93dd0c2-fe3e-7f43-a636-f9eae8fe7b7b");
	/// The burst where an enemy was stomped.
	public static readonly Guid StompStars = Id("4690f883-70cf-d244-ac13-e9a94aefc730");
	/// The celebration at the flag.
	public static readonly Guid Confetti = Id("292a3bbc-dd5c-9847-b793-2147a3a3bdd8");

	private static Guid Id(StringView text) => Guid.Parse(text).Get();
}
