using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI.Null;

namespace Sedulous.Engine.Render.Tests;

/// The subsystem's pick API: requests key on the viewport, a null key is refused up front,
/// and a closing viewport cancels its requests.
class PickRequestTests
{
	[Test]
	public static void RequestPickKeysOnTheViewportAndCancels()
	{
		let device = scope NullDevice();
		let subsystem = scope RenderSubsystem(device, 2, null);

		int viewportKey = 0;
		// No key means no view could ever answer: refused up front, never pending.
		Test.Assert(subsystem.RequestPick(null, 5, 5) == PickSystem.cInvalidRequest);
		Test.Assert(!subsystem.IsPickPending(PickSystem.cInvalidRequest));

		let id = subsystem.RequestPick(&viewportKey, 5, 5);
		Test.Assert(id != PickSystem.cInvalidRequest);
		Test.Assert(subsystem.IsPickPending(id));
		let result = scope PickResult();
		Test.Assert(!subsystem.TryTakePickResult(id, result)); // nothing rendered yet

		// Distinct requests get distinct ids; a rect request is accepted as is, clamped at
		// render.
		let rect = subsystem.RequestPick(&viewportKey, -3, -3, 40, 40);
		Test.Assert(rect != id);
		Test.Assert(subsystem.IsPickPending(rect));

		// The viewport goes away: its requests vanish, never answered, never pending.
		subsystem.CancelPicks(&viewportKey);
		Test.Assert(!subsystem.IsPickPending(id));
		Test.Assert(!subsystem.IsPickPending(rect));
		Test.Assert(!subsystem.TryTakePickResult(id, result));
	}
}
