public class WorkrailsController {
    private final String baseUrl;
    
    public WorkrailsController() {
        Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
        String currentUrl = ApexPages.currentPage().getHeaders().get('Host');
        String envType = organization.IsSandbox
            ? currentUrl != null && currentUrl.contains('workrails') ? 'Dev' : 'UAT'
            : 'Production';
        WorkRails_Environment_Variables__mdt envData = [
            SELECT Location__c FROM WorkRails_Environment_Variables__mdt
            WHERE DeveloperName = :envType
        ];
        baseUrl = envData.Location__c;
    }
    
    public String getBaseUrl() {
        return baseUrl;
    }
}