using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Script.Fixture;

[Scriptable]
class WidgetComponentManager : ResourceBindingComponentManager<WidgetComponent>
{
	[Scriptable]
	public void Poke(EntityHandle entity) {}
}
