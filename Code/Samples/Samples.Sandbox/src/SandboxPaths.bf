using System;

namespace Samples.Sandbox;

/// Where this sandbox's content sits inside the repository's data.
///
/// Every one of these is OPTIONAL: a checkout without the models, images or environment maps
/// still runs, and simply shows the parts of the scene that need nothing.
static class SandboxPaths
{
	public const String cOutputDir = "Data/Output/Sandbox";
	public const String cModelDir = "Data/Assets/models";
	public const String cImageDir = "Data/Assets/images";
	public const String cEnvironmentDir = "Data/Assets/environment";

	public const String cHdrSky = "Data/Assets/environment/BlueSky.hdr";
	public const String cCubemapFace = "Data/Assets/environment/cube_sky/px.png";
	public const String cLogoImage = "logo.png";
}
