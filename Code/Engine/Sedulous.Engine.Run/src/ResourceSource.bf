using System;
using Sedulous.Resource;

namespace Sedulous.Engine.Run;

/// The application's resource manager as a run's own code finds it (an application service, found
/// through the run's scripts' host): read per call, since a host may hand over another manager
/// after startup (an editor's, as a project opens or closes).
class ResourceSource
{
	private delegate ResourceManager() mResolve ~ delete _;

	/// Takes `resolve` (null: no manager).
	public this(delegate ResourceManager() resolve)
	{
		mResolve = resolve;
	}

	/// The manager now, or null when there is none.
	public ResourceManager Manager => (mResolve != null) ? mResolve() : null;
}
