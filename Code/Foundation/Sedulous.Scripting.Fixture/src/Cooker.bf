using Sedulous.Core;

namespace Sedulous.Scripting.Fixture;

/// Lives in the pipeline domain.
[Scriptable, TypeDomain(ScriptDomains.Pipeline)]
class Cooker
{
	[Scriptable]
	public void Cook() {}
}
