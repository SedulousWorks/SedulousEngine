using System;

namespace Samples.UISandbox;

/// Where this sandbox's content sits inside the repository's data.
///
/// The walk that finds it is shared, because every sample that ships data needs the same one;
/// only the paths below are this sandbox's own.
static class SandboxContent
{
	public const String cFontFile = "Engine/Fonts/roboto/Roboto-Regular.ttf";
	public const String cBoldFontFile = "Engine/Fonts/roboto/Roboto-Bold.ttf";
	public const String cTitleFontFile =
		"Samples/Fonts/lilita-one/LilitaOne-Regular.ttf";
	public const String cPlayfulFontFile =
		"Samples/Fonts/chewy/Chewy-Regular.ttf";
	public const String cUiAssetDir = "Samples/UI";

	public static bool FindFile(StringView relative, String outPath) =>
		Samples.Common.SampleContent.FindFile(relative, outPath);

	public static bool FindDirectory(StringView relative, String outPath) =>
		Samples.Common.SampleContent.FindDirectory(relative, outPath);
}
