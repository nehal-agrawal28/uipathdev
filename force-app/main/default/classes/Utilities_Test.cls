@isTest
private class Utilities_Test {
    @isTest
    private static void getInstance(){
        String instance = '';
        Organization o = [SELECT OrganizationType, InstanceName FROM Organization limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;
        
        //Set this header to test it
        ApexPages.currentPage().getHeaders().put('Host', insName+'.visual.force.com');
        
        if(orgType == 'Enterprise Edition'){
            List<String> parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
            instance = parts[parts.size() - 4] + '.';
        }
        Utilities1.getInstance();
        //System.assertEquals(instance, Utilities1.getInstance());
    }
    @isTest
    private static void getSubdomainPrefix(){
        //This will always be empty unless it's sandbox
        Utilities1.getSubdomainPrefix();
        
        //System.assertEquals('', Utilities1.getSubdomainPrefix());
    }
    
}