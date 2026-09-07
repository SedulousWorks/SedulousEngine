using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// The devices, the frame's event stream, and which window has the pointer and the focus.
class SDL3InputManager : IInputManager
{
	private SDL3Keyboard mKeyboard = new .() ~ delete _;
	private SDL3Mouse mMouse = new .() ~ delete _;
	private SDL3Touch mTouch = new .() ~ delete _;
	private List<SDL3Gamepad> mGamepads = new .() ~ DeleteContainerAndItems!(_);
	private List<InputEvent> mEvents = new .() ~ delete _;
	private uint32 mHoverWindow;
	private uint32 mFocusWindow;

	public ~this()
	{
		ReleaseDevices();
	}

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => mMouse;
	public ITouch Touch => mTouch;

	public int32 GamepadCount => (int32)mGamepads.Count;

	public IGamepad GetGamepad(int32 index)
	{
		if ((index < 0) || (index >= (int32)mGamepads.Count))
			return null;
		return mGamepads[index];
	}

	public Span<InputEvent> Events => .(mEvents.Ptr, mEvents.Count);

	public uint32 HoverWindow => mHoverWindow;
	public uint32 FocusedWindow => mFocusWindow;

	/// Starts a frame: the previous state is copied and the event stream emptied, so
	/// everything the pump then delivers belongs to this frame.
	public void Update()
	{
		mEvents.Clear();
		mKeyboard.BeginFrame();
		mMouse.BeginFrame();
		for (let pad in mGamepads)
			pad.BeginFrame();
	}

	/// Closes every SDL owned device. Called BEFORE SDL_Quit, and idempotent so the
	/// destructor can call it again.
	public void ReleaseDevices()
	{
		ClearAndDeleteItems!(mGamepads);
		mMouse.ReleaseCursors();
	}

	public SDL3Keyboard KeyboardDevice => mKeyboard;
	public SDL3Mouse MouseDevice => mMouse;
	public SDL3Touch TouchDevice => mTouch;

	public void SetWindow(SDL_Window* window) => mMouse.SetWindow(window);

	public void EmitEvent(InputEvent e) => mEvents.Add(e);
	public void SetHoverWindow(uint32 id) => mHoverWindow = id;
	public void SetFocusWindow(uint32 id) => mFocusWindow = id;

	/// Opens a pad SDL just reported. Its INDEX is its position in this list, which is what
	/// a caller iterates, and is not SDL's instance id.
	public void AddGamepad(uint32 instanceId)
	{
		if (FindGamepadById(instanceId) != null)
			return;

		let handle = SDL3.SDL_OpenGamepad(instanceId);
		if (handle == null)
			return;

		let name = StringView(SDL3.SDL_GetGamepadName(handle));
		mGamepads.Add(new SDL3Gamepad(handle, instanceId, (int32)mGamepads.Count,
			(name.Ptr != null) ? name : "Gamepad"));
	}

	/// Removes a pad and RENUMBERS the rest, so the indices stay a contiguous run: a caller
	/// iterating zero to GamepadCount must not step over a hole.
	public void RemoveGamepad(uint32 instanceId)
	{
		for (int i = mGamepads.Count - 1; i >= 0; i--)
		{
			if (mGamepads[i].Id == instanceId)
			{
				mGamepads[i].Disconnect();
				delete mGamepads[i];
				mGamepads.RemoveAt(i);
			}
		}
		for (int i < mGamepads.Count)
			mGamepads[i].SetIndex((int32)i);
	}

	public SDL3Gamepad FindGamepadById(uint32 instanceId)
	{
		for (let pad in mGamepads)
		{
			if (pad.Id == instanceId)
				return pad;
		}
		return null;
	}
}
