import { api, track, LightningElement } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

import {
    createNewCollaborationCase, getCaseInfo, toast, logError
} from 'c/tsaNetHelper';

/** Flow Screen wizard to create an outbound TSANet collaboration request. */
export default class TsaNetCaseCreatorFlow extends LightningElement {

    @api caseId;
    @api searchText;

    @api isSuccess = false;
    @api tsanetRequestId;
    @api responseJson;
    @api errorMessage;

    @track isLoading = false;
    @track step = 1;
    @track company;
    @track form;
    @track submitResponse;
    @track caseRecord;

    resultMessage = 'Your case has been successfully submitted';
    resultDescription = 'The request was sent to TSANet and is now being processed';

    connectedCallback() {
        if (this.caseId) {
            getCaseInfo(this.caseId)
                .then(data => {
                    this.caseRecord = data?.caseRecord;
                })
                .catch(error => {
                    logError(error?.body, 'CREATE_TSANET_COLLABORATION_REQUEST', { caseId: this.caseId });
                    toast(this, 'Error', 'error', error?.body?.message);
                });
        }
    }

    onCancel = () => {
        if (!this.isSearchMode) {
            this.step--;
        }
    };

    onSave = () => {
        if (this.isSearchMode) {
            this.step++;
        } else {
            this.handleSubmit();
        }
    };

    handleSelectCompany(event) {
        this.form = event?.detail?.form;
        this.company = event?.detail?.company;
    }

    handleSubmit() {
        const tsaNetForm = this.template.querySelector('c-tsa-net-form');
        if (!tsaNetForm) {
            return;
        }

        const data = tsaNetForm.resolveCustomForm();
        if (data?.hasError || !data?.caseId) {
            return;
        }

        this.caseId = data?.caseId;
        const object = data?.object;

        this.isLoading = true;
        this.notifyFlowOutput('errorMessage', null);

        createNewCollaborationCase(data?.caseId, JSON.stringify(object))
            .then(response => {
                const res = JSON.parse(response);

                if (res?.message) {
                    toast(this, 'Error', 'error', res?.message);
                    logError({ message: res?.message }, 'CREATE_TSANET_COLLABORATION_REQUEST', { caseId: this.caseId });
                    this.notifyFlowOutput('isSuccess', false);
                    this.notifyFlowOutput('errorMessage', res?.message);
                } else {
                    this.submitResponse = res;
                    this.notifyFlowOutput('isSuccess', true);
                    this.notifyFlowOutput('tsanetRequestId', res?.id ? String(res.id) : null);
                    this.notifyFlowOutput('responseJson', JSON.stringify(res));
                    this.notifyFlowOutput('errorMessage', null);
                }
            })
            .catch(error => {
                const message = error?.body?.message;
                toast(this, 'Error', 'error', message);
                logError(error?.body, 'CREATE_TSANET_COLLABORATION_REQUEST', { caseId: this.caseId });
                this.notifyFlowOutput('isSuccess', false);
                this.notifyFlowOutput('errorMessage', message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /** Pushes an output value back to the hosting Screen Flow. */
    notifyFlowOutput(name, value) {
        this[name] = value;
        this.dispatchEvent(new FlowAttributeChangeEvent(name, value));
    }

    /** Blocks Flow Next until the collaboration request was submitted successfully. */
    @api
    validate() {
        if (this.isDone) {
            return { isValid: true };
        }
        return {
            isValid: false,
            errorMessage: 'Complete member selection, fill the form, and submit before continuing.'
        };
    }

    get isNextDisabled() {
        return !this.form;
    }

    get isSearchMode() {
        return this.step === 1;
    }

    get cancelButtonLabel() {
        return this.isSearchMode || this.isDone ? 'Close' : 'Back';
    }

    get submitButtonLabel() {
        return this.isSearchMode ? 'Next' : 'Submit';
    }

    get isDone() {
        return !!this.submitResponse?.id;
    }

    get showSubmitButton() {
        return !this.isLoading && !this.isDone;
    }

    get showCancelButton() {
        return !this.isLoading && !this.isSearchMode;
    }
}
