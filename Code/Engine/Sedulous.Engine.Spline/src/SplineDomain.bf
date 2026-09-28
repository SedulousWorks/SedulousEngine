using System;
using Sedulous.Engine.Domain;
using Sedulous.Resource;

namespace Sedulous.Engine.Spline;

/// The spline domain's declaration for the engine composition: its scene content. Built on
/// first use, so no static initialisation order matters.
static class SplineDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("spline", => SplineScene.AddSplineSceneManagers));
	private static DomainModule sModule ~ delete _;
}
