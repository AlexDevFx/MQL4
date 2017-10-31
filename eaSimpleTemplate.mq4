//+------------------------------------------------------------------+
//|                                             eaSimpleTemplate.mq4 |
//|                                                  A.Lopatin� 2017 |
//|                                              diver.stv@gmail.com |
//+------------------------------------------------------------------+
#property copyright " A.Lopatin� 2017"
#property link      "diver.stv@gmail.com"
#property version   "1.00"
#property strict

/* Error levels for a logging */
#define LOG_LEVEL_ERR 1
#define LOG_LEVEL_WARN 2
#define LOG_LEVEL_INFO 3
#define LOG_LEVEL_DBG 4

#include <stdlib.mqh>
#include <stderror.mqh>

/* input options of the EA */

input double  Lots                 = 0.1;       //fixed lot size
input int     StopLoss             = 50;        //stoploss value in points, if 0, then disabled
input int     TakeProfit           = 70;        //takeprofit value in points, if 0, then disabled
input int     MagicNumber          = 111112232; //Magic number for EA's orders
input int     Slippage             = 3;         //maximum allowed deviation (in pips) of the price by opening


int retry_attempts 		= 10;                   //attempts count for opening of the order
double sleep_time 		= 4.0;                  //pause in seconds between atempts
double sleep_maximum 	= 25.0;                 // in seconds
static int ErrorLevel 	= LOG_LEVEL_ERR;        //level of error logging
static int _OR_err 		= 0;                    // error code
const int c_shift = 1;                                  //bar index for signal checking
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
    
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   DoTrade();
}
//+------------------------------------------------------------------+
/* the function for a trade signal checking returns (int) a order type for opening
input: int index - index of bar for checking */
int CheckEntrySignal(const int index)
{
    /*if(  )
        return(OP_BUY);
    if(  )
        return(OP_SELL);*/
    
    return(-1);
}

int ChecExitSignal(const int index)
{
    /*if(  )
        return(OP_BUY);
    if(  )
        return(OP_SELL);*/
    
    return(-1);
}

/* the main function for trading*/
void DoTrade()
{
    int total_orders = OrdersCount(MagicNumber);//count of opening orders
    double point = XGetPoint(Symbol());//get point value
    int signal = -1;
    RefreshRates(); // refresh  a price quotes        
    if( total_orders < 1 )
    {
       signal = CheckEntrySignal(c_shift);//check a trade signal
       if( signal == OP_BUY )
       {
            if( OpenTrade(OP_BUY, CalculateVolume(), Ask, Slippage, StopLoss, TakeProfit, "", MagicNumber) > 0 )
                return;
       }
       
       if( signal == OP_SELL )
       {
            if( OpenTrade(OP_SELL, CalculateVolume(), Bid, Slippage, StopLoss, TakeProfit, "", MagicNumber) > 0 )
                return;
       }
    }
}

/* the function for managing of EA's orders*/
void DoManage(const int magic)
{
}

/* the function returns count of opened  orders by EA
arguments: magic - magic number of orders */
int OrdersCount(const int magic )
{
    int orders_total = OrdersTotal(), count = 0;
    
    for( int i = 0; i < orders_total; i++ )
    {
        if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )
        {
            if( OrderSymbol() != Symbol() )
                continue;
            if( OrderMagicNumber() != magic )
                continue;
                
            count++;
        }
    }
    
    return(count);
}

/* The function for opening new order for current symbol. If successed returns ticket of opened order, if failed -1 */
int OpenTrade(int type, double lots, double price, int slippage, int stoploss,int takeprofit, string comment, int magic, datetime expiration = 0, color arrow_color = CLR_NONE)
{
    double tp = 0.0, sl = 0.0, point = XGetPoint(Symbol());
    int retn_ticket = -1;
    price = NormalizeDouble(price, Digits);
       
    if( takeprofit > 0 )
    {
        if( type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT )
            tp = NormalizeDouble(price + takeprofit*point, Digits);
        if( type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT )
            tp = NormalizeDouble(price - takeprofit*point, Digits);
    }
    
    if( stoploss > 0 )
    {
        if( type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT )
            sl = NormalizeDouble(price - stoploss*point, Digits);
        if( type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT )
            sl = NormalizeDouble(price + stoploss*point, Digits);
    }
    
    retn_ticket = XOrderSend(Symbol(), type, lots, price, slippage, sl, tp, comment, magic, expiration,  arrow_color);
    
    return(retn_ticket);
}

