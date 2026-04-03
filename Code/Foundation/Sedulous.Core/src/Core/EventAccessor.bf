using System;
using System.Threading;
namespace Sedulous.Core;

class EventAccessor<T> where T : Delegate
{
	private Event<T> mEvent = .();
	private Monitor mMonitor;

	public this(Monitor monitor = null)
	{
		mMonitor = monitor;
	}

	public ~this()
	{
		mEvent.Dispose();
	}

	public void Subscribe(T handler)
	{
		mMonitor?.Enter();
		defer mMonitor?.Exit();
		mEvent.Add(handler);
	}

	public Result<void> Unsubscribe(T handler, bool deleteDelegate = true)
	{
		mMonitor?.Enter();
		defer mMonitor?.Exit();
		return mEvent.Remove(handler, deleteDelegate);
	}

	/// Invokes all subscribed handlers with the given parameters.
	private rettype(T) Invoke(params T p)
	{
		return mEvent.Invoke(params p);
	}
}