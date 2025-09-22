#include "main.h"


ID3D11Device* pd3dDevice = nullptr;
ID3D11DeviceContext* pd3dDeviceContext = nullptr;
IDXGISwapChain* pSwapChain = nullptr;
ID3D11RenderTargetView* pMainRenderTargetView = nullptr;
HWND hDota2Window = nullptr;
HANDLE hDota2Process = nullptr;
bool bDraw = true;
float WIDTH = 400;
float HEIGHT = 200;


LRESULT __stdcall WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg)
    {
    case WM_SIZE:
        if (pd3dDevice != nullptr && wParam != SIZE_MINIMIZED)
        {
            CleanupRenderTarget();
            pSwapChain->ResizeBuffers(0, (UINT)LOWORD(lParam), (UINT)HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
            CreateRenderTarget();
        }
        return 0;

    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU)
            return 0;
        break;

    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;

    default:
        break;
    }
    return ::DefWindowProc(hWnd, msg, wParam, lParam);
}


int APIENTRY WinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPSTR lpCmdLine, _In_ int nCmdShow) {



    float value = 1200.0f;
    BYTE orgbytes[18];

    const WCHAR* moduleName = L"client.dll";
    DWORD processId = GetProcessIdByName(L"dota2.exe");
    if (processId == 0) {
        MessageBoxA(NULL, "Dota 2 is not running!", "Error", MB_ICONERROR | MB_OK);
        return 1;
    }

    hDota2Process = OpenProcess(PROCESS_ALL_ACCESS, FALSE, processId);
    if (hDota2Process == NULL) {
        MessageBoxA(NULL, "Failed to open Dota 2 process!", "Error", MB_ICONERROR | MB_OK);
        return 1;
    }

    hDota2Window = FindDota2Window();
    if (hDota2Process == NULL) {
        MessageBoxA(NULL, "Dota 2 Window Not Found", "Error", MB_ICONERROR | MB_OK);
        return 1;
    }
    SetForegroundWindow(hDota2Window);

    uintptr_t moduleBase = GetModuleBaseAddress(processId, moduleName);
    if (moduleBase == 0) {
        MessageBoxA(NULL, "client.dll not found!", "Error", MB_ICONERROR | MB_OK);
        CloseHandle(hDota2Process);
        return 1;
    }

    std::string pattern = "48 83 EC 28 E8 ?? ?? ?? FF F3 0F 10 00 48 83 C4 28 C3";

    uintptr_t addr = patternScanModule(moduleName, pattern);
    if (!addr) {
        MessageBoxA(NULL, "Pattern not found!", "Error", MB_ICONERROR | MB_OK);
        CloseHandle(hDota2Process);
        return 1;
    }
    ReadProcessMemory(hDota2Process, (LPCVOID)addr, orgbytes, sizeof(orgbytes), nullptr);
    WriteProcessMemory(hDota2Process, (LPVOID)(addr + 4), "\xB8\x00\xC0\x92\x44\x66\x0F\x6E\xC0\x48\x83\xC4\x28", 13, nullptr);





    ImGui_ImplWin32_EnableDpiAwareness();



    WNDCLASSEX wc;

    wc.cbClsExtra = NULL;
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.cbWndExtra = NULL;
    wc.hbrBackground = (HBRUSH)CreateSolidBrush(RGB(0, 0, 0));
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
    wc.hIconSm = LoadIcon(nullptr, IDI_APPLICATION);
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpfnWndProc = WndProc;
    wc.lpszClassName = _T("Dota 2 Zoom Hack");
    wc.lpszMenuName = nullptr;
    wc.style = CS_VREDRAW | CS_HREDRAW;

    ::RegisterClassEx(&wc);
    const HWND hwnd = ::CreateWindowExW(WS_EX_TOPMOST | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE, wc.lpszClassName, _T("Dota 2 Zoom Hack"), WS_POPUP, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), nullptr, nullptr, wc.hInstance, nullptr);

    SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
    const MARGINS margin = { -1, 0, 0, 0 };
    DwmExtendFrameIntoClientArea(hwnd, &margin);

    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClass(wc.lpszClassName, wc.hInstance);
        return 1;
    }

    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.Fonts->Clear();
    ImFont* fontbold = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\arialbd.ttf", 24.0f);
    io.IniFilename = nullptr;
    ImGui::StyleColorsDark();


    const HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    MONITORINFO info = {};
    info.cbSize = sizeof(MONITORINFO);
    GetMonitorInfo(monitor, &info);
    const int monitor_height = info.rcMonitor.bottom - info.rcMonitor.top;

    if (monitor_height > 1080)
    {
        const float fScale = 2.0f;
        ImFontConfig cfg;
        cfg.SizePixels = 13 * fScale;
        ImGui::GetIO().Fonts->AddFontDefault(&cfg);
    }



    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(pd3dDevice, pd3dDeviceContext);

    const ImVec4 clear_color = ImVec4(0.0f, 0.0f, 0.0f, 0.0f);



    bool bDone = false;

    while (!bDone)
    {
        MSG msg;
        while (::PeekMessage(&msg, nullptr, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);


            switch (msg.message) {
            case WM_QUIT:
            case WM_CLOSE:
            case WM_DESTROY:
            case WM_ENDSESSION:
                
                bDone = true;
                break;
            }
        }

        if (GetAsyncKeyState(VK_END) & 1)
            bDone = true;


        if (!IsWindowAlive())
            bDone = true;

        if (bDone) {
            WriteProcessMemory(hDota2Process, (LPVOID)addr, orgbytes, sizeof(orgbytes), nullptr);
            break;
        }


        if (hDota2Window != nullptr)
            MoveWindow(hwnd);


        if (!IsWindowFocus(hwnd))
        {
            const float clear_color_with_alpha[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w };
            pd3dDeviceContext->OMSetRenderTargets(1, &pMainRenderTargetView, nullptr);
            pd3dDeviceContext->ClearRenderTargetView(pMainRenderTargetView, clear_color_with_alpha);

            pSwapChain->Present(1, 0);

            continue;
        }

        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();
        {
            if (bDraw) {
                ImGui::SetNextWindowSize(ImVec2(WIDTH, HEIGHT));
                ImGui::Begin("General", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoBackground);

                auto draw = ImGui::GetWindowDrawList();
                const auto& p = ImGui::GetWindowPos();






                
                ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 255, 255, 195));
                ImGui::Text("MapZoom %.0f", value);
                ImGui::PopStyleColor();

                ImVec2 pos = ImGui::GetCursorScreenPos();
                float width = ImGui::GetContentRegionAvail().x;
                float height = 20.0f;

                ImGui::InvisibleButton("slider", ImVec2(width, height));
                bool is_hovered = ImGui::IsItemHovered();
                bool is_active = ImGui::IsItemActive();

                if (is_active) {
                    float mouse_x = ImGui::GetIO().MousePos.x - pos.x;
                    value = 1000.0f + (mouse_x / width) * (2000.0f - 1000.0f);
                    value = std::max(1000.0f, std::min(value, 2000.0f));
                    WriteProcessMemory(hDota2Process, (LPVOID)(addr + 5), &value, sizeof(float), nullptr);
                }


                ImVec2 p_min = pos;
                ImVec2 p_max = ImVec2(pos.x + width, pos.y + height);
                draw->AddRectFilledMultiColor(p_min, p_max, IM_COL32(50, 0, 0, 255), IM_COL32(150, 0, 0, 255), IM_COL32(150, 0, 0, 255), IM_COL32(50, 0, 0, 255));


                float frac = (value - 1000.0f) / (2000.0f - 1000.0f);
                ImVec2 fill_max = ImVec2(pos.x + width * frac, pos.y + height);
                draw->AddRectFilledMultiColor(p_min, fill_max, IM_COL32(200, 0, 0, 255), IM_COL32(255, 50, 50, 255), IM_COL32(255, 50, 50, 255), IM_COL32(200, 0, 0, 255));

                float grab_width = 10.0f;
                ImVec2 grab_pos = ImVec2(pos.x + width * frac - grab_width / 2, pos.y);
                uint32_t grab_color = is_active ? IM_COL32(255, 255, 255, 255) : (is_hovered ? IM_COL32(200, 200, 200, 255) : IM_COL32(220, 220, 220, 255));
                draw->AddRectFilled(grab_pos, ImVec2(grab_pos.x + grab_width, grab_pos.y + height), grab_color, 4.0f);




                ImGui::End();
            }
        }

        if (GetAsyncKeyState(VK_INSERT) & 1)
            bDraw = !bDraw;

        ImGui::EndFrame();

        if (bDraw)
            SetWindowLong(hwnd, GWL_EXSTYLE, WS_EX_TOPMOST | WS_EX_LAYERED | WS_EX_TOOLWINDOW);
        else
            SetWindowLong(hwnd, GWL_EXSTYLE, WS_EX_TOPMOST | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW);


        ImGui::Render();
        const float clear_color_with_alpha[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w };
        pd3dDeviceContext->OMSetRenderTargets(1, &pMainRenderTargetView, nullptr);
        pd3dDeviceContext->ClearRenderTargetView(pMainRenderTargetView, clear_color_with_alpha);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        pSwapChain->Present(1, 0);
    }



    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();

    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClass(wc.lpszClassName, wc.hInstance);


    ExitProcess(0);


	return 0;
}











