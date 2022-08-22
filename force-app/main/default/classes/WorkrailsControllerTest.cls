@isTest
class WorkrailsControllerTest {
    @isTest static void test1() {
    
        WorkrailsController wc = new WorkrailsController();
        
        System.assertNotEquals(wc.getBaseUrl(), null);
        System.assert(wc.getBaseUrl().contains('.workrails.'));
    }
  }