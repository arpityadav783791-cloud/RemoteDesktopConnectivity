#include <freerdp/freerdp.h>
#include <freerdp/settings.h>
#include <freerdp/settings_keys.h>
#include <freerdp/update.h>
#include <freerdp/gdi/gdi.h>
#include <freerdp/codec/color.h>
#include <freerdp/input.h>

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static freerdp* g_instance = NULL;
static pthread_t g_thread;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t g_connect_cond = PTHREAD_COND_INITIALIZER;

static int g_thread_started = 0;
static int g_connect_done = 0;
static int g_connect_result = 0;
static int g_stop_requested = 0;
static int g_connected = 0;

static uint8_t* g_frame = NULL;
static size_t g_frame_capacity = 0;
static size_t g_frame_size = 0;
static uint32_t g_frame_width = 0;
static uint32_t g_frame_height = 0;
static int g_frame_ready = 0;

static char g_last_error[512] = {0};

static void set_error_from_instance(freerdp* instance)
{
    g_last_error[0] = '\0';

    if (!instance || !instance->context)
        return;

    const UINT32 error = freerdp_get_last_error(instance->context);
    if (error == 0)
        return;

    const char* name = freerdp_get_last_error_name(error);
    const char* message = freerdp_get_last_error_string(error);

    snprintf(
        g_last_error,
        sizeof(g_last_error),
        "%s: %s [0x%08X]",
        name ? name : "FreeRDP error",
        message ? message : "Unknown error",
        error);
}

static void free_frame(void)
{
    free(g_frame);
    g_frame = NULL;
    g_frame_capacity = 0;
    g_frame_size = 0;
    g_frame_width = 0;
    g_frame_height = 0;
    g_frame_ready = 0;
}

static BOOL rdc_begin_paint(rdpContext* context)
{
    (void)context;
    return TRUE;
}

static BOOL rdc_end_paint(rdpContext* context)
{
    if (!context || !context->gdi)
        return FALSE;

    rdpGdi* gdi = context->gdi;

    if (!gdi->primary_buffer || gdi->width <= 0 || gdi->height <= 0)
        return TRUE;

    const uint32_t width = (uint32_t)gdi->width;
    const uint32_t height = (uint32_t)gdi->height;
    const size_t row_size = (size_t)width * 4;
    const size_t frame_size = row_size * height;

    pthread_mutex_lock(&g_lock);

    if (frame_size > g_frame_capacity)
    {
        uint8_t* resized = realloc(g_frame, frame_size);
        if (!resized)
        {
            pthread_mutex_unlock(&g_lock);
            return FALSE;
        }

        g_frame = resized;
        g_frame_capacity = frame_size;
    }

    for (uint32_t y = 0; y < height; y++)
    {
        memcpy(
            g_frame + ((size_t)y * row_size),
            gdi->primary_buffer + ((size_t)y * gdi->stride),
            row_size);
    }

    g_frame_width = width;
    g_frame_height = height;
    g_frame_size = frame_size;
    g_frame_ready = 1;

    pthread_mutex_unlock(&g_lock);

    return TRUE;
}

static BOOL rdc_desktop_resize(rdpContext* context)
{
    if (!context || !context->gdi || !context->settings)
        return FALSE;

    const uint32_t width =
        freerdp_settings_get_uint32(context->settings, FreeRDP_DesktopWidth);
    const uint32_t height =
        freerdp_settings_get_uint32(context->settings, FreeRDP_DesktopHeight);

    if (!gdi_resize(context->gdi, width, height))
        return FALSE;

    pthread_mutex_lock(&g_lock);
    g_frame_width = width;
    g_frame_height = height;
    g_frame_size = 0;
    g_frame_ready = 0;
    pthread_mutex_unlock(&g_lock);

    return TRUE;
}

static BOOL rdc_post_connect(freerdp* instance)
{
    if (!instance || !instance->context)
        return FALSE;

    if (!gdi_init(instance, PIXEL_FORMAT_RGBA32))
        return FALSE;

    instance->context->update->BeginPaint = rdc_begin_paint;
    instance->context->update->EndPaint = rdc_end_paint;
    instance->context->update->DesktopResize = rdc_desktop_resize;

    pthread_mutex_lock(&g_lock);
    if (instance->context->gdi)
    {
        g_frame_width = (uint32_t)instance->context->gdi->width;
        g_frame_height = (uint32_t)instance->context->gdi->height;
    }
    pthread_mutex_unlock(&g_lock);

    return TRUE;
}

static void rdc_post_disconnect(freerdp* instance)
{
    if (instance && instance->context && instance->context->gdi)
        gdi_free(instance);
}

