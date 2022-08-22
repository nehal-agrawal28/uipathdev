/**
 * Modified:
 * May-2021: SLTECH-14288 - Removed Influencer name logic and added primary influencer logic
 **/
public class PartnerInvolvementTriggerAllHandler 
{
    	
    // private final String INFLUENCE_PARTNER_ROLE = 'Influence (No Financial Comp from UiPath)';
    // private final String SOLD_TO_PARTNER_ROLE = 'Sold to Partner (Buying Directly from UiPath)';
    
    // private static Map<Id, Partner_Involvement__c> opportunityPartnerInvMap = new Map<Id, Partner_Involvement__c>();

    // public void modifyOpportunity(List<Partner_Involvement__c> newPIList, Map<Id, Partner_Involvement__c> oldPIMap, String triggerType)
    // {
    //     Set<Id> picIdSet = new Set<Id>();
         
    //     for(Partner_Involvement__c picTmp : newPIList)
    //     {
    //         if (picTmp.PartnerOpp_Name__c != null)
    //         {
    //             picIdSet.add(picTmp.PartnerOpp_Name__c);
    //         }
    //         // SLTECH-14288
    //         if(oldPIMap != null && oldPIMap.containsKey(picTmp.Id)){
    //             if(picTmp.Primary_Influence__c != oldPIMap.get(picTmp.Id).Primary_Influence__c){
    //                if(picTmp.Primary_Influence__c == true){
    //                    opportunityPartnerInvMap.put(picTmp.PartnerOpp_Name__c, picTmp);
    //                }
    //                 else{
    //                     opportunityPartnerInvMap.put(picTmp.PartnerOpp_Name__c, null);
    //                 }
    //             }
    //         }
    //         else if(oldPIMap == null  && picTmp.Primary_Influence__c == true){
    //             opportunityPartnerInvMap.put(picTmp.PartnerOpp_Name__c, picTmp);
    //         }
    //     }
        
    //     if (picIdSet.size() > 0)
    //     {
    //         List<Opportunity> oppToUpdateList = [select Id, Sold_to_Partner__c, Tier_2_Partner__c, Tier_3_Partner__c, Implementation_Partner__c, Influencers__c, Influence__c,
    //                                                 (SELECT Partner_Sales_Role__c, Partner_Delivery_Role__c, Partner_Account_Name__c, Partner_Account_Name__r.Name, Influence_Approval_Status__c FROM Opportunity_Partners__r) from Opportunity where Id in :picIdSet];
    //         List<Opportunity> toUpdate = new List<Opportunity>();
    //         for (Opportunity opp : oppToUpdateList) {
    //             Id soldToPartnerId = null;
    //             Id tier2PartnerId = null;
    //             Id tier3PartnerId = null;
    //             String influencerId = '';
    //             //String influencerName = '';
    //             Id implementationPartnerId = null;
                
    //             for (Partner_Involvement__c picTmp : opp.Opportunity_Partners__r)
    //             {
                        
    //                 if (picTmp.Partner_Sales_Role__c == 'Sold to Partner (Buying Directly from UiPath)')
    //                 {
    //                     soldToPartnerId = picTmp.Partner_Account_Name__c;
    //                 }
    //                 if (picTmp.Partner_Sales_Role__c == 'Tier 2 Partner (Buying from Sold to Partner)')
    //                 {
    //                     tier2PartnerId = picTmp.Partner_Account_Name__c;
    //                 }
    //                 if (picTmp.Partner_Sales_Role__c == 'Tier 3 Partner (Buying from Tier 2 Partner)')
    //                 {
    //                     tier3PartnerId = picTmp.Partner_Account_Name__c;
    //                 }
    //                 if (picTmp.Partner_Sales_Role__c == 'Influence (No Financial Comp from UiPath)' /* && picTmp.Influence_Approval_Status__c == 'approved' */)
    //                 {
    //                     if (influencerId != '' && picTmp.Influence_Approval_Status__c == 'approved') {
    //                         influencerId += ';';
    //                     }
    //                     if(picTmp.Influence_Approval_Status__c == 'approved'){
    //                         influencerId += picTmp.Partner_Account_Name__c;
    //                     }

