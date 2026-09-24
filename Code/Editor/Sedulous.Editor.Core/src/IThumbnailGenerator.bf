using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// One per asset type thumbnail producer, split across threads: Prepare runs on the MAIN
/// thread and gathers everything the worker needs, content access being main thread only
/// since a cook or a delete can run beside the light lane; Generate runs on the LIGHT worker
/// over that payload, CPU only, no UI, no GPU. The output is already thumbnail sized; the
/// service saves it verbatim.
interface IThumbnailGenerator
{
	/// The content asset type names covered, full names as an instance carries them.
	void AssetTypeNames(List<StringView> outNames);

	/// MAIN thread: what the worker will need, WITHOUT reading it. `sources` is the project's
	/// Sources/ mount, where imported source files live by mount relative path; embedded data
	/// lives in the instance's streams.
	///
	/// Open a stream and hand it over rather than draining it: the read is the expensive part
	/// and belongs on the worker. A header composed here arrives before those bytes.
	Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources,
		ThumbnailPrepared outPrepared);

	/// LIGHT worker: the thumbnail pixels from the prepared payload.
	Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage);
}
