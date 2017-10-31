//+------------------------------------------------------------------+
//|                                                 VisualOrders.mq4 |
//|                                                   A.Lopatin 2017 |
//|                                              diver.stv@gmail.com |
//+------------------------------------------------------------------+
#property copyright "A.Lopatin 2017"
#property link      "diver.stv@gmail.com"
#property version   "1.00"
#property strict

#define OPEN_ARROW_CODE    1
#define CLOSE_ARROW_CODE   3
#define OPEN_TAG           "open "
#define CLOSE_TAG          "close "
#define LINE_TAG           "line "
#define INFO_LABEL_TAG      "_label_info"
#define LINE_STYLE         STYLE_DOT

input datetime StartDate      = D'2017.05.05 11:00'; //Start date for history orders
input datetime EndDate        = D'2017.11.01 12:00'; //End date for history orders
input color    PositiveColor  = clrDodgerBlue;       //Line color for profitable orders
input color    NegativeColor  = clrRed;              //Line color for losing orders
input color    BuyColor       = clrYellow;           //Arrow color for buy orders
input color    SellColor      = clrRed;              //Arrow color for sell orders
input string   FontName       = "Arial";             //Font name for chart comments
input int      FontSize       = 11;                  //Font size
input color    FontColor      = clrWhite;            //Font color
//--- input parameters

int y_spacing = 7, label_corner = CORNER_LEFT_UPPER, x_shift = 10, y_shift = 20;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ClearChart();
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      PlotOrders();
  }
//+------------------------------------------------------------------+
void ClearChart()
{
   long chart_id = ChartID();
   string obj_name = "";
   
   for(int i = ObjectsTotal(chart_id, -1, -1)-1; i >= 0; i-- )
   {
      obj_name = ObjectName(chart_id, i);
      
      if(StringFind(obj_name, OPEN_TAG) > -1 )
         ObjectDelete(chart_id, obj_name);
      if(StringFind(obj_name, CLOSE_TAG) > -1 )
         ObjectDelete(chart_id, obj_name);
      if(StringFind(obj_name, LINE_TAG) > -1 )
         ObjectDelete(chart_id, obj_name);
      if(StringFind(obj_name, INFO_LABEL_TAG) > -1 )
         ObjectDelete(chart_id, obj_name);
   }
}

void PlotOrders()
{
   int i = 0, orders_count = OrdersHistoryTotal(), order_type = -1;
   string symbol = Symbol();
   int total_orders = 0, long_orders = 0, short_orders = 0;
   double net_profit = 0.0;
   
   for(i = 0; i < orders_count; i++)
   {
      if( !OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) )
         continue;
      if( OrderSymbol() != symbol )
         continue;
      order_type = OrderType();
      if( StartDate <= OrderOpenTime() && OrderOpenTime() <= EndDate )
      {
         if( order_type == OP_BUY || order_type == OP_SELL )
         {
            DrawOrder(OrderTicket());
            total_orders++;
            net_profit += (OrderProfit() + OrderSwap() + OrderCommission());
         }
         
         if( order_type == OP_BUY )
            long_orders++;
         if( order_type == OP_SELL )
            short_orders++;
      }
   }
   string text_info = StringConcatenate("Orders from ", TimeToString(StartDate), " to ", TimeToString(EndDate));
   DrawLabel(INFO_LABEL_TAG + "1", x_shift, y_shift, label_corner, text_info, FontName, FontSize, FontColor);
   text_info = StringConcatenate("Counf of orders total: ", total_orders, " Short: ", short_orders, " Long: ", long_orders );
   DrawLabel(INFO_LABEL_TAG + "2", x_shift, y_shift + 1.6*FontSize*1, label_corner, text_info, FontName, FontSize, FontColor);
   text_info = StringConcatenate("Net profit: ", net_profit );
   DrawLabel(INFO_LABEL_TAG + "3", x_shift, y_shift + 1.6*FontSize*2, label_corner, text_info, FontName, FontSize, FontColor);
}

