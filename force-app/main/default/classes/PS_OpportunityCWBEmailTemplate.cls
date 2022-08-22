/*******************************************************************************
* @author         : SalesTech Team
* @date           : July 2021
* @description    : Class is used as a controller for vf component PS_OpportunityCWBEmailTemplate 
					It is used for ps email template to pmo for CWB / CWP Opp
* @Revisions      :
        #1        : Created 
*******************************************************************************/
public with sharing class PS_OpportunityCWBEmailTemplate {
	
    // Opportunity Id
    public String oppId{
        				get;
        				set{
                            	oppId = value;queryQuoteLines();
                       	}
    					} 
    
    // List of quote lines
    public List<SBQQ__QuoteLine__c> quoteLines{get;set;}
    
    // Opp link used in email template
    public string oppLink{get;set;}
    
    // Opportunity name
    public string oppName{get;set;}
    
    // Opportunity status
    public string oppStatus{get;set;}
    
    // This method queries quote lines related to primary quote
    private void queryQuoteLines(){
        if(!String.isBlank(oppId) && quoteLines == null){
			List<Opportunity> oppList = [SELECT Id, Name, SBQQ__PrimaryQuote__c, StageName
                                       	FROM Opportunity
                                       WHERE ID=: oppId];
            if(!oppList.isEmpty()){
                oppName = oppList[0].Name;
                oppStatus =  oppList[0].StageName;
                oppLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+oppList[0].id;
                quoteLines = [SELECT id,SBQQ__ProductName__c, SBQQ__ListPrice__c, CRT__c 
                              FROM SBQQ__QuoteLine__c 
                              WHERE SBQQ__Quote__c =: oppList[0].SBQQ__PrimaryQuote__c];
            }
        }
    }

    
}