DWORD GetProcessIdByName(const std::wstring& processName)
{
    PROCESSENTRY32 processInfo;
    processInfo.dwSize = sizeof(processInfo);

    HANDLE processesSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
    if (processesSnapshot == INVALID_HANDLE_VALUE) {
        return 0;
    }

    Process32First(processesSnapshot, &processInfo);
    if (!processName.compare(processInfo.szExeFile))
    {
        CloseHandle(processesSnapshot);
        return processInfo.th32ProcessID;
    }

    while (Process32Next(processesSnapshot, &processInfo))
    {
        if (!processName.compare(processInfo.szExeFile))
        {
            CloseHandle(processesSnapshot);
            return processInfo.th32ProcessID;
        }
    }

    CloseHandle(processesSnapshot);
    return 0;
}

uintptr_t GetModuleBaseAddress(DWORD processId, const WCHAR* moduleName) {
    uintptr_t baseAddress = 0;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, processId);
    MODULEENTRY32 moduleEntry;
    moduleEntry.dwSize = sizeof(MODULEENTRY32);

    if (Module32First(snapshot, &moduleEntry)) {
        do {
            if (wcscmp(moduleEntry.szModule, moduleName) == 0) {
                baseAddress = (uintptr_t)moduleEntry.modBaseAddr;
                break;
            }
        } while (Module32Next(snapshot, &moduleEntry));
    }

    CloseHandle(snapshot);
    return baseAddress;
}


