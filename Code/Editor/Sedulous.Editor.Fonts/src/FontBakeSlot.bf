namespace Sedulous.Editor.Fonts;

/// One in flight preview bake: the outcome the worker fills, and whether the page that
/// asked is still there when the completion lands.
class FontBakeSlot
{
	public FontBakeRequest Request = new .() ~ delete _;
	public FontBakeOutcome Outcome = new .() ~ delete _;
	public bool PageAlive = true;
}
