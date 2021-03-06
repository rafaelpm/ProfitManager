//+------------------------------------------------------------------+
//|                                                ProfitManager.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

input int PipsGainMax = 1400;
input int PipsStop = 300;
//Spread was fixed because they always return with zero in my broker.
input int Spread = 5;

//When arriving in the first price target, the stop loss is a moved to the second price
//This was adjusted to work with indices in Brazil
int TPs[] = {      
   100,50,//Target price 100, so move to 50
   200,100,   
   300,200,   
   400,300,
   450,400,   
   500,450,
   550,500,
   600,500,
   700,600,
   800,700,
   900,800,
   1000,900,
   1100,1000,
   1200,1100,
   1300,1200,
   1400,1300,
   1500,1400};
   
int totalTPs = 0;

//+------------------------------------------------------------------+
int getPIPs(double Price1, double Price2){
   return (int)((Price1-Price2)/Point());
}
//+------------------------------------------------------------------+
double getNewPrice(double Price, int pips){
   return ND(pips * Point()) + Price;
}
//+------------------------------------------------------------------+
double ND(double v){
   v = MathCeil(v);         
   int rest = (int)v;   
   rest %= Spread;   
   v -= rest;
   return NormalizeDouble(v,Digits());   
}
//+------------------------------------------------------------------+
MqlTick tick_last;
void ManagerStop(){   
   int total=PositionsTotal();   
   double open=0, last=0, tp=0, sl=0;
   int stopPips = 0, vol = 0, type=0;
   int pips=0;
   ulong ticket = 0;   
   bool updateStop = false;
       
   SymbolInfoTick(Symbol(),tick_last);
         
   for(int pos=0;pos<total;pos++){  
      ticket = PositionGetTicket(pos);
      if(ticket <= 0){      
         continue;
      }
         
      type = (int)PositionGetInteger(POSITION_TYPE);
      sl = ND(PositionGetDouble(POSITION_SL));
      open = ND(PositionGetDouble(POSITION_PRICE_OPEN));
      tp = ND(PositionGetDouble(POSITION_TP));
      
      last = PositionGetDouble(POSITION_PRICE_CURRENT);
      last = tick_last.last;
      
      if(sl == 0){
         //Set PipsStop
         if(type == POSITION_TYPE_SELL){            
            sl = getNewPrice(open,PipsStop);
         }else{
            sl = getNewPrice(open,-PipsStop);
         }
         trade.PositionModify(ticket,sl,tp);
      }
      
      if(tp == 0){
         //Set PipsGainMax
         if(type == POSITION_TYPE_SELL){            
            tp = getNewPrice(open,-PipsGainMax);
         }else{
            tp = getNewPrice(open,PipsGainMax);
         }
         trade.PositionModify(ticket,sl,tp);
      }
      
      if(type == POSITION_TYPE_SELL){
         //Sell
         pips = getPIPs(open,last);         
         stopPips = getPIPs(open,sl);         
      }else{
         //Buy
         pips = getPIPs(last, open);
         stopPips = getPIPs(sl, open);
      }            
      
      updateStop = false;
      
      for(int i=0; i < totalTPs; i+=2){
         if(pips >= TPs[i]){
            //Change stop to the next TP
            if(stopPips >= TPs[i+1]){
               continue;
            }
                              
            if(type == POSITION_TYPE_SELL){
               //Sell
               sl = getNewPrice(open,-TPs[i+1]);
            }else{
               //Buy
               sl = getNewPrice(open,TPs[i+1]);
            }
            printf("Stop moved to +"+IntegerToString(TPs[i+1]));
            updateStop = true;                                  
         }                  
      }
      
      if(updateStop){
         updateStop = false;
         if(!trade.PositionModify(ticket,sl,tp)){
            printf("Error when move stop: "+trade.ResultComment());
         }  
      }      
            
   }   
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   totalTPs = ArraySize(TPs);   
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   ManagerStop();
   
//---
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
void OnTick()
  {
//---
   ManagerStop();
  }
//+------------------------------------------------------------------+
