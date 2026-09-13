using System;

namespace Sedulous.UI.Pipeline;

/// What a NEW document or theme opens on, so an editor page never starts on a void.
static class UIStarterContent
{
	/// A pause menu, in the vocabulary the sandbox uses: kebab case attributes and EXPLICIT
	/// sizes, since an unsized child of a root flex stretches into a bar.
	public const String cDocument = """
		<Flex direction="vertical" justify="center" align="center" padding="32">
		  <Panel padding="24"
		         style="background: rounded-rect(rgb(35, 38, 48), radius=12);">
		    <Flex direction="vertical" align="center" spacing="8">
		      <Label id="title" text="New Document" font-size="24"/>
		      <Spacer spacer-height="12"/>
		      <Button id="ok-btn" text="OK" width="200" height="40"/>
		    </Flex>
		  </Panel>
		</Flex>
		""";

	public const String cTheme = """
		/* Game theme overrides - selectors match control types and .classes. */
		Label { text-color: #E8E8E8; }
		""";
}
