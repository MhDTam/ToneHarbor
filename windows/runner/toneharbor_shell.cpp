#include "toneharbor_shell.h"
#include <shellapi.h>
#include <shlobj.h>
#include <vector>

namespace {
bool WriteUserString(const std::wstring& path, const wchar_t* name,
                     const std::wstring& value) {
  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) return false;
  const LONG result = RegSetValueExW(key, name, 0, REG_SZ,
      reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(key);
  return result == ERROR_SUCCESS;
}
}

bool RegisterToneHarborAudioTypes() {
  std::vector<wchar_t> path(32768);
  const DWORD length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
  if (length == 0 || length >= path.size()) return false;
  const std::wstring executable(path.data(), length);
  const std::wstring command = L"\"" + executable + L"\" \"%1\"";
  const std::wstring icon = L"\"" + executable + L"\",0";
  const std::wstring classes = L"Software\\Classes\\";
  const std::wstring app = classes + L"Applications\\ToneHarbor.exe";
  const std::wstring prog = classes + L"ToneHarbor.Audio.1";
  wchar_t previous[32768] = {};
  DWORD bytes = sizeof(previous);
  const bool changed = RegGetValueW(HKEY_CURRENT_USER,
      (app + L"\\shell\\open\\command").c_str(), nullptr, RRF_RT_REG_SZ,
      nullptr, previous, &bytes) != ERROR_SUCCESS || command != previous;
  bool ok = WriteUserString(app, L"FriendlyAppName", L"ToneHarbor");
  ok = WriteUserString(app + L"\\DefaultIcon", nullptr, icon) && ok;
  ok = WriteUserString(app + L"\\shell\\open\\command", nullptr, command) && ok;
  ok = WriteUserString(prog, nullptr, L"ToneHarbor audio") && ok;
  ok = WriteUserString(prog + L"\\DefaultIcon", nullptr, icon) && ok;
  ok = WriteUserString(prog + L"\\shell\\open\\command", nullptr, command) && ok;
  const std::wstring capabilities = L"Software\\ToneHarbor\\Capabilities";
  ok = WriteUserString(capabilities, L"ApplicationName", L"ToneHarbor") && ok;
  ok = WriteUserString(capabilities, L"ApplicationDescription", L"Local audio player and editor") && ok;
  for (const wchar_t* extension : {L".mp3", L".wav", L".flac", L".m4a", L".aac", L".ogg", L".opus", L".wma"}) {
    ok = WriteUserString(app + L"\\SupportedTypes", extension, L"") && ok;
    ok = WriteUserString(classes + extension + L"\\OpenWithProgids", L"ToneHarbor.Audio.1", L"") && ok;
    ok = WriteUserString(capabilities + L"\\FileAssociations", extension, L"ToneHarbor.Audio.1") && ok;
  }
  ok = WriteUserString(L"Software\\RegisteredApplications", L"ToneHarbor", capabilities) && ok;
  // Only advertise the handler. UserChoice/default associations are untouched.
  if (ok && changed) SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
  return ok;
}

bool ForwardToneHarborInvocation() {
  HWND window = nullptr;
  for (int i = 0; i < 30 && !window; ++i) {
    window = FindWindowW(kToneHarborWindowClass, nullptr);
    if (!window) Sleep(100);
  }
  if (!window) return false;
  DWORD owner = 0;
  GetWindowThreadProcessId(window, &owner);
  AllowSetForegroundWindow(owner);
  if (IsIconic(window)) ShowWindow(window, SW_RESTORE);
  SetForegroundWindow(window);
  const wchar_t* command = GetCommandLineW();
  COPYDATASTRUCT data{};
  data.dwData = kToneHarborOpenFiles;
  data.cbData = static_cast<DWORD>((wcslen(command) + 1) * sizeof(wchar_t));
  data.lpData = const_cast<wchar_t*>(command);
  DWORD_PTR acknowledgement = 0;
  return SendMessageTimeoutW(window, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&data),
      SMTO_ABORTIFHUNG, 5000, &acknowledgement) != 0 && acknowledgement != 0;
}
