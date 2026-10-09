import { createElement } from 'lwc'
import { CurrentPageReference } from 'lightning/navigation'
import TsaNetWebhookCreator from 'c/tsaNetWebhookCreator'
import registerWebhook from '@salesforce/apex/TSANetWebhookService.registerWebhook'
import getDefaultCallbackUrl from '@salesforce/apex/TSANetWebhookService.getDefaultCallbackUrl'

jest.mock(
    '@salesforce/apex/TSANetWebhookService.registerWebhook',
    () => ({ default: jest.fn() }),
    { virtual: true }
)

jest.mock(
    '@salesforce/apex/TSANetWebhookService.getDefaultCallbackUrl',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest')
        return { default: createApexTestWireAdapter(jest.fn()) }
    },
    { virtual: true }
)

const DEFAULT_CALLBACK = 'https://org.my.salesforce.com/services/apexrest/tsanetconnect/webhook'
const CREDENTIAL_ID = 'a00CREDENTIAL000001'
const WEBHOOK_ID = 'a01WEBHOOK00000001'

const encodeInContextOfRef = (recordId) =>
    '1.' + btoa(JSON.stringify({ attributes: { recordId, objectApiName: 'TSANet_Credentials__c' } }))

describe('c-tsa-net-webhook-creator', () => {
    let element

    beforeEach(() => {
        registerWebhook.mockResolvedValue(WEBHOOK_ID)
        element = createElement('c-tsa-net-webhook-creator', { is: TsaNetWebhookCreator })
        document.body.appendChild(element)
    })

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild)
        }
        jest.clearAllMocks()
    })

    const inputByLabel = (label) =>
        [...element.shadowRoot.querySelectorAll('lightning-input')].find((input) => input.label === label)

    const emitDefaultCallback = async () => {
        getDefaultCallbackUrl.emit(DEFAULT_CALLBACK)
        await Promise.resolve()
    }

    const fillBaseFields = async () => {
        await emitDefaultCallback()
        element.shadowRoot.querySelector('lightning-record-picker')
            .dispatchEvent(new CustomEvent('change', { detail: { recordId: CREDENTIAL_ID } }))
        element.shadowRoot.querySelectorAll('lightning-input, lightning-checkbox-group, lightning-record-picker')
            .forEach((el) => {
                el.reportValidity = jest.fn().mockReturnValue(true)
            })
        await Promise.resolve()
    }

    const fillOAuthFields = async () => {
        inputByLabel('Client Id').dispatchEvent(new CustomEvent('change', { detail: { value: 'client-id' } }))
        inputByLabel('Client Secret').dispatchEvent(new CustomEvent('change', { detail: { value: 'client-secret' } }))
        element.shadowRoot.querySelectorAll('lightning-input, lightning-checkbox-group, lightning-record-picker')
            .forEach((el) => {
                el.reportValidity = jest.fn().mockReturnValue(true)
            })
        await Promise.resolve()
    }

    it('prefills Org Domain and disables Callback URL', async () => {
        await emitDefaultCallback()

        const callbackInput = element.shadowRoot.querySelector('.callback-url-input')
        expect(callbackInput.value).toBe(DEFAULT_CALLBACK)
        expect(callbackInput.disabled).toBe(true)
        expect(element.shadowRoot.querySelector('.callback-host-combobox')).toBeNull()
    })

    it('enables Callback URL when Edit is checked', async () => {
        await emitDefaultCallback()

        element.shadowRoot.querySelector('.edit-callback-url')
            .dispatchEvent(new CustomEvent('change', { detail: { checked: true } }))
        await Promise.resolve()

        expect(element.shadowRoot.querySelector('.callback-url-input').disabled).toBe(false)
    })

    it('defaults both V1 event types', () => {
        const group = element.shadowRoot.querySelector('lightning-checkbox-group')
        expect(group.value).toEqual(['collaboration-request.created', 'note.created'])
    })

    it('reads the parent credential from related-list inContextOfRef', async () => {
        CurrentPageReference.emit({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'TSANetWebhook__c', actionName: 'new' },
            state: { inContextOfRef: encodeInContextOfRef(CREDENTIAL_ID) }
        })
        await Promise.resolve()

        const picker = element.shadowRoot.querySelector('lightning-record-picker')
        expect(picker.value).toBe(CREDENTIAL_ID)
    })

    it('does not register when the callback URL is missing', async () => {
        element.shadowRoot.querySelector('lightning-record-picker')
            .dispatchEvent(new CustomEvent('change', { detail: { recordId: CREDENTIAL_ID } }))
        await Promise.resolve()

        element.shadowRoot.querySelector('.save-button').click()
        await Promise.resolve()

        expect(registerWebhook).not.toHaveBeenCalled()
    })

    it('always shows Client Id and Client Secret', async () => {
        await emitDefaultCallback()

        const labels = [...element.shadowRoot.querySelectorAll('lightning-input')].map((input) => input.label)
        expect(labels).toContain('Client Id')
        expect(labels).toContain('Client Secret')
        expect(element.shadowRoot.querySelector('.add-oauth-button')).toBeNull()
        expect(element.shadowRoot.querySelector('.remove-oauth-button')).toBeNull()
    })

    it('requires Client Id and Client Secret', async () => {
        await fillBaseFields()

        element.shadowRoot.querySelector('.save-button').click()
        await Promise.resolve()

        expect(registerWebhook).not.toHaveBeenCalled()
    })

    it('registers the webhook with client credentials', async () => {
        await fillBaseFields()
        await fillOAuthFields()

        element.shadowRoot.querySelector('.save-button').click()
        await Promise.resolve()
        await Promise.resolve()

        expect(registerWebhook).toHaveBeenCalledWith({
            callbackUrl: DEFAULT_CALLBACK,
            eventTypes: ['collaboration-request.created', 'note.created'],
            clientId: 'client-id',
            clientSecret: 'client-secret',
            credentialId: CREDENTIAL_ID
        })
    })
})
