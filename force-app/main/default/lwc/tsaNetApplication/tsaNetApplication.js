import { LightningElement, track, api } from 'lwc'

import { getCaseInfo } from 'c/tsaNetHelper'

export default class TsaNetApplication extends LightningElement {

    @api recordId

    @track state = {}

    @track isLoading = false

    @track isNotAccess = false
    @track isUnauthorized = false

    connectedCallback(){
        this.getData()
    }

    getData(){
        this.isLoading = true
        getCaseInfo(this.recordId)
        .then(data => this.setData(data))
        .then(() => this.isLoading = false)
        .catch(error => {
            this.isUnauthorized = error?.body?.message == 'Username and password can not be empty!'
            this.isNotAccess = error?.body?.message == 'Insufficient permissions: secure query included inaccessible field'
            this.isLoading = false
        })
    }

    setData(data){
        this.state = data
    }

    handleRefresh(){
        this.isUnauthorized = false
        this.isLoading = false
        this.isNotAccess = false
        this.getData()
    }
}