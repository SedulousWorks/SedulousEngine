using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// A platform a game exports to: its tag (the platform name a template, a preset and a plugin
/// package's platforms use), the built-in icon its templates get unless their maker names
/// another, and how its build names the player made from a base name: an executable, a page, or
/// the library an Android app loads.
struct ExportPlatform
{
	public StringView Tag;
	public StringView Icon;
	public StringView PlayerPrefix;
	public StringView PlayerSuffix;

	public this(StringView tag, StringView icon, StringView playerPrefix, StringView playerSuffix)
	{
		Tag = tag;
		Icon = icon;
		PlayerPrefix = playerPrefix;
		PlayerSuffix = playerSuffix;
	}

	/// The platforms a game exports to. A new package supports them all, and the tools that take
	/// a platform name them from here.
	public static ExportPlatform[4] All = .(.("Linux64", "linux", "", ""), .("Win64", "windows", "", ".exe"),
		.("Web", "web", "", ".html"), .("Android64", "phone", "lib", ".so"));

	/// The export platform tagged `tag`, or null when no game exports to it.
	public static ExportPlatform* Find(StringView tag)
	{
		for (var platform in ref All)
		{
			if (platform.Tag == tag)
				return &platform;
		}
		return null;
	}

	/// Whether `tag` is one of them.
	public static bool IsKnown(StringView tag) => Find(tag) != null;

	/// The file `platform`'s build makes of a player called `baseName` ("libmain.so" on Android);
	/// `baseName` itself on a platform not among them.
	public static void PlayerFile(StringView platform, StringView baseName, String outName)
	{
		outName.Clear();
		if (let known = Find(platform))
			outName.AppendF("{}{}{}", known.PlayerPrefix, baseName, known.PlayerSuffix);
		else
			outName.Append(baseName);
	}

	/// Their tags, comma separated ("Linux64, Win64, ..."), for a message or a tool's description.
	public static void List(String outList)
	{
		for (let platform in All)
		{
			if (!outList.IsEmpty)
				outList.Append(", ");
			outList.Append(platform.Tag);
		}
	}
}

/// What an Android export builds: an APK to install (on a phone, or from a store that takes
/// one), an Android App Bundle for Google Play, or both.
[Reflect(.StaticFields)]
enum AndroidPackage : uint8
{
	case Apk;
	case Bundle;
	case Both;
}

/// How an export makes its player. A template export copies the template's prebuilt player (no
/// toolchain needed); a native export ships the game's own player, built from the engine
/// checkout with the game's native parts linked in (its plugin packages). A project with native
/// parts exports natively only.
[Reflect(.StaticFields)]
enum ExportKind : uint8
{
	case Template;
	case Native;
}

/// A preset field that is one platform's alone (the Android app's id is no desktop's), so an
/// editor of presets shows it only for a preset of that platform.
[AttributeUsage(.Field, .ReflectAttribute, ReflectUser = .NonStaticFields)]
struct PresetPlatformAttribute : Attribute
{
	public String Platform;

	public this(String platform)
	{
		Platform = platform;
	}
}

/// One export target: which template, the player and its runtime sidecars, plus the game
/// specific extras and the output naming. References a template by id or platform, never
/// an absolute path, so a preset is portable and committable. The CLI and the editor's
/// Export menu both drive the export from these, so a preset produces the SAME dist
/// whichever surface triggers it.
///
/// Each field a preset editor sets is a [Setting]: the MCP preset tools read and set them
/// through its reflection.
[Serializable(1)]
class ExportPreset
{
	/// "Linux64 Desktop"
	[Setting("Name")]
	public String Name = new .() ~ delete _;
	/// "Win64" / "Linux64" / "Web": the build platform tag.
	[Setting("Platform")]
	public String Platform = new .() ~ delete _;
	/// Which template; empty resolves by platform and config.
	[Setting("Template")]
	public String TemplateId = new .() ~ delete _;
	/// The output executable name; empty is the template's player basename.
	[Setting("Player name")]
	public String PlayerName = new .() ~ delete _;
	/// The export root relative output directory; empty is the sanitised Name.
	[Setting("Output subdir")]
	public String OutputSubdir = new .() ~ delete _;
	/// Game specific extra files, beyond the template's sidecars, project relative.
	[Setting("Extra files")]
	public List<String> AdditionalFiles = new .() ~ DeleteContainerAndItems!(_);
	/// "Debug" / "Release" / "Test"; empty is Release.
	[Setting("Config")]
	public String Config = new .() ~ delete _;
	/// Stage the template's symbol files into the dist; the default ships stripped.
	[Setting("Stage debug symbols")]
	public bool StageSymbols = false;
	/// The template's player, or the game's own.
	[Appended, Setting("Export kind")]
	public ExportKind Kind = .Template;
	/// Ship only the closure of the entry points; the default packs everything, the escape
	/// hatch for a team not managing reachability.
	[Setting("Prune to reachable content")]
	public bool PruneToReachable = false;

	/// This platform draws at its own resolution rather than the project's (a handheld's
	/// native panel, say): the dist carries these instead.
	[Appended, Setting("Own render size")]
	public bool OverridesRender = false;
	[Appended, Setting("Render width"), Range(0, 16384, 1)]
	public uint32 RenderWidth = 0;
	[Appended, Setting("Render height"), Range(0, 16384, 1)]
	public uint32 RenderHeight = 0;
	[Appended, Setting("Render fit")]
	public FitMode RenderFit = .Letterbox;

