using System;

namespace Sedulous.UI;

/// An observable value with change notification and owner invalidation.
///
/// Beef's corlib Event is a multicast delegate, so change notification is that and the UI
/// carries no Event type of its own.
class Property<T> where bool : operator T == T
{
	private T mValue;
	/// Guards against a two way binding driving itself round in circles.
	private bool mIsUpdating;
	private IPropertyOwner mOwner;
	private InvalidationKind mInvalidationKind;

	/// Fired with the NEW value whenever it changes. Owns the handlers added to it.
	public Event<delegate void(T)> Changed ~ _.Dispose();

	public this() {}

	public this(T initialValue)
	{
		mValue = initialValue;
	}

	public this(T initialValue, InvalidationKind kind)
	{
		mValue = initialValue;
		mInvalidationKind = kind;
	}

	/// Setting fires Changed and invalidates the owner, but only when the value actually
	/// differs: a property assigned its current value must not cost a layout pass.
	public T Value
	{
		get => mValue;
		set
		{
			if (mIsUpdating)
				return;
			if (mValue == value)
				return;

			mIsUpdating = true;
			mValue = value;
			Changed(mValue);

			if (mOwner != null)
				mOwner.OnPropertyChanged(mInvalidationKind);

			mIsUpdating = false;
		}
	}

	/// Sets without firing Changed or invalidating.
	///
	/// For initialisation, and for echoing a value back to a source that already knows: a
	/// binding that reported what it was just told would look like a change and loop.
	public void SetSilent(T value)
	{
		mValue = value;
	}

	/// Wires up automatic invalidation. Called while a view is being constructed.
	public void SetOwner(IPropertyOwner owner, InvalidationKind kind = .Layout)
	{
		mOwner = owner;
		mInvalidationKind = kind;
	}

	/// One way: a change here pushes the value into `target`.
	public void BindTo(Property<T> target)
	{
		Changed.Add(new (value) => { target.Value = value; });
	}

	/// Two way: a change to either side updates the other. The loop guard is what stops the
	/// pair from bouncing forever.
	public void BindTwoWay(Property<T> other)
	{
		Changed.Add(new (value) => { other.Value = value; });
		other.Changed.Add(new (value) => { this.Value = value; });
	}
}
