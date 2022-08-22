//Slalom
//v0.1 - Baseline version
//v0.2 - 24-Jan-19 -added control for Opps at Closed Won Pending or above -> should not be presented with merge candidates

public with sharing class OpportunityListController {
    @AuraEnabled
    public static List<Opportunity> getOpportunitiesForAccount(Id oppId) {
        // Check for null arguments
        if (oppId == null) {
            return new List<Opportunity>();
        }

        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_OpportunityListController__c FROM CPQ_Controls__mdt LIMIT 1];

            if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null){
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }
        /** **/

        // Get the setting for the Stage Name
        Opportunity_Merge__mdt oppMergeSettings = [SELECT Months_Ahead__c, Months_Prior__c, TypeNamesToExclude__c FROM Opportunity_Merge__mdt WHERE MasterLabel = 'Default' LIMIT 1];

        // Get this Opportunity record data
        Opportunity o = [SELECT AccountId, CloseDate, CurrencyIsoCode, Probability FROM Opportunity WHERE Id = :oppId];

        //Opp at Closed Won Pending or above -> should not be presented with merge candidates
        if(o.Probability >= 95){
            return new List<Opportunity>();
        }

        Date oppCloseDate = Date.valueOf(o.CloseDate);
        Date monthsPrior = oppCloseDate.addMonths(Integer.valueOf(String.valueOf(oppMergeSettings.Months_Prior__c)));
        Date monthsAhead = oppCloseDate.addMonths(Integer.valueOf(String.valueOf(oppMergeSettings.Months_Ahead__c)));

        // Split the TypeNamesToExclude__c field into a list of Strings
        String[] typeNamesToExclude = oppMergeSettings.TypeNamesToExclude__c.split(',');

        List<Opportunity> opps = new List<Opportunity>();

        //CPQ controls
        //1. if CPQ RT isn't set OR CPQ RT is set AND CPQ inclusion is enabled - normal operation
        if(cpqRtId == null || (cpqRtId != null && cpqControls.Opp_C_OpportunityListController__c)){
            // Get a list of Opportunities that belong to the same account (but don't return the Opp that has the Id passed to this method)
            opps = [
                    SELECT Id, Name, Amount, StageName, CloseDate, Owner.Name
                    FROM Opportunity
                    WHERE AccountId = :o.AccountId
                    AND Id != :oppId
                    AND HasOpportunityLineItem = True
                    AND CloseDate > :monthsPrior
                    AND CloseDate < :monthsAhead
                    AND IsClosed != True
                    AND Type NOT IN :typeNamesToExclude
                    AND CurrencyIsoCode = :o.CurrencyIsoCode
            ];

        }
        else{
            // Get a list of Opportunities that belong to the same account (but don't return the Opp that has the Id passed to this method or the CPQ opp)
            opps = [
                    SELECT Id, Name, Amount, StageName, CloseDate, Owner.Name
                    FROM Opportunity
                    WHERE AccountId = :o.AccountId
                    AND Id != :oppId
                    AND HasOpportunityLineItem = True
                    AND CloseDate > :monthsPrior
                    AND CloseDate < :monthsAhead
                    AND IsClosed != True
                    AND Type NOT IN :typeNamesToExclude
                    AND CurrencyIsoCode = :o.CurrencyIsoCode
                    AND RecordTypeId !=: cpqRtId
            ];
        }



        return opps;
    }
}