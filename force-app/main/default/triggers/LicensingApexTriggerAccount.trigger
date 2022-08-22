trigger LicensingApexTriggerAccount on Account (after insert, after update, after delete) {
    try {
        if (Trigger.isUpdate) {
            System.debug('BOON: Trigger update Account=' + Trigger.new[0].Account_ID_Long__c);
            LicensingApiDispatch.onAccountUpdate(Trigger.new[0].Account_ID_Long__c);
        } else if (Trigger.isDelete && (Trigger.new==null || Trigger.new.size()==0) &&(Trigger.old != null)) {
            string masterRecordId = null;
            //merge accounts?
            List<String> mergedAccountIds = new List<String>();
            for(Account account:Trigger.old) {
                if(account.MasterRecordId!=null) {
                    masterRecordId = account.MasterRecordId;
                    mergedAccountIds.add(account.Account_ID_Long__c);
                }
            }
            if (mergedAccountIds.size() > 0) {
                System.debug('BOON: Trigger merge into Account=' + masterRecordId);
                LicensingApiDispatch.onAccountsMerged(masterRecordId, mergedAccountIds);
            }
        }
    } catch (Exception e){
        System.debug('BOON: Error: ' + e);
    }
}