    //                     /*if (influencerName != '')
    //                         influencerName += ';';
    //                     influencerName += picTmp.Partner_Account_Name__r.Name;*/
    //                 }
    //                 if (picTmp.Partner_Delivery_Role__c == 'Primary Implementation')
    //                 {
    //                     implementationPartnerId = picTmp.Partner_Account_Name__c;
    //                 }
    //             }
                
    //             if (opp.Sold_to_Partner__c != soldToPartnerId || opp.Tier_2_Partner__c != tier2PartnerId || opp.Tier_3_Partner__c != tier3PartnerId || opp.Influencers__c != influencerId || opp.Implementation_Partner__c != implementationPartnerId){
    //                     //|| opp.Influence__c != influencerName) {
    //                 opp.Sold_to_Partner__c = soldToPartnerId;
    //                 opp.Tier_2_Partner__c = tier2PartnerId;
    //                 opp.Tier_3_Partner__c = tier3PartnerId;
    //                 opp.Influencers__c = influencerId;
    //                 //opp.Influence__c = influencerName;
    //                 opp.Implementation_Partner__c = implementationPartnerId;
    //                 toUpdate.add(opp);
    //             }
    //             if(opportunityPartnerInvMap.containsKey(opp.Id)){
    //                 Partner_Involvement__c pInv = opportunityPartnerInvMap.get(opp.Id);
    //                 if(pInv != null){
    //                 	opp.Primary_Influence_Partner__c = pInv.Partner_Account_Name__c;
    //                 }
    //                 else{
    //                     opp.Primary_Influence_Partner__c = null;
    //                 }
    //                 if(!toUpdate.contains(opp)){
    //                     toUpdate.add(opp);
    //                 }
    //             }
    //         }
            
    //         if (toUpdate.size() > 0)
    //             update toUpdate;
    //     }

    // }
    
    // ============================================================================
    // added by Mirela Chituc - 3/25/2021 ========================================
    // if Opportunity_Sourced__c is checked - check Is_Partner_Sourced__c on the opportunity
    // ============================================================================
    // public void setIsPartnerSourced(List<Partner_Involvement__c> newPIList, Map<Id, Partner_Involvement__c> oldPIMap) {
    //     Set<Id> opportunitySet = new Set<Id>();
    //     if(newPIList != null) {
    //         for(Partner_Involvement__c pi: newPIList) {
    //             opportunitySet.add(pi.PartnerOpp_Name__c);
    //         }
    //     } else {
    //         for(Partner_Involvement__c pi: oldPIMap.values()) {
    //             opportunitySet.add(pi.PartnerOpp_Name__c);
    //         }
    //     }
        
    //     if (opportunitySet.size() > 0) {
    //         List<Partner_Involvement__c> piWithOppSourced = [SELECT Id, PartnerOpp_Name__c, Opportunity_Sourced__c, PartnerOpp_Name__r.Is_Partner_Sourced__c 
    //                                                     FROM Partner_Involvement__c 
    //                                                     WHERE PartnerOpp_Name__c IN: opportunitySet];
    //         Map<Id, Integer> oppMaps = new Map<Id, Integer>();
            
    //         for(Partner_Involvement__c pi: piWithOppSourced) {
    //             if(pi.Opportunity_Sourced__c == true) {
    //                 oppMaps.put(pi.PartnerOpp_Name__c, 1);
    //             } 
    //         }
            
    //         List<Opportunity> allOpps = [SELECT Id, Is_Partner_Sourced__c FROM Opportunity WHERE Id IN: opportunitySet];
            
    //         List<Opportunity> oppToUpdate = new List<Opportunity>();
    //         for(Opportunity opp: allOpps) {
    //             if(oppMaps.containsKey(opp.Id) && opp.Is_Partner_Sourced__c != true) {
    //                 opp.Is_Partner_Sourced__c = true;
    //                 oppToUpdate.add(opp);
    //             }
    //             if(!oppMaps.containsKey(opp.Id) && opp.Is_Partner_Sourced__c == true) { 
    //                 opp.Is_Partner_Sourced__c = false; 
    //                 oppToUpdate.add(opp);  
    //             }
    //         }
            
