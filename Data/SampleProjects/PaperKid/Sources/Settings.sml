<screen mode="modal" transition="fade" default-focus="master-slider">

  <Panel class="dim">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="card">
      <Flex direction="vertical" align="center">
        <Label id="settings-title" font-family="Alfa Slab One" text="Settings" font-size="56" class="headline"/>
        <Spacer spacer-height="22"/>

        <Flex direction="vertical" spacing="16">
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Master" font-size="29" width="110" class="body"/>
            <Slider id="master-slider" min="0" max="1" step="0.05" width="280" height="30"/>
            <Label id="master-value" text="100%" font-size="26" width="64" class="note"/>
          </Flex>
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Music" font-size="29" width="110" class="body"/>
            <Slider id="music-slider" min="0" max="1" step="0.05" width="280" height="30"/>
            <Label id="music-value" text="100%" font-size="26" width="64" class="note"/>
          </Flex>
          <Flex direction="horizontal" align="center" spacing="16">
            <Label text="Effects" font-size="29" width="110" class="body"/>
            <Slider id="effects-slider" min="0" max="1" step="0.05" width="280" height="30"/>
            <Label id="effects-value" text="100%" font-size="26" width="64" class="note"/>
          </Flex>
        </Flex>

        <Spacer spacer-height="28"/>
        <Button id="settings-back-btn" text="Back" width="240" height="52" class="primary" font-size="31"/>
        <Spacer spacer-height="14"/>
        <Label text="Left and right to adjust, Esc or Start to go back" font-size="23" class="note"/>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
