@IsTest
public with sharing class LoginControllerTest_PP {
  static testMethod void itShouldCallLogin() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    UsersService_PP serviceMock = (UsersService_PP) mocks.mock(UsersService_PP.class);

    String username = 'A12345678';
    String password = 'test';
    String url = '';

    String resultExpected = 'communityURL';

    mocks.startStubbing();
    mocks.when(serviceMock.login(username, password, url)).thenReturn(resultExpected);
    mocks.stopStubbing();

    Application_PP.Service.setMock(UsersService_PP.class, serviceMock);

    String result = LoginController_PP.login(username, password, url);

    ((UsersService_PP) mocks.verify(serviceMock)).login(username, password, url);
    System.assertEquals('communityURL', result, 'Incorrect returned result');
  }
}