static void signal_connect_result(int result)
{
    pthread_mutex_lock(&g_lock);
    g_connect_result = result;
    g_connect_done = 1;
    pthread_cond_signal(&g_connect_cond);
    pthread_mutex_unlock(&g_lock);
}

static void* rdc_session_thread(void* arg)
{
    freerdp* instance = (freerdp*)arg;
    const BOOL connected = freerdp_connect(instance);

    if (!connected)
    {
        pthread_mutex_lock(&g_lock);
        set_error_from_instance(instance);
        g_connected = 0;
        pthread_mutex_unlock(&g_lock);

        signal_connect_result(0);

        freerdp_disconnect(instance);

        pthread_mutex_lock(&g_lock);
        g_instance = NULL;
        pthread_mutex_unlock(&g_lock);

        return NULL;
    }

    pthread_mutex_lock(&g_lock);
    g_connected = 1;
    pthread_mutex_unlock(&g_lock);

    signal_connect_result(1);

    while (!freerdp_shall_disconnect_context(instance->context))
    {
        pthread_mutex_lock(&g_lock);
        const int stop = g_stop_requested;
        pthread_mutex_unlock(&g_lock);

        if (stop)
            break;

        HANDLE events[MAXIMUM_WAIT_OBJECTS] = {0};
        const DWORD count =
            freerdp_get_event_handles(instance->context, events, ARRAYSIZE(events));

        if (count == 0)
            break;

        const DWORD wait_result =
            WaitForMultipleObjects(count, events, FALSE, 100);

        if (wait_result == WAIT_FAILED)
            break;

        if (wait_result == WAIT_TIMEOUT)
            continue;

        if (!freerdp_check_event_handles(instance->context))
            break;
    }

    freerdp_disconnect(instance);

    pthread_mutex_lock(&g_lock);
    g_connected = 0;
    g_instance = NULL;
    pthread_mutex_unlock(&g_lock);

    return NULL;
}

int rdc_bridge_version(int* major, int* minor, int* revision)
{
    if (!major || !minor || !revision)
        return 0;

    freerdp_get_version(major, minor, revision);
    return 1;
}

int rdc_connect(
    const char* host,
    int port,
    const char* username,
    const char* password,
    const char* domain,
    int width,
    int height)
{
    if (!host || !username || !password)
        return 0;

    pthread_mutex_lock(&g_lock);

    if (g_thread_started || g_instance)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    g_last_error[0] = '\0';
    g_connect_done = 0;
    g_connect_result = 0;
    g_stop_requested = 0;
    g_connected = 0;
    g_frame_ready = 0;
    free_frame();

    g_instance = freerdp_new();
    if (!g_instance)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    pthread_mutex_unlock(&g_lock);

    if (!freerdp_context_new(g_instance))
        goto fail;

    rdpSettings* settings = g_instance->context->settings;

    if (!settings)
        goto fail;

    if (!freerdp_settings_set_string(
            settings, FreeRDP_ServerHostname, host))
        goto fail;

    if (!freerdp_settings_set_uint32(
            settings, FreeRDP_ServerPort, (UINT32)port))
        goto fail;

    if (!freerdp_settings_set_string(
            settings, FreeRDP_Username, username))
        goto fail;

    if (!freerdp_settings_set_string(
            settings, FreeRDP_Password, password))
        goto fail;

    if (domain && domain[0] != '\0')
    {
        if (!freerdp_settings_set_string(
                settings, FreeRDP_Domain, domain))
            goto fail;
    }

    if (!freerdp_settings_set_uint32(
            settings, FreeRDP_DesktopWidth,
            (UINT32)(width > 0 ? width : 1280)))
        goto fail;

    if (!freerdp_settings_set_uint32(
            settings, FreeRDP_DesktopHeight,
            (UINT32)(height > 0 ? height : 720)))
        goto fail;

    if (!freerdp_settings_set_uint32(
            settings, FreeRDP_ColorDepth, 32))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_SoftwareGdi, TRUE))
        goto fail;

    /* Strict local/remote isolation policy. */
    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectClipboard, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectDrives, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectPrinters, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_AudioCapture, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_AudioPlayback, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectSmartCards, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectSerialPorts, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_RedirectParallelPorts, FALSE))
        goto fail;

    if (!freerdp_settings_set_bool(
            settings, FreeRDP_DeviceRedirection, FALSE))
        goto fail;

    g_instance->PostConnect = rdc_post_connect;
    g_instance->PostDisconnect = rdc_post_disconnect;

    pthread_mutex_lock(&g_lock);
    g_thread_started = 1;
    pthread_mutex_unlock(&g_lock);

    if (pthread_create(&g_thread, NULL, rdc_session_thread, g_instance) != 0)
    {
        pthread_mutex_lock(&g_lock);
        g_thread_started = 0;
        pthread_mutex_unlock(&g_lock);
        goto fail;
    }

    /* The session runs in the native worker thread. */
    return 1;

