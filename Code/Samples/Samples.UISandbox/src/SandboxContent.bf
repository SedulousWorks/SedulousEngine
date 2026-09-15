using System;

namespace Samples.UISandbox;

/// Where this sandbox's content sits inside the repository's data.
///
/// The walk that finds it is shared, because every sample that ships data needs the same one;
/// only the paths below are this sandbox's own.
static class SandboxContent
{
	public const String cFontFile = "Assets/fonts/roboto/Roboto-Regular.ttf";
	public const String cMonsterFontFile =
		"Assets/fonts/attack-of-monster/Attack Of Monster.ttf";
	public const String cJungleFontFile =
		"Assets/fonts/jungle-adventurer/JungleAdventurer.ttf";
	public const String cUiAssetDir = "Assets/ui";

	public static bool FindFile(StringView relative, String outPath) =>
		Samples.Common.SampleContent.FindFile(relative, outPath);

	public static bool FindDirectory(StringView relative, String outPath) =>
		Samples.Common.SampleContent.FindDirectory(relative, outPath);
}