    //         if(oppToUpdate.size() > 0)
    //             update oppToUpdate;
              
    //     }
    // }
    
    
    // ============================================================================
    // added by Mirela Chituc - 3/19/2021 ========================================
    // Prevent checking Opportunity_Sourced__c if there is another partner involvement with Opportunity_Sourced__c true on the opportunity
    // ============================================================================
    // public void preventCheckingOpportunitySourced(List<Partner_Involvement__c> newPIList, Map<Id, Partner_Involvement__c> oldPIMap) {
    //     Set<Id> opportunitySet = new Set<Id>();
    //     Set<Id> PISet = new Set<Id>();
    //     for(Partner_Involvement__c pi: newPIList) {
    //         if(oldPIMap == null) {
    //             if(pi.Opportunity_Sourced__c == true)
    //                 opportunitySet.add(pi.PartnerOpp_Name__c);
    //         } else {
    //             Partner_Involvement__c oldPI = oldPIMap.get(pi.Id);
    //             if(pi.Opportunity_Sourced__c == true && pi.Opportunity_Sourced__c != oldPI.Opportunity_Sourced__c) {
    //                 opportunitySet.add(pi.PartnerOpp_Name__c);
    //                 PISet.add(pi.Id);
    //             }
    //         }
    //     }
    //     if (opportunitySet.size() > 0) {
    //         List<Partner_Involvement__c> piWithOppSourced = [SELECT Id, PartnerOpp_Name__c 
    //                                                     FROM Partner_Involvement__c 
    //                                                     WHERE PartnerOpp_Name__c IN: opportunitySet AND Id NOT IN: PISet AND Opportunity_Sourced__c = true];
    //         Map<Id, Integer> oppMap = new Map<Id, Integer>();
    //         for(Partner_Involvement__c pi: piWithOppSourced) {
    //             oppMap.put(pi.PartnerOpp_Name__c, 1);
    //         }                    
    //         for (Partner_Involvement__c pi : newPIList) {
    //             if (oppMap.containsKey(pi.PartnerOpp_Name__c)) {
    //                 pi.addError('There is another sourced partner involvement for this opportunity.');
    //             }
    //         }
    //     }
    // }
    
    // public void preventDeletion(List<Partner_Involvement__c> oldList) {
    //     User usr = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
    //     if (usr.Profile.Name != 'Super Admin' && usr.Profile.Name != 'System Administrator' && usr.Profile.Name != 'Data Stewards') {
    //         Set<Id> oppIdSet = new Set<Id>();
    //         for (Partner_Involvement__c pi : oldList) {
    //             oppIdSet.add(pi.PartnerOpp_Name__c);
    //         }
    //         Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id IN :oppIdSet]);
    //         for (Partner_Involvement__c pi : oldList) {
    //             if (oppMap.containsKey(pi.PartnerOpp_Name__c)) {
    //                 if (oppMap.get(pi.PartnerOpp_Name__c).RecordType.DeveloperName == 'UiPath_Standard_Locked' || oppMap.get(pi.PartnerOpp_Name__c).RecordType.DeveloperName == 'CPQ_Locked')
    //                     pi.addError('You cannot delete a partner involvement record for a locked opportunity. Please reach out to Compensation.');
    //             }
    //         }
    //     }
    // }
    
    
    // public void setDefaultValue4JP(List<Partner_Involvement__c> newList) {
    //    User usr = [SELECT Id, Name, AccountId, ContactId, IsPortalEnabled FROM User WHERE Id = :UserInfo.getUserId()];
    //    if (String.isNotEmpty(usr.ContactId)) {
    //        for (Partner_Involvement__c pi : newList) {
    //            if (String.isEmpty(pi.Partner_Delivery_Role__c)) {
    //                pi.Partner_Delivery_Role__c = 'None';
    //            }
    //        }
    //    }
    // } 
    
