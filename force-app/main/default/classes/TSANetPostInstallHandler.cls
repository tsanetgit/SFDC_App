/**
 * Post-install handler for TSANet Connect.
 *
 * Stale Basic Auth credentials are not mutated here: InstallHandler has no
 * subscriber-admin user context. Admins disconnect those records and abort
 * leftover scheduled jobs in Setup after upgrade.
 *
 * The class stays public so subscriber code cannot invoke the handler; only
 * onInstall must be global, which the InstallHandler interface requires.
 */
public with sharing class TSANetPostInstallHandler implements InstallHandler {

    /**
     * Entry point invoked by the platform after install or upgrade.
     * @param context install context supplied by Salesforce
     */
    public void onInstall(InstallContext context){
        // No DML. Upgrade cleanup is a manual admin step.
    }
}