/*The function for calculation the trade volume, returns lot size*/
double CalculateVolume()
{
   double result = Lots;
      
   return(result);
}

/* The function closes and deletes all EA's orders, returns count of closed orders */
int CloseAllOrdes(const int magic, const int type = -1 )
{
    int orders_count = OrdersTotal();
	int ord_type = -1, n = 0;
	string symbol = Symbol();

	for( int i = orders_count-1; i >= 0; i--)
	{
		if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber() == magic )
		{
			if( symbol != OrderSymbol() )
				continue;
           
			ord_type = OrderType();
         
         if( type == ord_type || type == -1 )
         {        
              if( ord_type == OP_BUY  )
			     {
				     if( XOrderClose(OrderTicket(), OrderLots(), Bid, Slippage) )
				         n++;
				     continue;
			     }
			     
			     if( ord_type == OP_SELL  )
			     {
				     if( XOrderClose(OrderTicket(), OrderLots(), Ask, Slippage) )
				         n++;
				     continue;
			     }
                 
			     if( ord_type == OP_BUYSTOP || ord_type == OP_SELLSTOP || ord_type == OP_BUYLIMIT || ord_type == OP_SELLLIMIT )
			     {
				     if( OrderDelete( OrderTicket() ) )
				         n++;
				     continue;
			     }
	      }
		}	
	}
	
	return(n);
}

/* The function-wrapper for Print() function
inputs: log_level - level for logging
        text - text of the message
        is_show_comments - show message in comments, by default disabled*/
void XPrint( int log_level, string text, bool is_show_comments = false ) {
   string prefix, message;
   
   if( log_level > ErrorLevel )
      return;

   switch(log_level) {
      case LOG_LEVEL_ERR:
         prefix = "Error";
         break;
      case LOG_LEVEL_WARN:
         prefix = "Warning";
         break;
      case LOG_LEVEL_INFO:
         prefix = "Info";
         break;
      case LOG_LEVEL_DBG:
         prefix = "Debug";
         break;                  
   }
   
   message = StringConcatenate( prefix, ": ", text );
   
   if( is_show_comments )
      Comment( message );
   
   Print(message);
}

