using System;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// A keyboard whose state a test sets directly.
class FakeKeyboard : IKeyboard
{
	private bool[512] mDown = .();
	private bool[512] mPressed = .();

	public KeyModifiers Modifiers { get; set; } = .None;

	public bool IsKeyDown(KeyCode key) => mDown[(uint32)key & 511];
	public bool IsKeyPressed(KeyCode key) => mPressed[(uint32)key & 511];
	public bool IsKeyReleased(KeyCode key) => false;

	public void SetDown(KeyCode key, bool value = true) => mDown[(uint32)key & 511] = value;
	public void SetPressed(KeyCode key, bool value = true) => mPressed[(uint32)key & 511] = value;
}
