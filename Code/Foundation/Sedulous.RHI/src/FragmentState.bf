using System;

namespace Sedulous.RHI;

struct FragmentState
{
	public ProgrammableStage Shader = .();
	/// One per colour attachment, in attachment order.
	public Span<ColorTargetState> Targets = default;

	public this() {}
}
