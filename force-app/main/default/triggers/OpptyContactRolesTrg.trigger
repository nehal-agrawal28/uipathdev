/**********************************************************
 * @className   : OpptyContactRolesTrg.Extension
 * @testClass   : OpptyContactRolesTrg_TEST.Extension
 * @author      : Marian Iovi (marian.iovi@deutoria.com)
 * @date        : April 11, 2018
 * @description : rollUpSumContactRoles() - calculates the number of Contact Roles related to an opportunity
 * @updated by  : Mirela Chituc (mirela.chituc@uipath.com)
 * @date date   : Oct 10, 2019
 * @description : clonePartnerInvolvment() - clones Partner_Involvement__c from the original opps to the newly created amendeded / renewal opps
 **********************************************************/

trigger OpptyContactRolesTrg on Opportunity(after insert, before update) {
  if (Trigger.isAfter) {
    //if (Trigger.isInsert)
      //OpptyContactRoles_Helper.clonePartnerInvolvment(Trigger.new);

    // ============================================================================
    // commented by Vali Coteanu - 07/15/2020 =====================================
    // this was never running as it never had the "after update" parameter
    // ============================================================================
    /*if(Trigger.isUpdate)
     OpptyContactRoles_Helper.setCustomerStageOnAccount(trigger.new, trigger.oldMap);*/
  }

  if (Trigger.isBefore) {
    //if(Trigger.isUpdate)
    //OpptyContactRoles_Helper.rollUpSumContactRoles(trigger.new);
  }
}