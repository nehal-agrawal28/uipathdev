public class Portal_ViewOpportunity {

    @AuraEnabled
    public static Opportunity LoadOpportunity(string oppId) {
        /*return [SELECT Id, Name, Client__c, Opportunity_Vertical__c, Client_s_Billing_Country__c, Client_Project_Name__c,
                        Client_Contact_Email__c, Contract_Duration__c, Potential_Opportunity_Value__c, Description,
                        Products_offered__c, Working_with_other_partners_on_this_opp__c, Other_Partners_Involved__c
                FROM Opportunity WHERE Id = :oppId];*/
                return null;
    }
    
}