//+------------------------------------------------------------------+
//|                                        RSIExpertM15_Backtest.mq4 |
//|                     Copyright 2017, investdata.000webhostapp.com |
//|                             https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, investdata.000webhostapp.com"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.00"
#property strict

bool enableFileLog=false;
int file_handle=INVALID_HANDLE; // File handle
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//string exportPath = "C:\\Users\\InvesdataSystems\\Documents\\NetBeansProjects\\investdata\\public_html\\alerts\\data_history";

int OnInit()
  {
   LastBarTime=-1;

   printf("exportDir = "+TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

   if(enableFileLog)
     {
      string strPeriod=EnumToString((ENUM_TIMEFRAMES)Period());
      StringReplace(strPeriod,"PERIOD_","");
      file_handle=FileOpen(Symbol()+"_"+strPeriod+"_"+timestamp+"_backup.csv",FILE_CSV|FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle>0)
        {
         string sep=",";
         FileWrite(file_handle,"Timestamp"+sep+"Name"+sep+"Buy"+sep+"Sell"+sep+"Spread"+sep+"Broker"+sep+"Period"+sep+"RSI"+sep+"Momentum");
        }
      else
        {
         printf("error : "+GetLastError());
        }
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   ObjectDelete(0,"Text");

   if(enableFileLog)
     {
      FileClose(file_handle);
     }

/*if (reason==3){
      printf("deinit reason = REASON_CHARTCHANGE");
   }*/

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

MqlDateTime mqd_ot;
MqlTick last_tick_ot;

static datetime LastBarTime;//=-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//int oht = OrdersHistoryTotal();
//printf("Orders Hitsory Total = " + IntegerToString(oht));

   string sname=Symbol();

   MqlTick last_tick;
   double prix_achat;
   double prix_vente;
   double spread;

   bool positionFound=false; // To scan for open positions for current symbol
   int total=OrdersTotal();
   for(int pos=0;pos<total;pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
      //printf(OrderTicket()+" "+OrderOpenPrice()+" "+OrderOpenTime()+" "+OrderSymbol()+" "+OrderLots());

      bool closeOrderIfProfitOver=false;
      if(OrderProfit()>1)
        {
         if(closeOrderIfProfitOver)
           {
            bool b=OrderClose(OrderTicket(),0.1,prix_achat,0,Red);
           }
        }

      if(OrderSymbol()==sname)
        {
         positionFound=true;
        }
     }

   if(positionFound==false)
     {

      bool isNewJapaneseCandlestick=false;
      datetime ThisBarTime=(datetime)SeriesInfoInteger(sname,Period(),SERIES_LASTBAR_DATE);
      if(ThisBarTime==LastBarTime)
        {
         //same japanese candlestick
         //printf("same jcs");
        }
      else 
        {
         if(LastBarTime==-1)
           {
            //first japanese candlestick
            LastBarTime = ThisBarTime;
            
            //printf("first jcs");
           }
         else 
           {
            // new japanese candlestick
            LastBarTime=ThisBarTime;

            //printf("new jcs");
            isNewJapaneseCandlestick=true;
           }
        }

      // Here, if we are not on a new japanese candlestick then processing is ended.
      if(!isNewJapaneseCandlestick) return;

      const int NUMBER_OF_JCS=8;
      // Obtention des données bougies japonaises
      double open_array[];
      double high_array[];
      double low_array[];
      double close_array[];
      ArraySetAsSeries(open_array,true);
      int numO=CopyOpen(sname,Period(),0,NUMBER_OF_JCS,open_array);
      ArraySetAsSeries(high_array,true);
      int numH=CopyHigh(sname,Period(),0,NUMBER_OF_JCS,high_array);
      ArraySetAsSeries(low_array,true);
      int numL=CopyLow(sname,Period(),0,NUMBER_OF_JCS,low_array);
      ArraySetAsSeries(close_array,true);
      int numC=CopyClose(sname,Period(),0,NUMBER_OF_JCS,close_array);

      // Obtention des données de l'indicateur Ichimoku
      double cs26=iIchimoku(sname,Period(),9,26,52,MODE_CHIKOUSPAN,26);
      double cs27=iIchimoku(sname,Period(),9,26,52,MODE_CHIKOUSPAN,27);
      double tenkan_sen=iIchimoku(sname,Period(),9,26,52,MODE_TENKANSEN,1);
      double kijun_sen=iIchimoku(sname,Period(),9,26,52,MODE_KIJUNSEN,1);
      double ssa=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,1); // ssa bougie precedente
      double ssb=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,1); // ssb bougie precedente
      double ssa26=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,26); // ssa bougie precedente
      double ssb26=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,26); // ssb bougie precedente
      double ssa27=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,27); // ssa bougie precedente
      double ssb27=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,27); // ssb bougie precedente

      double rsi14=iRSI(sname,Period(),14,PRICE_CLOSE,0);
      double rsi14prev=iRSI(sname,Period(),14,PRICE_CLOSE,1);
      double m=iMomentum(sname,Period(),14,PRICE_CLOSE,0);
      double mprev=iMomentum(sname,Period(),14,PRICE_CLOSE,1);

      if(
         open_array[1]<ssa26
         && open_array[1]<ssb26
         && close_array[1]>ssa26
         && close_array[1]>ssb26
         )
        {
         printf(sname+": JCS(-1) is crossing over KUMO");
         printf("rsi14=" + DoubleToString(rsi14) + " momentum=" + DoubleToString(m));
         if (rsi14>=65){
            Buy(sname, last_tick);
         }         
        }

      if(
         (rsi14>=60) && (rsi14prev<60)
         && (m>=100.12)
         )
        {
         //printf("Will buy now");
         //Buy(sname,last_tick);

        }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Buy(string sname, MqlTick &last_tick)
  {  
   double prix_achat;
   double prix_vente;
   double spread;

   SymbolInfoTick(sname,last_tick);
   prix_achat = last_tick.ask;
   prix_vente = last_tick.bid;

   double stoploss=0;//prix_achat - 0.00025*2;//prix_achat-0.00100;
   //double takeprofit=prix_achat+spread+0.00025;
   double takeprofit=prix_achat+spread+prix_achat/100*0.1;

   bool enableTrading=true;
   if(enableTrading)
     {
      int ticket=OrderSend(sname,OP_BUY,0.5,prix_achat,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
      if(ticket<0)
        {
         Print(sname+" : OrderSend failed with error #",GetLastError());
         printf("pa="+DoubleToString(prix_achat));
        }
      else
         Print(sname+" : OrderSend placed successfully");
     }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

void OnTimer()
  {
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
