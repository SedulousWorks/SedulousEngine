<screen mode="modal" transition="fade" default-focus="play-btn">

  <Panel style="background: rgba(8, 14, 30, 0.45);">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Flex direction="vertical" align="center" spacing="6">
      <Label id="title" font-family="Lilita One" text="Sky Hopper" font-size="84" style="text-color: rgb(255, 226, 120);"/>
      <Label id="tagline" text="Coins, crabs and a flag at the end" font-size="20" class="label-dim"/>
    </Flex>

    <Spacer spacer-height="48"/>

    <Flex direction="vertical" spacing="10" width="280">
      <Button id="play-btn" text="Play" height="50" font-size="22" class="primary"/>
      <Button id="settings-btn" text="Settings" height="44"/>
      <Button id="quit-btn" text="Quit" height="44"/>
    </Flex>

    <Spacer spacer-height="36"/>
    <Label id="hint" text="Arrows or stick to choose, Enter or A to pick" font-size="14" class="label-dim"/>

  </Flex>
  </Panel>

</screen>