	/// This platform's window differs from the project's (fullscreen on a console-like
	/// device, say): the dist carries these instead.
	[Appended, Setting("Own window")]
	public bool OverridesWindow = false;
	[Appended, Setting("Window width"), Range(1, 16384, 1)]
	public uint32 WindowWidth = 1280;
	[Appended, Setting("Window height"), Range(1, 16384, 1)]
	public uint32 WindowHeight = 720;
	[Appended, Setting("Window mode")]
	public WindowMode WindowMode = .Windowed;
	[Appended, Setting("Window resizable")]
	public bool WindowResizable = true;

	/// This platform is held its own way (a phone-facing Web preset says Landscape, so a game
	/// that takes any shape on a desktop is presented turned on a phone held upright).
	[Appended, Setting("Own orientation")]
	public bool OverridesOrientation = false;
	[Appended, Setting("Orientation")]
	public ScreenOrientation Orientation = .Any;

	/// The dist keeps its custom shaders' HLSL (a game that wants modders to read them). Off:
	/// the pack carries the shaders as bytecode and the dist ships no shader source, as the
	/// engine's own ship none.
	[Appended, Setting("Include shader source")]
	public bool IncludeShaderSource = false;

	/// The quality level this platform starts at, one of the project's levels (a phone's lower
	/// than a desktop's); nil is the project's default.
	[Appended, Setting("Quality level", "RenderQualityAsset", "(the project's default)")]
	public Guid QualityLevelId;

	/// An Android export's app (Android64 presets alone): its id, the version a store and a
	/// phone compare (the code) and the one a person reads (the name), the name under its icon
	/// (empty: the project's), the launcher icon (a square PNG in the project, 512 pixels or
	/// more; empty: the platform's), what it builds, and the release keystore it is signed with
	/// (empty: the developer's debug key) by the key `AndroidKeyAlias`. The keystore's passwords
	/// are never in a preset: the export asks for them, or reads them from the environment.
	[Appended, Setting("Application id"), PresetPlatform("Android64")]
	public String AndroidApplicationId = new .() ~ delete _;
	[Appended, Setting("Version code"), PresetPlatform("Android64"), Range(1, 2100000000, 1)] // Google Play's ceiling
	public uint32 AndroidVersionCode = 1;
	[Appended, Setting("Version name"), PresetPlatform("Android64")]
	public String AndroidVersionName = new .("1.0") ~ delete _;
	[Appended, Setting("App name"), PresetPlatform("Android64")]
	public String AndroidLabel = new .() ~ delete _;
	[Appended, Setting("App icon"), PresetPlatform("Android64")]
	public String AndroidIcon = new .() ~ delete _;
	[Appended, Setting("Package"), PresetPlatform("Android64")]
	public AndroidPackage AndroidPackage = .Apk;
	[Appended, Setting("Keystore"), PresetPlatform("Android64")]
	public String AndroidKeystore = new .() ~ delete _;
	[Appended, Setting("Key alias"), PresetPlatform("Android64")]
	public String AndroidKeyAlias = new .() ~ delete _;

	/// Why `id` cannot be an Android application id, in `outWhy`, or true when it can: two or
	/// more parts joined by '.', each a letter followed by letters, digits or '_'
	/// ("com.studio.game").
	public static bool CheckAndroidApplicationId(StringView id, String outWhy)
	{
		if (id.IsEmpty)
		{
			outWhy.Append("an Android export needs an application id (as com.studio.game)");
			return false;
		}
		int parts = 0;
		for (let part in id.Split('.'))
		{
			if (part.IsEmpty || !(((part[0] >= 'a') && (part[0] <= 'z')) || ((part[0] >= 'A') && (part[0] <= 'Z'))))
			{
				outWhy.AppendF("'{}' is not an application id: each part, between the dots, starts with a letter", id);
				return false;
			}
			for (let c in part.RawChars)
			{
				if (!(((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_')))
				{
					outWhy.AppendF("'{}' is not an application id: its parts hold letters, digits and '_'", id);
					return false;
				}
			}
			parts++;
		}
		if (parts < 2)
		{
			outWhy.AppendF("'{}' is not an application id: it has two parts or more (as com.studio.game)", id);
			return false;
		}
		return true;
	}

	public void CopyTo(ExportPreset other)
	{
		other.Name.Set(Name);
		other.Platform.Set(Platform);
		other.TemplateId.Set(TemplateId);
		other.PlayerName.Set(PlayerName);
		other.OutputSubdir.Set(OutputSubdir);
		ClearAndDeleteItems(other.AdditionalFiles);
		for (let file in AdditionalFiles)
			other.AdditionalFiles.Add(new String(file));
		other.Config.Set(Config);
		other.StageSymbols = StageSymbols;
		other.Kind = Kind;
		other.PruneToReachable = PruneToReachable;
		other.OverridesRender = OverridesRender;
		other.RenderWidth = RenderWidth;
		other.RenderHeight = RenderHeight;
		other.RenderFit = RenderFit;
		other.OverridesWindow = OverridesWindow;
		other.WindowWidth = WindowWidth;
		other.WindowHeight = WindowHeight;
		other.WindowMode = WindowMode;
		other.WindowResizable = WindowResizable;
		other.OverridesOrientation = OverridesOrientation;
		other.Orientation = Orientation;
		other.IncludeShaderSource = IncludeShaderSource;
		other.QualityLevelId = QualityLevelId;
		other.AndroidApplicationId.Set(AndroidApplicationId);
		other.AndroidVersionCode = AndroidVersionCode;
		other.AndroidVersionName.Set(AndroidVersionName);
		other.AndroidLabel.Set(AndroidLabel);
		other.AndroidIcon.Set(AndroidIcon);
		other.AndroidPackage = AndroidPackage;
		other.AndroidKeystore.Set(AndroidKeystore);
		other.AndroidKeyAlias.Set(AndroidKeyAlias);
	}

	/// The config for resolution: empty reads as Release.
	public StringView EffectiveConfig => Config.IsEmpty ? "Release" : StringView(Config);
}
