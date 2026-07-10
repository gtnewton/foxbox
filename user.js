// foxbox baseline preferences
// This file is read by Firefox on every startup and overrides prefs.js.
// Edit here, not in prefs.js. Changes take effect on next foxbox launch.

// -- Cache (core to ephemeral dev use) ---------------------------------------
user_pref("browser.cache.disk.enable",   false);
user_pref("browser.cache.memory.enable", false);

// -- DevTools ----------------------------------------------------------------
user_pref("devtools.everOpened",                          true);
user_pref("devtools.selfxss.count",                       5);
user_pref("devtools.toolbox.host",                        "window");
user_pref("devtools.toolbox.previousHost",                "bottom");
user_pref("devtools.toolbox.selectedTool",                "webconsole");
user_pref("devtools.toolbox.zoomValue",                   "1.7");
user_pref("devtools.toolsidebar-height.inspector",        350);
user_pref("devtools.toolsidebar-width.inspector",         600);
user_pref("devtools.toolsidebar-width.inspector.splitsidebar", 300);

// -- Telemetry / studies off -------------------------------------------------
user_pref("app.normandy.enabled",                         false);
user_pref("app.normandy.first_run",                       false);
user_pref("app.shield.optoutstudies.enabled",             false);
user_pref("browser.discovery.enabled",                    false);
user_pref("browser.ping-centre.telemetry",                false);
user_pref("datareporting.healthreport.uploadEnabled",     false);
user_pref("datareporting.policy.dataSubmissionPolicyAcceptedVersion", 2);
// Kills the "choose what I share" data-reporting infobar outright rather
// than relying on dataSubmissionPolicyAcceptedVersion staying in sync with
// Mozilla's currentPolicyVersion (TelemetryReportingPolicy.sys.mjs
// _shouldNotifyDataReportingPolicy checks this pref directly).
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("datareporting.usage.uploadEnabled",            false);
user_pref("nimbus.rollouts.enabled",                      false);
user_pref("toolkit.telemetry.enabled",                    false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun",   false);
user_pref("toolkit.telemetry.unified",                    false);

// -- Extensions --------------------------------------------------------------
// Enable sideloaded profile extensions automatically instead of disabling them
// and waiting for the manual "enable add-on" prompt. This is what lets the
// install warm-up activate the bundled extensions without interaction.
user_pref("extensions.autoDisableScopes",  0);
user_pref("extensions.startupScanScopes",  1);

// -- Passwords / autofill ----------------------------------------------------
user_pref("extensions.formautofill.creditCards.enabled",  false);
user_pref("signon.management.page.breach-alerts.enabled", false);
user_pref("signon.rememberSignons",                       false);

// -- Suppress first-run UI ---------------------------------------------------
user_pref("browser.aboutConfig.showWarning",              false);
user_pref("browser.aboutwelcome.didSeeFinalScreen",       true);
user_pref("browser.aboutwelcome.enabled",                 false);
user_pref("browser.bookmarks.restore_default_bookmarks",  false);
user_pref("browser.laterrun.enabled",                     true);
user_pref("browser.migration.enabled",                    false);
// Every foxbox session clones the master profile fresh, so this pref never
// gets durably written on its own. Without it, BrowserHandler.majorUpgrade
// reads true on every launch, which can trigger Firefox's post-update
// spotlight dialog. "ignore" is Mozilla's own documented automation value
// (bug 1351422) for suppressing majorUpgrade detection outright.
user_pref("browser.startup.homepage_override.mstone",     "ignore");
user_pref("browser.rights.3.shown",                       true);
// Not under the browser.* prefix. This is the actual switch behind the
// mandatory Terms of Use / data-collection consent spotlight — it's what
// remote/shared/RecommendedPreferences.sys.mjs sets for Marionette/automation
// profiles. browser.aboutwelcome.enabled does not affect it.
user_pref("termsofuse.bypassNotification",                true);
user_pref("browser.termsofuse.prefMigrationCheck",        true);
user_pref("doh-rollout.doneFirstRun",                     true);
user_pref("trailhead.firstrun.didSeeAboutWelcome",        true);

// -- Sponsored / promoted content off ----------------------------------------
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored",             false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes",   false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites",     false);

// -- DoH (CIRA Canadian Shield) ----------------------------------------------
user_pref("doh-rollout.home-region",  "CA");
user_pref("doh-rollout.mode",         2);
user_pref("doh-rollout.self-enabled", true);
user_pref("doh-rollout.uri",          "https://private.canadianshield.cira.ca/dns-query");

// -- Chrome theme ------------------------------------------------------------
// Load <profile>/chrome/userChrome.css so foxbox sessions are visually distinct
// from a normal Firefox. install.sh stages the stylesheet and its SVG assets.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// -- UI ----------------------------------------------------------------------
user_pref("browser.search.region",                "CA");
user_pref("browser.theme.toolbar-theme",          0);
user_pref("browser.toolbars.bookmarks.visibility","never");
user_pref("sidebar.revamp",                       true);
user_pref("sidebar.visibility",                   "hide-sidebar");

user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"downloads-button\",\"unified-extensions-button\",\"_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"firefox-view-button\",\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\",\"screenshot-button\",\"_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"unified-extensions-area\",\"toolbar-menubar\",\"TabsToolbar\"],\"currentVersion\":23,\"newElementCount\":1}");

// -- New tab pinned sites ----------------------------------------------------
user_pref("browser.newtabpage.pinned", "[{\"url\":\"https://127.0.0.1:8443\",\"label\":\"Local server (8443)\"},{\"url\":\"http://127.0.0.1:8000\",\"label\":\"Local server (8000)\"}]");

// -- Privacy -----------------------------------------------------------------
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.sanitize.timeSpan",           0);
