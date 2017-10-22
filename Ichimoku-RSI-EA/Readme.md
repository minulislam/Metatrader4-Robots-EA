Trading Algorithm (working in current timeframe, here 1-minute timeframe) :

If Ichimoku Kumo Breakout <=> Last Japanese Candlestick has open price under kumo top and close price over kumo top.

And RSI>=65

Then open a BUY position (LONG) with following parameters :

- no stoploss
- takeprofit = buy price + spread + buy price/100*0.1 (<=> buy price + spread + 0.1% of buy price)

Backtest with Darwinex MT4 platform :

From 05/09/2017 to 19/10/2017 in 1-minute timeframe on EUR/USD
Initial equity = 500€
Final equity = 1363.82€
ROI = +136%



