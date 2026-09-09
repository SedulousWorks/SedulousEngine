namespace Sedulous.Render;

/// A shader instrumented debug mode: the forward shader outputs the named term instead of the
/// lit result.
///
/// A uniform branch rather than a cooked variant, so it costs nothing when it is off and
/// there is no second pipeline to keep in step. The values reach the screen RAW, since the
/// compose blits the scene colour past tone mapping. Mesh and forward materials only: the sky
/// and the bespoke renderers draw normally.
enum ViewDebugSemantic : uint8
{
	case Off = 0;
	/// The base colour after vertex colours and textures, before any lighting.
	case Albedo;
	/// The mapped world space normal, remapped about a half.
	case Normal;
	case Roughness;
	case Metallic;
	/// The shadow cascade chosen, tinted over the albedo's luminance.
	case Cascades;
	/// How many clustered lights touched each pixel, blue through red.
	case ClusterHeat;
	/// Magenta wherever the lit result came out non finite or implausibly hot.
	case Overbright;
}