    // public void preventSecondSoldToPartner(List<Partner_Involvement__c> newList, Map<Id, Partner_Involvement__c> oldMap) {
    //    Set<Id> oppIds = new Set<Id>();
    //    Set<Id> partnerAccountIds = new Set<Id>();
	//    Map<Id, Id> primaryInfluenceMap = new Map<Id, Id>();
    //    for(Partner_Involvement__c pi: newList) {
    //        partnerAccountIds.add(pi.Partner_Account_Name__c);
           
    //        if((oldMap == null || (oldMap != null && pi.Partner_Sales_Role__c != oldMap.get(pi.Id).Partner_Sales_Role__c)) &&
    //            pi.Partner_Sales_Role__c == 'Sold to Partner (Buying Directly from UiPath)'){
    //            		oppIds.add(pi.PartnerOpp_Name__c);
    //        }
    //        // SLTECH-14288
    //         else  if((oldMap == null || (oldMap != null && (pi.Partner_Sales_Role__c != oldMap.get(pi.Id).Partner_Sales_Role__c) ||
    //                 (pi.Primary_Influence__c != oldMap.get(pi.Id).Primary_Influence__c) && pi.Primary_Influence__c == true)) &&
    //                 pi.Partner_Sales_Role__c == INFLUENCE_PARTNER_ROLE){
    //             	oppIds.add(pi.PartnerOpp_Name__c);
                    
	// 				if(pi.Primary_Influence__c == true){
                        
	// 					primaryInfluenceMap.put(pi.PartnerOpp_Name__c, pi.Id);
	// 				}
    //         	}
           
    //    }
    //    if(OppIds.size() > 0) {
    //        List<Partner_Involvement__c> SoldToPartner = [SELECT Id, PartnerOpp_Name__c, Primary_Influence__c, Partner_Sales_Role__c FROM Partner_Involvement__c 
    //                    WHERE PartnerOpp_Name__c IN: oppIds AND id !=: newList AND (Partner_Sales_Role__c = 'Sold to Partner (Buying Directly from UiPath)'
    //                                                      OR (Partner_Sales_Role__c =: INFLUENCE_PARTNER_ROLE AND Primary_Influence__c = true))];
    //        Map<Id, Account> techAllianceAccountMap = new Map<Id, Account>([Select id 
	// 																	   from Account 
	// 																	   Where id in: partnerAccountIds 
	// 																	   and RecordType.Name = 'Technology Alliance']);                                              
	// 	   Set<Id> SoldToPartnerSet = new Set<Id>();
           
    //        for(Partner_Involvement__c pi: SoldToPartner){
    //            if(pi.Partner_Sales_Role__c == SOLD_TO_PARTNER_ROLE){
    //        			SoldToPartnerSet.add(pi.PartnerOpp_Name__c); 
    //             } 
    //             // SLTECH-14288
    //             else if(pi.Partner_Sales_Role__c == INFLUENCE_PARTNER_ROLE && pi.Primary_Influence__c == true){
    //                 primaryInfluenceMap.put(pi.PartnerOpp_Name__c, pi.Id);
    //             } 
    //        }
           
