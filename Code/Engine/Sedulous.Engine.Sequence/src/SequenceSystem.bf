using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence.Resource;

namespace Sedulous.Engine.Sequence;

/// A scene's player of sequences: it holds every play running in its scene and steps them each
/// frame, in the order they started, right after the behaviours. What a play reports goes to its
/// owner as entity events, or, with no owner, out on the run's bus as a SequenceNotice (every scene
/// in the run hears that bus, so the notice names its play). An event track bound to an actor posts
/// to that actor.
class SequenceSystem : SceneSystem
{
	/// After the behaviours (BehaviorSystem's -110) and the sequence components (-100), so a play
	/// a script or a component starts or resumes this frame steps this frame, and before what reads
	/// what plays write.
	public const int32 cUpdateOrder = -99;

	/// One play: its sequence held loaded while it runs, what it reports to, and the play.
	private class Running
	{
		/// Keeps the sequence loaded while it plays; null for a sequence made in code. Declared
		/// first: let go of last, after the play reading the sequence is gone.
		public ResourceHold Hold ~ { if (_ != null) _.Release(); };
		public uint32 Id;
		public Guid Sequence;
		public Reporter Reporter ~ delete _;
		/// Declared last: destroyed first, before the reporter it reports to.
		public Sedulous.Sequence.SequencePlay Play ~ delete _;
	}

	/// BORROWED, from the last resolve; null until then.
	private ResourceManager mResources = null;
	/// In the order they started.
	private List<Running> mPlays = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mNextId = 1;

	public override int32 UpdateOrder => cUpdateOrder;
	public override bool IsSimulationOnly => true;

	/// The manager plays by asset id load through.
	public ResourceManager Resources => mResources;
	public int PlayCount => mPlays.Count;

	public ~this()
	{
		// The scene is going away: nothing is put back or let go of in it.
		for (let running in mPlays)
			running.Play.Abandon();
	}

	public override void ResolveResources(ResourceManager manager)
	{
		mResources = manager;
	}

	public override void CollectResourceIds(HashSet<Guid> outIds)
	{
		// What plays stays loaded while the scene is.
		for (let running in mPlays)
		{
			if (running.Sequence != Guid.Empty)
				outIds.Add(running.Sequence);
		}
	}

	public override void OnSceneStopped()
	{
		StopAll();
	}

	/// Starts a play of the asset `sequence`, loaded through the manager the scene was resolved
	/// with. 0 when there is no manager or no such sequence.
	public uint32 Play(Guid sequence, Sedulous.Sequence.SequenceFinish finish = .Release, EntityHandle owner = .Invalid)
	{
		if ((mResources == null) || (sequence == Guid.Empty))
			return 0;
		let proxy = mResources.Bind<SequenceResource>(sequence);
		let resource = proxy.Get;
		if (resource == null)
		{
			GlobalLog(.Warning, "Sequence: no sequence asset with id {}", sequence);
			return 0;
		}
		return Start(resource, sequence, proxy.Handle, finish, owner, null);
	}

	/// Starts a play of `resource` (BORROWED: it must outlive the play), named `id` in notices.
	/// `owner`, when assigned, is told what the play reports as entity events; otherwise it goes on
	/// the run's bus. `hold`, when given, keeps the sequence loaded while it plays. `prepare`, when
	/// given, sets the play up (its cast, its speed) before it starts, so time 0 is applied on what
	/// it fills. The play is at time 0 when this returns. Its id, or 0 when there is no sequence.
	public uint32 Play(SequenceResource resource, Guid id, Sedulous.Sequence.SequenceFinish finish = .Release,
		EntityHandle owner = .Invalid, ResourceHandle hold = null, delegate void(Sedulous.Sequence.SequencePlay) prepare = null)
		=> Start(resource, id, hold, finish, owner, prepare);

	/// The play numbered `id`, or null once it has ended.
	public Sedulous.Sequence.SequencePlay Find(uint32 id)
	{
		for (let running in mPlays)
		{
			if (running.Id == id)
				return running.Play;
		}
		return null;
	}

	/// Ends the play numbered `id` (its finish decides what it puts back).
	public void Stop(uint32 id)
	{
		for (int i < mPlays.Count)
		{
			if (mPlays[i].Id == id)
			{
				let running = mPlays[i];
				mPlays.RemoveAt(i);
				running.Play.Stop();
				delete running;
				return;
			}
		}
	}

