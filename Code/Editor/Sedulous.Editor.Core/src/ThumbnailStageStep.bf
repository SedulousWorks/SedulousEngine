namespace Sedulous.Editor.Core;

/// One step of staging an asset into the preview scene.
enum ThumbnailStageStep : uint8
{
	/// Resources still resolving: Stage again next frame.
	Pending,
	/// The scene is populated; the framing carries the view.
	Ready,
	/// Cannot stage, a missing product or an unbound resource: negative cached.
	Failed
}
