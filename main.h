#pragma once
#define NOMINMAX
#include <Windows.h>
#include <dwmapi.h>
#include <d3dcompiler.h>
#include <DirectXMath.h>
#include <tchar.h>
#include <vector>
#include <TlHelp32.h>
#include <string>
#include <algorithm>
#include "d3d11.h"
#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_dx11.h"
#include "ImGui/imgui_impl_win32.h"



extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
HWND FindDota2Window();
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
bool IsWindowAlive();
bool IsWindowFocus(const HWND hCurrentProcessWindow);
void MoveWindow(HWND hCurrentProcessWindow);
uintptr_t GetModuleBaseAddress(DWORD processId, const WCHAR* moduleName);
uintptr_t patternScanModule(const WCHAR* moduleName, const std::string& patternStr);
DWORD GetProcessIdByName(const std::wstring& processName);

