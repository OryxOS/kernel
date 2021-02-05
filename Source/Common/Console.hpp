#pragma once

#include <HAL/Interface/Text.hpp>
#include <Libs/Std/Types.hpp>
#include <utility>

using namespace Types;

inline struct {
	template<typename T, typename ...Ts>
		void operator()(const char *fmt, T &&arg, Ts &&...args) {
			auto next = ProcessSingle(*fmt,)
		}
private:
	template<typename T>
		const char* ProcessSingle(const char *fmt, T &&arg) {
			while (*fmt != '\0') {
				switch (*fmt) {
					case '%': {
						char out = static_cast<char>(arg);
						Text::PutChr(out);
						return fmt++;
					}

					default : {
						Text::PutChr(*fmt);
						fmt++;
					}
				}
			}
		}

} LogImpl;

namespace Console {
	template<typename ...Args>
		void Log(const char *fmt, const Args ...args) {
			LogImpl(fmt, ...args);
		}	

	void Log(const char *fmt) {
		Text::PutStr(fmt);
	}
}