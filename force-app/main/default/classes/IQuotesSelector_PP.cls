/**
 * File Name: IQuotesSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IQuotesSelector_PP extends fflib_ISObjectSelector {
  List<SBQQ__Quote__c> selectByIdWithReferences(Set<Id> quoteIds, Set<String> referencedFields);
}