uintptr_t patternScanModule(const WCHAR* moduleName, const std::string& patternStr) {

    uintptr_t baseAddress = 0;
    DWORD moduleSize = 0;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, GetProcessId(hDota2Process));
    MODULEENTRY32 moduleEntry;
    moduleEntry.dwSize = sizeof(MODULEENTRY32);

    if (Module32First(snapshot, &moduleEntry)) {
        do {
            if (wcscmp(moduleEntry.szModule, moduleName) == 0) {
                baseAddress = (uintptr_t)moduleEntry.modBaseAddr;
                moduleSize = moduleEntry.modBaseSize;
                break;
            }
        } while (Module32Next(snapshot, &moduleEntry));
    }

    CloseHandle(snapshot);
    if (!baseAddress) return 0;


    std::vector<BYTE> pattern;
    std::string mask;
    size_t i = 0;
    while (i < patternStr.size()) {
        if (std::isspace(patternStr[i])) { i++; continue; }
        if (patternStr[i] == '?') {
            pattern.push_back(0);
            mask += '?';
            if (i + 1 < patternStr.size() && patternStr[i + 1] == '?') i++;
        }
        else {
            pattern.push_back((BYTE)std::stoi(patternStr.substr(i, 2), nullptr, 16));
            mask += 'x';
            i++;
        }
        i += 2;
    }


    std::vector<BYTE> buffer(moduleSize);
    SIZE_T bytesRead;
    if (!ReadProcessMemory(hDota2Process, (LPCVOID)baseAddress, buffer.data(), moduleSize, &bytesRead))
        return 0;

    for (size_t i = 0; i < bytesRead - pattern.size(); ++i) {
        bool matched = true;
        for (size_t j = 0; j < pattern.size(); ++j) {
            if (mask[j] == 'x' && buffer[i + j] != pattern[j]) {
                matched = false;
                break;
            }
        }
        if (matched)
            return baseAddress + i;
    }

    return 0;
}






