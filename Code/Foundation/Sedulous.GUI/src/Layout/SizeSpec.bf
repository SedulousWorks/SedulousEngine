namespace Sedulous.GUI;

/// Specifies how a view should be sized along one axis.
/// Stored on LayoutParams (Width/Height fields).
public enum SizeSpec
{
	/// Explicit size with a unit (dp/pt/px).
	case Fixed(Unit size);

	/// Fill the parent's available space.
	case Match;

	/// Fit to the view's content (intrinsic size).
	case Wrap;

	/// Resolves this spec to a float given the DPI scale.
	/// For Fixed: resolves the Unit. For Match/Wrap: returns 0 (parent handles these).
	public float ResolveFixed(float dpiScale)
	{
		switch (this)
		{
		case .Fixed(let unit): return unit.Resolve(dpiScale);
		case .Match: return 0;
		case .Wrap: return 0;
		}
	}

	/// Whether this is a fixed size (not Match or Wrap).
	public bool IsFixed
	{
		get
		{
			switch (this)
			{
			case .Fixed: return true;
			default: return false;
			}
		}
	}
}
