/**
 * Created by Jack Cronin on 6/20/2022.
 */
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDocuments from '@salesforce/apex/MyProfileDocumentsController_PP.getDocuments';
import getPDFUrlHost from '@salesforce/apex/MyProfileDocumentsController_PP.getPDFUrlHost';
import { COLUMNS } from './constants';

export default class MyProfileDocuments extends NavigationMixin(LightningElement) {
  data = [];
  columns = COLUMNS;
  vfPageHost = '';
  loading = false;
  hasData = false;

  connectedCallback() {
    this.getPDFUrlHost();
    this.getDocuments();
  }

  getPDFUrlHost() {
    this.loading = true;
    getPDFUrlHost()
        .then(result => {
          this.loading = false;
          this.vfPageHost = result;
        })
        .catch(error => {
          this.loading = false;
          this.error = error;
        });
  }

  getDocuments() {
    getDocuments()
        .then(result => {
          this.data = result
          if(this.data){
            for (let row of this.data) {
              row['Url'] = this.generatePdf(row.DeveloperName);
              row['URLName'] = 'Generate PDF';
            }
            this.hasData = this.data;
          }else{
            this.hasData = false;
          }
        })
        .catch(error => {
          this.hasData = false;
        });
  }
  generatePdf(row) {
   return(this.vfPageHost + row);
  }
}