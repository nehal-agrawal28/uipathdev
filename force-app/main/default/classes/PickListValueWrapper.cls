public class PickListValueWrapper {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public Boolean isSelected {get;set;}
        public PickListValueWrapper (String label, String value) {
            this.label = label;
            this.value = value;
            isSelected = false;
        }
    }