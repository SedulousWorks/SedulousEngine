using System;

namespace Samples.Sandbox;

/// Where this sandbox's content sits inside the repository's data.
///
/// Every one of these is OPTIONAL: a checkout without the models, images or environment maps
/// still runs, and simply shows the parts of the scene that need nothing.
static class SandboxPaths
{
	public const String cOutputDir = "Output/Sandbox";
	public const String cModelDir = "Samples/Models";
	public const String cImageDir = "Samples/Images";
	public const String cEnvironmentDir = "Samples/Environment";

	public const String cHdrSky = "Templates/kloofendal_48d_partly_cloudy_puresky/kloofendal_48d_partly_cloudy_puresky_1k.hdr"; // the sky a new project starts with
	public const String cCubemapFace = "Samples/Environment/cube_sky/px.png";
	public const String cLogoImage = "logo.png";
}