void DrawOrder(int order_ticket)
{
   if( !OrderSelect(order_ticket, SELECT_BY_TICKET, MODE_HISTORY) )
      return;
   datetime start_time = OrderOpenTime(), end_time = OrderCloseTime();
   double start_price = OrderOpenPrice(), end_price = OrderClosePrice();
   
   color arrow_color = GetColorByOrderType(OrderType()),
         line_color = GetColorByOrderProfit(OrderProfit()+OrderCommission()+OrderSwap());
   int line_width = 1;
   string position_tag = StringConcatenate(OrderTypeToString(OrderType()), " #", OrderTicket());
   
   DrawArrow(StringConcatenate(OPEN_TAG, position_tag), start_time, start_price, arrow_color, OPEN_ARROW_CODE);
   DrawArrow(StringConcatenate(CLOSE_TAG, position_tag), end_time, end_price, arrow_color, CLOSE_ARROW_CODE);
   DrawLine(StringConcatenate(LINE_TAG, position_tag), start_time, end_time, start_price, end_price, line_color, LINE_STYLE, line_width);
}


color GetColorByOrderType(int order_type)
{
   color result_color = clrNONE;
   
   if( order_type == OP_BUY || order_type == OP_BUYSTOP || order_type == OP_BUYLIMIT )
      result_color = BuyColor;
   if( order_type == OP_SELL || order_type == OP_SELLSTOP || order_type == OP_SELLLIMIT )
      result_color = SellColor;   
   
   return result_color;
}

color GetColorByOrderProfit(double profit)
{
   color result_color = clrNONE;
   
   if( profit >= 0.0 )
      result_color = PositiveColor;
   else
      result_color = NegativeColor;
   
   return result_color;
}

string OrderTypeToString(int order_type)
{
   string type_string = "";
   
   switch(order_type)
   {
      case OP_BUY:
         type_string = "Buy";
         break;
      case OP_SELL:
         type_string = "Sell";
         break;
      case OP_BUYSTOP:
         type_string = "Buy stop";
         break;
      case OP_SELLSTOP:
         type_string = "Sell stop";
         break;
      case OP_BUYLIMIT:
         type_string = "Buy limit";
         break;
      case OP_SELLLIMIT:
         type_string = "Sell limit";
         break;
      default:
         break;
   }
   
   return type_string;
}

void DrawArrow(string name, datetime time, double price, color arrow_color, int arrow_code)
{
   long chart_id = ChartID();
   bool result = false;
   
   if( ObjectFind(chart_id, name) < 0 )
   {
      if( !ObjectCreate(chart_id, name, OBJ_ARROW, 0, time, price) )
         return;
      ObjectSetInteger(chart_id, name, OBJPROP_COLOR, arrow_color);
      ObjectSetInteger(chart_id, name, OBJPROP_ARROWCODE, arrow_code);
   }
}

void DrawLine(string name, datetime start_time, datetime end_time, double start_price, double end_price, color line_color, int style, int width)
{
   long chart_id = ChartID();
    
    if(ObjectFind(chart_id, name) < 0)
    {
       if( !ObjectCreate(chart_id, name, OBJ_TREND, 0, start_time, start_price, end_time, end_price) )
         return;
       ObjectSetInteger(chart_id, name, OBJPROP_COLOR, line_color);
       ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width);
       ObjectSetInteger(chart_id, name, OBJPROP_STYLE, style);
       ObjectSetInteger(chart_id, name, OBJPROP_RAY, 0);
    }
}

bool DrawLabel(const string name, const int _x, const int y, const int corner, const string text, const string font_name, const int font_size, const color label_color)
{
   long chart_id = ChartID();
   bool result = false;
   
   if( ObjectFind(chart_id, name) < 0 )
   {
      if( !ObjectCreate(chart_id, name, OBJ_LABEL, 0, 0, 0) )
         return(false);
   }
   result = ObjectSetText(name, text, font_size, font_name, label_color);
   result = ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, _x);
   result = ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
   result = ObjectSetInteger(chart_id, name, OBJPROP_CORNER, corner);
   
   return(result);
}