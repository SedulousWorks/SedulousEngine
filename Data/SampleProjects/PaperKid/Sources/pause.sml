<Flex direction="vertical" justify="center" align="center" padding="32">

  <ColorView style="background: rgba(0, 0, 0, 0.55);"/>

  <Panel padding="32"
         style="background: rounded-rect(rgb(31, 33, 43), radius=12, border-width=2, border=rgb(80, 90, 110));">

    <Flex direction="vertical" align="center">

      <Label id="title" text="Paused" font-size="28" class="label"/>

      <Spacer spacer-height="24"/>

      <Flex direction="vertical" spacing="8" width="260">
        <Button id="resume-btn" text="Resume" height="40" class="primary"/>
        <Button id="settings-btn" text="Settings" height="40"/>
        <Button id="quit-btn" text="Quit to Menu" height="40"/>
      </Flex>

      <Spacer spacer-height="20"/>

      <Label text="Press ESC to resume" class="label-dim" font-size="11"/>

    </Flex>

  </Panel>

</Flex>
