import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation"

import getAllRelatedFiles from '@salesforce/apex/TSANetUtils.getAllRelatedFiles'
import getAttachmentConfig from '@salesforce/apex/TSANetService.getAttachmentConfig'
import sendAttachment from '@salesforce/apex/TSANetService.sendAttachment'
 
export default class UploadAttachment extends NavigationMixin(LightningElement) {

    @api recordId
    @api record

    isDone = false
    hasConfig = false
    isLoading = true

    @api isQuickAction

    @track contentVersions = []
    @track files = []

    connectedCallback(){
        if(this.record?.tsanetconnect__Token__c){
            this.isLoading = true
            getAttachmentConfig({ token: this.record?.tsanetconnect__Token__c }).then(response => {
                let config = JSON.parse(response)

                if(config?.receiver?.parameters?.password){
                    this.hasConfig = true

                    getAllRelatedFiles({ caseId: this.record?.Id }).then(contentVersions => {
                        contentVersions.forEach(cv => {
                            cv['isSelected'] = false
                        })
                        this.contentVersions = contentVersions
                    })

                }
                this.isLoading = false

            }).catch(error => {
                console.error(error)
                this.isLoading = false
            })
        }
       
    }

    handleFileChange(event) {
        let files = event.target.files;

        for (const [key, file] of Object.entries(files)) {

            if (file) {
                const reader = new FileReader();
                reader.onload = () => {
                    let fileData = {
                        fileId: file.name + '-' + file?.size,
                        filename: file.name,
                        base64: reader.result.split(',')[1]
                    };

                    this.files.push(fileData)
                };
                reader.readAsDataURL(file);
            }
        }
    }

    handleDeleteFile(event){
        let fileId = event.currentTarget.dataset.fileId

        let found = this.files.find(file => ( file.fileId == fileId ))

        if(found?.cvId){
            this.contentVersions.forEach(cv => {
                if(cv.Id == found?.cvId){
                    cv['isSelected'] = !cv['isSelected']
                }
            })
        }

        this.files = this.files.filter(file => ( file.fileId != fileId ))
    }

    handleUpload() {
        if (this.files.length) {

            this.isLoading = true

            sendAttachment({ token: this.record?.tsanetconnect__Token__c, files: this.files }).then(response => {

                let results = JSON.parse(response)

                results.forEach(result => {
                    this.files.forEach(file => {
                        if(file?.filename == result?.fileName){
                            file['resultIconName'] = result?.receiverStatus == 'SUCCESS' ? 'action:approval' : 'action:close'
                            file['resultMessage'] = result?.receiverMessage
                        }
                    })
                })

                this.isDone = true
                this.isLoading = false

            }).catch(error => {
                console.error(error)
                this.isLoading = false
            })
            
        }
    }

    handleSelectContentVersion(event){
        let cvId = event.currentTarget.dataset.id

        this.contentVersions.forEach(cv => {
            if(cv.Id == cvId){
                cv['isSelected'] = !cv['isSelected']

                if(cv.isSelected){
                    this.files.push({
                        filename: cv.Title,
                        base64: undefined,
                        fileId: cv.Id,
                        cvId: cv.Id
                    })
                } 
                    
            }
        })
    }


    get unSelectedFiles(){
        return this.contentVersions.filter(item => !item?.isSelected)
    }

    get relatedFilesTitle(){
        return 'Related Files (' + this.contentVersions.length + ') '
    }

    get selectedFilesTitle(){
        return 'Selected Files (' + this.files.length + ') '
    }

    get receivedCompanyName(){
        return this.record?.tsanetconnect__receivedCompanyName__c
    }

    get closeButtonLabel(){
        return this.isDone ? 'Done' : 'Close'
    }

    handleClose(){
        this.handleCloseWindow(true)
    }

    handleCloseWindow(isRefresh){
        this.clearState()
        if(!this.isQuickAction){
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    refresh: isRefresh
                }
            }))
        } else {

            this[NavigationMixin.Navigate]({    
                type: "standard__recordPage",
                attributes: {
                    recordId: this.recordId,
                    actionName: "view"
                }
            })
            //location.reload()
            this.dispatchEvent(new CustomEvent('close'))
        }
    }

    clearState(){
        this.record = undefined
        this.isLoading = false
        this.isDone = false
        this.files = []
    }
}