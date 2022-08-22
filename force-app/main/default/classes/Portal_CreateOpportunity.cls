public class Portal_CreateOpportunity {

    @AuraEnabled
    public static Opportunity InitOpportunity() {
        return new Opportunity();
    }
    
    @AuraEnabled
    public static SaveResult SaveOpportunity(Opportunity opp) {
        opp.CloseDate = Date.today().addDays(30);
        opp.StageName = 'Discovery';
        try {
            insert opp;
            return new SaveResult(opp.Id);
        } catch (Exception ex) {
            return new SaveResult(ex.getMessage());
        }
    }
    
    public class SaveResult {
        @AuraEnabled
        public boolean success { get; set; }
        @AuraEnabled
        public string id { get; set; }
        @AuraEnabled
        public string errorMessage { get; set; }
        
        public SaveResult(Id id) {
            success = true;
            this.id = id;
        }
        public SaveResult(String errorMessage) {
            success = false;
            this.errorMessage = errorMessage;
        }
    }
}