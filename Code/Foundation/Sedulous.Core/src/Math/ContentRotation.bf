using System;

namespace Sedulous.Core;

/// How content is turned as it is presented, clockwise: a quarter turn shows its top on the
/// region's right, three quarters on its left.
[Reflect(.StaticFields)]
enum ContentRotation
{
	case None;
	case Quarter;
	case Half;
	case ThreeQuarter;
}
