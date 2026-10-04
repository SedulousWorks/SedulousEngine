<screen mode="modal" transition="fade" default-focus="master-slider">

  <Panel class="veil-heavy">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="32" class="cloud">
      <Flex direction="vertical" align="center">
        <Label id="settings-title" font-family="Lilita One" text="Settings" font-size="40" class="headline"/>
        <Spacer spacer-height="22"/>

        <Flex direction="vertical" spacing="14">
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Master" font-size="20" width="110" class="body"/>
            <Slider id="master-slider" min="0" max="1" step="0.05" width="260" height="28"/>
            <Label id="master-value" text="100%" font-size="18" width="60" class="note"/>
          </Flex>
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Music" font-size="20" width="110" class="body"/>
            <Slider id="music-slider" min="0" max="1" step="0.05" width="260" height="28"/>
            <Label id="music-value" text="100%" font-size="18" width="60" class="note"/>
          </Flex>
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Effects" font-size="20" width="110" class="body"/>
            <Slider id="effects-slider" min="0" max="1" step="0.05" width="260" height="28"/>
            <Label id="effects-value" text="100%" font-size="18" width="60" class="note"/>
          </Flex>
        </Flex>

        <Spacer spacer-height="26"/>
        <Button id="settings-back-btn" text="Back" width="220" height="44" class="primary"/>
        <Spacer spacer-height="14"/>
        <Label text="Left and right to adjust, Esc or Options to go back" font-size="14" class="note"/>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
