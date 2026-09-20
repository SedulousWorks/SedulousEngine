using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Tests;

/// A concrete asset: the source file the base carries plus one setting.
[Serializable]
class WidgetAsset : Asset
{
	public int32 Quality = 0;
}
