/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: Interface to create batch apex chaining
 */
global interface IGenericBatch {
  void execute(Database.BatchableContext BC, List<Sobject> sobjectList);

  void finish(Database.BatchableContext BC);
}