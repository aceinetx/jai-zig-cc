add :: (a: s32, b: s32) -> s32 #foreign;

main :: () {
    print("Hello, World! %\n", add(35, 34));
}

#import "Basic";
