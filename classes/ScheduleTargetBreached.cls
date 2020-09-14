global class ScheduleTargetBreached implements schedulable
{
    global void execute(SchedulableContext sc){
      UpdateOpptyTargetBreached b = new UpdateOpptyTargetBreached(); //ur batch class
      database.executebatch(b,200);
    }
}