	/// Ends every play (a skip, a level unloading).
	public void StopAll()
	{
		// Last first, so values two plays changed go back to what was there before both.
		for (int i = mPlays.Count - 1; i >= 0; i--)
			mPlays[i].Play.Stop();
		ClearAndDeleteItems!(mPlays);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || mPlays.IsEmpty)
			return;
		// Reports are queued (entity events and the bus both deliver later), so no play starts or
		// ends during this loop; one finished here leaves the list after it.
		for (let running in mPlays)
			running.Play.Advance(deltaTime);
		for (int i = mPlays.Count - 1; i >= 0; i--)
		{
			let play = mPlays[i].Play;
			if (play.IsFinished && (play.Finish != .Hold))
			{
				// Already let go when it finished.
				delete mPlays[i];
				mPlays.RemoveAt(i);
			}
		}
	}

	/// How a play ends, by name for scripts: "release" (the default), "hold", "restore".
	public static Sedulous.Sequence.SequenceFinish ParseFinish(StringView name)
	{
		if (name == "hold")
			return .Hold;
		if (name == "restore")
			return .Restore;
		return .Release;
	}

	private uint32 Start(SequenceResource resource, Guid id, ResourceHandle handle, Sedulous.Sequence.SequenceFinish finish,
		EntityHandle owner, delegate void(Sedulous.Sequence.SequencePlay) prepare)
	{
		if ((Scene == null) || (resource == null))
			return 0;
		let running = new Running();
		running.Id = mNextId++;
		running.Sequence = id;
		if (handle != null)
			running.Hold = new .(handle);
		running.Reporter = new .(Scene, running.Id, id, owner);
		running.Play = new .(Scene, resource.Sequence);
		running.Play.Finish = finish;
		running.Play.SetListener(running.Reporter);
		if (prepare != null)
			prepare(running.Play);
		mPlays.Add(running);
		running.Play.Play();
		return running.Id;
	}

	/// Tells whoever started a play what it reports: its owner as entity events, or the run's bus
	/// as notices. An event track bound to an actor posts to that actor.
	private class Reporter : Sedulous.Sequence.ISequenceListener
	{
		/// BORROWED.
		private Scene mScene;
		private uint32 mPlay;
		private Guid mSequence;
		private EntityHandle mOwner;

		public this(Scene scene, uint32 play, Guid sequence, EntityHandle owner)
		{
			mScene = scene;
			mPlay = play;
			mSequence = sequence;
			mOwner = owner;
		}

		public void OnSequenceEvent(EntityHandle target, StringView name, StringView value)
		{
			if (mScene.IsValid(target))
			{
				Post(target, SequenceEvents.Event, name, value);
				return;
			}
			Report(SequenceEvents.Event, SequenceEvents.EventBus, name, value);
		}

		public void OnSequenceHeld(StringView marker) => Report(SequenceEvents.Held, SequenceEvents.HeldBus, marker, "");

		public void OnSequenceFinished() => Report(SequenceEvents.Finished, SequenceEvents.FinishedBus, "", "");

		private void Report(StringView entityEvent, StringView busEvent, StringView name, StringView value)
		{
			if (mScene.IsValid(mOwner))
			{
				Post(mOwner, entityEvent, name, value);
				return;
			}
			let bus = mScene.Events;
			if (bus != null)
				bus.Publish(StringHash(busEvent), Variant.Create(SequenceNotice((int32)mPlay, mSequence, name, value)));
		}

		/// The values an entity behaviour's on<Name> receives: the name and value for an event,
		/// the marker for a hold, nothing more for the end.
		private void Post(EntityHandle target, StringView entityEvent, StringView name, StringView value)
		{
			if (!mScene.WantsEntityEvents)
				return;
			var args = EntityEventArg[2](.FromString(name), .FromString(value));
			int count = 0;
			if (entityEvent == SequenceEvents.Event)
				count = 2;
			else if (entityEvent == SequenceEvents.Held)
				count = 1;
			mScene.PostEntityEvent(.(target, entityEvent, .(&args[0], count)));
		}
	}
}
