import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import login from '@salesforce/apex/LoginController_PP.login';
export default class Login extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track error;
    username;
    password;

    handleUsernameChange(event){
        this.username = event.target.value;
     }

     handlePasswordChange(event){
        this.password = event.target.value;
     }

     handleLogin() {
        this.isLoading = true;

        const params = {
          username: this.username,
          password: this.password,
          startUrl: '/',
        };
        login(params)
          .then((homeUrl) => {
            window.open(homeUrl, '_top');
          })
          .catch(() => {
            this.error = 'Your login attempt has failed. Make sure the username and password are correct.';
          })
          .finally(() => {
            this.isLoading = false;
          });
      }
  
}