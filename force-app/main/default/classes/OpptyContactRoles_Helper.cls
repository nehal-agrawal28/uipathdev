/**********************************************************
 * @className   : OpptyContactRoles_Helper.cls
 * @testClass   : OpptyContactRolesTrg_TEST.cls
 * @author      : Marian Iovi (marian.iovi@deutoria.com)
 * @date        : April 11, 2018
 * @updated by  : Mirela Chituc (mirela.chituc@uipath.com)
 * @date date   : Oct 10, 2019
 **********************************************************/ 

public class OpptyContactRoles_Helper  {

    public static Boolean rollUpSumContactRolesFirstRun = true;

    // ============================================================================
    // added by Mirela Chituc - 10/10/2019 ========================================
    // clones Partner_Involvement__c from the original opps to the newly created amendeded / renewal opps
    // ============================================================================
    
    /*public static void clonePartnerInvolvment(List<Opportunity> newOppties){
       
        // add restriction based on record type
        Id CPQrecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CPQ_Default').getRecordTypeId();

        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp: newOppties)  {
            // if newly created opp is an amended or a renewal opportunity take the opps ids
            if(opp.RecordTypeId == CPQrecordTypeId && (opp.SBQQ__AmendedContract__c != null || (opp.SBQQ__RenewedContract__c != null && opp.SBQQ__Renewal__c == true)))
                oppIds.add(opp.Id);
        }
        
        if(oppIds.size() > 0) {
            // select all amendeded / renewal opps retrieving the original opportunity Id from the related contract
            List<Opportunity> allOpps = [SELECT Id, SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__c, 
                                            SBQQ__RenewedContract__c, SBQQ__RenewedContract__r.SBQQ__Opportunity__c, SBQQ__Renewal__c 
                                            FROM Opportunity WHERE Id IN: oppIds];
                                            
            Map<Id, Id> oppsMap = new Map<Id, Id>();
            // Itereate through all opportunities and populate a map with original opp Id as key and newly created opp as a value
            for(Opportunity opp: allOpps) {
                if(opp.SBQQ__AmendedContract__c != null) 
                    oppsMap.put(opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c, opp.Id);
                if(opp.SBQQ__RenewedContract__c != null && opp.SBQQ__Renewal__c == true) 
                    oppsMap.put(opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__c, opp.Id);
            }
            
            if(oppsMap.size() > 0) {
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Partner_Involvement__c').getDescribe().Fields.getMap();
                List<String> selectFields = new List<String>();
                     
                if (fieldMap != null){
                    // loop through all field tokens
                    for (Schema.SObjectField ft : fieldMap.values()) {  
                        // describe each field
                        Schema.DescribeFieldResult fd = ft.getDescribe(); 
                        if (fd.isCreateable()){ // field is creatable
                            selectFields.add(fd.getName());
                        }
                    }
                }
                
                // make a string with all creatable fields separated by coma
                String selectFieldsQuery = ''; 
                if (!selectFields.isEmpty()){
                    for (string s:selectFields){
                        selectFieldsQuery += s + ',';
                    }
                    if (selectFieldsQuery.endsWith(',')){
                        selectFieldsQuery = selectFieldsQuery.substring(0, selectFieldsQuery.lastIndexOf(','));
                    }
                }
                 
                // Get all related Partner Involvment records related to the original opportunities
                Set<Id> oppsMapKeys = oppsMap.keySet();
                List<Partner_Involvement__c> allPartnerInvolvments = Database.query('SELECT ' + selectFieldsQuery + ' FROM Partner_Involvement__c WHERE PartnerOpp_Name__c IN :oppsMapKeys');
                
                // Populate a map with original opp id as a key and a list with related Partner_Involvement__c as value
                Map<Id, List<Partner_Involvement__c>> partnerInvolvmentMap = new Map<Id, List<Partner_Involvement__c>>();
                for(Partner_Involvement__c pi: allPartnerInvolvments) {
                    if(!partnerInvolvmentMap.containskey(pi.PartnerOpp_Name__c)) {
                        partnerInvolvmentMap.put(pi.PartnerOpp_Name__c, new List<Partner_Involvement__c> { pi });
                    } else {
                        List<Partner_Involvement__c> piList = partnerInvolvmentMap.get(pi.PartnerOpp_Name__c);
                        piList.add(pi);
                        partnerInvolvmentMap.put(pi.PartnerOpp_Name__c, piList);
                    }
                }
                
                List<Partner_Involvement__c> partnerInvolvmentToInsert = new List<Partner_Involvement__c>();
                // go through a the map get the 
                for(Id oppId: partnerInvolvmentMap.keySet()) {
                    // get the Partner_Involvement__c list related to each original opportunity
                    List<Partner_Involvement__c> currentPartnerInvolvementList = partnerInvolvmentMap.get(oppId);
                    // get related new created opp
                    Id newlyCreatedOppId = oppsMap.get(oppId);
                    // clone each Partner_Involvement__c and change PartnerOpp_Name__c with the coresponding newly created opp Id
                    for(Partner_Involvement__c pi: currentPartnerInvolvementList) {
                        Partner_Involvement__c newPi = pi.clone();
                        newPi.PartnerOpp_Name__c = newlyCreatedOppId;
                        // add cloned records to a list
                        partnerInvolvmentToInsert.add(newPi);
                    }
                }
                
                // insert cloned Partner_Involvement__c records related to the new opportunities
                if(partnerInvolvmentToInsert.size() > 0)
                    insert partnerInvolvmentToInsert;
            }
        }
    }*/
    
