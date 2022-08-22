public without sharing class LoginController_PP {
  @AuraEnabled
  public static String login(String username, String password, String startUrl) {
    try {
      return ((UsersService_PP) Application_PP.Service.newInstance(UsersService_PP.class))
        .login(username, password, startUrl);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void forgotPassword(String username) {
    try {
      ((UsersService_PP) Application_PP.Service.newInstance(UsersService_PP.class)).forgotPassword(username);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}