<screen mode="modal" transition="scale" default-focus="gameover-retry-btn">

  <Panel class="veil-heavy">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="cloud">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="gameover-title" font-family="Lilita One" text="Game Over" font-size="56" class="headline"/>
        <Label id="gameover-reached" text="" font-size="18" class="note"/>
        <Flex direction="horizontal" align="center" spacing="8">
          <Label text="Score" font-size="20" class="tally-name"/>
          <Label id="gameover-score" text="0" font-family="Lilita One" font-size="34" class="tally-total"/>
        </Flex>
        <Label id="gameover-best" text="" font-family="Lilita One" font-size="18" class="best"/>
        <Spacer spacer-height="18"/>
        <Flex direction="vertical" spacing="10" width="280">
          <Button id="gameover-retry-btn" text="Try Again" height="50" font-size="22" class="primary"/>
          <Button id="gameover-title-btn" text="Back to Title" height="44"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
