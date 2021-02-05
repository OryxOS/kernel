#pragma once

namespace Text {
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

	void Clear();

	void SetBg(Color background);
	void SetFg(Color foreground);

	void PutChr(char c);
	void PutStr(const char* str);

	void Log(const char* fmt);
	//void LogLn();
}