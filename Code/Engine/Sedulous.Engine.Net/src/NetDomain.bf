using System;
using Sedulous.Engine.Domain;
using Sedulous.Resource;

namespace Sedulous.Engine.Net;

/// The net domain's declaration for the engine composition: its scene content. Built on first
/// use, so no static initialisation order matters.
static class NetDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("net", => NetworkScene.AddNetworkSceneManagers));
	private static DomainModule sModule ~ delete _;
}
