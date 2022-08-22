import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import forgotPassword from '@salesforce/apex/LoginController_PP.forgotPassword';

const SIMPLE_EMAIL_VALIDATION_REGEX = /.+@.+\..+/;

export default class ForgotPassword extends NavigationMixin(LightningElement) {
  error = '';

  isLoading = false;

  handleSubmitForgotPassword() {
    this.error = '';

    const username = this.template.querySelector('input[name="username"]').value;

    if (!username || !SIMPLE_EMAIL_VALIDATION_REGEX.test(username)) {
      this.error = 'Please enter a valid email address.';

      return;
    }

    this.isLoading = true;

    forgotPassword({ username })
      .then(() => this.navigateToCheckPassword())
      .catch(() => {
        this.error = 'Failed to reset your password.';
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  navigateToCheckPassword() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: 'Check_Password',
      },
    });
  }
}