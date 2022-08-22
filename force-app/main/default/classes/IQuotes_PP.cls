/**
 * File Name: IQuotes_PP
 * Description:
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IQuotes_PP extends fflib_ISObjectDomain {
  Set<Id> getAccountIds();
  Set<Id> getDistributorIds();
  Set<Id> getPartnerIds();
  List<SBQQ__Quote__c> getQuotes();

  Set<Id> getRecordIds();
}