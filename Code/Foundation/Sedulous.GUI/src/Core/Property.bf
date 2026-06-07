namespace Sedulous.GUI;

using System;

/// Observable value wrapper with change notification.
///
/// Every externally-settable property on View and its subclasses is a
/// Property<T>. This is the uniform property model for the framework —
/// no public fields, no Set*() methods, just Property<T>.
///
/// Usage:
///   let health = new Property<float>(100);
///   health.Changed.Add(new (newVal) => { healthBar.Progress.Value = newVal / 100; });
///   health.Value = 75; // fires Changed event
public class Property<T> where bool : operator T == T
{
	private T mValue;
	private bool mIsUpdating; // loop guard for two-way binding
	private View mOwner;
	private InvalidationKind mInvalidationKind;

	/// Fired when the value changes. Receives the new value.
	public Event<delegate void(T)> Changed ~ _.Dispose();

	/// The current value. Setting fires Changed if the value is different.
	public T Value
	{
		get => mValue;
		set
		{
			// Loop guard: prevent infinite recursion from two-way bindings.
			if (mIsUpdating)
				return;

			if (mValue == value)
				return;

			mIsUpdating = true;
			mValue = value;
			Changed(mValue);

			// Notify owner view of the change for invalidation.
			if (mOwner != null)
				mOwner.[Friend]OnPropertyChanged(this, mInvalidationKind);

			mIsUpdating = false;
		}
	}

	public this() { }

	public this(T initialValue)
	{
		mValue = initialValue;
	}

	public this(T initialValue, InvalidationKind kind)
	{
		mValue = initialValue;
		mInvalidationKind = kind;
	}

	/// Set value without firing Changed event or invalidating.
	/// Used for initialization or when the source already knows about the change.
	public void SetSilent(T value)
	{
		mValue = value;
	}

	/// Bind one-way: when this property changes, update the target property.
	public void BindTo(Property<T> target)
	{
		Changed.Add(new (val) => { target.Value = val; });
	}

	/// Bind two-way: changes to either property update the other.
	/// Loop guard prevents infinite recursion.
	public void BindTwoWay(Property<T> other)
	{
		Changed.Add(new (val) => { other.Value = val; });
		other.Changed.Add(new (val) => { this.Value = val; });
	}

	/// Called by View during property registration to set the owner and
	/// invalidation kind. Not intended for external use.
	public void SetOwner(View owner, InvalidationKind kind = .Layout)
	{
		mOwner = owner;
		mInvalidationKind = kind;
	}
}
