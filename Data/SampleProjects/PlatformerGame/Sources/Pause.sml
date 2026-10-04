<screen mode="modal" transition="fade" default-focus="resume-btn">

  <Panel class="veil-heavy">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="32" class="cloud">
      <Flex direction="vertical" align="center">
        <Label id="pause-title" font-family="Lilita One" text="Paused" font-size="40" class="headline"/>
        <Spacer spacer-height="22"/>
        <Flex direction="vertical" spacing="8" width="260">
          <Button id="resume-btn" text="Resume" height="44" class="primary"/>
          <Button id="restart-btn" text="Restart Level" height="44"/>
          <Button id="title-btn" text="Quit to Title" height="44"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
