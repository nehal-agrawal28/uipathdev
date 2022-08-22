public with sharing class OpportunityListContainerController {
    @AuraEnabled
    public static string mergeOpportunities(Id destinationOpp, List<Id> oppsToMergeFrom){
        // Check for null arguments
        if (destinationOpp == null || oppsToMergeFrom == null) {
            return 'ERROR: Bad arguments to OpportunityListContainerController.mergeOpportunities';
        }

        Savepoint sp = Database.setSavepoint();
        Try{
            // Get the setting for the Stage Name
            Opportunity_Merge__mdt oppMergeSettings = [SELECT DroppedOppStageName__c FROM Opportunity_Merge__mdt WHERE MasterLabel = 'Default' LIMIT 1];
            
            // First, query for all Opportunity products that point to an Opportunity with an ID in the list "oppsToMergeFrom"
            List<OpportunityLineItem> olisToDestroy = [ SELECT Id, OpportunityId, Quantity, TotalPrice, PricebookEntryId, Original_OppPr_Id__c, Discount, ServiceDate, Product_Version__c, Asset__c
                                                        FROM OpportunityLineItem 
                                                        WHERE OpportunityId IN :oppsToMergeFrom];

            List<OpportunityLineItem> olisToCreate = new List<OpportunityLineitem>();

            // Clone all of the Oli's, pointing to the new Opp ID
            for (OpportunityLineItem oli : olisToDestroy) {
                OpportunityLineItem oliClone = oli.clone(false, false, false, false);
                oliClone.OpportunityId = destinationOpp;
                oliClone.Quantity = oli.Quantity;

                oliClone.PricebookEntryId = oli.PricebookEntryId;
                //carry over pointer to the original oli for merged olis
                oliClone.Original_OppPr_Id__c = oli.Original_OppPr_Id__c;

                oliClone.Discount = oli.Discount;
                oliClone.ServiceDate = oli.ServiceDate;
                oliClone.Product_Version__c = oli.Product_Version__c;

                olisToCreate.add(oliClone);
            }


            // Clear down the old opps (set the stage according to the custom metadata type), pointing to the new Opp ID
            List<Opportunity> oppsToMergeFromWithFields = [ SELECT Id, StageName, Merged_into_Opportunity__c, Dropped_reason__c 
                                                            FROM Opportunity 
                                                            WHERE Id IN :oppsToMergeFrom];

            List<Opportunity> oppsToDrop = new List<Opportunity>();

            for (Opportunity o : oppsToMergeFromWithFields) {
                o.StageName = oppMergeSettings.DroppedOppStageName__c;
                o.Won_Reasons__c = 'Product Roadmap';
                String destinationOppUrl = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm()) + '/' + destinationOpp;
                o.Dropped_reason__c = 'Automatically merged into Opportunity: ' + destinationOppUrl;
                o.Merged_into_Opportunity__c = destinationOpp;
                o.Primary_Lost_Reason__c = 'Weak Product Roadmap';

                oppsToDrop.add(o);
            }
            update oppsToDrop;


            /* 
                Moved this down, below the dropping of the source opportunity:
                    Creation of new opportunity line items on the master and removing them from the source opportunity.
                Reason for addressing the line items second, is that the closing of the opportunity is most likely to fail 
                due to validation rules. We want to avoid copying over the line items and then not being able to close the source opportunity.
                Also, removing the products first could fire a validation rule that requires the opportunity to have products when probability is > 60%
            */
            insert olisToCreate;

            //Clear out asset, so that old products can be deleted
            for (OpportunityLineItem oli : olisToDestroy) {    
                oli.Asset__c = null;
                oli.Original_OppPr_Id__c = null; //blank out reference, to prevent asset being referenced again
            }

            //update old products to clear out assets
            update olisToDestroy;

            // Clear down the old OLI's
            delete olisToDestroy;

        }
        catch(DmlException dmle) {
            Database.rollback(sp);
            return dmle.getMessage() + '\n\n' + dmle.getStackTraceString();
        }

        return 'Success';
    }
}