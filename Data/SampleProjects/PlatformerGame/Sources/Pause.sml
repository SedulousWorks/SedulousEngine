<screen mode="modal" transition="fade" default-focus="resume-btn">

  <Panel style="background: rgba(0, 0, 0, 0.55);">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="32"
           style="background: rounded-rect(rgb(24, 28, 38), radius=12, border-width=2, border=rgb(90, 104, 130));">
      <Flex direction="vertical" align="center">
        <Label id="pause-title" font-family="Lilita One" text="Paused" font-size="36" class="label"/>
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
