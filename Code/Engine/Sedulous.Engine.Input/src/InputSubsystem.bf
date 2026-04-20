namespace Sedulous.Engine.Input;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Shell.Input;

/// Subsystem that manages input contexts and action processing.
/// Bridges Shell.InputManager with high-level action system.
public class InputSubsystem : Subsystem
{
	/// Input should be processed very early, before game logic.
	public override int32 UpdateOrder => -900;

	private IInputManager mInputManager;
	private List<InputContext> mContextStack = new .() ~ delete _;
	private Dictionary<String, InputContext> mContextsByName = new .();

	/// Whether UI consumed input this frame (set by UI subsystem).
	public bool UIConsumedInput { get; set; }

	/// Gets the low-level input manager.
	public IInputManager InputManager => mInputManager;

	/// Sets the input manager. Call this during initialization.
	public void SetInputManager(IInputManager inputManager)
	{
		mInputManager = inputManager;
	}

	public ~this()
	{
		for (let ctx in mContextStack)
			delete ctx;
		mContextStack.Clear();

		DeleteDictionaryAndKeys!(mContextsByName);
	}

	/// Called at the beginning of each frame to update input.
	public override void BeginFrame(float deltaTime)
	{
		if (mInputManager == null)
			return;

		// Reset consumption flag at start of frame
		UIConsumedInput = false;

		// Update contexts in priority order (highest first)
		for (let context in mContextStack)
		{
			if (!context.Enabled)
				continue;

			context.Update(mInputManager);

			if (context.BlocksInput)
				break;
		}
	}

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	// ==================== Public API ====================

	/// Creates and pushes a new context.
	public InputContext CreateContext(StringView name, int32 priority = 0)
	{
		let context = new InputContext(name, priority);
		PushContext(context);
		return context;
	}

	/// Pushes an existing context onto the stack.
	public void PushContext(InputContext context)
	{
		// Insert sorted by priority (descending)
		int insertIndex = 0;
		for (int i = 0; i < mContextStack.Count; i++)
		{
			if (mContextStack[i].Priority < context.Priority)
			{
				insertIndex = i;
				break;
			}
			insertIndex = i + 1;
		}
		mContextStack.Insert(insertIndex, context);
		mContextsByName[new String(context.Name)] = context;
	}

	/// Removes a context from the stack.
	/// Note: Does NOT delete the context - caller is responsible for deletion.
	public void PopContext(InputContext context)
	{
		mContextStack.Remove(context);

		String keyToRemove = null;
		for (let kv in mContextsByName)
		{
			if (kv.value == context)
			{
				keyToRemove = kv.key;
				break;
			}
		}
		if (keyToRemove != null)
		{
			mContextsByName.Remove(keyToRemove);
			delete keyToRemove;
		}
	}

	/// Gets a context by name.
	public InputContext GetContext(StringView name)
	{
		if (mContextsByName.TryGetValue(scope String(name), let ctx))
			return ctx;
		return null;
	}

	/// Enables/disables a context by name.
	public void SetContextEnabled(StringView name, bool enabled)
	{
		if (let ctx = GetContext(name))
			ctx.Enabled = enabled;
	}

	/// Gets an action from the first context that contains it.
	/// Searches from highest to lowest priority.
	public InputAction GetAction(StringView name)
	{
		for (let ctx in mContextStack)
		{
			if (!ctx.Enabled)
				continue;

			if (let action = ctx.GetAction(name))
				return action;
		}
		return null;
	}

	/// Gets the number of active contexts.
	public int ContextCount => mContextStack.Count;

	/// Enumerates all contexts (highest priority first).
	public List<InputContext>.Enumerator Contexts => mContextStack.GetEnumerator();
}
