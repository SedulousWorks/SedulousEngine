using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting.Tests.Fixture;

[Scriptable]
class WidgetComponentManager : SerializableComponentManager<WidgetComponent>
{
	[Scriptable]
	public void Poke(EntityHandle entity) {}
}
