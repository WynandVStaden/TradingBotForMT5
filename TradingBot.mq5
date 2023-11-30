// Advanced Trading Bot

input int fastMA_Period = 10;  // Period for fast moving average
input int slowMA_Period = 30;  // Period for slow moving average
input double lotSize = 0.1;     // Trading lot size
input double riskPercentage = 1; // Risk per trade percentage

double riskPerTrade;
int totalTrades = 0;

int OnInit()
{
   riskPerTrade = AccountFreeMarginCheck(_Symbol, OP_BUY, lotSize) * riskPercentage / 100;
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double fastMA = iMA(_Symbol, 0, fastMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double slowMA = iMA(_Symbol, 0, slowMA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);

   if (fastMA > slowMA)
   {
      // Buy Signal
      double stopLoss = NormalizeDouble(Bid - 0.005, _Digits);
      double takeProfit = NormalizeDouble(Bid + 0.01, _Digits);

      int ticket = OrderSend(_Symbol, OP_BUY, lotSize, Ask, 3, stopLoss, takeProfit, "Buy Order", 0, 0, Green);
      
      if (ticket > 0)
      {
         totalTrades++;
         riskPerTrade = AccountFreeMarginCheck(_Symbol, OP_BUY, lotSize) * riskPercentage / 100;
      }
   }
   else if (fastMA < slowMA)
   {
      // Sell Signal
      double stopLoss = NormalizeDouble(Ask + 0.005, _Digits);
      double takeProfit = NormalizeDouble(Ask - 0.01, _Digits);

      int ticket = OrderSend(_Symbol, OP_SELL, lotSize, Bid, 3, stopLoss, takeProfit, "Sell Order", 0, 0, Red);
      
      if (ticket > 0)
      {
         totalTrades++;
         riskPerTrade = AccountFreeMarginCheck(_Symbol, OP_SELL, lotSize) * riskPercentage / 100;
      }
   }
}

void OnTrade()
{
   for (int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if (OrderSymbol() == _Symbol && OrderMagicNumber() == 0 && OrderType() <= OP_SELL)
         {
            double profit = OrderProfit();
            double riskRewardRatio = profit / riskPerTrade;

            if (riskRewardRatio > 2)
            {
               double closePrice = 0;
               if (OrderType() == OP_BUY)
                  closePrice = NormalizeDouble(Bid, _Digits);
               else if (OrderType() == OP_SELL)
                  closePrice = NormalizeDouble(Ask, _Digits);

               OrderSend(OrderSymbol(), OP_CLOSE, OrderLots(), closePrice, 3, 0, 0, "Take Profit", 0, 0, Yellow);
            }
         }
      }
   }
}


