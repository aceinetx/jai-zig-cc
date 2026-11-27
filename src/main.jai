add :: (a: s32, b: s32) -> s32 #foreign;
hello :: () #foreign;

Krbc_State :: void;

krbc_Optimize :: enum {
    NONE;
    MID;
    HIGH;
};

krbc_State_init :: () -> *Krbc_State #foreign;
krbc_load :: (state: *Krbc_State, optimize_level: krbc_Optimize, code: *u8) #foreign;
krbc_State_deinit :: (state: *Krbc_State) #foreign;
krbc_dump_ops :: (state: *Krbc_State) #foreign;
krbc_interpret :: (state: *Krbc_State, userdata: *void, output_f: *void, input_f: *void) #foreign;

main :: () {
    print("Hello, World! %\n", add(35, 34));
    hello();

    code : *u8 = "++++++++++[>+>+++>+++++++>++++++++++<<<<-]>>>++.>+.+++++++..+++.<<++.>+++++++++++++++.>.+++.------.--------.<<+.<.";
    state := krbc_State_init();
    defer krbc_State_deinit(state);

    krbc_load(state, .MID, code);

    krbc_dump_ops(state);

    krbc_interpret(state, null, null, null);
}

#import "Basic";
