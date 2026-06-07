namespace Sedulous.GUI;

/// Specifies one axis of sizing for a view within its parent container.
public enum SizeSpec
{
	/// Explicit size with unit (dp/pt/px).
	case Fixed(Unit size);
	/// Fill parent's available space.
	case Match;
	/// Fit to content (default).
	case Wrap;

	/// Resolves a Fixed size to pixels, or returns 0 for Match/Wrap.
	public float ResolveFixed(float dpiScale)
	{
		if (this case .Fixed(let unit))
			return unit.Resolve(dpiScale);
		return 0;
	}

	public bool IsFixed => this case .Fixed;
}
