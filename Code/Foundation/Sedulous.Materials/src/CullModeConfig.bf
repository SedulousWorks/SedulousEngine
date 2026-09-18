using Sedulous.Core;

namespace Sedulous.Materials;

/// The face culling preset.
///
/// DISTINCT from the RHI's CullMode so the material layer stays RHI agnostic at the data
/// level: a material is data that an editor writes and a cook stores, and it should not
/// carry a GPU enum into an asset file. Mapped when the pipeline is built.
[Scriptable(.AllPublic)]
enum CullModeConfig : uint8
{
	case None;
	case Back;
	case Front;
}