    //        for(Partner_Involvement__c pi: newList) {
    //            if(SoldToPartnerSet.contains(pi.PartnerOpp_Name__c) && pi.Partner_Sales_Role__c == SOLD_TO_PARTNER_ROLE){
	// 				pi.addError('You cannot have more than one Sold To Partners.');
	// 			}
	// 			// SLTECH-14288
	// 			else if(pi.Partner_Sales_Role__c == INFLUENCE_PARTNER_ROLE){
    //                 if(primaryInfluenceMap.containsKey(pi.PartnerOpp_Name__c) && pi.Primary_Influence__c == true && 
	// 					primaryInfluenceMap.get(pi.PartnerOpp_Name__c)!= pi.Id){
    //                 	pi.addError('There is already another primary influence partner for this opportunity');
    //                 }
    //                 else if(!primaryInfluenceMap.containsKey(pi.PartnerOpp_Name__c) && !techAllianceAccountMap.containsKey(pi.Partner_Account_Name__c)){
    //                     pi.Primary_Influence__c = true;
    //                     primaryInfluenceMap.put(pi.PartnerOpp_Name__c, pi.Id);
    //                 }
    //             }
    //        }             
    //    }
    // }
    // public void applyPartnerInfluenceApprovalMatrix(List<Partner_Involvement__c> newList, Map<Id, Partner_Involvement__c> oldPIMap) {
    //     List<String> relatedOppsGeos = new List<String>();
    //     Map<Id, User> userAndRoleMap = new Map<Id, User>();
    //     QuoteApprovalMatrixSetting__c setting = QuoteApprovalMatrixSetting__c.getInstance();
    //     List<Partner_Involvement__c> influencePI = new List<Partner_Involvement__c>();
    //     Set<Id> opportunityIds = new Set<Id>();
    //     Set<Id> partnerIds = new Set<Id>();
    //     Map<Id, Opportunity> oppMap;
    //     Map<Id, Account> partnersMap;

    //     for(Partner_Involvement__c partnerInvolvement : newList) {
    //         if(oldPIMap == null) {
    //             if(partnerInvolvement.Partner_Sales_Role__c == 'Influence (No Financial Comp from UiPath)'
    //                 && partnerInvolvement.Partner_Record_Type__c != 'Technology Alliance') {
    //             influencePI.add(partnerInvolvement);
    //             opportunityIds.add(partnerInvolvement.PartnerOpp_Name__c);
    //             partnerIds.add(partnerInvolvement.Partner_Account_Name__c);
    //         } 
    //     } else {
    //         Partner_Involvement__c oldPI = oldPIMap.get(partnerInvolvement.Id);
    //         if(partnerInvolvement.Partner_Sales_Role__c == 'Influence (No Financial Comp from UiPath)'
    //             && oldPI.Partner_Sales_Role__c != 'Influence (No Financial Comp from UiPath)' && partnerInvolvement.Partner_Record_Type__c != 'Technology Alliance') {
    //         influencePI.add(partnerInvolvement);
    //         opportunityIds.add(partnerInvolvement.PartnerOpp_Name__c);
    //         partnerIds.add(partnerInvolvement.Partner_Account_Name__c);
    //         }
    //     }            
    // }

    //     if(!influencePI.isEmpty()){
    //         oppMap = new Map<Id, Opportunity>([
    //                 SELECT Id,
    //                         Account.Geo__c,
    //                         Account.Region__c,
    //                         Account.Area__c,
    //                         OwnerId,
    //                         Owner.UserRole.Name
    //                 FROM Opportunity
    //                 WHERE Id IN :opportunityIds
    //         ]);

    //         partnersMap = new Map<Id, Account>([
    //                 SELECT Id,
    //                         Business_Partner_Type__c,
    //                         Regional_Business_Partner_Type__c
    //                 FROM Account
    //                 WHERE Id IN :partnerIds
    //         ]);

    //         System.debug('The Opportunity map size is: ' + oppMap.size());
    //         System.debug('The Partners map size is: ' + partnersMap.size());

    //         for(Partner_Involvement__c influencer : influencePI) {
    //             relatedOppsGeos.add(oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c);
    //             System.debug('The Geo is: ' + oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c);
    //             System.debug('The relatedOppsGeos list size is: ' + relatedOppsGeos.size());
    //             /*System.debug('The Geos value is: ' + relatedOppsGeos.get(0));*/
    //             userAndRoleMap.put(oppMap.get(influencer.PartnerOpp_Name__c).OwnerId, null);
    //             System.debug('userAndRoleMap size is: ' + userAndRoleMap.size());
    //         }

    //         List<Quote_Approval_Matrix__c> matrixList = [SELECT Id, Approver__c, X2nd_Approver_GSI__c, X2nd_Approver_VAR__c, Geo__c, Region__c, Area__c, Role__c, Type__c
    //         FROM Quote_Approval_Matrix__c
    //         WHERE Geo__c IN :relatedOppsGeos AND Type__c = 'Influence'];

