#include "include/flutter_file_upload/flutter_file_upload_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_file_upload_plugin.h"

void FlutterFileUploadPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_file_upload::FlutterFileUploadPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
