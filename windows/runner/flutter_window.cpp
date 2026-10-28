#include "flutter_window.h"
#include "toneharbor_shell.h"
#include "utils.h"
#include <shellapi.h>

#include <optional>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
    const std::vector<std::string>& arguments)
    : project_(project), pending_files_(arguments) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  RegisterToneHarborAudioTypes();
  media_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.musiconvert.mp3noads/media_open",
      &flutter::StandardMethodCodec::GetInstance());
  media_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "getInitialMedia") { result->NotImplemented(); return; }
    media_ready_ = true;
    flutter::EncodableList files;
    for (const auto& path : pending_files_) files.emplace_back(path);
    pending_files_.clear();
    flutter::EncodableMap payload;
    payload[flutter::EncodableValue("paths")] = flutter::EncodableValue(files);
    result->Success(flutter::EncodableValue(payload));
  });

  hotkey_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "toneharbor/hotkeys",
      &flutter::StandardMethodCodec::GetInstance());
  hotkey_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "unregisterAll") {
      for (const auto& shortcut : hotkeys_) UnregisterHotKey(GetHandle(), shortcut.first);
      hotkeys_.clear();
      result->Success();
      return;
    }
    if (call.method_name() != "register") { result->NotImplemented(); return; }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) { result->Error("arguments", "Missing shortcut arguments"); return; }
    auto read = [args](const char* name) -> int {
      auto it = args->find(flutter::EncodableValue(name));
      if (it == args->end()) return 0;
      if (const auto* value = std::get_if<int32_t>(&it->second)) return *value;
      if (const auto* value = std::get_if<int64_t>(&it->second)) return static_cast<int>(*value);
      return 0;
    };
    const int id = read("id");
    const UINT modifiers = static_cast<UINT>(read("modifiers"));
    const UINT key = static_cast<UINT>(read("key"));
    if (id < 1 || id > 100 || key == 0) { result->Error("arguments", "Invalid shortcut"); return; }
    const auto old = hotkeys_.find(id);
    if (old != hotkeys_.end() && old->second == std::make_pair(modifiers, key)) {
      result->Success(flutter::EncodableValue(true)); return;
    }
    const auto previous = old == hotkeys_.end() ? std::pair<UINT, UINT>{0, 0} : old->second;
    UnregisterHotKey(GetHandle(), id);
    if (!RegisterHotKey(GetHandle(), id, modifiers | MOD_NOREPEAT, key)) {
      if (previous.second) RegisterHotKey(GetHandle(), id, previous.first | MOD_NOREPEAT, previous.second);
      result->Success(flutter::EncodableValue(false)); return;
    }
    hotkeys_[id] = {modifiers, key};
    result->Success(flutter::EncodableValue(true));
  });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  for (const auto& shortcut : hotkeys_) UnregisterHotKey(GetHandle(), shortcut.first);
  hotkeys_.clear();
  hotkey_channel_.reset();
  media_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_COPYDATA && lparam) {
    const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (data->dwData == kToneHarborOpenFiles && data->lpData &&
        data->cbData >= sizeof(wchar_t) && data->cbData <= 1024 * 1024 &&
        data->cbData % sizeof(wchar_t) == 0) {
      const auto* command = static_cast<const wchar_t*>(data->lpData);
      if (command[data->cbData / sizeof(wchar_t) - 1] != L'\0') return FALSE;
      int count = 0;
      wchar_t** arguments = CommandLineToArgvW(command, &count);
      if (!arguments) return FALSE;
      std::vector<std::string> files;
      for (int i = 1; i < count; ++i) files.push_back(Utf8FromUtf16(arguments[i]));
      LocalFree(arguments);
      OpenFiles(files);
      return TRUE;
    }
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_HOTKEY:
      if (hotkey_channel_) hotkey_channel_->InvokeMethod("pressed", std::make_unique<flutter::EncodableValue>(static_cast<int32_t>(wparam)));
      return 0;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::OpenFiles(const std::vector<std::string>& files) {
  if (!media_ready_ || !media_channel_) {
    if (!files.empty()) pending_files_ = files;
    return;
  }
  if (files.empty()) return;
  flutter::EncodableList paths;
  for (const auto& path : files) paths.emplace_back(path);
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("paths")] = flutter::EncodableValue(paths);
  media_channel_->InvokeMethod("openMedia", std::make_unique<flutter::EncodableValue>(payload));
}
