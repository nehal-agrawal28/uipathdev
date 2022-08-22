public without sharing class OpportunityContactRoleHandlerAll
{
    public static void setOutreachFirstPrimaryContact(List<OpportunityContactRole> opcCntRoleList, Map<Id, OpportunityContactRole> opcCntRoleMap) {
        Set<Id> oppSet = new Set<Id>();
        for(OpportunityContactRole ocr: opcCntRoleList) {
            if(opcCntRoleMap == null)  {
                if(ocr.IsPrimary == true) 
                    oppSet.add(ocr.OpportunityId);    
            } else {
                OpportunityContactRole opcOld = opcCntRoleMap.get(ocr.Id);
                if(ocr.IsPrimary != opcOld.IsPrimary) 
                    oppSet.add(ocr.OpportunityId);
            }
             
        }
        
        if(oppSet.size() > 0) {
            List<Opportunity> toUpdateOpps = new List<Opportunity>();
            List<Opportunity> opps = [SELECT Id, Outreach_First_Primary_Contact_Sequence__c, (SELECT Id, ContactId, Contact.Outreach_Current_Sequence_Name__c FROM OpportunityContactRoles WHERE IsPrimary = TRUE) FROM Opportunity WHERE Id IN: oppSet];
            for(Opportunity opp: opps) {
                if((opp.OpportunityContactRoles).size() == 1) {
                    opp.Outreach_First_Primary_Contact_Sequence__c = opp.OpportunityContactRoles[0].Contact.Outreach_Current_Sequence_Name__c;
                    toUpdateOpps.add(opp);
                }
            }
            if(toUpdateOpps.size() > 0)
                update toUpdateOpps;
        }  
    }
    
    public static void setMarketingSourced(List<OpportunityContactRole> opcCntRoleList) {
        
        set<Id> contactIds = new set<Id>();
        set<Id> opportunityIds = new set<Id>();
        
        for(OpportunityContactRole ocr: opcCntRoleList) {
            contactIds.add(ocr.ContactId);
            opportunityIds.add(ocr.OpportunityId);
        }
        
        Map<Id, Lead> convertedContacts = new Map<Id, Lead>();
        for(Lead l: [SELECT Id, ConvertedContactId, MQL_Date_Time__c FROM Lead WHERE ConvertedContactId IN: contactIds])
            convertedContacts.put(l.ConvertedContactId, l);
        Map<Id, Opportunity> oppNotRenewals = new Map<Id, Opportunity>([SELECT Id, CreatedDate FROM Opportunity WHERE Type != 'Renewal' AND Id IN :opportunityIds]);
        
        List<Opportunity> OpportunityToUpdate = new List<Opportunity>();
        for(OpportunityContactRole ocr: opcCntRoleList) {
            if(convertedContacts.containsKey(ocr.ContactId) && oppNotRenewals.containsKey(ocr.OpportunityId)) {
                DateTime leadMQLDateTime = convertedContacts.get(ocr.ContactId).MQL_Date_Time__c;
                DateTime oppCreatedDateTime = oppNotRenewals.get(ocr.OpportunityId).CreatedDate ;
                if(leadMQLDateTime < oppCreatedDateTime) {
                    Opportunity opp = oppNotRenewals.get(ocr.OpportunityId);
                    opp.Marketing_Sourced__c = true;
                    OpportunityToUpdate.add(opp); 
                }
            }
        }
        if(OpportunityToUpdate.size() > 0) {
            update OpportunityToUpdate;
        }
    }
    
    // public static void setOppPrimaryContact(List<OpportunityContactRole> opcCntRoleList, Map<Id, OpportunityContactRole> opcCntRoleMap) {
    //     Set<Id> oppSet = new Set<Id>();
        
    //     for(OpportunityContactRole ocr: opcCntRoleList) 
    //     {
    //         if(opcCntRoleMap == null) 
    //         {
    //             if(ocr.IsPrimary == true) 
    //             {
    //                 oppSet.add(ocr.OpportunityId);
    //             }    
    //         } else {
    //             OpportunityContactRole opcOld = opcCntRoleMap.get(ocr.Id);
    //             if(ocr.IsPrimary != opcOld.IsPrimary) 
    //             {
    //                 oppSet.add(ocr.OpportunityId);
    //             }
    //         }
    //     }
    //     system.debug('oppSet ======> ' + oppSet);
    //     if(oppSet.size() > 0) 
    //     {
    //         List<Opportunity> opportunityListToUpdate = new List<Opportunity>(); 
            
    //         /** CPQ Controls **/
    //         Id cpqRtId = null;
    //         CPQ_Controls__mdt cpqControls = null;
    //         try {
    //             cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_SetPrimaryContactSchedulable__c FROM CPQ_Controls__mdt LIMIT 1];
    
    //             if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null){
    //                 cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
    //             }
    //         }
    //         catch(Exception e){
    //             System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
    //         }
            
    //         List<Opportunity> opportunityList;
    //         if(cpqRtId == null || cpqControls.Opp_C_SetPrimaryContactSchedulable__c)
    //         {
    //             //CPQ included
    //             opportunityList =
    //             [
    //                 SELECT Id, Customer_Primary_Contact__c, CloseDate,
    //                 (
    //                         SELECT Id, ContactId, IsPrimary
    //                         FROM OpportunityContactRoles
    //                         WHERE IsPrimary = true
    //                 )
    //                 FROM Opportunity
    //                 WHERE Id IN: oppSet
    //             ];
    //             system.debug('no cpq  ' + opportunityList);
    //         } else {
    //             //CPQ excluded
    //             opportunityList =
    //             [
    //                     SELECT Id, Customer_Primary_Contact__c, CloseDate,
    //                 (
    //                         SELECT Id, ContactId, IsPrimary
    //                         FROM OpportunityContactRoles
    //                         WHERE IsPrimary = true
    //                 )
    //                 FROM Opportunity
    //                 WHERE Id IN : oppSet
    //                 AND RecordTypeId != : cpqRtId
    //             ];
    //             system.debug('nwith cpq  ' + opportunityList);      
    //         }
    //          system.debug('opportunityList ======> ' + opportunityList);
    //         for(Opportunity opportunity : opportunityList)
    //         {
    //             opportunity.Customer_Primary_Contact__c = null;
    //             // You cannot update an Opportunity with a Close Date in the past
    //             if(opportunity.CloseDate >= Date.today() && opportunity.OpportunityContactRoles.size() > 0 && opportunity.Customer_Primary_Contact__c != opportunity.OpportunityContactRoles[0].ContactId)
    //             {   
    //                 opportunity.Customer_Primary_Contact__c = opportunity.OpportunityContactRoles[0].ContactId;
    //             }
    //             opportunityListToUpdate.add(opportunity);
    //         }
    //          system.debug('opportunityListToUpdate ======> ' + opportunityListToUpdate);
    //         if(opportunityListToUpdate.size() > 0)
    //         {
    //            update opportunityListToUpdate;
    //         }
    //     }
    // }
    
    /* public static void setContactStatus(List<OpportunityContactRole> opcCntRoleList, Map<Id, OpportunityContactRole> opcCntRoleMap) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> oldContactIds = new Set<Id>();
        if(opcCntRoleList != null) {
            for(OpportunityContactRole ocr: opcCntRoleList) {
                if(opcCntRoleMap == null) {
                    contactIds.add(ocr.ContactId);
                } else {
                    OpportunityContactRole oldOCR = opcCntRoleMap.get(ocr.Id);
                    if(ocr.ContactId != oldOCR.ContactId) {
                        contactIds.add(ocr.ContactId);
                        oldContactIds.add(oldOCR.ContactId);
                    } 
                    //if(ocr.Role != oldOCR.Role) {
                        //contactIds.add(ocr.ContactId);
                    //}
                }
            }
        } else {
            for(OpportunityContactRole oldOCR: opcCntRoleMap.values()) {
               oldContactIds.add(oldOCR.ContactId);
            }
        }
        System.debug('contactIds ====> ' + contactIds);
        List<Contact> contactsToUpdate = new List<Contact>();
        if(contactIds.size() > 0) {
            List<Contact> contacts = [SELECT Id, Contact_Status__c FROM Contact WHERE Id IN: contactIds];
            for(Contact cnt: contacts) {
                if(cnt.Contact_Status__c != 'Influencer' && cnt.Contact_Status__c != 'New') {
                    cnt.Contact_Status__c = 'Added to Opportunity';
                    cnt.Date_Time_Added_to_Opportunity__c = DateTime.Now();
                    contactsToUpdate.add(cnt);
                }
            }
        }
        if(oldContactIds.size() > 0) {
            List<Contact> oldContacts = [SELECT Id, Contact_Status__c FROM Contact WHERE Id IN: oldContactIds];
            for(Contact cnt: oldContacts) {
                if(cnt.Contact_Status__c != 'Influencer' && cnt.Contact_Status__c != 'New') {
                    cnt.Contact_Status__c = '';
                    contactsToUpdate.add(cnt);
                }
            }
        }
        if(contactsToUpdate.size() > 0) {
            update contactsToUpdate;
        }
    }*/
}