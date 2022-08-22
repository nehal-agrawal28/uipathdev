public class BoonWrapper {
    
    public String accountId {get;set;} 
    public String accountName {get;set;} 
    public String accountCountry {get;set;} 
    public License licenseObj {get;set;}
    
    public BoonWrapper(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                     if (text == 'accountId') {
                        accountId = parser.getText();
                    }else if (text == 'accountName') {
                        accountName = parser.getText();
                    }else if (text == 'accountCountry') {
                        accountCountry = parser.getText();
                    }else if (text == 'license') {
                        licenseObj = new License(parser);
                    }else {
                        System.debug(LoggingLevel.WARN, 'JSON2Apex consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    public class License {
        public String name {get;set;} 
        public String subscriptionCode {get;set;} 
        public String endDate {get;set;}
        public String duration {get;set;}
        public String createdDateTime {get;set;}
        public License(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'name') {
                            name = parser.getText();
                        } else if (text == 'subscriptionCode') {
                            subscriptionCode = parser.getText();
                        } else if (text == 'endDate') {
                            endDate = parser.getText();
                        } else if (text == 'duration') {
                            duration = parser.getText();
                        } else if (text == 'createdDateTime') {
                            createdDateTime = parser.getText();
                        } else{
                            System.debug(LoggingLevel.WARN, 'License consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
   }
    
    public static BoonWrapper parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new BoonWrapper(parser);
    }
    
    public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                    depth++;
                } else if (curr == System.JSONToken.END_OBJECT ||
                           curr == System.JSONToken.END_ARRAY) {
                               depth--;
                           }
        } while (depth > 0 && parser.nextToken() != null);
    }
}