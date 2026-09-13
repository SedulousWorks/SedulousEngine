using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Cook.Tests;

/// What every stand in builder here cooks to, so a case can read one number back and know
/// which inputs reached the build.
[Serializable]
class CookWidgetProduct
{
	public int32 CookedValue = 0;
}
