<screen mode="overlay">

  <Flex direction="horizontal" justify="space-between" align="start" padding="18">

    <!-- Lives and coins: the run's stakes, each an icon and a count. -->
    <Panel padding="10" class="hud">
      <Flex direction="horizontal" align="center" spacing="8">
        <Panel id="hud-heart" class="icon-heart" width="30" height="30"/>
        <Label id="hud-lives" text="x 3" font-family="Lilita One" font-size="24" class="hud-value"/>
        <Spacer spacer-width="10"/>
        <Panel id="hud-coin" class="icon-coin" width="28" height="28"/>
        <Label id="hud-coins" text="0 / 0" font-family="Lilita One" font-size="24" class="hud-coins"/>
        <Panel id="hud-gem" class="icon-gem" width="26" height="26" visibility="hidden"/>
      </Flex>
    </Panel>

    <!-- The level and its clock. -->
    <Panel padding="10" class="hud">
      <Flex direction="horizontal" align="center" spacing="8">
        <Label id="hud-level" text="1  Grassy Hills" font-size="18" class="hud-level"/>
        <Spacer spacer-width="8"/>
        <Panel class="icon-clock" width="24" height="24"/>
        <Label id="hud-time" text="0:00" font-family="Lilita One" font-size="22" class="hud-value"/>
      </Flex>
    </Panel>

    <!-- The score, and the gains that float up from it. -->
    <Flex direction="vertical" align="end" spacing="2">
      <Panel padding="10" class="hud" min-width="96">
        <Label id="hud-score" text="0" font-family="Lilita One" font-size="28" class="hud-score"/>
      </Panel>
      <Label id="hud-popup" text="+100" font-family="Lilita One" font-size="26" class="popup" visibility="hidden"/>
      <Label id="hud-life-popup" text="1UP" font-family="Lilita One" font-size="26" class="popup-life" visibility="hidden"/>
    </Flex>

  </Flex>

</screen>
