using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource;

/// The resource reference a component holds.
///
/// Three things in one: an IDENTITY that is serialized, a runtime BINDING to the manager,
/// and a DIRECT override for an object that was made in code and has no identity at all.
/// Get prefers the direct object, so a procedural mesh wins over anything the identity
/// would have resolved to.
///
/// ONLY THE IDENTITY IS SERIALIZED. The binding and the override are runtime state, and a
/// reference read from a file arrives unbound.
///
/// The direct object is BORROWED: whoever created it owns it and must outlive this. Beef
/// gives a struct no destructor, so a field cannot release what it points at, and pretending
/// otherwise would be a leak with extra steps. A stored binding is retained and forgotten by
/// the component that holds it, for the same reason.
struct Ref<T> where T : class
{
	/// The serialized identity. Nil means unset, or an object that only exists in code.
	public Guid Id;

	private Proxy<T> mProxy;
	private T mDirect;

	public this(Guid id)
	{
		Id = id;
		mProxy = default;
		mDirect = null;
	}

	/// The object, or null. The direct override wins over the binding.
	public T Get => (mDirect != null) ? mDirect : mProxy.Get;

	public bool HasValue => Get != null;
	public bool IsBound => !mProxy.IsNull;
	public ResourceState State => (mDirect != null) ? .Ready : mProxy.State;

	/// Points this at an object made in code. It is not serialized, and it wins over the
	/// binding for as long as it is set.
	public void SetDirect(T instance) mut
	{
		mDirect = instance;
	}

	public void SetId(Guid id) mut
	{
		Id = id;
	}

	/// Attaches the runtime binding for the current identity.
	public void Bind(ResourceManager manager) mut
	{
		if ((manager == null) || (Id == Guid.Empty))
			return;
		mProxy = manager.Bind<T>(Id);
	}

	/// Re-points at the current identity, dropping the override and any previous binding.
	/// What an editor picker does after assigning a different asset.
	public void Rebind(ResourceManager manager) mut
	{
		ClearBinding();
		Bind(manager);
	}

	/// Drops the binding AND the override.
	///
	/// Deserialization calls this when an incoming identity replaces a different one:
	/// reading a NIL identity has to actually unbind, or the old resource carries on being
	/// rendered by something that was told to stop.
	public void ClearBinding() mut
	{
		mProxy = default;
		mDirect = null;
	}

	/// For a reference being STORED, which keeps the handle observable. Balanced by Forget.
	public void Retain() mut => mProxy.Retain();
	public void Forget() mut => mProxy.Forget();

	/// Identity only. The wire shape is a guid, exactly as if the field were one, so a
	/// component that gains a resource reference where it had a bare identity reads its
	/// old data unchanged.
	public void Serialize(ISerializer ar) mut
	{
		let before = Id;
		Sedulous.Core.Serialization.Serialize(ar, ref Id);

		// Replaying over a LIVE component, which is what a paste or an undo does: a
		// changed identity must drop the stale binding rather than keep showing the
		// previous resource.
		if (Id != before)
			ClearBinding();
	}
}
