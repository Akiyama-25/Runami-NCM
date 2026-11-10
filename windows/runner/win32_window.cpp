#include "win32_window.h"

#include <flutter_windows.h>
#include "resource.h"

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() {
    UnregisterClassW(kWindowClassName, nullptr);
  }

  static WindowClassRegistrar* GetInstance() {
    static WindowClassRegistrar instance;
    return &instance;
  }

  void Register(HINSTANCE instance) {
    if (registered_) return;
    WNDCLASSW window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = instance;
    window_class.hIcon = LoadIcon(instance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpfnWndProc = &Win32Window::WndProc;
    RegisterClassW(&window_class);
    registered_ = true;
  }

 private:
  WindowClassRegistrar() = default;
  bool registered_ = false;
};

}  // namespace

Win32Window::Win32Window() {}

Win32Window::~Win32Window() {
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  HINSTANCE instance = GetModuleHandle(nullptr);
  WindowClassRegistrar::GetInstance()->Register(instance);

  const DWORD style = WS_OVERLAPPEDWINDOW;

  RECT window_rect = {
      static_cast<LONG>(origin.x),
      static_cast<LONG>(origin.y),
      static_cast<LONG>(origin.x + size.width),
      static_cast<LONG>(origin.y + size.height),
  };
  AdjustWindowRect(&window_rect, style, false);

  window_handle_ = CreateWindowExW(
      0, kWindowClassName, title.c_str(), style,
      window_rect.left, window_rect.top,
      window_rect.right - window_rect.left,
      window_rect.bottom - window_rect.top,
      nullptr, nullptr, instance, this);

  return window_handle_ != nullptr;
}

bool Win32Window::Show() {
  if (!window_handle_) return false;
  ShowWindow(window_handle_, SW_SHOWNORMAL);
  UpdateWindow(window_handle_);
  return true;
}

void Win32Window::Destroy() {
  OnDestroy();
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
}

HWND Win32Window::GetHandle() const {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

RECT Win32Window::GetClientArea() const {
  RECT rect;
  GetClientRect(window_handle_, &rect);
  return rect;
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();
  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);
  SetFocus(child_content_);
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {}

LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    that->window_handle_ = window;
  } else if (Win32Window* that = reinterpret_cast<Win32Window*>(
                 GetWindowLongPtr(window, GWLP_USERDATA))) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT Win32Window::MessageHandler(HWND hwnd,
                                    UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  switch (message) {
    case WM_CREATE:
      return OnCreate() ? 0 : -1;
    case WM_SIZE:
      if (child_content_ != nullptr) {
        RECT rect = GetClientArea();
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}
