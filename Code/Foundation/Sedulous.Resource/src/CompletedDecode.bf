using System;

namespace Sedulous.Resource;

/// A decode that finished on a worker and is waiting for the main thread.
struct CompletedDecode
{
	public Guid Id;
	public ResourceHandle Handle;
	public IResourceFactory Factory;
	/// Null when the decode failed. Owned until finalize takes it.
	public Object Decoded;
}
