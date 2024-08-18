## Basic rules

- Currency Pair - GBPUSD
- Time range 2am - 10am
- Entry points 7 pips above and below

## Strategy

- Find high and low btn 2am and 10am
- if currentTime is after range, get next range
- if currentTime is within range:

  - wait for end of range
  - get high and low and start monitoring price

- if currentTime is btn 6pm and 1:59am wait for next range

- sl = avg(high and low)
- tp = sl\*2

## Example

- double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;
  Comment(" \n\rMT5 SERVER TIME: ", TimeCurrent(),
  " (OPERATING AT UTC/GMT",StringFormat("%+.1f", offsetInHours),
  ") \n\n NOW: ", now, "\n\r",
  " END TIME: ", EndTime, "\n\r",
  " START TIME: ", StartTime, "\n\r",
  " CUTOFF TIME: ", CuttOffTime, "\n\r",
  " IN RANGE: ", InRange, "\n\r",
  " Currently in range: ", currentlyInRange, "\n\r",
  " EXITED RANGE: ", InRange && !currentlyInRange, "\n\r",
  " OUT OF RANGE: ", now >= EndTime, "\n\r",
  " PAST 6PME: ", now >= CuttOffTime, "\n\r",
  " BUY ENTRY PRICE: ", BuyEntryPrice, "\n\r",
  " SELL ENTRY PRICE: ", SellEntryPrice, "\n\r");
-
