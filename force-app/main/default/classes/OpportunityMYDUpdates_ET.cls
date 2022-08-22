/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is OpportunityMYDUpdates class
 */
public class OpportunityMYDUpdates_ET implements IGenericBatch {
  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    List<Opportunity> updateOpps = new List<Opportunity>();
    for (Opportunity opp : (List<Opportunity>) sobjectList) {
      opp.Closed_Territory__c = opp.Territory2.Name;
      updateOpps.add(opp);
    }
    try {
      Database.SaveResult[] saveResults = Database.update(updateOpps, false);
      Logger.debug(new LogMessage('Opportunity Closed_Territory__c Result', ''), saveResults);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Opportunity Closed_Territory__c failed', ex.getLineNumber()));
    } finally {
      logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
  }
}