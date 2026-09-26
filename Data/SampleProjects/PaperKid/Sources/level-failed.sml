<Flex direction="vertical" justify="center" align="center" padding="32">

  <ColorView style="background: rgba(0, 0, 0, 0.55);"/>

  <Panel padding="36"
         style="background: rounded-rect(rgb(40, 30, 32), radius=12, border-width=2, border=rgb(160, 90, 95));">

    <Flex direction="vertical" align="center">

      <Label id="title" text="Time's Up!" font-size="34" class="label"/>
      <Label id="summary" text="" class="label-dim" font-size="15"/>

      <Spacer spacer-height="28"/>

      <Flex direction="vertical" spacing="8" width="260">
        <Button id="retry-btn" text="Retry" height="44" class="primary"/>
        <Button id="menu-btn" text="Main Menu" height="44"/>
      </Flex>

    </Flex>

  </Panel>

</Flex>
