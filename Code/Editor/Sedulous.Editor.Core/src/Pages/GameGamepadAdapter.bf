namespace Sedulous.Editor.Core;

using System;
using Sedulous.Shell.Input;

/// IGamepad adapter owned by a GameEditorPage. Focus-gated identically
/// to GameKeyboardAdapter - when the page isn't the active editor tab,
/// IsButtonDown/Pressed/Released and GetAxis report neutral state. This
/// keeps controller input scoped to the game viewport: pressing A on
/// the pad while the inspector is focused doesn't trigger gameplay
/// actions.
///
/// Identity (Index / Name / Connected) and rumble passthrough at all
/// times - those are device-level facts, not input. Letting Connected
/// flip with focus would confuse pause-menu reconnection prompts.
class GameGamepadAdapter : IGamepad
{
	private IGamepad mShell;
	private bool mFocused;

	public this(IGamepad shell)
	{
		mShell = shell;
	}

	public bool Focused
	{
		get => mFocused;
		set => mFocused = value;
	}

	public int Index => mShell?.Index ?? -1;
	public StringView Name => mShell?.Name ?? "";
	public bool Connected => mShell?.Connected ?? false;

	public bool IsButtonDown(GamepadButton button) =>
		mFocused && (mShell?.IsButtonDown(button) ?? false);
	public bool IsButtonPressed(GamepadButton button) =>
		mFocused && (mShell?.IsButtonPressed(button) ?? false);
	public bool IsButtonReleased(GamepadButton button) =>
		mFocused && (mShell?.IsButtonReleased(button) ?? false);

	public float GetAxis(GamepadAxis axis) =>
		mFocused ? (mShell?.GetAxis(axis) ?? 0) : 0;

	public void SetRumble(float lowFreq, float highFreq, uint32 durationMs)
	{
		mShell?.SetRumble(lowFreq, highFreq, durationMs);
	}
}
