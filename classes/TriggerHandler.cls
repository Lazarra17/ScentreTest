/**
 ** Comments: Used to controll which trigger to bypass and execute.
 ** Date Provided: 18-04-2018
 ** Owner: Accenture PLC
 ** Confidential. This document incorporates information that is proprietary to Accenture. 
 ** The Accenture information in this document is supplied in confidence and, except for any purposes agreed by the parties, 
 ** should not be disclosed, duplicated or otherwise revealed in whole or in part without the prior written consent of Accenture
 **/
public virtual class TriggerHandler {

  // static map of handlername, times run() was invoked
  public static Set<String> bypassedHandlers;
  //public static Map<String, DescribeSObjectResult> objectDescribeResult;
  public static Map<String,ITrigger> handlerInstances ;
  // static initialization
  static {
    bypassedHandlers = new Set<String>();
    handlerInstances = new Map<String,ITrigger>(); //RPP-10922
  }
  
  // constructor
  public TriggerHandler() {

  }

  /***************************************
   * public static methods
   ***************************************/

  public static void bypass(String handlerName) {
    TriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    TriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return TriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    TriggerHandler.bypassedHandlers.clear();
  }


  // exception class
  public class TriggerHandlerException extends Exception {}

}