using Sedulous.Core;

namespace Sedulous.Script.Fixture;

/// Lives in the pipeline domain.
[Scriptable, TypeDomain(ScriptDomains.Pipeline)]
class Cooker
{
	[Scriptable]
	public void Cook() {}
}
