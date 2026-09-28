using System;
using Sedulous.Engine.Domain;
using Sedulous.Input.Resource;
using Sedulous.Resource;

namespace Sedulous.Engine.Input;

/// The input domain's declaration for the engine composition: no scene content, and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class InputDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("input", null,
		new .(
			InputResources.Module)));
	private static DomainModule sModule ~ delete _;
}
