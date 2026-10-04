<screen mode="modal" transition="fade" default-focus="resume-btn">

  <Panel class="dim">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="card">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="pause-title" font-family="Alfa Slab One" text="Paused" font-size="56" class="headline"/>
        <Spacer spacer-height="18"/>
        <Flex direction="vertical" spacing="10" width="300">
          <Button id="resume-btn" text="Resume" height="52" class="primary" font-size="31"/>
          <Button id="restart-btn" text="Restart block" height="52" font-size="31"/>
          <Button id="settings-btn" text="Settings" height="52" font-size="31"/>
          <Button id="menu-btn" text="Quit to menu" height="52" font-size="31"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
