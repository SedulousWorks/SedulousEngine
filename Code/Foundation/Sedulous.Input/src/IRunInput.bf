using System;

namespace Sedulous.Input;

/// A run's input, as a service the run offers: its actions evaluated against its own source.
/// Whoever starts the frame (the input subsystem) drives every run's before any scene steps, so
/// fixed steps and updates read this frame's input.
interface IRunInput
{
	/// `deltaTime` is the frame's, unscaled; `timeScale` the context's (for actions that follow
	/// it).
	void DriveInput(float deltaTime, float timeScale);
}
