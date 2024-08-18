//+------------------------------------------------------------------+
//|                                                 Breakout2_v1.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade        Trade;
CPositionInfo PositionInfo;

enum ENUM_RISK_TYPE {
   RISK_TYPE_FIXED_LOTS, // Fixed lots
   RISK_TYPE_EQUITY_PERCENT, // Percent of equity
}

;

//+------------------------------------------------------------------+
//|	Inputs
//+------------------------------------------------------------------+
// Time range
input int     InpRangeStartHour   = 1; // Range start hour
input int     InpRangeStartMinute = 0; // Range start minute
input int     InpRangeEndHour     = 1; // Range end hour
input int     InpRangeEndMinute   = 0; // Range end minute
input int     InpCutOffHour       = 1; // Cut off hour
input int     InpCutOffMinute     = 0; // Cut off minute

input double  InpRangeGapPips     = 7.0;  // Entry gap from outer range pips
input int     InpMultiplier       = 2;    // Stop Loss to Profit Ratio

// Standard features
input long           InpMagic          = 232323;               // Magic number
input string         InpTradeComment   = "custom Breakout2";   // Trade comment
input ENUM_RISK_TYPE InpRiskType       = RISK_TYPE_FIXED_LOTS; // Risk Type
input double         InpRisk           = 1.0;                  // Risk

//+------------------------------------------------------------------+
//| Global variables
//+------------------------------------------------------------------+
double        RangeGap            = 0;
double        StopLoss            = 0;
double        TakeProfit          = 0;

datetime      StartTime           = 0;
datetime      EndTime             = 0;
datetime      CuttOffTime         = 0;
bool          InRange             = false;

double        BuyEntryPrice       = 0;
double        SellEntryPrice      = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   
   // check if inputs are valid
   if(!IsInputsValid()) return INIT_PARAMETERS_INCORRECT;
   
   // init global variables
   RangeGap       = PipsToDouble(InpRangeGapPips);
   StopLoss       = PipsToDouble(StopLoss);
   TakeProfit     = PipsToDouble(TakeProfit);
   
   BuyEntryPrice  = 0;
   SellEntryPrice = 0;
   
   Trade.SetExpertMagicNumber(InpMagic);
   
   // setup for starting time
   datetime now = TimeCurrent();
   EndTime      = SetEndTime(now + 60, InpRangeEndHour, InpRangeEndMinute);
   StartTime    = SetStartTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
   CuttOffTime  = SetCutOffTime(now + 60, InpCutOffHour, InpCutOffMinute);
   InRange      = (StartTime <= now && EndTime > now);
   
   
   /*
   MqlDateTime timeStruct;
   TimeToStruct(now, timeStruct );
   datetime fromTime;
   datetime toTime;
   
   bool output =  SymbolInfoSessionTrade( Symbol(), 
   (ENUM_DAY_OF_WEEK)timeStruct.day_of_week, 0, fromTime, toTime );
   
   Print(" Now: ", now, " || ", timeStruct);
   Print(" Start: ", StartTime, " End: ", EndTime, "\n");
   Print(" FromTime: ", fromTime, " ToTime: ", toTime);
   Print(" DATA FOR SESSION AVAILABLE: ", output);*/
   
   //SymbolInfoSessionTrade()
   
   //Print("NOW:", now," START:", StartTime, " END:", EndTime, " CUTTOFF:", CuttOffTime);
   
   /* RangeGap = NormalizeDouble(RangeGap, digits);   
   double RangeGapPips = DoubleToPips(RangeGap);
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   
   double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;
   Comment("\n\rMT5 SERVER TIME: ", TimeCurrent(), " (OPERATING AT UTC/GMT",
       StringFormat("%+.1f", offsetInHours),")", 
       " NOW: ", now, "\n\r\n\r",
       " END TIME: ", EndTime, "\n\r\n\r",
       " START TIME: ", StartTime, "\n\r\n\r",
       " CUTOFF TIME: ", CuttOffTime, "\n\r\n\r",
       " IN RANGE: ", InRange, "\n\r\n\r",
       " RANGE GAP: ", RangeGap, "\n\r\n\rT",
       " Range Gap Pips: ", RangeGapPips, "\n\r\n\r"
       );*/

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   
   datetime now = TimeCurrent();
   bool currentlyInRange = (StartTime <= now && now < EndTime);
   
   if(InRange && !currentlyInRange) { SetTradeEntryPrices();}
   
   // if we're out of range, then reset the range
   if(now >= EndTime) {
      EndTime   = SetEndTime(EndTime + 60, InpRangeEndHour, InpRangeEndMinute);
      StartTime = SetStartTime(EndTime, InpRangeStartHour, InpRangeStartMinute);
   }
      
   InRange = currentlyInRange;
   
   // check for any open positions
   int countBuy, countSell;
   if(!CountOpenPositions(countBuy, countSell)) {
      Print("====Failed to count open positions");
      return;
   }   
   if(countBuy > 0 || countSell > 0) {
      // PrintFormat("There are %d Buy and %d Sell Positions opened", countBuy, countSell);
      return;
   }
   
   //--- entering trades
   double currentPrice = 0;
   if (BuyEntryPrice > 0) {
      currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      if (currentPrice >= BuyEntryPrice) {
         OpenTrade(ORDER_TYPE_BUY, currentPrice);
         BuyEntryPrice  = 0;
         SellEntryPrice = 0;
         
         CuttOffTime = SetCutOffTime(now + 60, InpCutOffHour, InpCutOffMinute);
      }
   }
   
   if (SellEntryPrice > 0) {
      currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      //&& now < CuttOffTime
      if (currentPrice <= SellEntryPrice) {
         OpenTrade(ORDER_TYPE_SELL, currentPrice);
         BuyEntryPrice  = 0;
         SellEntryPrice = 0;
         
         CuttOffTime = SetCutOffTime(now + 60, InpCutOffHour, InpCutOffMinute);         
      }
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
//--- Count open positions
bool CountOpenPositions(int &countBuy, int &countSell) {
   countBuy = 0;
   countSell = 0;
   int total = PositionsTotal();
     
   for(int i = total-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) {
         Print("====Failed to get position Ticket");
         return false;
      }
      
      if(!PositionSelectByTicket(ticket)) {
         Print("====Failed to select position");
         return false;
      }
      
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {
         Print("====Failed to get position magic no.");
         return false;
      }
      
      if(magic != InpMagic) continue;
      
      long type;
      if(!PositionGetInteger(POSITION_TYPE, type)) {
         Print("====Failed to get position type");
         return false;
      }
      
      if(type == POSITION_TYPE_BUY) countBuy++;
      if(type == POSITION_TYPE_SELL) countSell++;
      
   }
   
   return true;
}

