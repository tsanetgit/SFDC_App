# CLAUDE.md: SFDC_App

TSANet Connect for Salesforce: a second-generation managed package (namespace `tsanetconnect`) that lets a member's support agents create, work and close TSANet Connect collaboration cases from Salesforce. It calls the Connect REST API through the named credentials in `force-app/main/default/namedCredentials`. Members install released versions, so packaged components are a contract with them. This repo is public.

## Build and test

Install the [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) and Node, then `npm install`. The repo has no lock file; don't commit the one `npm install` creates.

```bash
npm test                    # LWC Jest unit tests (sfdx-lwc-jest)
npx eslint <changed .js files under aura/ or lwc/>

# Apex tests run in a Salesforce org, not locally: your own development org (see Environments)
sf apex run test --target-org tsanet_dev --code-coverage --result-format human --wait 30

# Deploy force-app to the org authenticated as alias tsanet_dev
npm run deploy:dev
```

No hook or CI runs these, so run them yourself before committing. `npm run lint` already reports errors on `main`, so lint the files you change and add no new errors. Don't run `npm run prettier` or `prettier:verify`: no Prettier config loads the Apex and XML plugins, so they fail on most files, and `prettier` would rewrite thousands of them.

## Layout

- `force-app/main/default/classes`: Apex, with the `@IsTest` classes alongside
- `force-app/main/default/lwc`: Lightning web components; Jest tests live in each component's `__tests__`
- `force-app/main/default/aura`: Aura components, most of them behind the quick actions in `quickActions/`
- `force-app/main/default/flows`, `triggers`, `objects`, `layouts`, `flexipages`, `permissionsets`: the rest of the packaged metadata
- `force-app/main/default/namedCredentials`, `externalCredentials`: one pair per Connect environment (Dev, Beta, Test, and Prod as `TSANetAPI` with `TSANetExternalCredentialProd`)
- `sfdx-project.json`: package definition, version number and package version aliases
- `scripts/`, `config/`: Salesforce DX scaffolding

## Conventions

- Claude branches from `main` as `feat/<slug>` or `fix/<slug>` and opens draft PRs. A draft is only the starting point. The person who asked for the change reads it and takes it out of draft (Claude doesn't), Copilot reviews it, QA runs in a new session, and a person approves and merges. A PR should be out of draft when it merges. Claude never pushes to `main` directly.
- Releases are different: the release maintainer commits each release to `main` directly. Claude doesn't build, version or promote packages.
- Don't rename or delete a packaged component, or change a field's or object's API name, without TSANet's agreement: members' orgs upgrade in place, and a managed package can't rename what a released version shipped.
- The API contract: the OpenAPI spec in tsanetgit/Connect-API-Code is the source of truth for endpoints and fields.

## Environments

- **Salesforce org:** each developer deploys to and tests in their own development org, authenticated as `tsanet_dev` (`sf org login web --alias tsanet_dev`). Never deploy to the packaging org that owns the `tsanetconnect` namespace, or to a member's org.
- **Connect API:** work against the Dev or Beta environment (named credentials `TSANetAPIDev` and `TSANetAPIBeta`) with test cases only, never `TSANetAPI`, which is Prod. No production credentials on this machine.
- Never put hostnames, org IDs, credentials or real member or case data in code, tests, docs, commit messages or PR text.

## Off-limits

- The Prod named and external credentials (`TSANetAPI`, `TSANetExternalCredentialProd`), and every endpoint or scope value in the credentials metadata.
- `sfdx-project.json` versioning: `versionName`, `versionNumber`, `ancestorId`, `namespace` and `packageAliases`. Releases set them.
- `npm run package:beta` and `npm run package:promote`.
- `.sfdx/`: local Salesforce tooling state that is committed here. Never edit it or commit changes to it.
