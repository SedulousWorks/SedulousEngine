<screen mode="modal" transition="fade" default-focus="again-btn">

  <Panel class="dim-heavy">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="card">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="over-title" font-family="Alfa Slab One" text="Game over" font-size="56" class="masthead"/>
        <Label id="over-score" text="" font-size="39" class="body"/>
        <Label id="over-reached" text="" font-size="29" class="note"/>
        <Spacer spacer-height="24"/>
        <Flex direction="vertical" spacing="10" width="300">
          <Button id="again-btn" text="Play again" height="52" class="primary" font-size="31"/>
          <Button id="menu-btn" text="Main menu" height="52" font-size="31"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
