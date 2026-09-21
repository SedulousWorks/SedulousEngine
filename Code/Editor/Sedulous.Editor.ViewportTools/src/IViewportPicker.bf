using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Editor.ViewportTools;

/// The host's GPU pick seam, the render subsystem's RequestPick over the page's viewport key:
/// a tool asks for the entities under a pixel rect of the view and polls for the answer a few
/// frames later. Null on the host context means no GPU picking, and the tool's CPU pick stands
/// alone.
interface IViewportPicker
{
	/// The rect in view pixels. Returns nought when nothing could answer: no renderer, no view.
	uint32 RequestPick(int32 x, int32 y, uint32 width, uint32 height);

	/// True once the request answered: the hits are the live entities in the rect, at most one
	/// for a 1x1 rect. A request that expired answers with no hits.
	bool TryTakePick(uint32 request, List<EntityHandle> hits);
}
