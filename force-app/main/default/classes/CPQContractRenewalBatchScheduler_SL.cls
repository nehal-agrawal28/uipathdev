global class CPQContractRenewalBatchScheduler_SL implements Schedulable {
  global void execute(SchedulableContext ctx) {
    Database.executeBatch(new CPQContractRenewalBatch_SL(), 1);
  }
}