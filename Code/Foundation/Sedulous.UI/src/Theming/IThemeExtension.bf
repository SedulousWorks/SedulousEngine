namespace Sedulous.UI;

/// Implement to inject styles into a Theme after base initialization.
/// Register via Theme.RegisterExtension() at startup. Allows external
/// libraries to define control styles without modifying core themes.
public interface IThemeExtension
{
	void Apply(Theme theme);
}