/* The function-wrapper for OrderSend() function */
int XOrderSend(string symbol, int cmd, double volume, double price,
					  int slippage, double stoploss, double takeprofit,
					  string comment, int magic, datetime expiration = 0, 
					  color arrow_color = CLR_NONE) {

   int digits;
   
	XPrint( LOG_LEVEL_INFO,StringConcatenate( "Attempted " , XCommandString(cmd) , " " , volume , 
						" lots @" , price , " sl:" , stoploss , " tp:" , takeprofit)); 
						
	if (IsStopped()) {
		XPrint( LOG_LEVEL_WARN, "Expert was stopped while processing order. Order was canceled.");
		_OR_err = ERR_COMMON_ERROR; 
		return(-1);
	}
	
	int cnt = 0;
	while(!IsTradeAllowed() && cnt < retry_attempts) {
		XSleepRandomTime(sleep_time, sleep_maximum); 
		cnt++;
	}
	
	if (!IsTradeAllowed()) 
	{
		XPrint( LOG_LEVEL_WARN, "No operation possible because Trading not allowed for this Expert, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 

		return(-1);  
	}

   digits = (int)MarketInfo( symbol, MODE_DIGITS);

   if( price == 0 ) {
      RefreshRates();
      if( cmd == OP_BUY ) {
			price = Ask;      
      }
      if( cmd == OP_SELL ) {
			price = Bid;      
      }      
   }

	if (digits > 0) {
		price = NormalizeDouble(price, digits);
		stoploss = NormalizeDouble(stoploss, digits);
		takeprofit = NormalizeDouble(takeprofit, digits); 
	}
	
	if (stoploss != 0) 
		XEnsureValidStop(symbol, price, stoploss); 

	int err = GetLastError(); // clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	bool limit_to_market = false; 
	
	// limit/stop order. 
	int ticket=-1;

	if ((cmd == OP_BUYSTOP) || (cmd == OP_SELLSTOP) || (cmd == OP_BUYLIMIT) || (cmd == OP_SELLLIMIT)) {
		cnt = 0;
		while (!exit_loop) {
			if (IsTradeAllowed()) {
				ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
				err = GetLastError();
				_OR_err = err; 
			} else {
				cnt++;
			} 
			
			switch (err) {
				case ERR_NO_ERROR:
					exit_loop = true;
					break;
				
				// retryable errors
				case ERR_SERVER_BUSY:
				   break;
				case ERR_NO_CONNECTION:
				   break;
				case ERR_INVALID_PRICE:
				   break;
				case ERR_OFF_QUOTES:
				   break;
				case ERR_BROKER_BUSY:
				   break;
				case ERR_TRADE_CONTEXT_BUSY: 
					cnt++; 
					break;
					
				case ERR_PRICE_CHANGED:
				   break;
				case ERR_REQUOTE:
					RefreshRates();
					continue;	// we can apparently retry immediately according to MT docs.
					
				case ERR_INVALID_STOPS:
				{
					double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * XGetPoint(symbol); 
					if (cmd == OP_BUYSTOP) {
						// If we are too close to put in a limit/stop order so go to market.
						if (MathAbs(Ask - price) <= servers_min_stop)	
							limit_to_market = true; 
							
					} 
					else if (cmd == OP_SELLSTOP) 
					{
						// If we are too close to put in a limit/stop order so go to market.
						if (MathAbs(Bid - price) <= servers_min_stop)
							limit_to_market = true; 
					}
					exit_loop = true; 
					break; 
				}
				default:
					// an apparently serious error.
					exit_loop = true;
					break; 
					
			}  // end switch 

			if (cnt > retry_attempts) 
				exit_loop = true; 
			 	
			if (exit_loop) {
				if (err != ERR_NO_ERROR) {
					XPrint( LOG_LEVEL_ERR, "Non-retryable error - " + XErrorDescription(err)); 
				}
				if (cnt > retry_attempts) {
					XPrint( LOG_LEVEL_INFO, StringConcatenate("Retry attempts maxed at " , retry_attempts)); 
				}
			}
			 
			if (!exit_loop) {
				XPrint( LOG_LEVEL_DBG, StringConcatenate("Retryable error (" , cnt , "/" , retry_attempts , 
									"): " , XErrorDescription(err))); 
				XSleepRandomTime(sleep_time, sleep_maximum); 
				RefreshRates(); 
			}
		}
		 
		// We have now exited from loop. 
		if (err == ERR_NO_ERROR) {
			XPrint( LOG_LEVEL_INFO, "apparently successful order placed.");
			return(ticket); // SUCCESS! 
		} 
		if (!limit_to_market) {
			XPrint( LOG_LEVEL_ERR, StringConcatenate("failed to execute stop or limit order after " , cnt , " retries"));
			XPrint( LOG_LEVEL_INFO, StringConcatenate("failed trade: " , XCommandString(cmd) , " " , symbol , 
								"@" , price , " tp@" , takeprofit , " sl@" , stoploss)); 
			XPrint( LOG_LEVEL_INFO, StringConcatenate("last error: " , XErrorDescription(err))); 
			return(-1); 
		}
	}  // end	  
  
	if (limit_to_market) {
		XPrint( LOG_LEVEL_DBG, "going from limit order to market order because market is too close." );
		RefreshRates();
		if ((cmd == OP_BUYSTOP) || (cmd == OP_BUYLIMIT)) {
			cmd = OP_BUY;
			price = Ask;
		} 
		else if ((cmd == OP_SELLSTOP) || (cmd == OP_SELLLIMIT)) 
		{
			cmd = OP_SELL;
			price = Bid;
		}	
	}
	
	// we now have a market order.
	err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	ticket = -1;

	if ((cmd == OP_BUY) || (cmd == OP_SELL)) {
		cnt = 0;
		while (!exit_loop) {
			if (IsTradeAllowed()) {
				ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
				err = GetLastError();
				_OR_err = err; 
			} else {
				cnt++;
			} 
			switch (err) {
				case ERR_NO_ERROR:
					exit_loop = true;
					break;
					
				case ERR_SERVER_BUSY:
				case ERR_NO_CONNECTION:
				case ERR_INVALID_PRICE:
				case ERR_OFF_QUOTES:
				case ERR_BROKER_BUSY:
				case ERR_TRADE_CONTEXT_BUSY: 
					cnt++; // a retryable error
					break;
					
				case ERR_PRICE_CHANGED:
				case ERR_REQUOTE:
					RefreshRates();
					continue; // we can apparently retry immediately according to MT docs.
					
				default:
					// an apparently serious, unretryable error.
					exit_loop = true;
					break; 
					
			}  // end switch 

			if (cnt > retry_attempts) 
			 	exit_loop = true; 
			 	
			if (!exit_loop) {
				XPrint( LOG_LEVEL_DBG, StringConcatenate("retryable error (" , cnt , "/" , 
									retry_attempts , "): " , XErrorDescription(err))); 
				XSleepRandomTime(sleep_time,sleep_maximum); 
				RefreshRates(); 
			}
			
			if (exit_loop) {
				if (err != ERR_NO_ERROR) {
					XPrint( LOG_LEVEL_ERR, StringConcatenate("non-retryable error: " , XErrorDescription(err))); 
				}
				if (cnt > retry_attempts) {
					XPrint( LOG_LEVEL_INFO, StringConcatenate("retry attempts maxed at " , retry_attempts)); 
				}
			}
		}
		
		// we have now exited from loop. 
		if (err == ERR_NO_ERROR) {
			XPrint( LOG_LEVEL_INFO, "apparently successful order placed, details follow.");
//			OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
//			OrderPrint(); 
			return(ticket); // SUCCESS! 
		} 
		XPrint( LOG_LEVEL_ERR, StringConcatenate("failed to execute OP_BUY/OP_SELL, after " , cnt , " retries"));
		XPrint( LOG_LEVEL_INFO, StringConcatenate("failed trade: " , XCommandString(cmd) , " " , symbol , 
							"@" , price , " tp@" , takeprofit , " sl@" , stoploss)); 
		XPrint( LOG_LEVEL_INFO, StringConcatenate("last error: " , XErrorDescription(err))); 
		return(-1); 
	}
	return(-1);
}

/* The function converts type order into string */
string XCommandString(int cmd) {
	if (cmd == OP_BUY) 
		return("BUY");

	if (cmd == OP_SELL) 
		return("SELL");

	if (cmd == OP_BUYSTOP) 
		return("BUY STOP");

	if (cmd == OP_SELLSTOP) 
		return("SELL STOP");

	if (cmd == OP_BUYLIMIT) 
		return("BUY LIMIT");

	if (cmd == OP_SELLLIMIT) 
		return("SELL LIMIT");

	return(StringConcatenate("(" , cmd , ")")); 
}

/* The function calculate valid stoploss for the order.
arguments: symbol - currency symbol
           price - open price of a order
           sl - output the price of the stoploss*/
void XEnsureValidStop(string symbol, double price, double& sl) {
	// Return if no S/L
	if (sl == 0) 
		return;
	
	double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * XGetPoint(symbol); 
	
	if (MathAbs(price - sl) <= servers_min_stop) {
		// we have to adjust the stop.
		if (price > sl)
			sl = price - servers_min_stop;	// we are long
			
		else if (price < sl)
			sl = price + servers_min_stop;	// we are short			
		else
			XPrint( LOG_LEVEL_WARN, "Passed Stoploss which equal to price"); 
			
		sl = NormalizeDouble(sl, (int)MarketInfo(symbol, MODE_DIGITS)); 
	}
}

/* The function returns point value for currency (symbol).
   Multiplies the point value for 10 for 3-5 digits brokers.*/
double XGetPoint( string symbol ) {
   double point;
   
   point = MarketInfo( symbol, MODE_POINT );
   double digits = NormalizeDouble( MarketInfo( symbol, MODE_DIGITS ),0 );
   
   if( digits == 3 || digits == 5 ) {
      return(point*10.0);
   }
   
   return(point);
}

/* The function-wrapper for Sleep()*/
void XSleepRandomTime(double mean_time, double max_time) {
	if (IsTesting()) 
		return; 	// return immediately if backtesting.

	double tenths = MathCeil(mean_time / 0.1);
	if (tenths <= 0) 
		return; 
	 
	int maxtenths = (int)MathRound(max_time/0.1); 
	double p = 1.0 - 1.0 / tenths; 
	  
	Sleep(100); 	// one tenth of a second PREVIOUS VERSIONS WERE STUPID HERE. 
	
	for(int i=0; i < maxtenths; i++) {
		if (MathRand() > p*32768) 
			break; 
			
		// MathRand() returns in 0..32767
		Sleep(100); 
	}
}  

/* The function-wrapper for ErrorDescription()*/
string XErrorDescription(int err) {
   return(ErrorDescription(err)); 
}

/* The function-wrapper for OrderModify()*/
bool XOrderModify(int ticket, double price, double stoploss, 
						 double takeprofit, datetime expiration, 
						 color arrow_color = CLR_NONE) {

	XPrint( LOG_LEVEL_INFO, StringConcatenate(" attempted modify of #" , ticket , " price:" , price , " sl:" , stoploss , " tp:" , takeprofit)); 

	if (IsStopped()) {
		XPrint( LOG_LEVEL_WARN, "Expert was stopped while processing order. Order was canceled.");
		return(false);
	}
	
	int cnt = 0;
	while(!IsTradeAllowed() && cnt < retry_attempts) {
		XSleepRandomTime(sleep_time,sleep_maximum); 
		cnt++;
	}
	if (!IsTradeAllowed()) {
		XPrint( LOG_LEVEL_WARN, "No operation possible because Trading not allowed for this Expert, even after retries.");
		_OR_err = ERR_TRADE_CONTEXT_BUSY; 
		return(false);  
	}

	int err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	cnt = 0;
	bool result = false;
	
	while (!exit_loop) {
		if (IsTradeAllowed()) {
			result = OrderModify(ticket, price, stoploss, takeprofit, expiration, arrow_color);
			err = GetLastError();
			_OR_err = err; 
		} 
		else 
			cnt++;

		if (result == true) 
			exit_loop = true;

		switch (err) {
			case ERR_NO_ERROR:
				exit_loop = true;
				break;
				
			case ERR_NO_RESULT:
				// modification without changing a parameter. 
				// if you get this then you may want to change the code.
				exit_loop = true;
				break;
				
			case ERR_SERVER_BUSY:
			case ERR_NO_CONNECTION:
			case ERR_INVALID_PRICE:
			case ERR_OFF_QUOTES:
			case ERR_BROKER_BUSY:
			case ERR_TRADE_CONTEXT_BUSY: 
			case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope. 
				cnt++; 	// a retryable error
				break;
				
			case ERR_PRICE_CHANGED:
			case ERR_REQUOTE:
				RefreshRates();
				continue; 	// we can apparently retry immediately according to MT docs.
				
			default:
				// an apparently serious, unretryable error.
				exit_loop = true;
				break; 
				
		}  // end switch 

		if (cnt > retry_attempts) 
			exit_loop = true; 
			
		if (!exit_loop) 
		{
			XPrint( LOG_LEVEL_DBG, StringConcatenate("retryable error (" , cnt , "/" , retry_attempts , "): "  ,  XErrorDescription(err))); 
			XSleepRandomTime(sleep_time,sleep_maximum); 
			RefreshRates(); 
		}
		
		if (exit_loop) {
			if ((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT)) 
				XPrint( LOG_LEVEL_ERR, StringConcatenate("non-retryable error: " , XErrorDescription(err))); 

			if (cnt > retry_attempts) 
				XPrint( LOG_LEVEL_INFO, StringConcatenate("retry attempts maxed at " , retry_attempts)); 
		}
	}  
	
	// we have now exited from loop. 
	if ((result == true) || (err == ERR_NO_ERROR)) 	{
		XPrint( LOG_LEVEL_INFO, "apparently successful modification order.");
		return(true); // SUCCESS! 
	} 
	
	if (err == ERR_NO_RESULT) {
		XPrint( LOG_LEVEL_WARN, "Server reported modify order did not actually change parameters.");
		return(true);
	}
	
	XPrint( LOG_LEVEL_ERR, StringConcatenate("failed to execute modify after " , cnt , " retries"));
	XPrint( LOG_LEVEL_INFO, StringConcatenate("failed modification: " , ticket , " @" , price , " tp@" , takeprofit , " sl@" , stoploss)); 
	XPrint( LOG_LEVEL_INFO, StringConcatenate("last error: " , XErrorDescription(err))); 
	
	return(false);  
}


/* The function-wrapper for OrderClose()*/
bool XOrderClose(int ticket, double lots, double price, int slippage, color arrow_color = CLR_NONE) {
	int nOrderType;
	string strSymbol;
	
	XPrint( LOG_LEVEL_INFO, StringConcatenate(" attempted close of #" , ticket , " price:" , price , " lots:" , lots , " slippage:" , slippage)); 

	// collect details of order so that we can use GetMarketInfo later if needed
	if (!OrderSelect(ticket,SELECT_BY_TICKET)) {
		_OR_err = GetLastError();		
		XPrint( LOG_LEVEL_ERR, XErrorDescription(_OR_err));
		return(false);
	} else {
		nOrderType = OrderType();
		strSymbol = Symbol();
	}

	if (nOrderType != OP_BUY && nOrderType != OP_SELL)	{
		_OR_err = ERR_INVALID_TICKET;
		XPrint( LOG_LEVEL_WARN, StringConcatenate("trying to close ticket #" , ticket , ", which is " , XCommandString(nOrderType) , ", not BUY or SELL"));
		return(false);
	}

	if (IsStopped()) {
		XPrint( LOG_LEVEL_WARN, "Expert was stopped while processing order. Order processing was canceled.");
		return(false);
	}

	
	int cnt = 0;
	int err = GetLastError(); // so we clear the global variable.  
	err = 0; 
	_OR_err = 0; 
	bool exit_loop = false;
	cnt = 0;
	bool result = false;
	
	if( lots == 0)
	  lots = OrderLots();
	
	if( price == 0 ) {
	  RefreshRates();
	  if (nOrderType == OP_BUY)  
		  price = NormalizeDouble(MarketInfo(strSymbol, MODE_BID), (int)MarketInfo(strSymbol, MODE_DIGITS));
	  if (nOrderType == OP_SELL) 
		  price = NormalizeDouble(MarketInfo(strSymbol, MODE_ASK), (int)MarketInfo(strSymbol, MODE_DIGITS));
	}
	
	while (!exit_loop) 
	{
		if (IsTradeAllowed()) 
		{
			result = OrderClose(ticket, lots, price, slippage, arrow_color);
			err = GetLastError();
			_OR_err = err; 
		} 
		else 
			cnt++;

		if (result == true) 
			exit_loop = true;

		switch (err) {
			case ERR_NO_ERROR:
				exit_loop = true;
				break;
				
			case ERR_SERVER_BUSY:
			case ERR_NO_CONNECTION:
			case ERR_INVALID_PRICE:
			case ERR_OFF_QUOTES:
			case ERR_BROKER_BUSY:
			case ERR_TRADE_CONTEXT_BUSY: 
			case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope. 
				cnt++; 	// a retryable error
				break;
				
			case ERR_PRICE_CHANGED:
			case ERR_REQUOTE:
				continue; 	// we can apparently retry immediately according to MT docs.
				
			default:
				// an apparently serious, unretryable error.
				exit_loop = true;
				break; 
				
		}  // end switch 

		if (cnt > retry_attempts) 
			exit_loop = true; 
			
		if (!exit_loop) 
		{
			XPrint( LOG_LEVEL_DBG, StringConcatenate("retryable error (" , cnt , "/" , retry_attempts , "): "  ,  XErrorDescription(err))); 
			XSleepRandomTime(sleep_time,sleep_maximum); 
			
			// Added by Paul Hampton-Smith to ensure that price is updated for each retry
			if (nOrderType == OP_BUY)  
				price = NormalizeDouble(MarketInfo(strSymbol, MODE_BID), (int)MarketInfo(strSymbol, MODE_DIGITS));
			if (nOrderType == OP_SELL) 
				price = NormalizeDouble(MarketInfo(strSymbol, MODE_ASK), (int)MarketInfo(strSymbol, MODE_DIGITS));
		}
		
		if (exit_loop) 
		{
			if ((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT)) 
				XPrint( LOG_LEVEL_ERR, StringConcatenate("non-retryable error: " , XErrorDescription(err))); 

			if (cnt > retry_attempts) 
				XPrint( LOG_LEVEL_INFO, StringConcatenate("retry attempts maxed at " , retry_attempts)); 
		}
	}  
	
	// we have now exited from loop. 
	if ((result == true) || (err == ERR_NO_ERROR)) 
	{
		XPrint( LOG_LEVEL_INFO, "apparently successful close order.");
		return(true); // SUCCESS! 
	} 
	
	XPrint( LOG_LEVEL_ERR, StringConcatenate("failed to execute close after " , cnt , " retries"));
	XPrint( LOG_LEVEL_INFO, StringConcatenate("failed close: Ticket #" , ticket , ", Price: " , price , ", Slippage: " , slippage)); 
	XPrint( LOG_LEVEL_INFO, StringConcatenate("last error: " , XErrorDescription(err))); 
	
	return(false);  
}