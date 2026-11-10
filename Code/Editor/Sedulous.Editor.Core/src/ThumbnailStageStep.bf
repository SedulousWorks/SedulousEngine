namespace Sedulous.Editor.Core;

/// One step of staging an asset into the preview scene.
enum ThumbnailStageStep : uint8
{
	/// Resources still resolving: Stage again next frame.
	Pending,
	/// The scene is populated; the framing carries the view.
	Ready,
	/// Cannot stage, a missing product or an unbound resource: negative cached.
	Failed,
	/// What it shows has an asset the cook has not made yet (the generator asked for it):
	/// nothing is drawn or cached, and the job runs again when the cook finishes.
	WaitingForCook
}
