using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Script.Fixture;

/// A scene facade in script shape over the fixture's manager and system: what a script
/// reaches as `scene.Widgets`, one per scene, made on first use.
[Scriptable, SceneFacade("Widgets")]
class WidgetsFacade : SceneFacade
{
	public int Attached = 0;

	protected override void OnAttached() => Attached++;

	private WidgetComponentManager Widgets => Scene.GetSystem<WidgetComponentManager>();

	/// A composite: pokes the entity and counts the system's tick, two systems in one verb.
	[Scriptable, ScriptOnEntity]
	public int PokeAndTick(EntityHandle entity)
	{
		Widgets?.Poke(entity);
		let system = Scene.GetSystem<FixtureSystem>();
		if (system != null)
			system.TickCount++;
		return (Widgets != null) ? Widgets.Pokes : 0;
	}

	/// How many the scene's manager has been poked, in script shape: a plain count.
	[Scriptable]
	public int Pokes => Widgets?.Pokes ?? 0;

	/// A script shaped read of a component: the size, or nought for an entity without one.
	[Scriptable]
	public float SizeOf(EntityHandle entity)
	{
		let widget = Widgets?.Get(entity);
		return (widget != null) ? widget.Size : 0.0f;
	}
}
