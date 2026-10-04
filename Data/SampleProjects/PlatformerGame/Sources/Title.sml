<screen mode="modal" transition="fade" default-focus="play-btn">

  <Panel class="veil">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel class="cloud" padding="24">
      <Flex direction="vertical" align="center" spacing="4">
        <Label id="title" font-family="Lilita One" text="Sky Hopper" font-size="84" class="headline"/>
        <Label id="tagline" text="Five islands in the sky, three lives to cross them" font-size="20" class="note"/>
        <Spacer spacer-height="6"/>
        <!-- What the player has done so far, from the save: stars over every level, the best run. -->
        <Flex direction="horizontal" align="center" spacing="8">
          <Panel class="icon-star" width="26" height="26"/>
          <Label id="title-stars" text="0 / 15" font-family="Lilita One" font-size="22" class="tally-value"/>
          <Spacer spacer-width="16"/>
          <Label id="title-best" text="" font-family="Lilita One" font-size="22" class="best"/>
        </Flex>
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
