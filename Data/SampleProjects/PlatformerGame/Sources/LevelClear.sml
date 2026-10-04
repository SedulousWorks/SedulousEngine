<screen mode="modal" transition="scale">

  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="32" class="cloud">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="clear-title" font-family="Lilita One" text="Level Clear!" font-size="44" class="headline"/>

        <!-- The three stars: all the coins, no falls, under the par time. Each starts empty and
             the game fills it in turn. -->
        <Flex direction="horizontal" align="center" spacing="14">
          <Flex direction="vertical" align="center" spacing="2">
            <Panel width="56" height="56">
              <Panel id="star-1-empty" class="icon-star-empty" width="56" height="56"/>
              <Panel id="star-1" class="icon-star" width="56" height="56" visibility="hidden"/>
            </Panel>
            <Label text="All coins" font-size="13" class="note"/>
          </Flex>
          <Flex direction="vertical" align="center" spacing="2">
            <Panel width="64" height="64">
              <Panel id="star-2-empty" class="icon-star-empty" width="64" height="64"/>
              <Panel id="star-2" class="icon-star" width="64" height="64" visibility="hidden"/>
            </Panel>
            <Label text="No falls" font-size="13" class="note"/>
          </Flex>
          <Flex direction="vertical" align="center" spacing="2">
            <Panel width="56" height="56">
              <Panel id="star-3-empty" class="icon-star-empty" width="56" height="56"/>
              <Panel id="star-3" class="icon-star" width="56" height="56" visibility="hidden"/>
            </Panel>
            <Label id="star-3-caption" text="Under 1:00" font-size="13" class="note"/>
          </Flex>
        </Flex>

        <Spacer spacer-height="6"/>

        <!-- The tally: each row appears and counts up in turn, then the total. -->
        <Flex id="tally-coins-row" direction="horizontal" justify="space-between" align="center" width="340" visibility="hidden">
          <Label id="tally-coins-name" text="Coins" font-size="18" class="tally-name"/>
          <Label id="tally-coins" text="" font-size="18" class="tally-value"/>
        </Flex>
        <Flex id="tally-stomps-row" direction="horizontal" justify="space-between" align="center" width="340" visibility="hidden">
          <Label id="tally-stomps-name" text="Stomps" font-size="18" class="tally-name"/>
          <Label id="tally-stomps" text="" font-size="18" class="tally-value"/>
        </Flex>
        <Flex id="tally-gem-row" direction="horizontal" justify="space-between" align="center" width="340" visibility="hidden">
          <Label id="tally-gem-name" text="Gem" font-size="18" class="tally-name"/>
          <Label id="tally-gem" text="" font-size="18" class="tally-value"/>
        </Flex>
        <Flex id="tally-time-row" direction="horizontal" justify="space-between" align="center" width="340" visibility="hidden">
          <Label id="tally-time-name" text="Time" font-size="18" class="tally-name"/>
          <Label id="tally-time" text="" font-size="18" class="tally-value"/>
        </Flex>
        <Flex id="tally-flawless-row" direction="horizontal" justify="space-between" align="center" width="340" visibility="hidden">
          <Label id="tally-flawless-name" text="No falls" font-size="18" class="tally-name"/>
          <Label id="tally-flawless" text="" font-size="18" class="tally-value"/>
        </Flex>
        <Panel class="rule" width="340" height="3"/>
        <Flex direction="horizontal" justify="space-between" align="center" width="340">
          <Label text="Level score" font-family="Lilita One" font-size="24" class="tally-name"/>
          <Label id="tally-total" text="0" font-family="Lilita One" font-size="30" class="tally-total"/>
        </Flex>
        <Label id="clear-best" text="" font-family="Lilita One" font-size="20" class="best"/>

        <Spacer spacer-height="4"/>
        <Label id="clear-next" text="" font-size="16" class="note"/>
      </Flex>
    </Panel>

  </Flex>

</screen>
