#pragma once

#include <Common/Types.hxx>

using namespace Types;

namespace VGA {
	enum Color: char {
		Black,
		Blue,
		Green,
		Cyan,
		Red,
		Purple,
		Brown,
		Gray,
		DarkGray,
		LightBlue,
		LightGreen,
		LightCyan,
		LightRed,
		LightPurple,
		Yellow,
		White,
	};

	void Scroll(int amount);
	void Clear();

	void SetBg(Color background);
	void SetFg(Color foreground);

	void PutChar(char c);
	void PutStr(const char* str, u16 color);
}