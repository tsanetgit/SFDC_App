import { createElement } from 'lwc'
import TsaNetCredentialCreator from 'c/tsaNetCredentialCreator'
import getNamedCredentials from '@salesforce/apex/NamedCredentialSelector.getNamedCredentials'

jest.mock(
    '@salesforce/apex/NamedCredentialSelector.getNamedCredentials',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest')
        return { default: createApexTestWireAdapter(jest.fn()) }
    },
    { virtual: true }
)

const NAMED_CREDENTIALS = [
    { label: 'TSANet API', value: 'tsanetconnect__TSANetAPI', isCustom: false },
    { label: 'TSANet API Dev', value: 'TSANetAPIDev', isCustom: true }
]

describe('c-tsa-net-credential-creator', () => {
    let element

    beforeEach(() => {
        element = createElement('c-tsa-net-credential-creator', { is: TsaNetCredentialCreator })
        document.body.appendChild(element)
    })

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild)
        }
        jest.clearAllMocks()
    })

    const INTEGRATION_USER_ID = '005USER000000001'

    /** Emits the wire data and selects the given Named Credential in the combobox. */
    const selectNamedCredential = async (value) => {
        getNamedCredentials.emit(NAMED_CREDENTIALS)
        await Promise.resolve()

        const combobox = element.shadowRoot.querySelector('lightning-combobox')
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value } }))
        await Promise.resolve()
    }

    const selectIntegrationUser = async () => {
        element.shadowRoot.querySelector('c-user-lookup')
            .dispatchEvent(new CustomEvent('select', { detail: { value: INTEGRATION_USER_ID } }))
        await Promise.resolve()
    }

    it('shows a named credential dropdown and an integration user field', async () => {
        getNamedCredentials.emit(NAMED_CREDENTIALS)
        await Promise.resolve()

        const combobox = element.shadowRoot.querySelector('lightning-combobox')
        expect(combobox).not.toBeNull()
        expect(combobox.options).toEqual([
            { label: 'TSANet API (tsanetconnect__TSANetAPI)', value: 'tsanetconnect__TSANetAPI' },
            { label: 'TSANet API Dev (TSANetAPIDev) — custom', value: 'TSANetAPIDev' }
        ])
        expect(element.shadowRoot.querySelector('c-user-lookup')).not.toBeNull()
    })

    it('falls back to manual entry when the named credential list cannot be read', async () => {
        getNamedCredentials.error()
        await Promise.resolve()

        expect(element.shadowRoot.querySelector('lightning-combobox')).toBeNull()
        expect(element.shadowRoot.querySelector('lightning-input')).not.toBeNull()
    })

    it('saves the selected named credential', async () => {
        await selectNamedCredential('tsanetconnect__TSANetAPI')
        await selectIntegrationUser()

        const form = element.shadowRoot.querySelector('lightning-record-edit-form')
        form.submit = jest.fn()

        form.dispatchEvent(new CustomEvent('submit', { detail: { fields: {} } }))
        await Promise.resolve()

        expect(form.submit).toHaveBeenCalledWith({
            NamedCredential__c: 'tsanetconnect__TSANetAPI',
            IntegrationUser__c: INTEGRATION_USER_ID,
            isPrimary__c: true
        })
    })

    it('saves a custom named credential without a namespace prefix', async () => {
        await selectNamedCredential('TSANetAPIDev')
        await selectIntegrationUser()

        const form = element.shadowRoot.querySelector('lightning-record-edit-form')
        form.submit = jest.fn()

        form.dispatchEvent(new CustomEvent('submit', { detail: { fields: {} } }))
        await Promise.resolve()

        expect(form.submit).toHaveBeenCalledWith({
            NamedCredential__c: 'TSANetAPIDev',
            IntegrationUser__c: INTEGRATION_USER_ID,
            isPrimary__c: true
        })
    })

    it('does not save without a named credential', async () => {
        getNamedCredentials.emit(NAMED_CREDENTIALS)
        await Promise.resolve()
        await selectIntegrationUser()

        const form = element.shadowRoot.querySelector('lightning-record-edit-form')
        form.submit = jest.fn()

        form.dispatchEvent(new CustomEvent('submit', { detail: { fields: {} } }))
        await Promise.resolve()

        expect(form.submit).not.toHaveBeenCalled()
    })

    it('does not save without an integration user', async () => {
        await selectNamedCredential('tsanetconnect__TSANetAPI')

        const form = element.shadowRoot.querySelector('lightning-record-edit-form')
        form.submit = jest.fn()

        form.dispatchEvent(new CustomEvent('submit', { detail: { fields: {} } }))
        await Promise.resolve()

        expect(form.submit).not.toHaveBeenCalled()
    })
})
