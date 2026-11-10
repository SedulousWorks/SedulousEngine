using System;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Run;

namespace Sedulous.Engine.Gameplay;

/// A run's typed events: a struct type is the event, and its value the payload.
///
/// They ride the run's EventBus, keyed by the hash of the type's full name, which is the same
/// in every build (a TypeId is not). A listener checks the payload's type as well, so another
/// event that happens to share the key, carrying another kind of value, is not misread.
///
/// Two forms, as calls have: Emit delivers now, inside the caller, the payload a reference to
/// the caller's copy, so nothing is allocated; Post queues for the run's drain (the host's
/// frame end, GameInstance.DrainRunEvents), the payload a copy the bus owns (held in the
/// Variant itself up to eight bytes, else one allocation per post, freed after delivery). A
/// post made during that drain waits for the next one. The copy is shallow: a reference or
/// view inside the struct must outlive the drain.
static class GameEvents
{
	/// Delivers `evt` now to every listener of `T` in `run`, in subscription order. Nothing
	/// without a run.
	public static void Emit<T>(IRun run, T evt) where T : struct
	{
		let bus = BusOf(run);
		if (bus == null)
			return;
		var copy = evt;
		bus.Send(EventKey<T>.Hash, Variant.Create<T>(ref copy));
	}

	/// Queues `evt` for the run's next drain. Nothing without a run.
	public static void Post<T>(IRun run, T evt) where T : struct
	{
		let bus = BusOf(run);
		if (bus == null)
			return;
		bus.Post(EventKey<T>.Hash, Variant.Create<T>(evt));
	}

	/// Calls `handler` with every `T` emitted or posted in `run` until the returned
	/// subscription is disposed. TAKES OWNERSHIP of `handler`, which the bus deletes when the
	/// subscription ends (a handler may end its own), and at once when there is no run, the
	/// subscription then empty.
	public static EventSubscription Listen<T>(IRun run, delegate void(T) handler) where T : struct
	{
		let bus = BusOf(run);
		if (bus == null)
		{
			delete handler;
			return .();
		}
		delegate void(Variant) callback = new [=handler] (payload) =>
			{
				if (payload.VariantType == typeof(T))
					handler(payload.Get<T>());
			} ~ delete handler;
		return .(bus, bus.SubscribeOwned(EventKey<T>.Hash, callback));
	}

	/// The bus key of event `T`.
	public static StringHash KeyOf<T>() where T : struct => EventKey<T>.Hash;

	private static EventBus BusOf(IRun run) => (run != null) ? run.Events : null;
}

/// One event type's bus key, worked out on first use and kept.
static class EventKey<T> where T : struct
{
	private static StringHash sHash = .();

	public static StringHash Hash
	{
		get
		{
			if (!sHash.IsValid)
				sHash = StringHash(typeof(T).GetFullName(.. scope .()));
			return sHash;
		}
	}
}

/// A GameEvents subscription: disposing it ends the subscription. A value, so it can be held
/// anywhere; an empty one (no run) disposes as nothing.
struct EventSubscription : IDisposable
{
	/// BORROWED: the run's bus, which outlives its scenes and so everything in them that
	/// listens.
	private EventBus mBus;
	private uint32 mHandle;

	public this()
	{
		mBus = null;
		mHandle = 0;
	}

	public this(EventBus bus, uint32 handle)
	{
		mBus = bus;
		mHandle = handle;
	}

	public bool IsSubscribed => (mBus != null) && (mHandle != 0);

	public void Dispose() mut
	{
		if (mBus != null)
			mBus.Unsubscribe(mHandle);
		mBus = null;
		mHandle = 0;
	}
}