    // ============================================================================
    // added by Mirela Chituc - 10/21/2019 ========================================
    // Sets up Customer Status
    // ============================================================================
    // commented by Vali Coteanu - 07/15/2020 =====================================
    // this was never running as it never had the "after update" parameter
    // and it does nothing
    // ============================================================================
    
    /*
    public static void setCustomerStageOnAccount(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap) {
        
        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp: oppList) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if(opp.StageName == 'Closed Won Booked' && opp.StageName != oldOpp.StageName )
                accIds.add(opp.AccountId);
        }
        
        if(accIds.size() > 0) {
            List<Account> AccountsToUpdate = [SELECT Id FROM Account WHERE Id IN: accIds];
            update AccountsToUpdate;
        }
    }
	*/
    
    // =============================================================================================
    // @description  : This method calculates the number of Contact Roles related to an opportunity 
    // =============================================================================================
    
    /*public static void rollUpSumContactRoles(List<Opportunity> newOppties){

        // SLTECH-20917 Fix: Renewal Opportunity Creation Failing with SOQL 101
        if(!rollUpSumContactRolesFirstRun){
            return;
        }
        rollUpSumContactRolesFirstRun = false;

        Set<Id> opptyIds = new Set<Id>();
        for (Opportunity oppty: newOppties){ 
            opptyIds.add(oppty.Id);
        }//end for
        
        //get All OpportunityContactRoles based on opptyIds
        List<OpportunityContactRole> allOpptyCRs = [Select Id, OpportunityId FROM OpportunityContactRole 
                                                                WHERE OpportunityId IN :opptyIds AND OpportunityId != null];

        //calculate the number of Contact Roles related to an opportunity
        Map<Id, Integer> countCRsMap = new Map<Id, Integer>();
        for(OpportunityContactRole opptyCR: allOpptyCRs){
            if (countCRsMap.get(opptyCR.OpportunityId) != null){
                Integer newValue = countCRsMap.get(opptyCR.OpportunityId) + 1;
                countCRsMap.put(opptyCR.OpportunityId, newValue);
            }else
                countCRsMap.put(opptyCR.OpportunityId, 1);
        }

        //update Total_Contact_Roles__c field from opportunity records
        for(Opportunity oppty: newOppties){
            if (countCRsMap.get(oppty.Id) != null)
                oppty.Total_Contact_Roles__c = countCRsMap.get(oppty.Id);
            else oppty.Total_Contact_Roles__c = 0;
        }
    }*/

}