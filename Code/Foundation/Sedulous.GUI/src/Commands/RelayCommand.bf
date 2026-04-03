using System;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A command implementation that delegates to provided functions.
/// This is the most common way to create commands in application code.
public class RelayCommand : GUICommand
{
	private delegate void() mExecute;
	private delegate bool() mCanExecute;
	private EventAccessor<delegate void()> mCanExecuteChanged = new .() ~ delete _;

	/// Creates a command that can always execute.
	public this(delegate void() execute)
	{
		mExecute = execute;
	}

	/// Creates a command with a CanExecute predicate.
	public this(delegate void() execute, delegate bool() canExecute)
	{
		mExecute = execute;
		mCanExecute = canExecute;
	}

	public ~this()
	{
		if (mExecute != null)
			delete mExecute;
		if (mCanExecute != null)
			delete mCanExecute;
	}

	public void Execute(Object parameter = null)
	{
		if (mExecute != null && CanExecute(parameter))
			mExecute();
	}

	public bool CanExecute(Object parameter = null)
	{
		if (mCanExecute == null)
			return true;
		return mCanExecute();
	}

	public EventAccessor<delegate void()> CanExecuteChanged => mCanExecuteChanged;

	public void RaiseCanExecuteChanged()
	{
		mCanExecuteChanged.[Friend]Invoke();
	}
}

/// A command implementation that delegates to provided functions with a parameter.
public class RelayCommand<T> : GUICommand where T : class
{
	private delegate void(T) mExecute;
	private delegate bool(T) mCanExecute;
	private EventAccessor<delegate void()> mCanExecuteChanged = new .() ~ delete _;

	/// Creates a command that can always execute.
	public this(delegate void(T) execute)
	{
		mExecute = execute;
	}

	/// Creates a command with a CanExecute predicate.
	public this(delegate void(T) execute, delegate bool(T) canExecute)
	{
		mExecute = execute;
		mCanExecute = canExecute;
	}

	public ~this()
	{
		if (mExecute != null)
			delete mExecute;
		if (mCanExecute != null)
			delete mCanExecute;
	}

	public void Execute(Object parameter = null)
	{
		let typedParam = parameter as T;
		if (mExecute != null && CanExecute(parameter))
			mExecute(typedParam);
	}

	public bool CanExecute(Object parameter = null)
	{
		if (mCanExecute == null)
			return true;
		let typedParam = parameter as T;
		return mCanExecute(typedParam);
	}

	public EventAccessor<delegate void()> CanExecuteChanged => mCanExecuteChanged;

	public void RaiseCanExecuteChanged()
	{
		mCanExecuteChanged.[Friend]Invoke();
	}
}
