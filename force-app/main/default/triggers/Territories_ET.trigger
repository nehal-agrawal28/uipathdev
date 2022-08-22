/**
 * @AUTHOR: UIPath
 * @DATE: 07/12/2021
 * @DESCRIPTION: This is territory2 object trigger
 */
trigger Territories_ET on Territory2(before update, after insert, after update) {
  fflib_SObjectDomain.triggerHandler(Territories_ET.class);
}