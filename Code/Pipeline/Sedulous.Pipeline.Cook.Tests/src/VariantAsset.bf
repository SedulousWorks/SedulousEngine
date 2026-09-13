using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// An asset whose product depends on the export TARGET, so it cooks per target and is salted
/// in the recipe rather than carried forward.
[Serializable]
class VariantAsset : Asset
{
}
