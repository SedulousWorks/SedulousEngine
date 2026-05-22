namespace Sedulous.Editor.Core;

using System;
using Sedulous.Images;

/// Generator that produces thumbnails asynchronously (e.g., by dispatching
/// GPU work that completes a frame or two later). Implemented by
/// generators that can't return pixel data synchronously - typically
/// anything that needs to render a Scene into an offscreen target and
/// read back.
///
/// Either this interface OR `IAssetThumbnailGenerator` may be implemented;
/// the `ThumbnailService` dispatches based on which one the generator
/// provides. A generator that implements both is treated as async.
///
/// The contract for `GenerateThumbnailAsync`:
///   - Returns `true` if the work has been accepted; the generator will
///     eventually invoke `onComplete(data)` exactly once on the editor's
///     main thread, with either a freshly-allocated OwnedImageData
///     (caller takes ownership) or null (truly failed - asset missing,
///     parse error, etc).
///   - Returns `false` if the generator declined transiently (e.g., its
///     GPU renderer already has a job in flight). The service requeues
///     the request and tries again next frame. The generator must NOT
///     invoke `onComplete` in this case - and must not retain it - the
///     service deletes it.
///   - The service owns `onComplete` and frees it after it fires; the
///     generator must not delete it.
interface IAsyncAssetThumbnailGenerator
{
	bool GenerateThumbnailAsync(StringView assetPath, int32 width, int32 height,
		delegate void(OwnedImageData data) onComplete);
}
