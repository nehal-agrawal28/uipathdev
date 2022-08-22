/**
 * @AUTHOR: UIPath
 * @DATE: 21/10/2021
 * @DESCRIPTION: User Trigger used for ETM
 */
trigger Users_ET on User(before update) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(Users_ET.class);

}