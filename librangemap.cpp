#include "librangemap.h"
#include <vector>
#include "main.h"
#include <iostream>
using namespace RANGEMAP;


float main(int argc , float argv[]) {
	int argCount = argc;
	float argVariables[] = *argv;
	std::vector<float> args[argc];
	for (int x = 0; x < argc; x++) {
		args.push_back(argv[x]);
		std::cout << argv[x];
	}

}
