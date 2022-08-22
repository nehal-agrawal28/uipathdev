trigger Users_SL on User(after delete, after insert, after update, before delete, before insert, before update) {
  fflib_SObjectDomain.triggerHandler(Users_SL.class);
}