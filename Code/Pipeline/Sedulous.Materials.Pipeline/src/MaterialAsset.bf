using Sedulous.Core.Serialization;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Materials.Pipeline;

/// The authored material. Its source IS the runtime source, so writing it out IS the cook.
[Serializable]
class MaterialAsset : Asset
{
	public MaterialSource Source = new .() ~ delete _;
}
