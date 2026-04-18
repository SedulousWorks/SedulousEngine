namespace UISandbox;

using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.ImageData;

/// Shared resources for demo pages.
class DemoContext
{
	public UISubsystem UI;
	public OwnedImageData Checkerboard;
	public OwnedImageData ButtonNormal;
	public OwnedImageData ButtonPressed;
	public Label ClickLabel; // shared feedback label across pages
	public IFloatingWindowHost FloatingWindowHost;
}
