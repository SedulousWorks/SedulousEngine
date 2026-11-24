using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;

namespace Sedulous.Engine.Sequence;

/// One name of a sequence component's cast and the entity that fills it: Entity, or the
/// component's own entity when This Entity is set (a prefab's staged moment played by its root).
/// An object the component's list owns, so the inspector adds (by its reflected constructor),
/// removes and moves rows.
[Reflect(.All)]
[DisplayName("Cast Member")]
class SequenceCastEntry
{
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;
	[DisplayName("Entity")]
	public EntityRef Entity = .();
	[DisplayName("This Entity")]
	public bool Self = false;

	public this() {}

	public this(StringView name, EntityRef entity, bool ownEntity)
	{
		Name.Set(name);
		Entity = entity;
		Self = ownEntity;
	}
}

/// Plays a sequence from an entity: the cast picked in the inspector, what the play reports told
/// to this entity's behaviours as entity events, and the play stopped when the entity is
/// destroyed or disabled. The play runs in the scene's SequenceSystem like any other.
///
/// Play() and Stop() write intent the manager's next update consumes, so a call from a behaviour
/// is safe whenever it happens. Everything below the authored block is the manager's.
[SerializableComponent("sequence", 1)]
[DisplayName("Sequence")]
[Category("Animation")]
[Scriptable]
[Description("Plays a sequence from this entity: a cutscene timeline driving the entities of its cast.")]
struct SequenceComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public Ref<SequenceResource> Sequence = .(Guid());
	/// The names the sequence's tracks are bound to and who fills each. OWNED by the manager,
	/// with its entries.
	[DisplayName("Cast")]
	public List<SequenceCastEntry> Cast = null;
	[Scriptable]
	public bool Autoplay = true;
	[Scriptable]
	public float Speed = 1.0f;
	[Scriptable]
	public bool Loop = false;
	[DisplayName("At the End")]
	public SequenceFinish Finish = .Release;

	// ---- the manager's ----

	/// Its play in the scene's SequenceSystem; 0: none.
	[Hidden]
	public uint32 PlayId = 0;
	/// Play() asked; started at the next update.
	[Hidden]
	public bool StartPending = false;
	[Hidden]
	public bool StopPending = false;
	/// Autoplay has started it this run.
	[Hidden]
	public bool Autoplayed = false;

	public this() {}

	/// Starts the sequence from the beginning at the next update (again, if it is playing).
	[Scriptable]
	public void Play() mut
	{
		StartPending = true;
		StopPending = false;
	}

	/// Stops it at the next update.
	[Scriptable]
	public void Stop() mut
	{
		StopPending = true;
		StartPending = false;
	}

	public void ResolveResources(ResourceManager manager) mut
	{
		Sequence.Bind(manager);
	}

	/// The sequence, the cast as parallel lists (name, entity, this entity), and the settings. The
	/// manager's state is runtime only.
	public void Serialize(ISerializer ar) mut
	{
		let reading = ar.Mode == .Read;
		SerializeValue(ar, "sequence", ref Sequence.Id);
		let names = scope List<String>();
		let entities = scope List<Guid>();
		let ownEntity = scope List<uint8>();
		defer { ClearAndDeleteItems!(names); }
		if (!reading)
		{
			for (let entry in Cast)
			{
				names.Add(new .(entry.Name));
				entities.Add(entry.Entity.Id);
				ownEntity.Add(entry.Self ? 1 : 0);
			}
		}
		ar.Key("castName");
		SerializeList(ar, names);
		ar.Key("castEntity");
		SerializeList(ar, entities);
		ar.Key("castSelf");
		SerializeList(ar, ownEntity);
		if (reading)
		{
			ClearAndDeleteItems!(Cast);
			for (int i < Math.Min(names.Count, Math.Min(entities.Count, ownEntity.Count)))
				Cast.Add(new .(names[i], .(entities[i]), ownEntity[i] != 0));
		}
		SerializeValue(ar, "autoplay", ref Autoplay);
		SerializeValue(ar, "speed", ref Speed);
		SerializeValue(ar, "loop", ref Loop);
		uint8 finish = (uint8)Finish;
		SerializeValue(ar, "finish", ref finish);
		Finish = (finish <= (uint8)SequenceFinish.Restore) ? (SequenceFinish)finish : .Release;
	}
}

/// The sequence components of a scene: starts and stops their plays in the scene's SequenceSystem,
/// just before it steps them.
class SequenceComponentManager : ResourceBindingComponentManager<SequenceComponent>
{
	/// Just before the SequenceSystem (-99), so a play started here steps this frame; with the
	/// first gameplay systems after the behaviours (-110).
	public const int32 cUpdateOrder = -100;

	public override int32 UpdateOrder => cUpdateOrder;
	public override bool IsSimulationOnly => true;

	protected override void OnComponentCreated(SequenceComponent* component, EntityHandle entity)
	{
		component.Cast = new .();
	}

	protected override void OnComponentDestroyed(SequenceComponent* component, EntityHandle entity)
	{
		if (component.Cast != null)
			DeleteContainerAndItems!(component.Cast);
		component.Cast = null;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (Scene == null))
			return;
		let system = Scene.GetSystem<SequenceSystem>();
		ForEach(scope (component, owner) =>
		{
			if (!Scene.IsEffectivelyActive(owner))
				return;
			// A play that has ended leaves the system; forget it here too.
			if ((component.PlayId != 0) && ((system == null) || (system.Find(component.PlayId) == null)))
				component.PlayId = 0;
			if (component.StopPending)
			{
				component.StopPending = false;
				StopPlay(component);
			}
			if (component.StartPending || (component.Autoplay && !component.Autoplayed))
			{
				component.StartPending = false;
				component.Autoplayed = true;
				Start(component, owner);
			}
		});
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		let component = Get(entity);
		if (component != null)
			StopPlay(component);
		base.OnEntityDestroyed(entity);
	}

	public override void OnEntityActiveChanged(EntityHandle entity, bool active)
	{
		if (active)
			return;
		let component = Get(entity);
		if (component != null)
			StopPlay(component);
	}

	public override void OnSceneStopped()
	{
		// The system stops every play itself; the components only forget theirs, so the next run
		// autoplays again.
		ForEach(scope (component, owner) =>
		{
			component.PlayId = 0;
			component.StartPending = false;
			component.StopPending = false;
			component.Autoplayed = false;
		});
	}

	private void Start(SequenceComponent* component, EntityHandle owner)
	{
		StopPlay(component);
		let system = Scene.GetSystem<SequenceSystem>();
		let resource = component.Sequence.Get;
		if ((system == null) || (resource == null))
			return;
		let scene = Scene;
		component.PlayId = system.Play(resource, component.Sequence.Id, component.Finish, owner, component.Sequence.Handle,
			scope (play) =>
			{
				play.Speed = Math.Max(0.0f, component.Speed);
				play.Loop = component.Loop;
				for (let entry in component.Cast)
					play.Bind(entry.Name, entry.Self ? owner : scene.FindEntity(entry.Entity.Id));
			});
	}

	private void StopPlay(SequenceComponent* component)
	{
		if (component.PlayId == 0)
			return;
		let system = Scene.GetSystem<SequenceSystem>();
		if (system != null)
			system.Stop(component.PlayId);
		component.PlayId = 0;
	}
}
