<screen mode="modal" transition="fade" default-focus="play-btn">

  <Panel class="dim">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <!-- The front page: the masthead over a rule and the day's headline. -->
    <Panel class="card" padding="28">
      <Flex direction="vertical" align="center" spacing="6">
        <Label id="title" font-family="Lilita One" text="PaperKid" font-size="88" class="masthead"/>
        <Panel class="rule" width="460" height="4"/>
        <Label id="tagline" text="Deliver the papers before the clock runs out" font-size="31" class="body"/>
      </Flex>
    </Panel>

    <Spacer spacer-height="40"/>

    <Flex direction="vertical" spacing="14" width="320">
      <Button id="play-btn" text="New game" height="58" font-size="34" class="primary"/>
      <Button id="settings-btn" text="Settings" height="52" font-size="31"/>
      <Button id="quit-btn" text="Quit" height="52" font-size="31"/>
    </Flex>

    <Spacer spacer-height="32"/>
    <Panel class="strip" padding="8">
      <Label id="hint" text="Arrows or stick to choose, Enter or A to pick" font-size="23" class="note"/>
    </Panel>

  </Flex>
  </Panel>

</screen>