bool CreateDeviceD3D(HWND hWnd)
{
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory(&sd, sizeof(sd));
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    const UINT createDeviceFlags = 0;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0, };
    HRESULT res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &pSwapChain, &pd3dDevice, &featureLevel, &pd3dDeviceContext);
    if (res == DXGI_ERROR_UNSUPPORTED)
        res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &pSwapChain, &pd3dDevice, &featureLevel, &pd3dDeviceContext);
    if (res != S_OK)
        return false;

    CreateRenderTarget();
    return true;
}


void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer;
    pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    if (pBackBuffer != nullptr)
    {
        pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &pMainRenderTargetView);
        pBackBuffer->Release();
    }
}


void CleanupRenderTarget()
{
    if (pMainRenderTargetView)
    {
        pMainRenderTargetView->Release();
        pMainRenderTargetView = nullptr;
    }
}


bool IsWindowFocus(const HWND hCurrentProcessWindow)
{
    char lpCurrentWindowUsedClass[125];
    char lpCurrentWindowClass[125];
    char lpOverlayWindowClass[125];

    const HWND hCurrentWindowUsed = GetForegroundWindow();
    if (GetClassNameA(hCurrentWindowUsed, lpCurrentWindowUsedClass, sizeof(lpCurrentWindowUsedClass)) == 0)
        return false;

    if (GetClassNameA(hDota2Window, lpCurrentWindowClass, sizeof(lpCurrentWindowClass)) == 0)
        return false;

    if (GetClassNameA(hCurrentProcessWindow, lpOverlayWindowClass, sizeof(lpOverlayWindowClass)) == 0)
        return false;

    if (strcmp(lpCurrentWindowUsedClass, lpCurrentWindowClass) != 0 && strcmp(lpCurrentWindowUsedClass, lpOverlayWindowClass) != 0)
    {
        SetWindowLong(hCurrentProcessWindow, GWL_EXSTYLE, WS_EX_TOPMOST | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW);
        return false;
    }

    return true;
}

bool IsWindowAlive()
{


    if (hDota2Window == nullptr)
        return false;

    if (!IsWindow(hDota2Window))
        return false;


    return true;
}

void MoveWindow(HWND hCurrentProcessWindow)
{
    RECT rect;
    if (hDota2Window == nullptr)
        return;

    GetWindowRect(hDota2Window, &rect);

    int lWindowWidth = rect.right - rect.left;
    int lWindowHeight = rect.bottom - rect.top;

    lWindowWidth -= 5;
    lWindowHeight -= 29;

    SetWindowPos(hCurrentProcessWindow, nullptr, rect.left, rect.top, lWindowWidth, lWindowHeight, SWP_SHOWWINDOW);
}


void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (pSwapChain)
    {
        pSwapChain->Release();
        pSwapChain = nullptr;
    }

    if (pd3dDeviceContext)
    {
        pd3dDeviceContext->Release();
        pd3dDeviceContext = nullptr;
    }

    if (pd3dDevice)
    {
        pd3dDevice->Release();
        pd3dDevice = nullptr;
    }
}







HWND FindDota2Window()
{
    struct Finder {
        static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
            char title[256];
            GetWindowTextA(hwnd, title, sizeof(title));

            if (IsWindowVisible(hwnd) && strlen(title) > 0) {
                std::string windowTitle = title;
                if (windowTitle == "Dota 2") {
                    *(HWND*)lParam = hwnd;
                    return FALSE;
                }
            }
            return TRUE;
        }
    };

    HWND hDota = nullptr;
    EnumWindows(Finder::EnumWindowsProc, (LPARAM)&hDota);
    return hDota;
}
