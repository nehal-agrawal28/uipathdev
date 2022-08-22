import { LightningElement, api } from 'lwc';

export default class Modal extends LightningElement {
    @api
    openModal;
    @api
    title;
    @api
    description;

    @api
    closeModal() {
        this.openModal = false;
    }
}