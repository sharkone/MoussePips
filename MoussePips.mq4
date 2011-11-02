//+------------------------------------------------------------------+
//|                                             MoussePips.mq4 |
//|                                       Copyright © 2011, SharkOne |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2011, SharkOne"
#property link      "http://www.metaquotes.net"

// +------------------------------------------------------------------+

extern int     ma_fast_period  = 5;
extern int     ma_slow_period  = 10;

extern double  risk_percentage = 0.02;
extern int     sr_history_bars = 7;

// +------------------------------------------------------------------+

int init()
{
   return (0);
}

//+------------------------------------------------------------------+

int deinit()
{
   return (0);
}

//+------------------------------------------------------------------+

int get_open_buy()
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         break;
      
      if (OrderSymbol() != Symbol())
         continue;
      
      
      if (OrderType() == OP_BUY)
         return (OrderTicket());
   }

   return (-1);
}

//+------------------------------------------------------------------+

int get_open_sell()
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
         break;
      
      if (OrderSymbol() != Symbol())
         continue;
      
      
      if (OrderType() == OP_SELL)
         return (OrderTicket());
   }

   return (-1);
}

//+------------------------------------------------------------------+

double compute_lot_size(int stop_loss_points)
{
   return (NormalizeDouble((AccountFreeMargin() * risk_percentage) / ( stop_loss_points * MarketInfo(Symbol(), MODE_TICKVALUE)), 2));
}

//+------------------------------------------------------------------+

double compute_buy_stop_loss()
{
   return (Low[iLowest(NULL, 0, MODE_LOW, sr_history_bars, 0)]);
}

//+------------------------------------------------------------------+

double compute_sell_stop_loss()
{
   return (High[iHighest(NULL, 0, MODE_HIGH, sr_history_bars, 0)]);
}

//+------------------------------------------------------------------+

int start()
{
   if (Volume[0] > 1)
      return;

   double current_ma_fast = iMA(NULL, 0, ma_fast_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double current_ma_slow = iMA(NULL, 0, ma_slow_period, 0, MODE_EMA, PRICE_CLOSE, 0);

   // buy exit
   // ----------------------------------------------------------------------
   int open_buy = get_open_buy();
   
   if (open_buy != -1)
   {
      if (current_ma_fast < current_ma_slow)
      {
         if (OrderSelect(open_buy, SELECT_BY_TICKET) == true)
            OrderClose(OrderTicket(), OrderLots(), Bid, 3, White);
      }
   }
   
   // sell exit
   // ----------------------------------------------------------------------
   int open_sell = get_open_sell();
   
   if (open_sell != -1)
   {
      if (current_ma_fast > current_ma_slow)
      {
         if (OrderSelect(open_sell, SELECT_BY_TICKET) == true)
            OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);
      }
   }

   // buy entry
   // ----------------------------------------------------------------------

   if (get_open_buy() == -1)
   {
      if (current_ma_fast > current_ma_slow)
      {
         double buy_stop_loss        = compute_buy_stop_loss();
         int    buy_stop_loss_points = ((Ask - buy_stop_loss) / Point);
         double buy_lot_size         = compute_lot_size(buy_stop_loss_points);
         
         if (buy_lot_size > 0.0)
         {
            OrderSend(Symbol(), OP_BUY, buy_lot_size, Ask, 3, buy_stop_loss, 0.0, NULL, 0, 0, Lime);
         }
      }
   }
   
   // sell entry
   // ----------------------------------------------------------------------
   
   if (get_open_sell() == -1)
   {
      if (current_ma_fast < current_ma_slow)
      {
         double sell_stop_loss        = compute_sell_stop_loss();
         int    sell_stop_loss_points = ((sell_stop_loss - Bid) / Point);
         double sell_lot_size         = compute_lot_size(sell_stop_loss_points);
         
         if (sell_lot_size > 0.0)
         {
            OrderSend(Symbol(), OP_SELL, sell_lot_size, Bid, 3, sell_stop_loss, 0.0, NULL, 0, 0, Red); 
         }
      }
   }

   return (0);
}

//+------------------------------------------------------------------+

