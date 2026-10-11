using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Engine.UI.Tests;

/// Fingers a case sets, as a source reports them: normalized over an 800 x 600 surface, with
/// the pointer coordinates where its mouse would be.
class PointerFakeTouch : ITouch
{
	public List<TouchPoint> Points = new .() ~ delete _;

	public int32 TouchCount => (int32)Points.Count;
	public bool HasTouch => !Points.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		if ((index < 0) || (index >= Points.Count))
		{
			point = .();
			return false;
		}
		point = Points[index];
		return true;
	}

	/// One finger, `id`, at (x, y) in pointer pixels.
	public void Put(uint64 id, float x, float y)
	{
		Points.Clear();
		Points.Add(.(id, x / 800.0f, y / 600.0f, 1.0f, x, y));
	}
}
