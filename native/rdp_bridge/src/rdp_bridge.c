#include <freerdp/freerdp.h>
#include <freerdp/settings.h>
#include <freerdp/settings_keys.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static freerdp *g_instance = NULL;
static char g_last_error[512] = {0};

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
    g_last_error[0] = '\0';
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
    if (g_instance && g_instance->context)
    {
        const UINT32 error =
            freerdp_get_last_error(g_instance->context);

        const char *name =
            freerdp_get_last_error_name(error);

        const char *message =
            freerdp_get_last_error_string(error);

        if (error != 0)
        {
            snprintf(
                g_last_error,
                sizeof(g_last_error),
                "%s: %s [0x%08X]",
                name ? name : "FreeRDP error",
                message ? message : "Unknown error",
                error);
        }
    }

    if (g_instance && g_instance->context)
        freerdp_context_free(g_instance);

    if (g_instance)
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

const char *rdc_last_error(void)
{
    return g_last_error;
}