//--- Open New Order (Position) - Overloaded function
void OpenTrade( ENUM_ORDER_TYPE type, double price ) {   
   double sl = type == ORDER_TYPE_BUY ? price - StopLoss: price + StopLoss;
   double tp = type == ORDER_TYPE_BUY ? price + TakeProfit: price - TakeProfit;   
   OpenTrade(type, price, sl, tp);
}
//--- Over loaded function
bool OpenTrade(ENUM_ORDER_TYPE type, double price, double sl, double tp) {
   
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);   
   price = NormalizeDouble(price, digits);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   
   // setting lot size
   double volume = 0;
   if(InpRiskType == RISK_TYPE_FIXED_LOTS) {
      volume = InpRisk;
   } else if(InpRiskType == RISK_TYPE_EQUITY_PERCENT) {
      volume = GetRiskVolume(InpRisk/100, MathAbs(price - sl));
   }
   if(volume <= 0) {
      Print("==== Failed to enter trade, volume is 0");
      return false;
   }
   PrintFormat("@@@@@@@@@@@@@@ Opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f",
      EnumToString(type), volume, price, sl, tp);
   
   if (!Trade.PositionOpen( Symbol(), type, volume, price, sl, tp, InpTradeComment)) {
     PrintFormat( "===== Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString( type ), volume, price, sl, tp );
     return false;
   }

   return true;
}

// risk = fraction of equity to risk
// loss = price movement being risked
double GetRiskVolume( double risk, double loss ) {

   double equity     = AccountInfoDouble( ACCOUNT_EQUITY );
   double riskAmount = equity * risk; // risk in deposit currency

   double tickValue  = SymbolInfoDouble( Symbol(), SYMBOL_TRADE_TICK_VALUE ); // value of a tick in deposit currency
   double tickSize   = SymbolInfoDouble( Symbol(), SYMBOL_TRADE_TICK_SIZE );  // size of a tick price movement
   double lossTicks  = loss / tickSize;                                       // There may be rounding here, loss is in price movement

   double volume     = riskAmount / ( lossTicks * tickValue );
   volume            = NormaliseVolume(volume);

   return volume;
}

