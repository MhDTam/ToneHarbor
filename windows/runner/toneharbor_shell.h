#ifndef TONEHARBOR_SHELL_H_
#define TONEHARBOR_SHELL_H_
#include <windows.h>
#include <string>

inline constexpr wchar_t kToneHarborWindowClass[] = L"TONEHARBOR_RUNNER_WINDOW";
inline constexpr ULONG_PTR kToneHarborOpenFiles = 0x54484D46;
bool RegisterToneHarborAudioTypes();
bool ForwardToneHarborInvocation();
#endif
