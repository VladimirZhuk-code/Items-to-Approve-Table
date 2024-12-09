import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ApproveModal extends LightningModal {

    @api contentId;
    @api headerLabel;
    @api buttonAction;
    @api reassign;
    disableButton = true;
    comment = '';
    reassId;

    connectedCallback() {
        if (!this.reassign) {
            this.disableButton = false;
        } else {
            this.disableButton = true;
        }
    }

    renderedCallback() {
        if (!this.reassign) {
            const textarea = this.template.querySelector('lightning-textarea');
            textarea.focus();
        }
    }

    handleOnReady() {
        const recordPicker = this.template.querySelector('lightning-record-picker');
        recordPicker.focus();
    };

    handleButtonAction() {
        var result = {
            objButtonAction: this.buttonAction,
            objComment: this.comment,
            objReassId: this.reassId
        };
        this.close(result);
    }

    handleClose() {
        this.close();
    }

    handlePickerChange(event) {
        this.reassId = event.detail.recordId;

        if (event.detail.recordId) {
            this.disableButton = false;
        } else {
            this.disableButton = true;
        }
    }

    handleCommentChange(event) {
        this.comment = event.target.value;
    }
}