double NormaliseVolume(double volume) {

   if (volume <= 0) return 0; // nothing to do

   double max    = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double min    = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double step   = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   double result = MathRound(volume / step) * step;
   if (result > max) result = max;
   if (result < min) result = min;

   return result;
}

void SetTradeEntryPrices() {

   int    startBar = iBarShift( Symbol(), PERIOD_M1, StartTime, false );
   int    endBar   = iBarShift( Symbol(), PERIOD_M1, EndTime - 60, false );

   double high     = iHigh( Symbol(), PERIOD_M1, iHighest( Symbol(), PERIOD_M1, MODE_HIGH, startBar - endBar + 1, endBar ) );
   double low      = iLow( Symbol(), PERIOD_M1, iLowest( Symbol(), PERIOD_M1, MODE_LOW, startBar - endBar + 1, endBar ) );

   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   double midPoint = NormalizeDouble(MathAbs(high + low) / 2, digits);
   double slPips = DoubleToPips(NormalizeDouble(MathAbs(high - midPoint), digits));
   double tpPips = slPips * InpMultiplier;
   
   BuyEntryPrice   = high + RangeGap;
   SellEntryPrice  = low - RangeGap;
   
   StopLoss = PipsToDouble(slPips);
   TakeProfit = PipsToDouble(tpPips);  
}

datetime SetEndTime(datetime now, int hour, int minute) {

   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);

   nowStruct.sec     = 0;
   datetime nowTime  = StructToTime(nowStruct);

   nowStruct.hour    = hour;
   nowStruct.min     = minute;
   datetime endTime = StructToTime(nowStruct);

   while (endTime < nowTime || !IsTradingDay(endTime)) {
      endTime += 86400;
   }

   return endTime;
}

datetime SetStartTime(datetime now, int hour, int minute) {

   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);

   nowStruct.sec     = 0;
   datetime nowTime  = StructToTime(nowStruct);

   nowStruct.hour    = hour;
   nowStruct.min     = minute;
   datetime startTime = StructToTime(nowStruct);

   while (startTime >= nowTime || !IsTradingDay(startTime)) {
      startTime -= 86400;
   }

   return startTime;
}

datetime SetCutOffTime(datetime now, int hour, int minute) {

   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);

   nowStruct.sec     = 0;
   datetime nowTime  = StructToTime(nowStruct);

   nowStruct.hour    = hour;
   nowStruct.min     = minute;
   datetime cutOffTime = StructToTime(nowStruct);

   while (cutOffTime < nowTime || !IsTradingDay(cutOffTime)) {
      cutOffTime += 86400;
   }

   return cutOffTime;
}

bool IsTradingDay(datetime time ) {

   MqlDateTime timeStruct;
   TimeToStruct( time, timeStruct );
   datetime fromTime;
   datetime toTime;
   return SymbolInfoSessionTrade( Symbol(), ( ENUM_DAY_OF_WEEK )timeStruct.day_of_week, 0, fromTime, toTime );
}

double DoubleToPips(double value) {
    return DoubleToPips(Symbol(), value);
}

double DoubleToPips(string symbol, double value) {
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

    if (digits == 3 || digits == 5) {
        value /= 10;
    }

    return value / point;
}

double PipsToDouble(double pips) { return PipsToDouble(Symbol(), pips); }
double PipsToDouble(string symbol, double pips) {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if ( digits == 3 || digits == 5 ) {
      pips = pips * 10;
   }
   double value = pips * SymbolInfoDouble(symbol, SYMBOL_POINT);
   return value;
}


bool IsInputsValid () {
   bool inputsOK = true;

   // Validate start and end are valid times
   if ( InpRangeStartHour < 0 || InpRangeStartHour > 23 ) {
      Alert( "Start hour must be in the range from 0-23" );
      inputsOK = false;
   }

   if ( InpRangeStartMinute < 0 || InpRangeStartMinute > 59 ) {
      Alert( "Start minute must be in the range from 0-59" );
      inputsOK = false;
   }

   if ( InpRangeEndHour < 0 || InpRangeEndHour > 23 ) {
      Alert( "End hour must be in the range from 0-23" );
      inputsOK = false;
   }

   if ( InpRangeEndMinute < 0 || InpRangeEndMinute > 59 ) {
      Alert( "End minute must be in the range from 0-59" );
      inputsOK = false;
   }

   if ( InpRangeGapPips <= 0 ) {
      Alert( "Range Gap must be > 0" );
      inputsOK = false;
   }

   if ( InpRisk <= 0 ) {
      Alert( "Risk must be > 0" );
      inputsOK = false;
   }
   
   return inputsOK;
}