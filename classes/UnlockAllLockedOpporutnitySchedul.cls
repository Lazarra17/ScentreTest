global class UnlockAllLockedOpporutnitySchedul implements Schedulable {
      global void execute(SchedulableContext ctx) {
          
          UnlockAllLockedOpporutnity batchOppUnlock = new UnlockAllLockedOpporutnity();
          database.executeBatch(batchOppUnlock,2000);
      }
    
}