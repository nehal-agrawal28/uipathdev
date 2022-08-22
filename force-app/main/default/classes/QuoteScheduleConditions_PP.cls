public with sharing class QuoteScheduleConditions_PP extends fflib_Objects {
  public static QuoteScheduleConditions_PP newInstance(List<QuoteScheduleConditions_PP.Record> records) {
    return new QuoteScheduleConditions_PP(records);
  }

  public QuoteScheduleConditions_PP(List<QuoteScheduleConditions_PP.Record> records) {
    super(records);
  }

  public IDiscountSchedules_PP selectApplicableSchedules() {
    List<DiscountSchedule__c> result = new List<DiscountSchedule__c>();
    for (Record record : (List<Record>) getObjects()) {
      if (record.isApplicable == false)
        continue;

      result.add(record.schedule);
    }
    return DiscountSchedules_PP.newInstance(result);
  }

  public with sharing class Record {
    public SBQQ__Quote__c quote;
    public DiscountSchedule__c schedule;
    public String resolvedFormula;
    public Boolean isApplicable;

    public Record(SBQQ__Quote__c quote, DiscountSchedule__c schedule, String resolvedFormula, Boolean isApplicable) {
      this.quote = quote;
      this.schedule = schedule;
      this.resolvedFormula = resolvedFormula;
      this.isApplicable = isApplicable;
    }
  }
}