using System;
using System.Collections;

namespace Sedulous.Shaders;

/// One `// entry:` line of a shader the RHI binds directly: the stage, and the function it
/// names. A ray tracing library's entry names none (`// entry: raygen`), and Entry is empty.
class ShaderEntryDirective
{
	public ShaderStage Stage = .Vertex;
	public String Entry = new .() ~ delete _;
}

/// What a shader the RHI binds directly (an RHI sample's, often several entry points in one
/// file) names in its own comments, one line each:
///
///     // entry: vertex VSMain
///     // entry: fragment PSMain
///     // model: 6_5
///
/// Read by ShaderPackCooker.ParseEntryDirectives; a source with no entry line names none.
class ShaderEntryDirectives
{
	public List<ShaderEntryDirective> Entries = new .() ~ DeleteContainerAndItems!(_);
	/// The shader model the entries compile at: 6_0 when the source names none.
	public String ShaderModel = new .("6_0") ~ delete _;
}
