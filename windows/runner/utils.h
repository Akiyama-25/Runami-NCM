#pragma once

#include <string>
#include <vector>

std::vector<std::string> GetCommandLineArguments();
std::wstring Utf16FromUtf8(const std::string& utf8_string);
std::string Utf8FromUtf16(const std::wstring& utf16_string);