fail:
    pthread_mutex_lock(&g_lock);
    set_error_from_instance(g_instance);

    if (g_instance && g_instance->context)
        freerdp_context_free(g_instance);

    if (g_instance)
        freerdp_free(g_instance);

    g_instance = NULL;
    g_thread_started = 0;
    pthread_mutex_unlock(&g_lock);

    return 0;
}

int rdc_disconnect(void)
{
    pthread_mutex_lock(&g_lock);

    if (!g_instance && !g_thread_started)
    {
        g_connected = 0;
        free_frame();
        pthread_mutex_unlock(&g_lock);
        return 1;
    }

    g_stop_requested = 1;
    freerdp* instance = g_instance;
    const int thread_started = g_thread_started;

    pthread_mutex_unlock(&g_lock);

    if (instance && instance->context && !g_connected)
        freerdp_abort_connect_context(instance->context);

    if (thread_started)
        pthread_join(g_thread, NULL);

    pthread_mutex_lock(&g_lock);
    g_thread_started = 0;
    g_instance = NULL;
    g_connected = 0;
    free_frame();
    pthread_mutex_unlock(&g_lock);

    return 1;
}

int rdc_is_connected(void)
{
    pthread_mutex_lock(&g_lock);
    const int connected = g_connected;
    pthread_mutex_unlock(&g_lock);
    return connected;
}

int rdc_connection_state(void)
{
    pthread_mutex_lock(&g_lock);

    int state = 0;

    if (g_connected)
        state = 2;
    else if (g_thread_started && !g_connect_done)
        state = 1;
    else if (g_thread_started && g_connect_done && g_connect_result == 0)
        state = 3;

    pthread_mutex_unlock(&g_lock);
    return state;
}

const char* rdc_last_error(void)
{
    return g_last_error;
}

int rdc_get_frame_info(
    uint32_t* width,
    uint32_t* height,
    uint32_t* size)
{
    if (!width || !height || !size)
        return 0;

    pthread_mutex_lock(&g_lock);

    *width = g_frame_width;
    *height = g_frame_height;
    *size = (uint32_t)g_frame_size;
    const int ready = g_frame_ready;

    pthread_mutex_unlock(&g_lock);

    return ready && *width > 0 && *height > 0 && *size > 0;
}

int rdc_copy_frame(uint8_t* destination, uint32_t capacity)
{
    if (!destination)
        return 0;

    pthread_mutex_lock(&g_lock);

    if (!g_frame_ready || !g_frame || capacity < g_frame_size)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    const uint32_t size = (uint32_t)g_frame_size;
    memcpy(destination, g_frame, size);
    g_frame_ready = 0;

    pthread_mutex_unlock(&g_lock);

    return (int)size;
}

int rdc_send_key(uint16_t flags, uint8_t code)
{
    pthread_mutex_lock(&g_lock);

    if (!g_instance || !g_connected || !g_instance->context ||
        !g_instance->context->input ||
        !g_instance->context->input->KeyboardEvent)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    const int result =
        g_instance->context->input->KeyboardEvent(
            g_instance->context->input, flags, code)
            ? 1
            : 0;

    pthread_mutex_unlock(&g_lock);
    return result;
}

int rdc_send_unicode(uint16_t flags, uint16_t code)
{
    pthread_mutex_lock(&g_lock);

    if (!g_instance || !g_connected || !g_instance->context ||
        !g_instance->context->input ||
        !g_instance->context->input->UnicodeKeyboardEvent)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    const int result =
        g_instance->context->input->UnicodeKeyboardEvent(
            g_instance->context->input, flags, code)
            ? 1
            : 0;

    pthread_mutex_unlock(&g_lock);
    return result;
}

int rdc_send_mouse(uint16_t flags, uint16_t x, uint16_t y)
{
    pthread_mutex_lock(&g_lock);

    if (!g_instance || !g_connected || !g_instance->context ||
        !g_instance->context->input ||
        !g_instance->context->input->MouseEvent)
    {
        pthread_mutex_unlock(&g_lock);
        return 0;
    }

    const int result =
        g_instance->context->input->MouseEvent(
            g_instance->context->input, flags, x, y)
            ? 1
            : 0;

    pthread_mutex_unlock(&g_lock);
    return result;
}
