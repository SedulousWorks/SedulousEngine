<screen mode="modal" transition="fade" default-focus="retry-btn">

  <Panel class="dim">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="card-bad">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="failed-title" font-family="Alfa Slab One" text="Route failed" font-size="56" class="headline-bad"/>
        <Label id="failed-reason" text="" font-size="31" class="body"/>
        <Label id="failed-lives" text="" font-size="26" class="note"/>
        <Spacer spacer-height="24"/>
        <Flex direction="vertical" spacing="10" width="300">
          <Button id="retry-btn" text="Try again" height="52" class="primary" font-size="31"/>
          <Button id="menu-btn" text="Main menu" height="52" font-size="31"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
