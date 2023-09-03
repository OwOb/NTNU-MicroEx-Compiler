#include <iostream>
#include <string>
#include <vector>

extern int yyparse(void);
extern std::vector<std::string> ASM;

int main()
{
	yyparse();
	for (size_t i = 0; i < ASM.size(); ++i) {
		if (ASM[i].find("lb&") == 0) {
			std::cout << ASM[i];
		}
		else {
			std::cout << "\t" << ASM[i] << "\n";
		}
	}
}