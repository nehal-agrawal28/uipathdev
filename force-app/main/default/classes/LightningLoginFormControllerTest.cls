@IsTest(isParallel=true)
public class LightningLoginFormControllerTest 
{
    @isTest 
    static void testLoginForm()
    {
        //work
        LightningLoginFormController.login('username', 'password', 'startUrl');
		
       	//LightningLoginFormController.getForgotPasswordUrl();
        LightningLoginFormController.getIsUsernamePasswordEnabled();
        LightningLoginFormController.getIsSelfRegistrationEnabled();
        LightningLoginFormController.getSelfRegistrationUrl();
        LightningLoginFormController.setExperienceId('expId');
              
    }
}