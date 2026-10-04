<screen mode="modal" transition="fade" default-focus="play-btn">

  <Panel class="veil">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel class="cloud" padding="24">
      <Flex direction="vertical" align="center" spacing="4">
        <Label id="title" font-family="Lilita One" text="Sky Hopper" font-size="84" class="headline"/>
        <Label id="tagline" text="Coins, crabs and a flag at the end" font-size="20" class="note"/>
      </Flex>
    </Panel>

    <Spacer spacer-height="36"/>

    <Flex direction="vertical" spacing="12" width="280">
      <Button id="play-btn" text="Play" height="52" font-size="24" class="primary"/>
      <Button id="settings-btn" text="Settings" height="46"/>
      <Button id="quit-btn" text="Quit" height="46"/>
    </Flex>

    <Spacer spacer-height="28"/>
    <Panel class="cloud" padding="8">
      <Label id="hint" text="Arrows or stick to choose, Enter or A to pick" font-size="14" class="note"/>
    </Panel>

  </Flex>
  </Panel>

</screen>
