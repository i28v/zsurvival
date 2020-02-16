CXX = nasm
CXXFLAGS = -f bin
SOURCE = src/main.asm
OUTPUT = bin/Release/ZSURV.COM

build: 
	$(CXX) $(CXXFLAGS) $(SOURCE) -o $(OUTPUT) 