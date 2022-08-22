public with sharing class QuoteScheduleInsightController
{
	// Prevent instantiation of this class
	private QuoteScheduleInsightController(){}

	@AuraEnabled(Cacheable=true)
	public static List<Data> getQuoteScheduleInsight(String quoteId)
	{
		try
		{
			System.debug('QuoteId: '+quoteId);
			QuoteScheduleConditions_PP resolvedQuoteData =
					PartnerDiscountSchedulesService_PP.resolveQuoteScheduleConditions(
							Quotes_PP.newInstance(new Set<Id> { Id.valueOf(quoteId)})
					);
			System.debug('resolvedQuoteData: '+resolvedQuoteData);

			return getDataList(resolvedQuoteData);
		}
		catch (Exception e)
		{
			AuraHandledException auraException = new AuraHandledException(e.getMessage());
			auraException.setMessage(e.getStackTraceString());
			throw auraException;
		}
	}

	private static List<Data> getDataList(QuoteScheduleConditions_PP resolvedQuoteData)
	{
		List<Data> result = new List<Data>();
		for (QuoteScheduleConditions_PP.Record record : (List<QuoteScheduleConditions_PP.Record>) resolvedQuoteData.getObjects())
		{
			result.add(new Data(record));
		}
		return result;
	}

	public class Data
	{
		@AuraEnabled public Boolean isApplicable;
		@AuraEnabled public Decimal sequence;
		@AuraEnabled public String scheduleName;
		@AuraEnabled public String formula;
		@AuraEnabled public String evaluatedFormula;

		public Data(QuoteScheduleConditions_PP.Record record)
		{
			this.isApplicable = record.isApplicable;
			this.sequence = record.schedule.Sequence__c;
			this.scheduleName = record.schedule.Name;
			this.formula = record.schedule.ConditionFormula__c;
			this.evaluatedFormula = record.resolvedFormula;
		}
	}
}