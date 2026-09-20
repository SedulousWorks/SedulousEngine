using System;

namespace Sedulous.Editor.Core;

/// One queued GPU thumbnail job: the stage drives it, the service keeps the books.
struct SceneThumbnailJob
{
	public Guid Id = .Empty;
	/// Borrowed; lives on the service.
	public ISceneThumbnailGenerator Generator = null;

	public bool IsEmpty => !Id.IsSet;
}
