using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Navigation;

/// A straight line path across the mesh: the corners from the start to the end.
///
/// Not COMPLETE when the destination could not be reached, in which case the corners lead to
/// the nearest reachable point instead. That is reported rather than failing: an agent
/// walking as far as it can is almost always what a caller wants.
class NavigationPath
{
	public List<Float3> Corners = new .() ~ delete _;
	public bool Complete = false;

	public void Clear()
	{
		Corners.Clear();
		Complete = false;
	}
}