    //         userAndRoleMap = new Map<Id, User>([SELECT Id, UserRole.Name
    //         FROM User
    //         WHERE Id IN :userAndRoleMap.keySet()]);

    //         for(Partner_Involvement__c influencer : influencePI) {
    //             System.debug('This is the Business Partner Type: ' + partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c);
    //             Boolean firstApproverFound = false;
    //             Boolean secondApproverFound = false;
    //             for(Quote_Approval_Matrix__c matrix : matrixList) {
    //                 if(oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'AMER' || oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'EMEA' ||
    //                         (oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'APJ') && oppMap.get(influencer.PartnerOpp_Name__c).Account.Area__c == 'India') {
    //                     if(matrix.Geo__c == oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c &&
    //                             (matrix.Area__c == oppMap.get(influencer.PartnerOpp_Name__c).Account.Area__c || String.IsBlank(matrix.Area__c)) &&
    //                             userAndRoleMap.containsKey(oppMap.get(influencer.PartnerOpp_Name__c).OwnerId) &&
    //                             userAndRoleMap.get(oppMap.get(influencer.PartnerOpp_Name__c).OwnerId).UserRole != null &&
    //                             matrix.Role__c == userAndRoleMap.get(oppMap.get(influencer.PartnerOpp_Name__c).OwnerId).UserRole.Name) {
    //                         System.debug('Matrix 1st approver is' + matrix.Approver__c);
    //                         influencer.X1st_Approver__c = matrix.Approver__c;
    //                         System.debug('Influencer 1st approver is' + influencer.X1st_Approver__c);
    //                         firstApproverFound = true;
    //                         System.debug('Business Partner Type is: ' + partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c);
    //                         System.debug('2nd Approver GSI is: ' + matrix.X2nd_Approver_GSI__c);
    //                         System.debug('2nd Approver VAR is: ' + matrix.X2nd_Approver_VAR__c);
    //                         if(partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c == 'GSI' ||
    //                                 (oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'EMEA' &&
    //                                         partnersMap.get(influencer.Partner_Account_Name__c).Regional_Business_Partner_Type__c == 'RSI')) {
    //                             influencer.X2nd_Approver__c = matrix.X2nd_Approver_GSI__c;
    //                             secondApproverFound = true;
    //                         }
    //                         if(partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c == 'VAR') {
    //                             influencer.X2nd_Approver__c = matrix.X2nd_Approver_VAR__c;
    //                             secondApproverFound = true;
    //                         }
    //                     }
    //                 }

    //                 if(oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'APJ' && oppMap.get(influencer.PartnerOpp_Name__c).Account.Area__c == 'APAC') {
    //                     System.debug('APAC matrix 1st approver is' + matrix.Approver__c);
    //                     System.debug('APAC account Geo is: ' + oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c);
    //                     if(matrix.Region__c == oppMap.get(influencer.PartnerOpp_Name__c).Account.Region__c){
    //                         System.debug('APAC Influencer 1st approver is' + influencer.X1st_Approver__c);
    //                         influencer.X1st_Approver__c = matrix.Approver__c;
    //                         firstApproverFound = true;
    //                     }
    //                 }

    //                 if(((partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c != 'GSI' && partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c != 'VAR') ||
    //                         (oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'APJ' && oppMap.get(influencer.PartnerOpp_Name__c).Account.Area__c == 'APAC')) &&
    //                         firstApproverFound) {
    //                     break;
    //                 }
                    
    //                 if((partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c == 'GSI' || partnersMap.get(influencer.Partner_Account_Name__c).Business_Partner_Type__c == 'VAR') &&
    //                         !(oppMap.get(influencer.PartnerOpp_Name__c).Account.Geo__c == 'APJ' && oppMap.get(influencer.PartnerOpp_Name__c).Account.Area__c == 'APAC') &&
    //                         (firstApproverFound && secondApproverFound)) {
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    // }

    
   
}