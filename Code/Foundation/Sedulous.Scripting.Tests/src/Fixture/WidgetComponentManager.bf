using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting.Tests.Fixture;

[Scriptable]
class WidgetComponentManager : ResourceBindingComponentManager<WidgetComponent>
{
	[Scriptable]
	public void Poke(EntityHandle entity) {}
}
