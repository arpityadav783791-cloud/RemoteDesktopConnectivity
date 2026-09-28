#include <freerdp/freerdp.h>
#include <freerdp/settings.h>
#include <freerdp/settings_keys.h>

#include <stdlib.h>

static freerdp *g_instance = NULL;

int rdc_bridge_version(int *major, int *minor, int *revision)
{
    if (!major || !minor || !revision)
        return 0;

    freerdp_get_version(major, minor, revision);
    return 1;
}

int rdc_connect(
    const char *host,
    int port,
    const char *username,
    const char *password,
    const char *domain)
{
    if (!host || !username || !password)
        return 0;

    if (g_instance != NULL)
        return 0;

    g_instance = freerdp_new();

    if (!g_instance)
        return 0;

    if (!freerdp_context_new(g_instance))
    {
        freerdp_free(g_instance);
        g_instance = NULL;
        return 0;
    }

    rdpSettings *settings = g_instance->context->settings;

    if (!settings)
    {
        freerdp_context_free(g_instance);
        freerdp_free(g_instance);
        g_instance = NULL;
        return 0;
    }

    if (!settings)
    {
        freerdp_free(g_instance);
        g_instance = NULL;
        return 0;
    }

    /*
     * Basic connection settings.
     */
    if (!freerdp_settings_set_string(
            settings,
            FreeRDP_ServerHostname,
            host))
        goto fail;

    if (!freerdp_settings_set_uint32(
            settings,
            FreeRDP_ServerPort,
            (UINT32)port))
        goto fail;

    if (!freerdp_settings_set_string(
            settings,
            FreeRDP_Username,
            username))
        goto fail;

    if (!freerdp_settings_set_string(
            settings,
            FreeRDP_Password,
            password))
        goto fail;

    if (domain && domain[0] != '\0')
    {
        if (!freerdp_settings_set_string(
                settings,
                FreeRDP_Domain,
                domain))
            goto fail;
    }

    /*
     * SECURITY POLICY
     *
     * The application intentionally does NOT allow
     * local/remote resource sharing.
     */

    /* Clipboard */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectClipboard,
            FALSE))
        goto fail;

    /* Drive / filesystem redirection */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectDrives,
            FALSE))
        goto fail;

    /* Printer redirection */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectPrinters,
            FALSE))
        goto fail;

    /* Microphone/audio capture */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_AudioCapture,
            FALSE))
        goto fail;

    /* Remote audio playback */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_AudioPlayback,
            FALSE))
        goto fail;

    /* Smart cards */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectSmartCards,
            FALSE))
        goto fail;

    /* Serial ports */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectSerialPorts,
            FALSE))
        goto fail;

    /* Parallel ports */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_RedirectParallelPorts,
            FALSE))
        goto fail;

    /*
     * Disable general device redirection.
     */
    if (!freerdp_settings_set_bool(
            settings,
            FreeRDP_DeviceRedirection,
            FALSE))
        goto fail;

    /*
     * Establish the RDP connection.
     */
    if (!freerdp_connect(g_instance))
        goto fail;

    return 1;

fail:
    freerdp_free(g_instance);
    g_instance = NULL;
    return 0;
}

int rdc_disconnect(void)
{
    if (!g_instance)
        return 1;

    freerdp_disconnect(g_instance);
    freerdp_context_free(g_instance);
    freerdp_free(g_instance);

    g_instance = NULL;

    return 1;
}

int rdc_is_connected(void)
{
    return g_instance != NULL ? 1 : 0;
}