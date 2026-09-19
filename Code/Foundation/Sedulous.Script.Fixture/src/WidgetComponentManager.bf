using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Script.Fixture;

[Scriptable]
class WidgetComponentManager : ResourceBindingComponentManager<WidgetComponent>
{
	public int Pokes = 0;
	public EntityHandle LastPoked = .Invalid;

	/// On the entity as well: `entity.Poke()`, the entity-first rule by request.
	[Scriptable, ScriptOnEntity]
	public void Poke(EntityHandle entity)
	{
		Pokes++;
		LastPoked = entity;
	}

	/// Entity-first, but NOT asked onto the entity: a manager's verb stays on the manager.
	[Scriptable]
	public void Nudge(EntityHandle entity, float amount = 1.0f) {}
}
